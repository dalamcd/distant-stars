local class = require('lib.middleclass')
local item = require('items.item')
local drawable = require('drawable')
local mapObject = require('mapObject')

local corpse = class('corpse', item)

function corpse:initialize(objClass, name, map, posX, posY)
	local obj = objClass:retrieve(name)
	if obj then
		mapObject.initialize(self, obj, name, map, posX, posY, 1, 1, false)
	else
		error("attempted to initialize " .. name .. " but no object with that name was found")
	end

	self.maxStack = 1
	self.amount = 1
	self.name = name
	self.map = map

	self.originTileWidth = self.tileWidth
	self.originTileHeight = self.tileHeight
	self.originSpriteWidth = self.spriteWidth
	self.originSpriteHeight = self.spriteHeight
	self.originXOffset = self.xOffset
	self.originYOffset = self.yOffset

	self.tileWidth = self.originTileHeight
	self.tileHeight = self.originTileWidth
	self.width = self.originTileHeight
	self.height = self.originTileWidth
	self.spriteWidth = self.originSpriteHeight
	self.spriteHeight = self.originSpriteWidth
	self.xOffset = self.originYOffset
	self.yOffset = self.originXOffset
end

function corpse:draw()
	local c = self.map.camera
	local x = c:getRelativeX(self:getWorldX() + self.originSpriteHeight)
	local y = c:getRelativeY(self:getWorldY() + self.originSpriteWidth - TILE_SIZE)
	mapObject.draw(self, x, y, c.scale, math.pi/2)
end

function corpse:removedFromInventory(entity)
	item.removedFromInventory(self, entity)
	self.xOffset = self.originYOffset
	self.yOffset = self.originXOffset
end

return corpse