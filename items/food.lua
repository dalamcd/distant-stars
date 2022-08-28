local class = require('lib.middleclass')
local item = require('items.item')
local eatTask = require('tasks.task_entity_eat')

local food = class('food', item)

function food:initialize(name, label, map, posX, posY)
	local obj = item.initialize(self, name, label, map, posX, posY)

	self.nourishment = obj.nourishment or 0
end

function food:getPossibleTasks()
	local tasks = item.getPossibleTasks(self)

	if self.owned then return {} end

	local et = eatTask:new(self)
	table.insert(tasks, et)

	return tasks
end

function food:getClassName()
	return 'food'
end

function food:getClassPath()
	return 'items.food'
end

function food:getType()
	return item.getType(self) .. "[[food]]"
end

function food:getClass()
	return food
end

return food