local class = require('middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_walk')

local dropTask = class('dropTask', task)

local function runFunc(self)
	local p = self:getParams()
	if not self.entity.walking and self.entity.x == self.destination.x and self.entity.y == self.destination.y then
		self.entity:removeFromInventory(self.item)
		self:complete()
	elseif not p.routeFound then
		self.finished = true
	end
end

local function startFunc(self)
	local p = self:getParams()
	if not self.item.owned then
		self:complete()
		return
	end

	if self.entity.x ~= self.destination.x or self.entity.y ~= self.destination.y then
		local wt = walkTask:new(self.destination, self)
		self.entity:pushTask(wt)
	else
		self.entity:removeFromInventory(self.item)
		self:complete()
	end
end

local function endFunc(self)
	local p = self:getParams()
	if not self.abandoned then
		local s = self.item.map:inStockpile(self.item.x, self.item.y)
		p.dropped = true
		if s then
			s:addToStockpile(self.item)
		end
	end
end

local function contextFunc(self)
	return "Drop " .. self.item.name
end

local function strFunc(self)
	return "Dropping " .. self.item.name
end

function dropTask:initialize(item, destination, parentTask)
	if not item then error("dropTask initialized with no item") end
	if not destination then error("dropTask initialized with no destination") end

	self.item = item
	self.destination = destination
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
end

return dropTask