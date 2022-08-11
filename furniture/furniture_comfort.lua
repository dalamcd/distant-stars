local class = require('middleclass')
local furniture = require('furniture.furniture')
local sitTask = require('tasks.task_entity_sit')

local comfortFurniture = class('comfortFurniture', furniture)

function comfortFurniture:initialize(name, map, posX, posY)
	furniture.initialize(self, name, map, posX, posY)

	self.sittable = true
	self.sleepable = true
	self.maxComfort = 20
	self.comfortFactor = 1
	self.occupant = nil
end

function comfortFurniture:getPossibleTasks()
	local tasks = {sitTask:new(self)}

	return tasks
end

function comfortFurniture:beOccupiedBy(entity)
	if self.sittable or self.sleepable then
		self.occupant = entity
		return true
	end
	return false
end

function comfortFurniture:isWalkable()
	return true
end

function comfortFurniture:getType()
	return furniture.getType(self) .. "[[comfort]]"
end

return comfortFurniture