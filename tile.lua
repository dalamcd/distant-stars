local class = require('middleclass')
local game = require('game')
local drawable = require('drawable')

tile = class('tile', drawable)

function tile:initialize(tileset, tilesetX, tilesetY, name, map, posX, posY, index, walkable)
	drawable.initialize(self, tileset, tilesetX, tilesetY, TILE_SIZE, TILE_SIZE, posX, posY, 1, 1)	
	if not index then error("tile initialized without index") end
	if not map then error("tile initialized without map") end

	self.map = map
	self.index = index
	self.walkable = walkable or false
	self.name = name
end

function tile:inBounds(x, y)
	if( x - self:getWorldX() <= TILE_SIZE and x - self:getWorldX() >= 0) then
		if( y - self:getWorldY() <= TILE_SIZE and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function tile:isWalkable()
	return self.walkable
end

function tile:isWall()
	return not self.walkable
end

function tile:isOccupied()
	return self.map:isOccupied(self.x, self.y)
end

function tile:getPossibleTasks(map, entity)
	local tasks = {}

	if map:isWalkable(self.x, self.y) and #map:getEntitiesInTile(self) == 0 then
		if entity.x ~= self.x or entity.y ~= self.y then
			local walkTask = entity:getWalkTask(self)
			table.insert(tasks, walkTask)
		end
	end
	
	return tasks
end

function tile:draw()
	local c = self.map.camera
	drawable.draw(self, c:getRelativeX((self.x - 1)*TILE_SIZE), c:getRelativeY((self.y - 1)*TILE_SIZE), c.scale)
end

function tile:__tostring()
	return "Tile(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.index) .. ")"
end

return tile