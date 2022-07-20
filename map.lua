local class = require('middleclass')
local luastar = require('lua-star')
local tile = require('tile')
local door = require('door')

map = class('map')

function map:initialize()

	self.tiles = {}
	self.entities = {}
	self.items = {}
	self.furniture = {}
	self.stockpiles = {}

	self.jobs = {}

	self.oneSecondTimer = 0
end

function map:draw()
	for _, t in ipairs(self.tiles) do
		t:draw()
	end

	for _, s in ipairs(self.stockpiles) do
		s:draw()
	end

	for _, i in ipairs(self.items) do
		if not i.carried then
			i:draw()
		end
	end

	for _, f in ipairs(self.furniture) do
		f:draw()
	end

	for _, e in ipairs(self.entities) do
		e:draw()
	end

end

function map:addEntity(e)
	table.insert(self.entities, e)
end

function map:addItem(i)
	table.insert(self.items, i)
end

function map:addFurniture(f)
	table.insert(self.furniture, f)
end

function map:addStockpile(s)
	table.insert(self.stockpiles, s)
end

function map:isOccupied(x, y)

	for _, furn in ipairs(self.furniture) do
		if furn:inTile(x, y) then
			return true
		end
	end

	for _, ent in ipairs(self.entities) do
		if ent.x == x and ent.y == y then
			return true
		end
	end

	return false
end

function map:isWall(x, y)

	local wall = false
	local t = self:getTile(x, y)

	if t:isWall() then
		wall = true
	end

	for _, furn in ipairs(self:getFurnitureInTile(t)) do
		if furn:getType() == "door" then
			wall = true
		end
	end
	return wall
end

function map:isWalkable(x, y)
	local tile = self:getTile(x,y)
	
	local walkable = true
	
	if not tile:isWalkable() then
		walkable = false
	end

	for _, furn in ipairs(self.furniture) do
		if furn:inTile(x, y) then
			walkable = furn:isWalkable()
		end
	end

	for _, ent in ipairs(self.entities) do
		if ent.x == x and ent.y == y then
			walkable = ent:isWalkable()
		end
	end

	return walkable
end

function map:pathfind(start, goal)

	function isWalkable(x, y)
		return self:isWalkable(x,y)
	end

	--path = luastar:find(mapsize, mapsize, start, goal, positionIsOpenFunc)
	local nodes = nil
	local route = luastar:find(self.width, self.height, start, goal, isWalkable)
	if route then
		nodes = {}
		for i = #route, 2, -1 do
			local t = self:getTile(route[i].x, route[i].y)
			table.insert(nodes, t)
	  	end
	end

	return nodes
end

function map:getTileAtWorld(worldX, worldY)
	for _, t in ipairs(self.tiles) do
		if t:inBounds(worldX, worldY) then
			return t
		end
	end

	return nil
end

function map:getEntitiesAtWorld(worldX, y)
	local entities = {}
	for _, e in ipairs(self.entities) do
		if e:inBounds(worldX, y) then
			table.insert(entities, e)
		end
	end
	--if #entities > 0 then print(#entities) end
	return entities
end

function map:getItemsAtWorld(worldX, worldY)
	local items = {}
	for _, i in ipairs(self.items) do
		if i:inBounds(worldX, worldY) then
			table.insert(items, i)
		end
	end

	return items
end

function map:getFurnitureAtWorld(worldX, worldY)
	local furniture = {}
	for _, f in ipairs(self.furniture) do
		if f:inBounds(worldX, worldY) then
			table.insert(furniture, f)
		end
	end

	return furniture
end

function map:getStockpileAtWorld(worldX, worldY)
	for _, s in ipairs(self.stockpiles) do
		if s:inBounds(worldX, worldY) then
			return s
		end
	end
end

function map:getObjectsAtWorld(worldX, worldY)
	local objects = {}

	for _, e in ipairs(self:getEntitiesAtWorld(worldX, worldY)) do
		table.insert(objects, e)
	end
	for _, i in ipairs(self:getItemsAtWorld(worldX, worldY)) do
		table.insert(objects, i)
	end
	for _, f in ipairs(self:getFurnitureAtWorld(worldX, worldY)) do
		table.insert(objects, f)
	end

	return objects
end

function map:getRandomWalkableTile()
	local t

	repeat
		local random = math.random(#self.tiles)
		t = self.tiles[random]
	until self:isWalkable(t.x, t.y)

	return t
end

function map:getWalkableTileInRadius(x, y, r)
	local t
	local count = 0
	local points = midpointCircle(x, y, r)
	local tiles = self:getTilesFromPoints(points)
	local num = #points
	local max = num*num
	tmpTiles = tiles

	local walkable
	local occupied
	repeat
		local random = math.random(num)
		t = self:getTile(points[random].x, points[random].y)
		if t then
			walkable = self:isWalkable(t.x, t.y)
			occupied = self:isOccupied(t.x, t.y)
		end
		count = count + 1
		if count > max then break end
	until t and walkable and not occupied

	if t and walkable and not occupied then
		return t
	else
		return false
	end
end

function map:getRandomWalkableTileInRadius(x, y, r)
	local t
	local count = 0
	local points = midpointCircle(x, y, r)
	local tiles = self:getTilesFromPoints(points)
	local num = #points
	local max = num*num
	--tmpTiles = tiles

	repeat
		local random = math.random(num)
		t = self:getTile(points[random].x, points[random].y)
		count = count + 1
		if count > max then print("potential infinite loop in map:getRandomWalkableTileInRadius()?") break end
	until t and self:isWalkable(t.x, t.y)

	return t or false
end

function map:getTilesFromPoints(points)
	local tiles = {}
	for _, point in ipairs(points) do
		local t = self:getTile(point.x, point.y)
		if t then
			table.insert(tiles, t)
		end
	end
	return tiles
end

function map:getTilesInRectangle(x, y, width, height)
	local points = {}
	for r=0, width-1 do
		for c=0, height-1 do
			table.insert(points, {x=x+r, y=y+c})
		end
	end
	local tiles = self:getTilesFromPoints(points)
	return tiles
end

function map:detectRoom(tile)

	local discovered = {}
	local toSearch = {}
	table.insert(toSearch, tile)

	while #toSearch > 0 do
		local v = table.remove(toSearch)
		local alreadyFound = false
		for _, t in ipairs(discovered) do
			if t.uid == v.uid then
				alreadyFound = true
				break
			end
		end
		if not alreadyFound and not self:isWall(v.x, v.y) then
			table.insert(discovered, v)
			local neighbor = self:getTile(v.x+1, v.y)
			if neighbor then table.insert(toSearch, neighbor) end
			neighbor = self:getTile(v.x, v.y+1)
			if neighbor then table.insert(toSearch, neighbor) end
			neighbor = self:getTile(v.x-1, v.y)
			if neighbor then table.insert(toSearch, neighbor) end
			neighbor = self:getTile(v.x, v.y-1)
			if neighbor then table.insert(toSearch, neighbor) end
		end
	end
	return discovered
end

function map:getTile(x, y)
	if x <= 0 or y <= 0 or x > self.width or y > self.height then return nil end
	return self.tiles[(y - 1)*self.width + x]
end

function map:getItemsInTile(tile)
	local items = {}
	for _, item in ipairs(self.items) do
		if item.x == tile.x and item.y == tile.y then
			table.insert(items, item)
		end
	end
	return items
end

function map:getEntitiesInTile(tile)
	local entities = {}
	for _, entity in ipairs(self.entities) do
		if entity.x == tile.x and entity.y == tile.y then
			table.insert(entities, entity)
		end
	end
	return entities
end

function map:getFurnitureInTile(tile)
	local furniture = {}
	for _, furn in ipairs(self.furniture) do
		if furn.x == tile.x and furn.y == tile.y then
			table.insert(furniture, furn)
		end
	end
	return furniture
end

function map:getObjectsInTile(tile)
	local objects = {}

	for _, e in ipairs(self:getEntitiesInTile(tile)) do
		table.insert(objects, e)
	end
	for _, i in ipairs(self:getItemsInTile(tile)) do
		table.insert(objects, i)
	end
	for _, f in ipairs(self:getFurnitureInTile(tile)) do
		table.insert(objects, f)
	end

	return objects
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
			local index = ((r - 1) * self.width) + c
			local t
			if grid[index] == 1 then
				t = tile:new("floorTile", TILE_SIZE, 0, "metal wall", c, r, index, false)
			elseif grid[index] == 2 then
				t = tile:new("floorTile", 0, 0, "metal floor", c, r, index, true)
			elseif grid[index] == 3 then
				t = tile:new("floorTile", TILE_SIZE*2, 0, "void", c, r, index, false)
			elseif grid[index] == 4 then
				t = tile:new("floorTile", TILE_SIZE*0, 0, "void", c, r, index, false)
				local newDoor = door:new("furniture", TILE_SIZE*2, 0, TILE_SIZE, TILE_SIZE, "door", c, r)
				self:addFurniture(newDoor)
			end
			self.tiles[index] = t
		end
	end
end

function map:update(dt)

	if self.oneSecondTimer >= 60 then
		self.oneSecondTimer = 0
		self:pollForJobs()
	end

	self.oneSecondTimer = self.oneSecondTimer + 1

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

return map