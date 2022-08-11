local class = require('middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local gamestate = require('gamestate.gamestate')
local fade = require('gamestate.gamestate_fade')
local inventory = require('gamestate.gamestate_inventory')

local viewContentsTask = class('viewContentsTask', task)

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
	if not p.routeFound then
		self:abandon()
		self:complete()
		return
	end

	if not self.entity.walking and self.entity.x == self.entity.destination.x and self.entity.y == self.entity.destination.y then
		self:complete()
	end
end

local function endFunc(self)
	if not self.abandoned then
		local f = gamestate:getFadeState()
		local gs = gamestate:getInventoryState(self.furniture, self.entity)
		gamestate:push(f)
		gamestate:push(gs)
	end
end

local function contextFunc(self)
	return "View inventory"
end

local function strFunc(self)
	return "Viewing the inventory of " .. self.furniture.name
end

function viewContentsTask:initialize(furniture, parentTask)
	if not furniture then error("viewContentsTask initialized with no furniture") end

	self.furniture = furniture
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
end

return viewContentsTask