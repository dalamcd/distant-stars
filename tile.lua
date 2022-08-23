local class = require('lib.middleclass')
local game = require('game')
local drawable = require('drawable')
local mapObject = require('mapObject')
local walkTask = require('tasks.task_entity_walk')

local tile = class('tile', mapObject)

tile.static._loaded_tiles = {}

function tile.static:load(name, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight)
	local internalItem = self._loaded_tiles[name]

	if internalItem then
		return internalItem
	else
		self._loaded_tiles[name] = {
			tileset = tileset,
			tilesetX = tilesetX,
			tilesetY = tilesetY,
			spriteWidth = spriteWidth,
			spriteHeight = spriteHeight
		}
	end
end

function tile.static:retrieve(name)
	return self._loaded_tiles[name] or false
end

function tile:initialize(name, map, posX, posY, index, walkable)
	local obj = tile:retrieve(name)
	if obj then
		mapObject.initialize(self, obj, name, name, map, posX, posY, 1, 1, false)
	else
		error("attempted to initialize " .. name .. " but no item with that name was found")
	end
	if not index then error("tile initialized without index") end
	if not map then error("tile initialized without map") end

	self.map = map
	self.index = index
	self.walkable = walkable or false
	self.name = name
end

function tile:draw()
	local c = self.map.camera
	local x = self:getWorldX()
	local y = self:getWorldY()
	mapObject.draw(self, c:getRelativeX(x), c:getRelativeY(y), c.scale)
end

-- function tile:inBounds(x, y)
-- 	if( x - self:getWorldX() <= TILE_SIZE*self.map.scale and x - self:getWorldX() >= 0) then
-- 		if( y - self:getWorldY() <= TILE_SIZE*self.map.scale and y - self:getWorldY() >= 0) then
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end

function tile:isWalkable()
	return self.walkable
end

function tile:isWall()
	return self.map:isWall(self.x, self.y)
end

function tile:isOccupied()
	return self.map:isOccupied(self.x, self.y)
end

function tile:isHull()
	return self.map:isHull(self.x, self.y)
end

function tile:isDoor()
	return self.map:isDoor(self.x, self.y)
end

function tile:isBuildable()
	return self.map:isBuildable(self.x, self.y)
end

function tile:getNeighbors()
	local points = {
		{x=self.x+1, y=self.y},
		{x=self.x-1, y=self.y},
		{x=self.x, y=self.y+1},
		{x=self.x, y=self.y-1}
	}
	local tiles = self.map:getTilesFromPoints(points)

	return tiles
end

function tile:getPossibleTasks(map, entity)
	local tasks = {}
	if map:isWalkable(self.x, self.y) and #map:getEntitiesInTile(self) == 0 then
		if entity.x ~= self.x or entity.y ~= self.y then
			local wt = walkTask:new(self)
			table.insert(tasks, wt)
		end
	end
	
	return tasks
end

function tile:__tostring()
	return "Tile(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.index) .. ")"
end

return tile