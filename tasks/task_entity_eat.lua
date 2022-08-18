local class = require('lib.middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local sitTask = require('tasks.task_entity_sit')
local timer = require('timer')
local drawable = require('drawable')

local eatTask = class('eatTask', task)

local function startFunc(self)
	if self.item:isReserved() then
		self:abandon()
		return
	end
	if self.entity.x ~= self.item.x or self.entity.y ~= self.item.y then
		self.item:reserveFor(self.entity)
		local wt = walkTask:new(self.entity.map:getTile(self.item.x, self.item.y), self)
		self.entity:pushTask(wt)
	else
		self:complete()
	end
end

local function complete(self)
	if not self.timer then
		self.timer = timer:new(30)
	end
	local status, count = self.timer:tick()
	if status then
		self.count = count
	else
		self:complete()
	end
end

local function runFunc(self)
	local p = self:getParams()

	if self.gettingSeated then
		if p.reachedSeat then
			complete(self)
		end
	elseif not self.entity.walking and self.entity.x == self.entity.destination.x and self.entity.y == self.entity.destination.y then
		if self.item.amount > 0 then
			local singleItem = self.item:split(1)
			if singleItem then
				self.item:unreserve(self.entity)
				self.item = singleItem
				self.entity:addToInventory(singleItem)
				local seat = self.entity.map:getNearbyObject('comfort', self.entity.x, self.entity.y)
				if seat and not seat:isReserved() then
					self.gettingSeated = seat
					local st = sitTask:new(seat, self)
					self.entity:pushTask(st)
				else
					complete(self)
				end
			end
		else
			self:abandon()
			self:complete()
		end
	elseif not p.routeFound then
		self.finished = true
	end
end

local function endFunc(self)
	self.item:unreserve(self.entity)
	if not self.abandoned then
		self.entity:adjustSatiation(self.item.satiety)
		self.item:adjustAmount(-1)
	end
end

local function abandonFunc(self)
	self:complete()
end

local function strFunc(self)
	if self.timer then
		return "Eating " .. self.item.name .. ": " .. self.count
	end

	if self.gettingSeated then
		return "Going to " .. self.gettingSeated.name .. " to sit and eat " .. self.item.name
	else
		return "Going to eat " .. self.item.name
	end
end

local function contextFunc(self)
	return "Eat " .. self.item.name
end

function eatTask:initialize(item, parentTask)
	if not item then error("eatTask initialized with no item") end
	if not item:isType("food") then error("eatTask initialized with inedible item") end

	self.item = item
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
end

return eatTask