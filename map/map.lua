local class = require('middleclass')
local luastar = require('lua-star')
local utils = require('utils')
local tile = require('tile')
local door = require('furniture/door')
local hull = require('furniture/hull')
local room = require('room')
local furniture = require('furniture/furniture')
local wall = require('furniture/wall')
local map_utils = require('map/map_utils')
local alert = require('alert')
local map = class('map')
map:include(map_utils)

function map:initialize(name, xOffset, yOffset)

	name = name or "new map"

	self.tiles = {}
	self.entities = {}
	self.items = {}
	self.furniture = {}
	self.stockpiles = {}
	self.jobs = {}
	self.rooms = {}
	self.alert = alert:new(self)

	self.name = name
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

	for _, s in ipairs(self.stockpiles) do
		s:draw()
		--s.translationXOffset = s.translationXOffset + self.translationXOffset
		--s.translationYOffset = s.translationYOffset + self.translationYOffset
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

	for _, r in ipairs(self.rooms) do
		for _, t in ipairs(r.tiles) do
			circ("fill", t:getWorldCenterX(), t:getWorldCenterY(), 2, self.camera)
		end
		love.graphics.setColor(0.0, 1.0, 0.32, 1.0)
		for _, edge in ipairs(r.edges) do
			line((edge[1]*TILE_SIZE)+self.mapTranslationXOffset, edge[2]*TILE_SIZE+self.mapTranslationYOffset,
			edge[3]*TILE_SIZE+self.mapTranslationXOffset, edge[4]*TILE_SIZE+self.mapTranslationYOffset, self.camera)
		end
		-- for _, wall in ipairs(r.walls) do
		-- 	circ("fill", wall:getWorldCenterX(), wall:getWorldCenterY(), 2, self.camera)
		-- end
		love.graphics.reset()
	end

	if self.mouseSelection then
		self:drawSelectionDetails()
		self:drawSelectionBox()
	end

	self.alert:draw()
end

function map:drawSelectionBox()
	rect("line", self.mouseSelection:getWorldX(), self.mouseSelection:getWorldY(),
				self.mouseSelection.spriteWidth, self.mouseSelection.spriteHeight, self.mouseSelection.map.camera)
end

function map:drawSelectionDetails()

	local width = 300
	local height = 100
	local padding = 10
	local textPadding = 5
	love.graphics.rectangle("line", love.graphics.getWidth() - width - padding, 
									love.graphics.getHeight() - height - padding, 
									width,
									height)
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", love.graphics.getWidth() - width - padding + 1, 
									love.graphics.getHeight() - height - padding + 1, 
									width - 1,
									height -1)
	love.graphics.reset()

	love.graphics.print(self.mouseSelection.name .."["..self.mouseSelection.uid.."]",
						love.graphics.getWidth() - width - textPadding,
						love.graphics.getHeight() - height - textPadding)

	if self.mouseSelection:isType("entity") then
		local tlist = self.mouseSelection:getTasks()
		local itemNum = 1
		local idleSeconds = math.floor(self.mouseSelection.idleTime/60)
		if idleSeconds > 0 then
			love.graphics.print("Idle for " .. idleSeconds .. " seconds",
								love.graphics.getWidth() - width - textPadding,
								love.graphics.getHeight() - height + textPadding*itemNum*3)
			itemNum = itemNum + 1
		end

		for i=#tlist, 1, -1 do
			if not tlist[i]:isChild() then
				love.graphics.print(tlist[i]:getDesc(),
									love.graphics.getWidth() - width - textPadding,
									love.graphics.getHeight() - height + textPadding*itemNum*3)
				itemNum = itemNum + 1
			end
		end
	elseif self.mouseSelection:getType() == "stockpile" then
		for i, item in ipairs(self.mouseSelection.contents) do
			love.graphics.print(item.name,
								love.graphics.getWidth() - width - textPadding,
								love.graphics.getHeight() - height + textPadding*i*3)
		end
	end
end

function map:setMouseSelection(object)
	if self.mouseSelection then
		self.mouseSelection:deselect()
	end
	object:select()
	self.mouseSelection = object
end

function map:clearMouseSelection()
	if self.mouseSelection then
		self.mouseSelection:deselect()
	end
	self.mouseSelection = nil
end

function map:getMouseSelection()
	return self.mouseSelection
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

function map:getPossibleTasks(tile, entity)

	local tasks = {}
	
	for _, task in ipairs(tile:getPossibleTasks(self, entity)) do
		task.params.map = self
		tasks[#tasks+1] = task
	end

	for _, item in ipairs(self:getItemsInTile(tile)) do
		for _, task in ipairs(item:getPossibleTasks()) do
			task.params.map = self
			tasks[#tasks+1] = task
		end
	end

	for _, furn in ipairs(self:getFurnitureInTile(tile)) do
		for _, task in ipairs(furn:getPossibleTasks()) do
			task.params.map = self
			tasks[#tasks+1] = task
		end
	end

	for _, task in ipairs(entity:getPossibleTasks(tile)) do
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
	-- tasks = tile:getAvailableJobs(self, entity)
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

function map:load(fname)

	io.input(fname)
	local width = 0
	local height = 0
	local grid = {}
  -- Read format "N,M" where N and M are numbers specifying width and height, resepectively, discarding the comma
	local numOne, _, numTwo = io.read("*number", 1, "*number")
	
	if numOne and numTwo then
    	self.width = numOne
		self.height = numTwo
	end

	local line = io.read("*line")
	while line ~= nil do
		for i = 1, string.len(line) do
			local c = line:sub(i,i)
			if c == "#" then
        -- Insert wall tile
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
        -- Insert hull tile
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

	for r = 1, self.height do
		for c = 1, self.width do
			local x = c + self.xOffset
			local y = r + self.yOffset
			local index = ((r - 1) * self.width) + c
			local t
			if grid[index] == 1 then
				t = tile:new("metal floor", self, x, y, index, true)
				local f = wall:new("wall", self, c, r)
				self:addFurniture(f)
			elseif grid[index] == 2 then
				t = tile:new("metal floor", self, x, y, index, true)
			elseif grid[index] == 3 then
				t = tile:new("void", self, x, y, index, false)
			elseif grid[index] == 4 then
				t = tile:new("metal floor", self, x, y, index, true)
				local newDoor = door:new("door", self, c, r)
				self:addFurniture(newDoor)
			elseif grid[index] == 5 then
				t = tile:new("metal floor", self, x, y, index, true)
				local hull = hull:new("hull", self, c, r)
				self:addFurniture(hull)
			end
			self.tiles[index] = t
		end
	end

	-- Finding all rooms in a loaded map
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

return map