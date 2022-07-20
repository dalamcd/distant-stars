local class = require('middleclass')
local game = require('game')
local task = require('task')

item = class('item', drawable)

function item:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, posX, posY)
	drawable.initialize(self, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, posX, posY, 1, 1)

	name = name or "unknown item"
	self.name = name
end

function item:draw()
	drawable.draw(self, (self.x - 1)*TILE_SIZE, (self.y - 1)*TILE_SIZE)
end

function item:beDropped(entity)
	self.xOffset = self.origXOffset
	self.yOffset = self.origYOffset
	self.carried = false
end

function item:getAvailableJobs()
	local tasks = {}
	
	if self.x ~= 2 or self.y ~= 8 then
		function startFunc(tself)
			local p = tself:getParams()
			p.pickup = self:getPickupTask(tself)
			p.drop = self:getDropTask(tself)
			p.dest = getGameMap():getTile(2, 8)
			if not self.carried then
				p.entity:pushTask(p.pickup)
			else
				p.entity:pushTask(p.drop)
			end
		end

		function runFunc(tself)
			local p = tself:getParams()
			if not p.pickedUp and not p.dropped then
				p.entity:pushTask(p.pickup)
			elseif p.pickedUp and not p.dropped then
				p.entity:pushTask(p.drop)
			elseif p.dropped then
				tself:complete()
			end
		end

		function strFunc(tself)
			return "Hauling " .. self.name .. " to tile (1, 1)"
		end

		local haulTask = task:new(nil, nil, strFunc, nil, startFunc, runFunc, nil, nil, nil)
		table.insert(tasks, haulTask)
	end

	return tasks
end

function item:getPossibleTasks()
	local tasks = {}

	if self.carried then return {} end

	local pickupTask = self:getPickupTask()
	table.insert(tasks, pickupTask)

	return tasks
end

function item:getPickupTask(parentTask)
	function startFunc(tself)
		local p = tself:getParams()
		if p.entity.x ~= self.x or p.entity.y ~= self.y then
			local walkTask = p.entity:getWalkTask(p.map:getTile(self.x, self.y), tself)
			p.entity:pushTask(walkTask)
		else
			tself:complete()
		end
	end

	function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == self.x and p.entity.y == self.y then
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end

	function endFunc(tself)
		local p = tself:getParams()
		if not tself.abandoned then
			local m = getGameMap()
			local s = m:inStockpile(self.x, self.y)
			self.carried = true
			if s then
				s:removeFromStockpile(self)
			end
			p.pickedUp = true
			p.entity:pickUp(self)
		end
	end

	function strFunc(tself)
		return "Moving to (" .. self.x .. ", " .. self.y .. ") to pick up " .. self.name
	end

	function contextFunc(tself)
		return "Pick up " .. self.name
	end

	local pickupTask = task:new(params, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
	return pickupTask
end

-- requires params.dest (destination tile)
function item:getDropTask(parentTask)
	function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			p.entity:drop(self)
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end
	
	function startFunc(tself)
		local p = tself:getParams()
		if not self.carried then
			tself:complete()
			return
		end

		if p.entity.x ~= p.dest.x or p.entity.y ~= p.dest.y then
			local walkTask = p.entity:getWalkTask(p.dest, tself)
			p.entity:pushTask(walkTask)			
		else
			p.entity:drop(self)
			tself:complete()
		end
	end

	function endFunc(tself)
		local p = tself:getParams()
		if not tself.abandoned then
			local m = getGameMap()
			local s = m:inStockpile(self.x, self.y)
			p.dropped = true
			if s then
				s:addToStockpile(self)
			end
		end
	end

	function contextFunc(tself)
		return "Drop " .. self.name
	end

	function strFunc(tself)
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
	return "item"
end

function item:getPluralName()
	return self.name + "s"
end

function item:__tostring()
	return "Item(".. self.name .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return item