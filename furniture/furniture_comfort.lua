local class = require('lib.middleclass')
local furniture = require('furniture.furniture')
local sitTask = require('tasks.task_entity_sit')

local comfortFurniture = class('comfortFurniture', furniture)

function comfortFurniture:initialize(name, label, map, posX, posY)
	local mobj = furniture.initialize(self, name, label, map, posX, posY)

	self.sittable = mobj.sittable or false
	self.sleepable = mobj.sleepable or false
	self.maxComfort = mobj.maxComfort or 0
	self.comfortFactor = mobj.comfortFactor or 0
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

function comfortFurniture:beUnnocupiedBy(entity)
	if self.occupant and self.occupant.uid == entity.uid then
		self.occupant = nil
		return true
	end
	return false
end

function comfortFurniture:isWalkable()
	return true
end

function comfortFurniture:isOccupied()
	return self.occupant
end

function comfortFurniture:getClassName()
	return 'comfort'
end

function comfortFurniture:getClassPath()
	return 'furniture.furniture_comfort'
end

function comfortFurniture:getType()
	return furniture.getType(self) .. "[[comfort]]"
end

return comfortFurniture