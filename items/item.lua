local class = require('lib.middleclass')
local game = require('game')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local pickupTask = require('tasks.task_item_pickup')
local dropTask = require('tasks.task_item_drop')
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

function item:initialize(name, map, posX, posY, amount, maxStack)
	local i = item:retrieve(name)
	if i then
		drawable.initialize(self, i.tileset, i.tilesetX, i.tilesetY, i.spriteWidth, i.spriteHeight, posX, posY, 1, 1)
	else
		error("attempted to initialize " .. self.name .. " but no item with that name was found")
	end

	amount = amount or 1
	maxStack = maxStack or 50

	self.name = name
	self.map = map
	self.amount = amount
	self.maxStack = maxStack
end

function item:draw()
	local c = self.map.camera
	local x = c:getRelativeX((self.x - 1)*TILE_SIZE)
	local y = c:getRelativeY((self.y - 1)*TILE_SIZE)
	drawable.draw(self, x, y, c.scale)
	if self.amount > 1 then
		drawable.drawSubText(self, self.amount, x + c.scale*(TILE_SIZE/2 - love.graphics.getFont():getWidth(self.amount)/2), y + TILE_SIZE*c.scale/2, c.scale)
	end
end

function item:removedFromInventory(entity)
	self.owner = nil
	self.owned = false
	self.x = entity.x
	self.y = entity.y
	self.xOffset = self.origXOffset
	self.yOffset = self.origYOffset
	--self:addedToTile()
end

function item:addedToInventory(entity)
	self.owner = entity
	self.owned = true
	self.x = entity.x
	self.y = entity.y
end

function item:adjustAmount(amt)
	self.amount = self.amount + amt
	if self.amount <= 0 then
		self:delete()
	end
end

function item:addedToTile()
	for _, mapItem in ipairs(self.map:getItemsInTile(self.map:getTile(self.x, self.y))) do
		if mapItem.uid ~= self.uid then
			local tmp = self:mergeWith(mapItem)
			if tmp ~= 0 then
				local t = self.map:getRandomWalkableTileInRadius(self.x, self.y, 1)
				if self.amount > mapItem.amount then
					mapItem.x = t.x
					mapItem.y = t.y
					mapItem:addedToTile()
				else
					self.x = t.x
					self.y = t.y
					self:addedToTile()
				end
			end
		end
	end
end

function item:mergeWith(mergeItem)

	if self:getType() ~= mergeItem:getType() or mergeItem.uid == self.uid then return false end

	if self.amount + mergeItem.amount < self.maxStack then
		self:adjustAmount(mergeItem.amount)
		mergeItem:delete()
		return 0
	elseif self.amount < self.maxStack then
		local diff = self.maxStack - self.amount
		mergeItem.amount = mergeItem.amount - (self.maxStack - self.amount)
		self.amount = self.maxStack
		return diff
	end
	return -1
end

function item:split(amt)
	if self.amount >= amt then
		local tmp = self:getClass():new(self.name, self.map, self.x, self.y, amt, self.maxStack)
		self:adjustAmount(-amt)
		return tmp
	else
		print("failed split")
		return false
	end
end

function item:delete()
	if self.owned then
		self.owner:removeFromInventory(self)
	end
	if self.map then
		self.map:removeItem(self)
	end
end

function item:getAvailableJobs()
	local tasks = {}

	if self.x ~= 2 or self.y ~= 8 then
		local function startFunc(tself)
			local p = tself:getParams()
			p.pickup = pickupTask:new(self, tself)
			p.drop = dropTask:new(self, tself)
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

	local pt = pickupTask:new(self)
	table.insert(tasks, pt)

	return tasks
end

function item:setPos(x, y, xOffset, yOffset)
	self.x = x
	self.y = y
	self.xOffset = xOffset
	self.yOffset = yOffset
end

function item:getType()
	return drawable.getType(self) .. "[[item]][[" .. self.name .. "]]"
end

function item:getClass()
	return item
end

function item:getPluralName()
	return self.name + "s"
end

function item:__tostring()
	return "Item(".. self.amount .. " of " .. self.name .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return item