local class = require('middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_walk')

local eatTask = class('eatTask', task)

local function startFunc(self)
	if self.entity.x ~= self.item.x or self.entity.y ~= self.item.y then
		local wt = walkTask:new(self.entity.map:getTile(self.item.x, self.item.y), self)
		self.entity:pushTask(wt)
	else
		self:complete()
	end
end

local function runFunc(self)
	local p = self:getParams()
	if not self.entity.walking and self.entity.x == self.item.x and self.entity.y == self.item.y then
		self:complete()
	elseif not p.routeFound then
		self.finished = true
	end
end

local function endFunc(self)
	if not self.abandoned then
		self.entity:adjustSatiation(self.item.satiety)
		self.item:adjustAmount(-1)
	end
end

local function strFunc(self)
	return "Moving to (" .. self.item.x .. ", " .. self.item.y .. ") to eat " .. self.item.name
end

local function contextFunc(self)
	return "Eat " .. self.item.name
end

function eatTask:initialize(item, parentTask)
	if not item then error("eatTask initialized with no item") end
	if not item:isType("food") then error("eatTask initialized with inedible item") end

	self.item = item
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
end

return eatTask