local class = require('middleclass')
local tile = require('tile')

map = class('map')

function map:initialize()

	self.tiles = {}

end

function map:draw()
	for _, t in ipairs(self.tiles) do
		t:draw()
	end
end

function map:getTileAtPos(x, y)
	for _, t in ipairs(self.tiles) do
		if t:inBounds(x, y) then
			return t
		end
	end

	return nil
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

return map