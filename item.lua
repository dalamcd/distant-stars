local class = require('middleclass')
local game = require('game')
local task = require('task')
local drawable = require('drawable')

local item = class('item', drawable)

item.static._loaded_items = {}

function item.static:load(name, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight)
	local internalItem = self._loaded_items[name]

	if internalItem then
		return internalItem
	else
		self._loaded_items[name] = {
			tileset = tileset,
			tilesetX = tilesetX,
			tilesetY = tilesetY,
			spriteWidth = spriteWidth,
			spriteHeight = spriteHeight
		}
	end
end

function item.static:retrieve(name)
	return self._loaded_items[name] or false
end

function item:initialize(name, map, posX, posY)
	local i = item:retrieve(name)
	if i then
		drawable.initialize(self, i.tileset, i.tilesetX, i.tilesetY, i.spriteWidth, i.spriteHeight, posX, posY, 1, 1)
	else
		error("attempted to initialize " .. self.name .. " but no item with that name was found")
	end

	self.name = name
	self.map = map
end

function item:draw()
	local c = self.map.camera
	drawable.draw(self, c:getRelativeX((self.x - 1)*TILE_SIZE), c:getRelativeY((self.y - 1)*TILE_SIZE), c.scale)
end

function item:removedFromInventory(entity)
	self.owner = nil
	self.owned = false
	self.x = entity.x
	self.y = entity.y
	self.xOffset = self.origXOffset
	self.yOffset = self.origYOffset
end

function item:addedToInventory(entity)
	self.owner = entity
	self.owned = true
	self.x = entity.x
	self.y = entity.y
end

function item:getAvailableJobs()
	local tasks = {}
	
	if self.x ~= 2 or self.y ~= 8 then
		local function startFunc(tself)
			local p = tself:getParams()
			p.pickup = self:getPickupTask(tself)
			p.drop = self:getDropTask(tself)
			p.dest = self.map:getTile(2, 8)
			if not self.owned then
				p.entity:pushTask(p.pickup)
			else
				p.entity:pushTask(p.drop)
			end
		end

		local function runFunc(tself)
			local p = tself:getParams()
			if not p.pickedUp and not p.dropped then
				p.entity:pushTask(p.pickup)
			elseif p.pickedUp and not p.dropped then
				p.entity:pushTask(p.drop)
			elseif p.dropped then
				tself:complete()
			end
		end

		local function strFunc(tself)
			return "Hauling " .. self.name .. " to tile (1, 1)"
		end

		local haulTask = task:new(nil, nil, strFunc, nil, startFunc, runFunc, nil, nil, nil)
		table.insert(tasks, haulTask)
	end

	return tasks
end

function item:getPossibleTasks()
	local tasks = {}

	if self.owned then return {} end

	local pickupTask = self:getPickupTask()
	table.insert(tasks, pickupTask)

	return tasks
end

function item:getPickupTask(parentTask)
	local function startFunc(tself)
		local p = tself:getParams()
		if p.entity.x ~= self.x or p.entity.y ~= self.y then
			local walkTask = p.entity:getWalkTask(p.map:getTile(self.x, self.y), tself)
			p.entity:pushTask(walkTask)
		else
			tself:complete()
		end
	end

	local function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == self.x and p.entity.y == self.y then
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end

	local function endFunc(tself)
		local p = tself:getParams()
		if not tself.abandoned then
			local s = self.map:inStockpile(self.x, self.y)
			self.owned = true
			if s then
				s:removeFromStockpile(self)
			end
			p.pickedUp = true
			p.entity:addToInventory(self)
		end
	end

	local function strFunc(tself)
		return "Moving to (" .. self.x .. ", " .. self.y .. ") to pick up " .. self.name
	end

	local function contextFunc(tself)
		return "Pick up " .. self.name
	end

	local pickupTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
	return pickupTask
end

-- requires params.dest (destination tile)
function item:getDropTask(parentTask)
	local function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			p.entity:removeFromInventory(self)
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end
	
	local function startFunc(tself)
		local p = tself:getParams()
		if not self.owned then
			tself:complete()
			return
		end

		if p.entity.x ~= p.dest.x or p.entity.y ~= p.dest.y then
			local walkTask = p.entity:getWalkTask(p.dest, tself)
			p.entity:pushTask(walkTask)			
		else
			p.entity:removeFromInventory(self)
			tself:complete()
		end
	end

	local function endFunc(tself)
		local p = tself:getParams()
		if not tself.abandoned then
			local s = self.map:inStockpile(self.x, self.y)
			p.dropped = true
			if s then
				s:addToStockpile(self)
			end
		end
	end

	local function contextFunc(tself)
		return "Drop " .. self.name
	end

	local function strFunc(tself)
		return "Dropping " .. self.name
	end

	local dropTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
	return dropTask
end

function item:setPos(x, y, xOffset, yOffset)
	self.x = x
	self.y = y
	self.xOffset = xOffset
	self.yOffset = yOffset
end

function item:getType()
	return drawable.getType(self) .. "[[item]]"
end

function item:getPluralName()
	return self.name + "s"
end

function item:__tostring()
	return "Item(".. self.name .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return item