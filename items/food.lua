local class = require('lib.middleclass')
local item = require('items.item')
local eatTask = require('tasks.task_entity_eat')

local food = class('food', item)

function food:initialize(name, map, posX, posY, amount, maxStack)
	item.initialize(self, name, map, posX, posY, amount, maxStack)

	self.satiety = 50
end

function food:getPossibleTasks()
	local tasks = item.getPossibleTasks(self)

	if self.owned then return {} end

	local et = eatTask:new(self)
	table.insert(tasks, et)

	return tasks
end

function food:getType()
	return item.getType(self) .. "[[food]]"
end

function food:getClass()
	return food
end

return food