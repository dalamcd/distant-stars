--- Helper function for maps
local map_utils = {
	isOccupied = function(self, x, y)

		-- for _, furn in ipairs(self.furniture) do
		-- 	if furn:inTile(x, y) then
		-- 		return true
		-- 	end
		-- end

		for _, ent in ipairs(self.entities) do
			if ent.x == x and ent.y == y then
				return ent
			end
		end

		return false
	end,

	isWall = function(self, x, y)

		local wall = false
		local t = self:getTile(x, y)

		for _, furn in ipairs(self:getFurnitureInTile(t)) do
			if furn:isType("wall") or furn:isType("hull") then
				wall = furn
			end
		end
		return wall
	end,

	isWalkable = function(self, x, y)
		local tile = self:getTile(x,y)

		if tile and not tile:isWalkable() then
			return false
		end

		for _, furn in ipairs(self.furniture) do
			if furn:inTile(x, y) then
				if not furn:isWalkable() then
					return false
				end
			end
		end

		for _, ent in ipairs(self.entities) do
			if ent.x == x and ent.y == y then
				if not ent:isWalkable() then
					return false
				end
			end
		end

		return true
	end,

	isHull = function(self, x, y)
		for _, f in ipairs(self.furniture) do
			if f.x == x and f.y == y and f:getType() == "hull" then
				return f
			end
		end
		return false
	end,

	isDoor = function(self, x, y)
		for _, f in ipairs(self.furniture) do
			if f.x == x and f.y == y and f:isType('door') then
				return f
			end
		end
		return false
	end,

	inStockpile = function(self, x, y)
		for _, s in ipairs(self.stockpiles) do
			if s:inTile(x, y) then
				return s
			end
		end
		return nil
	end,

	isBuildable = function(self, x, y)
		if not self:isWalkable(x, y) then
			return false
		elseif self:isHull(x, y) then
			return false
		elseif self:isWall(x, y) then
			return false
		elseif #self:getFurnitureInTile(self:getTile(x, y)) > 0 then
			return false
		end
		return true
	end,

	inRoom = function(self, x, y)
		local t = self:getTile(x, y)
		for _, room in ipairs(self.rooms) do
			if t and room:inRoom(t) then
				return room
			end
		end
		return false
	end,

	getTile = function(self, x, y)
		local nx = x - self.xOffset
		local ny = y - self.yOffset
		if nx <= 0 or ny <= 0 or nx > self.width or ny > self.height then return nil end
		return self.tiles[(ny - 1)*self.width + nx]
	end,

	getTileAtIndex = function(self, idx)
		return self.tiles[idx]
	end,

	getTileAtWorld = function(self, worldX, worldY)
		for _, t in ipairs(self.tiles) do
			if t:inBounds(worldX, worldY) then
				return t
			end
		end

		return nil
	end,

	getEntitiesAtWorld = function(self, worldX, worldY)
		local entities = {}
		for _, e in ipairs(self.entities) do
			if e:inBounds(worldX, worldY) then
				table.insert(entities, e)
			end
		end
		return entities
	end,

	getItemsAtWorld = function(self, worldX, worldY)
		local items = {}
		for _, i in ipairs(self.items) do
			if not i.owned and i:inBounds(worldX, worldY) then
				table.insert(items, i)
			end
		end

		return items
	end,

	getFurnitureAtWorld = function(self, worldX, worldY)
		local furniture = {}
		for _, f in ipairs(self.furniture) do
			if f:inBounds(worldX, worldY) then
				table.insert(furniture, f)
			end
		end

		return furniture
	end,

	getStockpileAtWorld = function(self, worldX, worldY)
		for _, s in ipairs(self.stockpiles) do
			if s:inBounds(worldX, worldY) then
				return s
			end
		end
	end,

	getObjectsAtWorld = function(self, worldX, worldY)
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
	end,

	getItemsInTile = function(self, tile)
		local items = {}
		for _, item in ipairs(self.items) do
			if not item.owned and item.x == tile.x and item.y == tile.y then
				table.insert(items, item)
			end
		end
		return items
	end,

	getEntitiesInTile = function(self, tile)
		local entities = {}
		for _, entity in ipairs(self.entities) do
			if entity.x == tile.x and entity.y == tile.y then
				table.insert(entities, entity)
			end
		end
		return entities
	end,

	getFurnitureInTile = function(self, tile)
		local furniture = {}
		for _, furn in ipairs(self.furniture) do
			if furn:inTile(tile.x, tile.y) then
				table.insert(furniture, furn)
			end
		end
		return furniture
	end,

	getObjectsInTile = function(self, tile)
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
		for _, s in ipairs(self.stockpiles) do
			if s:inTile(tile) then
				table.insert(objects, s)
			end
		end

		return objects
	end,

	getCentermostTile = function(self)
		return self:getTile(math.ceil(self.width/2)+self.xOffset, math.ceil(self.height/2)+self.yOffset)
	end,

	getRandomWalkableTile = function(self)
		local t

		repeat
			local random = math.random(#self.tiles)
			t = self.tiles[random]
		until self:isWalkable(t.x, t.y)

		return t
	end,

	getWalkableTileInRadius = function(self, x, y, r)
		local t
		local count = 0
		local points = midpointCircle(x, y, r)
		local tiles = self:getTilesFromPoints(points)
		local num = #points
		local max = num*num
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
	end,

	getRandomWalkableTileInRadius = function(self, x, y, r)
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
	end,

	getTilesFromPoints = function(self, points)
		local tiles = {}
		for _, point in ipairs(points) do
			local t = self:getTile(point.x + self.xOffset, point.y + self.yOffset)
			if t then
				table.insert(tiles, t)
			end
		end
		return tiles
	end,

	getTilesInRectangle = function(self, x, y, width, height)
		local points = {}

		--x = x - self.xOffset
		--y = y - self.yOffset
		for r=0, width-1 do
			for c=0, height-1 do
				table.insert(points, {x=x+r, y=y+c})
			end
		end
		local tiles = self:getTilesFromPoints(points)
		return tiles
	end,

	detectRoom = function(self, tile)

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
}

return map_utils