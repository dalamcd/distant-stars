local class = require('lib.middleclass')
local item = require('items.item')
local drawable = require('drawable')

local corpse = class('corpse', item)

function corpse:initialize(objClass, name, map, posX, posY)
	local i = objClass:retrieve(name)
	if i then
		drawable.initialize(self, i.tileset, i.tilesetX, i.tilesetY, i.spriteWidth, i.spriteHeight, posX, posY, 1, 1)
	else
		error("attempted to initialize " .. name .. " but no entity with that name was found")
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
	local x = c:getRelativeX((self.x - 1)*TILE_SIZE) + self.originSpriteHeight*c.scale
	local y = c:getRelativeY((self.y - 1)*TILE_SIZE) + (self.originSpriteWidth - TILE_SIZE)*c.scale
	drawable.draw(self, x, y, c.scale, math.pi/2)
end

function corpse:getWorldX()
	local c = self.map.camerax
	return drawable.getWorldX(self)
end

function corpse:getWorldY()
	local c = self.map.camera
	return drawable.getWorldY(self) + (self.originSpriteWidth - TILE_SIZE)
end

function corpse:removedFromInventory(entity)
	item.removedFromInventory(self, entity)
	self.xOffset = self.originYOffset
	self.yOffset = self.originXOffset
end

return corpse