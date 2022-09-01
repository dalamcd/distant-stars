local class = require('lib.middleclass')
local furniture = require('furniture.furniture')
local drawable = require('drawable')
local mapObject = require('mapObject')
local utils = require('utils')
local gui   = require('gui.gui')

local unfinished = class('unfinished', furniture)

function unfinished:initialize(name, label, map, posX, posY)
	local obj = furniture:retrieve("unfinished")
	if obj then
		furniture.initialize(self, "unfinished", label, map, posX, posY)
		-- mapObject.initialize(self, obj, "unfinished", label, map, posX, posY, obj.tileWidth, obj.tileHeight, true)
	else
		error("attempted to initialize unfinished but no furniture with that name was found (tileset not loaded?)")
	end

	local data = furniture:retrieve(name)
	if data then
		self.obj = drawable:new("furniture", 0, TILE_SIZE*4, TILE_SIZE, TILE_SIZE, data.tileWidth, data.tileHeight, true)
		self.map = map
		self.x = posX
		self.y = posY
		self.xScale, self.yScale = convertQuadToScale(self.obj.sprite, TILE_SIZE*data.tileWidth, TILE_SIZE*data.tileHeight)
		self.name = label
		self.data = data
		self.rotation = 0
		self.spriteWidth = TILE_SIZE*data.tileWidth
		self.spriteHeight = TILE_SIZE*data.tileHeight
		self.width = data.tileWidth
		self.height = data.tileHeight
		self:getWalkableTileAround()
	else
		error("attempted to initialize unfinished " .. name .. " but no item with that name was found")
	end
end

function unfinished:draw()
	local c = self.map.camera
	local x = self:getWorldX()
	local y = self:getWorldY()
	drawable.draw(self.obj, c:getRelativeX(x), c:getRelativeY(y), self.xScale*c.scale, self.yScale*c.scale, 0)
end

function unfinished:rotate(facing)
	furniture.rotate(self, facing)
	self.xScale, self.yScale = convertQuadToScale(self.obj.sprite, TILE_SIZE*self.width, TILE_SIZE*self.height)
end

function unfinished:getWalkableTileAround()
	local x = self.x + self.map.xOffset
	local y = self.y + self.map.yOffset
	local tiles = self.map:getTilesInRectangle(x - 1, y - 1, self.width + 2, self.height + 2)
	for _, t in ipairs(tiles) do
		if self.map:isWalkable(t.x, t.y) then
			if (t.x < x or t.x >= x + self.width) or (t.y < y or t.y >= y + self.height) then
				return t
			end
		end
	end
	return false
end

function unfinished:startWork()
	local f = self:convertToFurniture()
	f:rotate(self.rotation)
	self.map:addFurniture(f)
end

function unfinished:convertToFurniture()
	self.map:removeFurniture(self)
	return self.data.class:new(self.data.name, self.label, self.map, self.x - self.map.xOffset, self.y - self.map.yOffset)
end

function unfinished:getType()
	return furniture.getType(self) .. "[[unfinished]]"
end

return unfinished