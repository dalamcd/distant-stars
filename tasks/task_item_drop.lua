local class = require('lib.middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')

local dropTask = class('dropTask', task)

local function runFunc(self)
	local p = self:getParams()
	if not self.entity.walking and self.entity.x == self.destination.x and self.entity.y == self.destination.y then
		self.entity:removeFromInventory(self.item)
		self.item:addedToTile()
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
		self.item:addedToTile()
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
	elseif self:isChild() then
		self.parent:abandon()
	end
end

local function abandonFunc(self)
	if self:isChild() then
		self.parent:abandon()
	end
end

local function contextFunc(self)
	return "Drop " .. self.item.label
end

local function strFunc(self)
	return "Dropping " .. self.item.label
end

function dropTask:initialize(item, destination, parentTask)
	if not item then error("dropTask initialized with no item") end
	if not destination then error("dropTask initialized with no destination") end

	self.item = item
	self.destination = destination
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
end

return dropTask