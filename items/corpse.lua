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
	self.label = name
	self.map = map

	self.originTileWidth = self.width
	self.originTileHeight = self.height
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
end

function corpse:draw(ent)
	local c = self.map.camera
	local x, y
	if ent then
		x = c:getRelativeX(ent:getWorldX())
		y = c:getRelativeY(ent:getWorldY())
	else
		x = c:getRelativeX(self:getWorldX())
		y = c:getRelativeY(self:getWorldY())
	end
	mapObject.draw(self, x, y, c.scale, math.pi/2)
end

function corpse:removedFromInventory(entity)
	item.removedFromInventory(self, entity)
end

return corpse