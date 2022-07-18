local class = require('middleclass')
local luastar = require('lua-star')
local tile = require('tile')

map = class('map')

function map:initialize()

	self.tiles = {}
	self.entities = {}
	self.items = {}
	self.furniture = {}
end

function map:draw()
	for _, t in ipairs(self.tiles) do
		t:draw()
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

function map:getTile(x, y)
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
	tasks = tile:getPossibleTasks(self, entity)

	for _, item in ipairs(self:getItemsInTile(tile)) do
		for _, task in ipairs(item:getPossibleTasks(self, entity)) do
			tasks[#tasks+1] = task
		end
	end

	--for _, ent in ipairs(self:getEntitiesInTile(tile)) do
		for _, task in ipairs(entity:getPossibleTasks(self, tile)) do
			tasks[#tasks+1] = task
		end
	--end

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
			end
			self.tiles[index] = t
		end
	end
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
end

return map