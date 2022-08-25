local class = require('lib.middleclass')
local item = require('items.item')
local drawable = require('drawable')
local mapObject = require('mapObject')

local corpse = class('corpse', item)

function corpse:initialize(classObj, name, label, map, posX, posY)
	local obj = classObj:retrieve(name)
	if obj then
		mapObject.initialize(self, obj, name, label, map, posX, posY, 1, 1, false)
	else
		error("attempted to initialize " .. name .. " but no object with that name was found")
	end

	self.map = map
	self.amount = 1

	-- self.originTileWidth = self.width
	-- self.originTileHeight = self.height
	-- self.originSpriteWidth = self.spriteWidth
	-- self.originSpriteHeight = self.spriteHeight
	-- self.originXOffset = self.xOffset
	-- self.originYOffset = self.yOffset

	-- self.tileWidth = self.originTileHeight
	-- self.tileHeight = self.originTileWidth
	-- self.width = self.originTileHeight
	-- self.height = self.originTileWidth
	-- self.spriteWidth = self.originSpriteHeight
	-- self.spriteHeight = self.originSpriteWidth
end

function corpse:draw(ent)
	local c = self.map.camera
	local x, y

	x = c:getRelativeX(self:getWorldX())
	y = c:getRelativeY(self:getWorldY() + self.spriteHeight - TILE_SIZE)
	
	mapObject.draw(self, x, y, c.scale, math.pi/2)
end

function corpse:removedFromInventory(entity)
	item.removedFromInventory(self, entity)
end

return corpse