local class = require('middleclass')

local room = class('room')

function room.static:detectRoom(map, tile)

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
		if v.x == 15 and v.y == 4 then print(alreadyFound) end
		if not alreadyFound and not map:isWall(v.x, v.y) and not map:isHull(v.x, v.y) then
			table.insert(discovered, v)
			local neighbor = map:getTile(v.x+1, v.y)
			if neighbor then table.insert(toSearch, neighbor) end
			neighbor = map:getTile(v.x, v.y+1)
			if neighbor then table.insert(toSearch, neighbor) end
			neighbor = map:getTile(v.x-1, v.y)
			if neighbor then table.insert(toSearch, neighbor) end
			neighbor = map:getTile(v.x, v.y-1)
			if neighbor then table.insert(toSearch, neighbor) end
		end
	end
	return discovered
end

function room:initialize(map, tiles)
	self.map = map
	self.tiles = tiles

	self.edges = {}
	self.walls = {}
	self:detectEdgeTiles()
end

function room:inRoom(tile)
	for _, t in ipairs(self.tiles) do
		if tile.uid == t.uid then
			return true
		end
	end
	return false
end

function room:detectEdgeTiles()

	for _, tile in ipairs(self.tiles) do
		local right = self.map:getTile(tile.x + 1, tile.y) 
		local bottom = self.map:getTile(tile.x, tile.y + 1) 
		local left = self.map:getTile(tile.x - 1, tile.y) 
		local top = self.map:getTile(tile.x, tile.y - 1)

		local wall = false

		if right and not self:inRoom(right) then
			table.insert(self.edges, {tile.x, tile.y-1, tile.x, tile.y})
			if right:isWall() or right:isHull() then
				table.insert(self.walls, right)
			end
			wall = true
		end
		if bottom and not self:inRoom(bottom) then
			table.insert(self.edges, {tile.x-1, tile.y, tile.x, tile.y})
			if bottom:isWall() or bottom:isHull() then
				table.insert(self.walls, bottom)
			end
			wall = true
		end
		if left and not self:inRoom(left) then
			table.insert(self.edges, {tile.x-1, tile.y-1, tile.x-1, tile.y})
			if left:isWall() or left:isHull() then
				table.insert(self.walls, left)
			end
			wall = true
		end
		if top and not self:inRoom(top) then
			table.insert(self.edges, {tile.x-1, tile.y-1, tile.x, tile.y-1})
			if top:isWall() or top:isHull() then
				table.insert(self.walls, top)
			end
			wall = true
		end
		if wall then
		end
	end
end

function room:detectContiguous(tile)
	tile = tile or self.tiles[1]
	if #self.tiles == #room:detectRoom(tile) then
		return true
	end
	return false
end

return room