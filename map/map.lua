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
local drawable = require('drawable')

local map = class('map')
map:include(map_utils)

map.static._loaded_maps = {}

function map.static:load(name, m, label, width, height, roof, entities, furn, items)
	local internalItem = self._loaded_maps[name]

	if internalItem then
		return internalItem
	else
		self._loaded_maps[name] = {
			map = m,
			label = label,
			width = width,
			height = height,
			roof = roof,
			entities = entities,
			furniture = furn,
			items = items
		}
	end
end

function map.static:retrieve(name)
	local mobj = self._loaded_maps[name]
	if not mobj then error("attempted to retrieve " .. name .. " but no map with that name was found") end

	local ts = drawable:getTileset(mobj.roof.tileset)
	local m = self:new(mobj.label, 0, 0)
	m.tileset = ts
	m.sprite = love.graphics.newQuad(mobj.roof.tilesetX, mobj.roof.tilesetY, mobj.roof.spriteWidth, mobj.roof.spriteHeight, ts:getWidth(), ts:getHeight())
	io.input("data/ships/" .. mobj.map)
	local grid = {}

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
		-- Insert hullBotLeft tile
			if c == "\\" then
				table.insert(grid, 6)
			end
		-- Insert hullBotRight tile
			if c == "/" then
				table.insert(grid, 7)
			end
		-- Insert hullTopRight tile
			if c == ">" then
				table.insert(grid, 8)
			end
		-- Insert hullTopLeft tile
			if c == "<" then
				table.insert(grid, 9)
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
				t = tile:new("metal floor", "metal floor", m, x, y)
				local f = wall:new("wall", "wall", m, c, r)
				m:addFurniture(f)
			elseif grid[index] == 2 then
				t = tile:new("metal floor", "metal floor", m, x, y)
			elseif grid[index] == 3 then
				t = tile:new("void", "void", m, x, y, index, false)
			elseif grid[index] == 4 then
				t = tile:new("metal floor", "metal floor", m, x, y)
				local newDoor = door:new("door", "door", m, c, r)
				m:addFurniture(newDoor)
			elseif grid[index] == 5 then
				t = tile:new("void", "void", m, x, y)
				local h = hull:new("hull", "hull", m, c, r)
				m:addFurniture(h)
				table.insert(m.hullTiles, t)
			elseif grid[index] == 6 then
				t = tile:new("void", "void", m, x, y)
				local h = hull:new("hullBotLeft", "hull", m, c, r)
				m:addFurniture(h)
				table.insert(m.hullTiles, t)
			elseif grid[index] == 7 then
				t = tile:new("void", "void", m, x, y)
				local h = hull:new("hullBotRight", "hull", m, c, r)
				m:addFurniture(h)
				table.insert(m.hullTiles, t)
			elseif grid[index] == 8 then
				t = tile:new("metal floor", "metal floor", m, x, y)
				local h = hull:new("hullTopRight", "hull", m, c, r)
				m:addFurniture(h)
				table.insert(m.hullTiles, t)
			elseif grid[index] == 9 then
				t = tile:new("metal floor", "metal floor", m, x, y)
				local h = hull:new("hullTopLeft", "hull", m, c, r)
				m:addFurniture(h)
				table.insert(m.hullTiles, t)
			end
			m.tiles[index] = t
		end
	end

	room:detectCycle(m.hullTiles)

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
		local newEnt = ent.class:new(ent.name, ent.label, m, ent.x, ent.y)
		m:addEntity(newEnt)
	end

	-- Load furniture
	for _, furn in ipairs(mobj.furniture) do
		local newFurn = furn.class:new(furn.name, furn.label, m, furn.x, furn.y)
		m:addFurniture(newFurn)
	end

	-- Load items
	for _, it in ipairs(mobj.items) do
		local newIt = it.class:new(it.name, it.label, m, it.x, it.y)
		if it.amount then
			newIt:setAmount(it.amount)
		end
		m:addItem(newIt)
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
	self.hullTiles = {}
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

	local ts = drawable:getTileset("ships")
	self.tileset = ts
	self.sprite = love.graphics.newQuad(TILE_SIZE*6, 0, TILE_SIZE*15, TILE_SIZE*16, ts:getWidth(), ts:getHeight())

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

	self:detectEntitiesInRooms()
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
	if self.selected then
		for _, t in ipairs(self.tiles) do
			t.mapTranslationXOffset = self.mapTranslationXOffset
			t.mapTranslationYOffset = self.mapTranslationYOffset
			t:draw()
		end

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
	else
		local x = self.camera:getRelativeX(self.tiles[1]:getWorldX())
		local y = self.camera:getRelativeY(self.tiles[1]:getWorldY())
		love.graphics.draw(self.tileset, self.sprite, x, y, 0, self.camera.scale)
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

function map:serialize()
	local fmt = "hhh"
	local serializedData = love.data.pack("string", "h", self.width)
	serializedData = serializedData .. love.data.pack("string", "h", self.height)
	serializedData = serializedData .. love.data.pack("string", "h", #self.tiles)
	for _, t in ipairs(self.tiles) do
		local tData, fmtString = t:serialize()
		serializedData = serializedData .. tData
		fmt = fmt .. fmtString
	end
	return serializedData, fmt
end

function map:deserialize(data)
	local deserializedData, idx = love.data.unpack("s", data)
	print(deserializedData)
	local dataTable = {love.data.unpack(tostring(deserializedData), data, tonumber(idx))}
	self:generateVoid(dataTable[1], dataTable[2])
	for i=4, dataTable[3]*4 + 1, 4 do
		local t = tile:new(dataTable[i+2], dataTable[i+3], self, dataTable[i], dataTable[i+1])
		self:addTile(t, t.index)
	end
end

function map:loadMapTable(fname)
	local status, mapRaw = pcall(love.filesystem.load, fname)
	if not status then
		error(tostring(mapRaw))
	else
		local mapData = mapRaw()
		assert(mapData.width and mapData.height, "Map table missing either width or height")
		self:generateVoid(mapData.width, mapData.height)
		for _, obj in ipairs(mapData.tiles) do
			local t = obj.class:new(obj.name, obj.label, self, obj.x, obj.y)
			self:addTile(t, t.index)
		end
		for _, obj in ipairs(mapData.entities) do
			self:addEntity(obj.class:new(obj.name, obj.label, self, obj.x, obj.y))
		end
		for _, obj in ipairs(mapData.furniture) do
			local f = obj.class:new(obj.name, obj.label, self, obj.x, obj.y)
			self:addFurniture(f)
			if obj.label == "o2gen" then
				print(f.outputAmount)
			end
		end
		for _, obj in ipairs(mapData.items) do
			self:addItem(obj.class:new(obj.name, obj.label, self, obj.x, obj.y))
		end
		self:detectRooms()
	end
end

function map:generateVoid(width, height)
	self.width = width
	self.height = height
	for r = 1, height do
		for c = 1, width do
			local x = c + self.xOffset
			local y = r + self.yOffset
			local index = ((r - 1) * width) + c
			local t = tile:new("metal floor", "metal floor", self, x, y, index, true)
			self.tiles[index] = t
		end
	end
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

function map:deselect()
	self.selected = false
end

function map:detectRooms()

	for _, mapTile in ipairs(self.tiles) do
		local roomList = self.rooms
		local inRoom = false
		for _, r in ipairs(roomList) do
			if r:inRoom(mapTile) then
				inRoom = true
				break
			end
		end

		if not inRoom then
			local roomTiles = room:detectRoom(self, mapTile)
			if #roomTiles > 0 then
				local newRoom = room:new(self, roomTiles)
				table.insert(self.rooms, newRoom)
			end
		end
	end

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

function map:addTile(t, idx)
	t.map = self
	t.x = t.x + self.xOffset
	t.y = t.y + self.yOffset
	t.mapTranslationXOffset = self.mapTranslationXOffset
	t.mapTranslationYOffset = self.mapTranslationYOffset
	self.tiles[idx] = t
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

function map:removeFurniture(f)
	for idx, furn in ipairs(self.furniture) do
		if f.uid == furn.uid then
			table.remove(self.furniture, idx)
			return true
		end
	end
	return false
end

function map:removeObject(obj)
	if obj:isType('furniture') then
		self:removeFurniture(obj)
	elseif obj:isType('entity') then
		self:removeEntity(obj)
	elseif obj:isType('item') then
		self:removeItem(obj)
	else
		print("ERR: attempted to remove an object from a map where it didn't exist")
	end
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
	self.alert:addMessage(str, 1)
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

function map:detectEntitiesInRooms()
	for _, r in ipairs(self.rooms) do
		r:detectEntities()
	end
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