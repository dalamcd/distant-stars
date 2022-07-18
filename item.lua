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


function item:getPossibleTasks(map, entity)
	local tasks = {}
	local params = {startFunc = {}}

	if self.carried then return {} end

	-- PICKUP ITEM
	function startFunc(tself)
		if entity.x ~= self.x or entity.y ~= self.y then
			local walkTask = entity:getWalkTask(map, map:getTile(self.x, self.y), tself)
			entity:pushTask(walkTask)
		else
			tself:complete()
		end
	end

	function runFunc(tself)
		if entity.x == self.x and entity.y == self.y then
			tself:complete()
		elseif not tself:getParams().startFunc.routeFound then
			tself.finished = true
		end
	end

	function endFunc(tself)
		self.carried = true
		entity:pickUp(self)
	end

	function strFunc(tself)
		return "Moving to (" .. self.x .. ", " .. self.y .. ") to pick up " .. self.name
	end

	function contextFunc(tself)
		return "Pick up " .. self.name
	end

	local pickupTask = task:new(params, contextFunc, strFunc, nil, startFunc, runFunc, endFunc)
	table.insert(tasks, pickupTask)
	-- END PICKUP ITEM

	return tasks
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

function item:__tostring()
	return "Item(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ")"
end

return item