local class = require('lib.middleclass')
local luastar = require('lib.lua-star')
local utils = require('utils')
local tile = require('tile')
local door = require('furniture.door')
local hull = require('furniture.hull')
local room = require('rooms.room')
local furniture = require('furniture.furniture')
local wall = require('furniture.wall')
local map_utils = require('map.map_utils')
local alert = require('alert')

local map = class('map')
map:include(map_utils)

map.static._loaded_maps = {}

function map.static:load(name, map, label, width, height, entities, furniture)
	local internalItem = self._loaded_maps[name]

	if internalItem then
		return internalItem
	else
		self._loaded_maps[name] = {
			map = map,
			label = label,
			width = width,
			height = height,
			entities = entities,
			furniture = furniture
		}
	end
end

function map.static:retrieve(name)
	local mobj = self._loaded_maps[name]
	if not mobj then error("attempted to retrieve " .. name .. " but no map with that name was found") end

	io.input("data/ships/" .. mobj.map)
	local grid = {}
	local m = self:new(mobj.label, 0, 0)

    m.width = mobj.width
	m.height = mobj.height

	local line = io.read("*line")
	while line ~= nil do
		for i = 1, string.len(line) do
			local c = line:sub(i,i)
			if c == "#" then
        -- Insert wall
				table.insert(grid, 1)
			end
        -- Insert floor tile
			if c == "." then
				table.insert(grid, 2)
			end
        -- Insert void tile
			if c == "*" then
				table.insert(grid, 3)
			end
        -- Insert hull
			if c == "@" then
				table.insert(grid, 5)
			end
		-- Insert door
			if c == "D" then
				table.insert(grid, 4)
			end

		end
		line = io.read("*line")
	end

	-- Load tiles
	for r = 1, m.height do
		for c = 1, m.width do
			local x = c + m.xOffset
			local y = r + m.yOffset
			local index = ((r - 1) * m.width) + c
			local t
			if grid[index] == 1 then
				t = tile:new("metal floor", m, x, y, index, true)
				local f = wall:new("wall", m, c, r)
				m:addFurniture(f)
			elseif grid[index] == 2 then
				t = tile:new("metal floor", m, x, y, index, true)
			elseif grid[index] == 3 then
				t = tile:new("void", m, x, y, index, false)
			elseif grid[index] == 4 then
				t = tile:new("metal floor", m, x, y, index, true)
				local newDoor = door:new("door", "door", m, c, r)
				m:addFurniture(newDoor)
			elseif grid[index] == 5 then
				t = tile:new("metal floor", m, x, y, index, true)
				local h = hull:new("hull", "hull", m, c, r)
				m:addFurniture(h)
			end
			m.tiles[index] = t
		end
	end

	-- Finding all rooms in a loaded map
	for _, mapTile in ipairs(m.tiles) do
		local roomList = m.rooms
		local inRoom = false
		for _, r in ipairs(roomList) do
			if r:inRoom(mapTile) then
				inRoom = true
				break
			end
		end

		if not inRoom then
			local roomTiles = room:detectRoom(m, mapTile)
			if #roomTiles > 0 then
				local newRoom = room:new(m, roomTiles)
				table.insert(m.rooms, newRoom)
			end
		end
	end

	-- Load entities
	for _, ent in ipairs(mobj.entities) do
		local args = ent.args or {}
		local newEnt = ent.class:new(ent.name, ent.label, m, ent.x, ent.y, unpack(args))
		m:addEntity(newEnt)
	end

	-- Load furniture
	for _, furn in ipairs(mobj.furniture) do
		local args = furn.args or {}
		local newFurn = furn.class:new(furn.name, furn.label, m, furn.x, furn.y, unpack(args))
		m:addFurniture(newFurn)
	end

	return m
end

function map:initialize(label, xOffset, yOffset)

	label = label or "new map"

	self.tiles = {}
	self.entities = {}
	self.items = {}
	self.furniture = {}
	self.stockpiles = {}
	self.jobs = {}
	self.rooms = {}
	self.alert = alert:new(self)

	self.label = label
	self.selected = false
	self.uid = getUID()
	self.xOffset = xOffset or 0
	self.yOffset = yOffset or 0
	self.mapTranslationXOffset = 0
	self.mapTranslationYOffset = 0
	self.velX = 0
	self.velY = 0
	self.mouseSelection = nil

	self.oneSecondTimer = 0
end

function map:update(dt)

	for _, e in ipairs(self.entities) do
		e:update(dt)
	end
	for _, f in ipairs(self.furniture) do
		f:update(dt)
	end
	for _, i in ipairs(self.items) do
		i:update(dt)
	end
	for _, r in ipairs(self.rooms) do
		r:update(dt)
	end

	self.alert:update()

	if self.velX ~= 0 then
		self.mapTranslationXOffset = self.mapTranslationXOffset + self.velX
	end

	if self.velY ~= 0 then
		self.mapTranslationYOffset = self.mapTranslationYOffset + self.velY
	end

	if self.oneSecondTimer >= 60 then
		self.oneSecondTimer = 0
		self:pollForJobs()
	end

	self.oneSecondTimer = self.oneSecondTimer + 1
end

function map:draw()
	for _, t in ipairs(self.tiles) do
		t.mapTranslationXOffset = self.mapTranslationXOffset
		t.mapTranslationYOffset = self.mapTranslationYOffset
		t:draw()
	end
	if self.selected then
		for _, s in ipairs(self.stockpiles) do
			s:draw()
		end

		for _, i in ipairs(self.items) do
			i.mapTranslationXOffset = self.mapTranslationXOffset
			i.mapTranslationYOffset = self.mapTranslationYOffset
			if not i.owned then
				i:draw()
			end
		end

		for _, f in ipairs(self.furniture) do
			f.mapTranslationXOffset = self.mapTranslationXOffset
			f.mapTranslationYOffset = self.mapTranslationYOffset
			f:draw()
		end

		for _, e in ipairs(self.entities) do
			e.mapTranslationXOffset = self.mapTranslationXOffset
			e.mapTranslationYOffset = self.mapTranslationYOffset
			e:draw()
		end

		for _, r in ipairs(self.rooms) do
			r:draw()
		end

		self.alert:draw()
	end
	--[[
	for _, r in ipairs(self.rooms) do
		for _, t in ipairs(r.tiles) do
			circ("fill", t:getWorldCenterX(), t:getWorldCenterY(), 2, self.camera)
		end
		love.graphics.setColor(0.0, 1.0, 0.32, 1.0)
		for _, edge in ipairs(r.edges) do
			line((edge[1]*TILE_SIZE)+self.mapTranslationXOffset, edge[2]*TILE_SIZE+self.mapTranslationYOffset,
			edge[3]*TILE_SIZE+self.mapTranslationXOffset, edge[4]*TILE_SIZE+self.mapTranslationYOffset, self.camera)
		end
		for _, wall in ipairs(r.walls) do
			circ("fill", wall:getWorldCenterX(), wall:getWorldCenterY(), 2, self.camera)
		end
		love.graphics.reset()
	end
	--]]

end

function map:setOffset(x, y)
	local dx = x - self.xOffset
	local dy = y - self.yOffset
	for _, obj in ipairs(self.tiles) do
		obj.x = obj.x + dx
		obj.y = obj.y + dy
	end
	for _, obj in ipairs(self.furniture) do
		obj.x = obj.x + dx
		obj.y = obj.y + dy
	end
	for _, obj in ipairs(self.entities) do
		obj:adjustOffset(dx, dy)
	end
	for _, obj in ipairs(self.items) do
		obj.x = obj.x + dx
		obj.y = obj.y + dy
	end
	self.xOffset = x
	self.yOffset = y
end

function map:select()
	self.selected = true
end

function map:unselect()
	self.selected = false
end

function map:addEntity(e)
	e.map = self
	e.x = e.x + self.xOffset
	e.y = e.y + self.yOffset
	e.mapTranslationXOffset = self.mapTranslationXOffset
	e.mapTranslationYOffset = self.mapTranslationYOffset
	table.insert(self.entities, e)
end

function map:addItem(i)
	i.map = self
	i.x = i.x + self.xOffset
	i.y = i.y + self.yOffset
	i.mapTranslationXOffset = self.mapTranslationXOffset
	i.mapTranslationYOffset = self.mapTranslationYOffset
	table.insert(self.items, i)
end

function map:removeItem(i)
	for idx, item in ipairs(self.items) do
		if i.uid == item.uid then
			table.remove(self.items, idx)
			return true
		end
	end
	return false
end

function map:removeEntity(e)
	for idx, ent in ipairs(self.entities) do
		if e.uid == ent.uid then
			table.remove(self.entities, idx)
			return true
		end
	end
	return false
end

function map:addFurniture(f)
	f.map = self
	f.x = f.x + self.xOffset
	f.y = f.y + self.yOffset
	f.mapTranslationXOffset = self.mapTranslationXOffset
	f.mapTranslationYOffset = self.mapTranslationYOffset
	table.insert(self.furniture, f)
end

function map:addStockpile(s)
	s.map = self
	table.insert(self.stockpiles, s)
end

function map:updateStockpiles()
	for _, sp in ipairs(self.stockpiles) do
		sp:updateContents()
	end
end

function map:checkStockpileAvailableFor(it)
	for _, sp in ipairs(self.stockpiles) do
		local t = sp:getAvailableTileFor(it)
		if t then
			return sp
		end
	end
	return nil
end

function map:getNearbyUnreservedObject(objType, x, y)
	local nearest = math.huge
	local found = nil
	for _, t in ipairs(self.tiles) do
		for _, obj in ipairs(self:getObjectsInTile(t)) do
			if obj:isType(objType) then
				local dist = (x - obj.x)^2 + (y - obj.y)^2
				if dist < nearest and not obj:isReserved() and not obj:isOccupied() then
					nearest = dist
					found = obj
				end
			end
		end
	end
	return found
end

function map:getNearbyObject(objType, x, y)
	local nearest = math.huge
	local found = nil
	for _, t in ipairs(self.tiles) do
		for _, obj in ipairs(self:getObjectsInTile(t)) do
			if obj:isType(objType) then
				local dist = (x - obj.x)^2 + (y - obj.y)^2
				if dist < nearest then
					nearest = dist
					found = obj
				end
			end
		end
	end
	return found
end

function map:inBounds(worldX, worldY)
	local s = self.camera.scale
	local x = worldX - self.camera:getRelativeX(TILE_SIZE*self.xOffset)
	local y = worldY - self.camera:getRelativeY(TILE_SIZE*self.yOffset)
	if(x <= TILE_SIZE*self.width*s and x >= 0) then
		if(y <= TILE_SIZE*self.height*s and y >= 0) then
			return true
		end
	end
	return false
end

function map:addAlert(str)
	self.alert:addAlert(str)
end

function map:getAlerts()
	return self.alert.messages
end

function map:pathfind(start, goal)

	local function isWalkable(x, y)
		return self:isWalkable(x, y)
	end

	--path = luastar:find(mapsize, mapsize, start, goal, positionIsOpenFunc)
	local nodes = nil
	local route = luastar:find(self.width + self.xOffset, self.height + self.yOffset, start, goal, isWalkable)
	if route then
		nodes = {}
		for i = #route, 2, -1 do
			local t = self:getTile(route[i].x, route[i].y)
			table.insert(nodes, t)
	  	end
	end

	return nodes
end

function map:getPossibleTasks(theTile, entity)

	local tasks = {}
	
	for _, task in ipairs(theTile:getPossibleTasks(self, entity)) do
		task.params.map = self
		tasks[#tasks+1] = task
	end

	for _, item in ipairs(self:getItemsInTile(theTile)) do
		for _, task in ipairs(item:getPossibleTasks()) do
			task.params.map = self
			tasks[#tasks+1] = task
		end
	end

	for _, furn in ipairs(self:getFurnitureInTile(theTile)) do
		for _, task in ipairs(furn:getPossibleTasks()) do
			task.params.map = self
			tasks[#tasks+1] = task
		end
	end

	for _, task in ipairs(entity:getPossibleTasks(theTile)) do
		task.params.map = self
		tasks[#tasks+1] = task
	end

	return tasks
end

function map:removeJobFromJobList(job)
	for i, j in ipairs(self.jobs) do
		if j.uid == job.uid then
			table.remove(self.jobs, i)
			return
		end
	end
end

function map:pollForJobs()
	local jobs = self:getAvailableJobs()

	for _, ent in ipairs(self.entities) do
		ent:setJobList(jobs)
	end

	self.jobs = jobs
end

function map:getAvailableJobs()
	local tasks = {}
	for _, tile in ipairs(self.tiles) do
		for _, item in ipairs(self:getItemsInTile(tile)) do
			for _, task in ipairs(item:getAvailableJobs()) do
				task.params.map = self
				tasks[#tasks+1] = task
			end
		end
	end

	-- for _, task in ipairs(entity:getAvailableJobs(self, tile)) do
	-- 	tasks[#tasks+1] = task
	-- end

	return tasks
end

return map