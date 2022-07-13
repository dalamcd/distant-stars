local class = require('middleclass')
local luastar = require('lua-star')
local tile = require('tile')

map = class('map')

function map:initialize()

	self.tiles = {}
	self.entities = {}
	self.items = {}
end

function map:draw()
	for _, t in ipairs(self.tiles) do
		t:draw()
	end

	for _, i in ipairs(self.items) do
		i:draw()
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

function map:pathfind(start, goal)

	function isWalkable(x, y)
		return self:getTile(x,y):isWalkable()
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

function map:getEntityAtPos(x, y)
	for _, e in ipairs(self.entities) do
		if e:inBounds(x, y) then
			return e
		end
	end

	return nil
end

function map:getItemAtPos(x, y)
	for _, i in ipairs(self.entities) do
		if i:inBounds(x, y) then
			return i
		end
	end

	return nil
end

function map:getTileAtPos(x, y)
	for _, t in ipairs(self.tiles) do
		if t:inBounds(x, y) then
			return t
		end
	end

	return nil
end

function map:getTile(x, y)
	return self.tiles[(y - 1)*self.width + x]
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
			local t = tile:new(grid[index], c, r, index)
			self.tiles[index] = t
		end
	end
end

function map:update(dt)
	for _, e in ipairs(self.entities) do
		e:update(dt)
	end
end

return map