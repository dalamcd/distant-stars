local class = require('middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')

local sitTask = class('sitTask', task)

local function startFunc(self)
	if self.furniture:isReserved() then
		self:complete()
		return
	end

	local inRange = false

	for _, tile in ipairs(self.furniture:getInteractionTiles()) do
		if self.entity.x == tile.x and self.entity.y == tile.y then
			inRange = true
			break
		end
	end

	if not inRange then
		local tile = self.furniture:getAvailableInteractionTile()
		if tile then
			self.furniture:reserveFor(self.entity)
			local wt = walkTask:new(tile, self)
			self.entity:pushTask(wt)
		end
	else
		self:complete()
	end
end

local function runFunc(self)
	local p = self:getParams()
	if not p.routeFound then
		self:abandon()
		self:complete()
		return
	end

	if not self.entity.walking and self.entity.x == self.entity.destination.x and self.entity.y == self.entity.destination.y then
		if not self.entity.sitting then
			self.entity:sitOn(self.furniture)
			self:complete()
		end
	end
end

local function endFunc(self)
	local p = self:getParams()
	p.reachedSeat = true
	self.furniture:unreserve()
end

local function strFunc(self)
	if self.entity.walking then
		return "Moving to (" .. self.entity.destination.x .. ", " .. self.entity.destination.y .. ") to sit on " .. self.furniture.name
	else
		return "Sitting on " .. self.furniture.name
	end
end

local function contextFunc(self)
	return "Sit on " .. self.furniture.name
end

function sitTask:initialize(furniture, parentTask)
	if not furniture then error("sitTask initialized with no furniture") end
	if not furniture:isType("comfort") then error("sitTask initialized with unsittable furniture") end

	self.furniture = furniture
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
end

return sitTask