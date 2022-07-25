local class = require('middleclass')
local luastar = require('lua-star')
local tile = require('tile')
local door = require('door')
local map_utils = require('map/map_utils')

map = class('map')
map:include(map_utils)

function map:initialize(name, xOffset, yOffset)

	name = name or "new map"

	self.tiles = {}
	self.entities = {}
	self.items = {}
	self.furniture = {}
	self.stockpiles = {}
	self.jobs = {}

	self.name = name
	self.xOffset = xOffset or 0
	self.yOffset = yOffset or 0
	self.mapTranslationXOffset = 0
	self.mapTranslationYOffset = 0
	self.velX = 0
	self.velY = 0

	self.oneSecondTimer = 0
end

function map:update(dt)

	if not paused then
		for _, e in ipairs(self.entities) do
			e:update(dt)
		end
		for _, f in ipairs(self.furniture) do
			f:update(dt)
		end
		for _, i in ipairs(self.items) do
			i:update(dt)
		end
	end

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
		t:draw()
		t.mapTranslationXOffset = self.mapTranslationXOffset
		t.mapTranslationYOffset = self.mapTranslationYOffset
	end

	for _, s in ipairs(self.stockpiles) do
		s:draw()
		--s.translationXOffset = s.translationXOffset + self.translationXOffset
		--s.translationYOffset = s.translationYOffset + self.translationYOffset
	end

	for _, i in ipairs(self.items) do
		if not i.owned then
			i:draw()
		end
		i.mapTranslationXOffset = self.mapTranslationXOffset
		i.mapTranslationYOffset = self.mapTranslationYOffset
	end

	for _, f in ipairs(self.furniture) do
		f:draw()
		f.mapTranslationXOffset = self.mapTranslationXOffset
		f.mapTranslationYOffset = self.mapTranslationYOffset
	end

	for _, e in ipairs(self.entities) do
		e:draw()
		e.mapTranslationXOffset = self.mapTranslationXOffset
		e.mapTranslationYOffset = self.mapTranslationYOffset
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
				t = tile:new("floorTile", TILE_SIZE, 0, "metal wall", self, x, y, index, false)
			elseif grid[index] == 2 then
				t = tile:new("floorTile", 0, 0, "metal floor", self, x, y, index, true)
			elseif grid[index] == 3 then
				t = tile:new("floorTile", TILE_SIZE*2, 0, "void", self, x, y, index, false)
			elseif grid[index] == 4 then
				t = tile:new("floorTile", TILE_SIZE*2, 0, "void", self, x, y, index, false)
				--local newDoor = door:new("furniture", TILE_SIZE*2, 0, TILE_SIZE, TILE_SIZE, "door", self, c, r)
				--self:addFurniture(newDoor)
			end
			self.tiles[index] = t
		end
	end
end

return map