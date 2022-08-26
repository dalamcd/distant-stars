local class = require('lib.middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local sitTask = require('tasks.task_entity_sit')
local timer = require('timer')
local drawable = require('drawable')

local vacTask = class('vacTask', task)

local function startFunc(self)

end

local function runFunc(self)
	if not self.entity.map:isVoid(self.entity.x, self.entity.y) then
		self:complete()
		return
	end

	self.entity:wiggle(math.pi*2)
	self.entity:adjustHealth(-1, "the icy grip of the void")
end

local function endFunc(self)

end

local function abandonFunc(self)

end

local function strFunc(self)
	return "Dying in the cold, dark grip of the void"
end

local function contextFunc(self)
	return "<dying in space>"
end

function vacTask:initialize(parentTask)
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
end

return vacTask