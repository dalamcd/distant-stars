local class = require('middleclass')
local game = require('game')
local task = require('task')

item = class('item')

function item:initialize(imgPath, x, y, name)
	name = name or "unknown item"
	self.sprite = love.graphics.newImage(imgPath)
	self.x = x
	self.y = y
	self.xOffset = 0
	self.yOffset = 0
	self.imgYOffset = TILE_SIZE - self.sprite:getHeight()
	self.imgXOffset = (TILE_SIZE - self.sprite:getWidth())/2
	self.name = name
end

function item:draw()
	draw(self.sprite, (self.x - 1)*TILE_SIZE + self.xOffset + self.imgXOffset, (self.y - 1)*TILE_SIZE + self.yOffset + self.imgYOffset)
end

function item:inBounds(x, y)
	if(x - self:getWorldX() <= TILE_SIZE and x - self:getWorldX() >= 0) then
		if(y - self:getWorldY() <= TILE_SIZE and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function item:beDropped(entity)
	self.carried = false
end


function item:getPossibleTasks(map, entity)
	local tasks = {}

	if self.carried then return {} end
	local params = {}
	params.startFunc = {}
	params.startFunc.routeFound = true

	-- PICKUP ITEM
	function startFunc(tself)
		if entity.x ~= self.x or entity.y ~= self.y then
			entity:walkRoute(map, {x=self.x, y=self.y}, false, params)
		else
			tself:complete()
		end
	end

	function runFunc(tself)
		if entity.x == self.x and entity.y == self.y then
			tself:complete()
		elseif not tself.params.startFunc.routeFound then
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

	local pickupTask = task:new(contextFunc, strFunc, nil, startFunc, runFunc, endFunc, params)
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

function item:getWorldX()
	return (self.x - 1)*TILE_SIZE + self.xOffset
end

function item:getWorldY()
	return (self.y - 1)*TILE_SIZE + self.yOffset
end

function item:getWorldCenterY()
	return (self.y - 1 + 1/2)*TILE_SIZE + self.yOffset
end

function item:getWorldCenterX()
	return (self.x - 1 + 1/2)*TILE_SIZE + self.xOffset
end

function item:getPos()
	return {x=self.x, y=self.y}
end

function item:__tostring()
	return "Item(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ")"
end

return item