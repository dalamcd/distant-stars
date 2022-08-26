local class = require('lib.middleclass')
local utils = require('utils')
local attribute = require('rooms.attribute')

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
		if not alreadyFound and not map:isWall(v.x, v.y) and not map:isHull(v.x, v.y) and not map:isDoor(v.x, v.y) and not map:isVoid(v.x, v.y) then
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

function room.static:detectCycle(tiles)

	local function dfs(tile, previous)
		if tile.finished == true then
			return
		end
		if tile.visited == true then
			print("cycle found", tile.x, tile.y)
			return
		end
		tile.visited = true
		for _, neighbor in ipairs(tile:getNeighbors()) do
			local isPart = false
			for _, t in ipairs(tiles) do
				if neighbor.uid == t.uid and (not previous or t.uid ~= previous.uid) then
					isPart = true
					break
				end
			end
			if isPart then
				dfs(neighbor, tile)
			end
		end
		tile.finished = true
	end

	-- for idx, t in ipairs(tiles) do
	-- 	print(idx)
	-- 	dfs(t)
	-- 	if cycleFound then print("cycle found") end
	-- end
	dfs(tiles[1])

end

function room:initialize(map, tiles)
	self.map = map
	self.tiles = tiles

	self.uid = getUID()
	self.edges = {}
	self.walls = {}
	self.doors = {}
	self.entities = {}
	self.connections = {}
	self.attributes = {}
	self.roomConnections = false
	self:detectEdgeTiles()

	self.oneSecondTimer = 0
end

function room:update(dt)
	-- We should only be getting a call to update() after the map is fully loaded
	-- so at that point we find connections to other rooms
	if not self.roomConnections then
		self:detectConnections()
		self.roomConnections = true
	end

	if self.oneSecondTimer >= 60 then
		self.oneSecondTimer = 0
		self:disperseAttributes()
	end

	self.oneSecondTimer = self.oneSecondTimer + 1
end

function room:draw()
	-- Draw a color on a gradient from blue to red based on the atmo
	-- Interpolation function is (amount-min)/(max-min)*startColor + (1-(amount-min)/(max-min))*endColor
--[[

	-- This variable stands in for (amount-min)/(max-min) where min is 0
	local interpolate = oxy/100
	local oxy = self:getAttribute('oxygen') or 0
	-- The 0 terms are pointless but left in for clarity
	local gr = interpolate*0 + (1-interpolate)*255
	local gg = interpolate*255 + (1-interpolate)*0
	local gb = interpolate*0 + (1-interpolate)*0
	local r, g, b, a = love.math.colorFromBytes(gr, gg, gb, 255/3)
	local color = {r=r, g=g, b=b, a=a}
	for _, t in ipairs(self.tiles) do
		drawRect(self.map.camera:getRelativeX((t.x - 1)*TILE_SIZE), self.map.camera:getRelativeY((t.y - 1)*TILE_SIZE), TILE_SIZE*self.map.camera.scale, TILE_SIZE*self.map.camera.scale, color)
	end
	for _, dt in ipairs(self.doors) do
		circ("fill", dt.door:getWorldCenterX(), dt.door:getWorldCenterY(), 2, self.map.camera)
	end
	local t = self:getCentermostTile()
	if t then
		circ("fill", t:getWorldCenterX(), t:getWorldCenterY(), 5, self.map.camera)
		
		for _, con in ipairs(self.connections) do
			local center = con:getCentermostTile()
			love.graphics.line(self.map.camera:getRelativeX(t:getWorldCenterX()), self.map.camera:getRelativeY(t:getWorldCenterY()), self.map.camera:getRelativeX(center:getWorldCenterX()), self.map.camera:getRelativeY(center:getWorldCenterY()))
		end
	end
	]]
	if #self.entities == 0 then
		for _, t in ipairs(self.tiles) do
			local x = self.map.camera:getRelativeX(t:getWorldX())
			local y = self.map.camera:getRelativeY(t:getWorldY())
			local color = {r=0.2, g=0.2, b=0.2, a=0.7}
			drawRect(x, y, TILE_SIZE*self.map.camera.scale, TILE_SIZE*self.map.camera.scale, color, false)
		end
	end
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

function room:disperseAttributes()
	for _, con in ipairs(self.connections) do
		for name, attr in pairs(self:getAllAttributes()) do
			local conAmt = con:getAttribute(name)
			local selfAmt = attr:getAmount()
			local transfer

			if conAmt then
				if conAmt > selfAmt then
					transfer = -(conAmt/con:getTileCount())
				else
					transfer = selfAmt/self:getTileCount()
				end
			else
				transfer = selfAmt/self:getTileCount()
			end
			self:adjustAttribute(name, -transfer)
			con:adjustAttribute(name, transfer)
		end
	end
end

function room:listAttributes()
	for _, attr in pairs(self.attributes) do
		print(self.uid, attr.label, attr.amount)
	end
end

function room:addAttribute(attr)
	self.attributes[attr.name] = attr
end

function room:getAttribute(attr)
	if self.attributes[attr] then
		return self.attributes[attr].amount
	else
		return 0
	end
end

function room:setAttribute(attr, newAmt)
	local rmattr = self.attributes[attr]

	if not rmattr then
		rmattr = attribute:new(attr)
		self:addAttribute(rmattr)
	end

	if rmattr then
		rmattr:setAmount(newAmt)
	end
end

function room:adjustAttribute(attr, newAmt)
	local rmattr = self.attributes[attr]
	newAmt = newAmt / #self.tiles

	if not rmattr then
		rmattr = attribute:new(attr)
		self:addAttribute(rmattr)
	end

	if rmattr then
		rmattr:adjustAmount(newAmt)
	end
end

function room:getAllAttributes()
	return self.attributes
end

function room:getCentermostTile()
	local x = self.rightMost - math.floor(self.width/2)
	local y = self.bottomMost - math.floor(self.height/2)
	local t = self.map:getTile(x, y)

	if t and self:inTile(t.x, t.y) then
		return t
	else
		return self.tiles[1]
	end
end

function room:getTileCount()
	return #self.tiles
end

function room:detectEntities()
	self.entities = {}
	for _, t in ipairs(self.tiles) do
		local ents = self.map:getEntitiesInTile(t)
		self.entities = concatTables(self.entities, ents)
	end
end

function room:listEntities()
	return self.entities
end

function room:detectEdgeTiles()

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local xSum, ySum = 0, 0
	local doorTiles = {}

	for _, tile in ipairs(self.tiles) do
		local right = self.map:getTile(tile.x + 1, tile.y) 
		local bottom = self.map:getTile(tile.x, tile.y + 1) 
		local left = self.map:getTile(tile.x - 1, tile.y) 
		local top = self.map:getTile(tile.x, tile.y - 1)

		if right and not self:inRoom(right) then
			table.insert(self.edges, {tile.x, tile.y-1, tile.x, tile.y})
			if tile.x > maxX then maxX = tile.x end
			if right:isWall() or right:isHull() then
				table.insert(self.walls, right)
			elseif right:isDoor() then
				table.insert(self.doors, {door=right:isDoor(), x=1, y=0})
				if not self.map:inRoom(right.x, right.y) then
					table.insert(doorTiles, right)
				end
			end
		end
		if bottom and not self:inRoom(bottom) then
			table.insert(self.edges, {tile.x-1, tile.y, tile.x, tile.y})
			if tile.y > maxY then maxY = tile.y end
			if bottom:isWall() or bottom:isHull() then
				table.insert(self.walls, bottom)
			elseif bottom:isDoor() then
				table.insert(self.doors, {door=bottom:isDoor(), x=0, y=1})
				if not self.map:inRoom(bottom.x, bottom.y) then
					table.insert(doorTiles, bottom)
				end
			end
		end
		if left and not self:inRoom(left) then
			table.insert(self.edges, {tile.x-1, tile.y-1, tile.x-1, tile.y})
			if tile.x < minX then minX = tile.x end
			if left:isWall() or left:isHull() then
				table.insert(self.walls, left)
			elseif left:isDoor() then
				table.insert(self.doors, {door=left:isDoor(), x=-1, y=0})
				if not self.map:inRoom(left.x, left.y) then
					table.insert(doorTiles, left)
				end
			end
		end
		if top and not self:inRoom(top) then
			table.insert(self.edges, {tile.x-1, tile.y-1, tile.x, tile.y-1})
			if tile.y < minY then minY = tile.y end
			if top:isWall() or top:isHull() then
				table.insert(self.walls, top)
			elseif top:isDoor() then
				table.insert(self.doors, {door=top:isDoor(), x=0, y=-1})
				if not self.map:inRoom(top.x, top.y) then
					table.insert(doorTiles, top)
				end
			end
		end


		if left and top and not self:inRoom(left) and not self:inRoom(top) then
			local t = self.map:getTile(tile.x - 1, tile.y - 1)
			if t then table.insert(self.walls, t) end
		end
		if right and top and not self:inRoom(right) and not self:inRoom(top) then
			local t = self.map:getTile(tile.x + 1, tile.y - 1)
			if t then table.insert(self.walls, t) end
		end
		if left and bottom and not self:inRoom(left) and not self:inRoom(bottom) then
			local t = self.map:getTile(tile.x - 1, tile.y + 1)
			if t then table.insert(self.walls, t) end
		end
		if right and bottom and not self:inRoom(right) and not self:inRoom(bottom) then
			local t = self.map:getTile(tile.x + 1, tile.y + 1)
			if t then table.insert(self.walls, t) end
		end
	end

	self.tiles = concatTables(self.tiles, doorTiles)
	self.rightMost = maxX
	self.leftMost = minX
	self.bottomMost = maxY
	self.topMost = minY
	self.width = self.rightMost - self.leftMost
	self.height = self.bottomMost - self.topMost
end

function room:detectConnections()
	for _, dt in ipairs(self.doors) do
		local r = self.map:inRoom(dt.door.x + dt.x, dt.door.y + dt.y)
		if r and r.uid ~= self.uid then
			self:addRoomConnection(r)
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

function room:addRoomConnection(newCon)
	local dupe = false
	for _, con in ipairs(self.connections) do
		if con.uid == newCon.uid then
			dupe = true
			break
		end
	end
	if not dupe then
		table.insert(self.connections, newCon)
	end
end

function room:getType()
	return "[[room]]"
end

function room:getClass()
	return room
end

function room:isType(str)
	return string.match(self:getType(), str)
end

return room