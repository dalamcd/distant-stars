local class = require('middleclass')
local furniture = require('furniture')
local task = require('task')
local gamestate = require('gamestate/gamestate')
local stationstate = require('gamestate/gamestate_station')

local station = class('station', furniture)

function station:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, map, posX, posY, tileWidth, tileHeight, interactPoints)
	furniture.initialize(self, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, map, posX, posY, tileWidth, tileHeight, interactPoints)

	self.updateFunc = function() return end
	self.drawFunc = function() return end

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
			if p.entity.x == tile.x and p.entity.y == tile.y then
				inRange = true
				break
			end
		end

		if not inRange then
			local tile = self:getAvailableInteractionTile()
			if tile then
				p.dest = tile
				local walkTask = p.entity:getWalkTask(tile, tself)
				p.entity:pushTask(walkTask)
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
		
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			tself:complete()
		end
	end

	local function endFunc(tself)
		local p = tself:getParams()
		if not tself.abandoned then
			local fade = gamestate:getFadeState()
			local gs = gamestate:getStationState(self, p.entity)
			gamestate:push(fade)
			gamestate:push(gs)
		end
	end

	local function contextFunc(tself)
		return "Work on station"
	end

	local function strFunc(tself)
		return "Working on " .. self.name
	end

	local viewTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
	return viewTask
end

return station