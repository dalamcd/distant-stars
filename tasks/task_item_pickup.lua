local class = require('middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_walk')

local pickupTask = class('pickupTask', task)

local function startFunc(self)
	local p = self:getParams()
	if self.entity.x ~= self.item.x or self.entity.y ~= self.item.y then
		local wt = walkTask:new(p.map:getTile(self.item.x, self.item.y), self)
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
	local p = self:getParams()
	if not self.abandoned then
		local s = self.item.map:inStockpile(self.item.x, self.item.y)
		self.item.owned = true
		if s then
			s:removeFromStockpile(self.item)
		end
		p.pickedUp = true
		self.entity:addToInventory(self.item)
	end
end

local function strFunc(self)
	return "Moving to (" .. self.item.x .. ", " .. self.item.y .. ") to pick up " .. self.item.name
end

local function contextFunc(self)
	return "Pick up " .. self.item.name
end

function pickupTask:initialize(item, parentTask)
	if not item then error("pickupTask initialized with no item") end

	self.item = item
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
end

return pickupTask