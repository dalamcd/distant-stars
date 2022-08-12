local class = require('lib.middleclass')
local utils = require('utils')

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

	self.uid = getUID()
	self.edges = {}
	self.walls = {}
	self.atmo = 100
	self:detectEdgeTiles()
end

function room:update()
	-- TODO implement a reasonable model for o2 loss (based on entities in room?)
	self.atmo = self.atmo - 0.1
end

function room:draw()
	-- Draw a color on a gradient from blue to red based on the atmo
	-- Interpolation function is (amount-min)/(max-min)*startColor + (1-(amount-min)/(max-min))*endColor

	-- This variable stands in for (amount-min)/(max-min) where min is 0
	local interpolate = self.atmo/100
	-- The 0 terms are pointless but left in for clarity
	local gr = interpolate*0 + (1-interpolate)*255
	local gg = interpolate*0 + (1-interpolate)*0
	local gb = interpolate*255 + (1-interpolate)*0
	local r, g, b, a = love.math.colorFromBytes(gr, gg, gb, 255/3)
	local color = {r=r, g=g, b=b, a=a}
	-- for _, t in ipairs(self.tiles) do
	-- 	drawRect(self.map.camera:getRelativeX((t.x - 1)*TILE_SIZE), self.map.camera:getRelativeY((t.y - 1)*TILE_SIZE), TILE_SIZE, TILE_SIZE, color)
	-- end
end

function room:inRoom(tile)
	for _, t in ipairs(self.tiles) do
		if tile.uid == t.uid then
			return true
		end
	end
	return false
end

function room:inBounds(worldX, worldY)
	for _, tile in ipairs(self.tiles) do
		if tile:inBounds(worldX, worldY) then
			return true
		end
	end
	return false
end

function room:inTile(x, y)
	for _, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return true
		end
	end
	return false
end

function room:listAttributes()
	if self.attributes then
		for k, v in pairs(self.attributes) do
			print(self.uid, k, v)
		end
	end
end

function room:getAttribute(attr)
	if self.attributes then
		if self.attributes[attr] then
			return self.attributes[attr]
		else
			return nil
		end
	end
end

function room:adjustAttribute(attribute, amount, min, max)
	min = min or -math.huge
	max = max or math.huge
	if not self.attributes then
		self.attributes = {}
	end
	if self.attributes[attribute] then
		self.attributes[attribute] = clamp(self.attributes[attribute] + amount, min, max)
	else
		self.attributes[attribute] = clamp(amount, min, max)
	end
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

function room:getType()
	return "[[room]]"
end

function room:isType(str)
	return string.match(self:getType(), str)
end

return room