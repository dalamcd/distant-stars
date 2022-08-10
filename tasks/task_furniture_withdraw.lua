local class = require('middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_walk')

local withdrawTask = class('withdrawTask', task)

local function startFunc(self)
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
			local wt = walkTask:new(tile, self)
			self.entity:pushTask(wt)
		end
	else
		self:complete()
	end
end

local function runFunc(self)
	local p = self:getParams()
	if not self.entity.walking and self.entity.x == self.entity.destination.x and self.entity.y == self.entity.destination.y then
		self:complete()
	elseif not p.routeFound then
		self.finished = true
	end
end

local function endFunc(self)
	self.furniture:removeFromInventory(self.item)
	self.entity:addToInventory(self.item)
end

local function contextFunc(self)
	return "Take " .. self.item.name .. " from " .. self.furniture.name
end

local function strFunc(self)
	return "Taking " .. self.item.name .. " from " .. self.furniture.name
end

function withdrawTask:initialize(furniture, item, parentTask)
	if not item then error("withdrawTask initialized with no item") end
	if not furniture then error("withdrawTask initialized with no furniture") end

	self.item = item
	self.furniture = furniture
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
end

return withdrawTask