local class = require('lib.middleclass')
local furniture = require('furniture.furniture')
local task = require('tasks.task')
local gamestate = require('gamestate.gamestate')
local stationstate = require('gamestate.gamestate_station')
local walkTask = require('tasks.task_entity_walk')

local station = class('station', furniture)

function station:initialize(name, label, map, posX, posY)
	local obj = furniture.initialize(self, name, label, map, posX, posY)

	self.loadFunc = obj.loadFunc or function () end
	self.updateFunc = obj.updateFunc or function () end
	self.drawFunc = obj.drawFunc or function () end
	self.exitFunc = obj.exitFunc or function () end
	self.inputFunc = obj.inputFunc or function () end
	return obj
end

function station:update(dt)
end

function station:draw()
	furniture.draw(self)
end

function station:getPossibleTasks()
	local tasks = {self:getViewStationTask()}

	return tasks
end

function station:getViewStationTask(parentTask)
	local function startFunc(tself)
		local p = tself:getParams()
		local inRange = false

		for _, tile in ipairs(self:getInteractionTiles()) do
			if tself.entity.x == tile.x and tself.entity.y == tile.y then
				inRange = true
				break
			end
		end
	
		if not inRange then
			local tile = self:getAvailableInteractionTile()
			if tile then
				p.dest = tile
				local wt = walkTask:new(tile, tself)
				tself.entity:pushTask(wt)
			end
		else
			tself:complete()
		end
	end

	local function runFunc(tself)
		local p = tself:getParams()
		if not p.routeFound then
			tself:abandon()
			tself:complete()
			return
		end
		
		if not tself.entity.walking and tself.entity.x == p.dest.x and tself.entity.y == p.dest.y then
			tself:complete()
		end
	end

	local function endFunc(tself)
		if not tself.abandoned then
			local fade = gamestate:getFadeState()
			local gs = gamestate:getStationState(self, tself.entity)
			gamestate:push(fade)
			gamestate:push(gs)
		end
	end

	local function contextFunc(tself)
		return "Work on station"
	end

	local function strFunc(tself)
		return "Working on " .. self.label
	end

	local viewTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, nil, parentTask)
	return viewTask
end

function station:getType()
	return furniture.getType(self) .. "[[station]]"
end

return station