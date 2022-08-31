--[[ 
	A bundle is an item representing a dismantled piece of furniture ready to install
]]
local class = require('lib.middleclass')
local item = require('items.item')
local drawable = require('drawable')
local mapObject= require('mapObject')

local bundle = class('bundle', item)

function bundle:initialize(data, label, map, x, y)
	item.initialize(self, "bundle", label, map, x, y)
	self.obj = drawable:new(data.tileset, data.tilesetX, data.tilesetY, data.spriteWidth, data.spriteHeight, data.tileWidth, data.tileHeight, false)
	self.data = data
	local bundleFactor = 0.8
	local xs, ys = convertQuadToScale(self.obj.sprite, TILE_SIZE*bundleFactor, TILE_SIZE*bundleFactor)
	if self.obj.spriteWidth > self.obj.spriteHeight then
		self.scalar = xs
	else
		self.scalar = ys
	end
end

function bundle:draw()
	item.draw(self)
	local c = self.map.camera
	local x, y
	if self.owned then
		x = c:getRelativeX(self.owner:getWorldX() + (TILE_SIZE - self.obj.spriteWidth*self.scalar)/2)
		y = c:getRelativeY(self.owner:getWorldY() - TILE_SIZE/8)
	else
		x = c:getRelativeX(self:getWorldX() + (TILE_SIZE - self.obj.spriteWidth*self.scalar)/2 )
		y = c:getRelativeY(self:getWorldY() - TILE_SIZE/8)
	end
	mapObject.draw(self.obj, x, y, self.scalar*c.scale, -math.pi/4)

end

return bundle

--[[
	self.scaleFactor = 0.4
	self.imageHeight = TILE_SIZE*self.scaleFactor
	self.imageWidth = TILE_SIZE*self.scaleFactor
	self.angle = 0
	if sheight > swidth then
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageHeight, self.imageWidth)
		self.yScale = self.xScale
		--self.angle = math.pi/2
		self.xs = swidth*math.cos(self.angle)
		self.ys = sheight*math.sin(self.angle)
		self.imageX = x + (self.imageHeight - swidth*self.yScale)/2 + 1
		self.imageY = y + (self.imageHeight - sheight*self.yScale)/2
	else
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageWidth, self.imageHeight)
		self.xScale = self.yScale
		self.imageX = x + (self.imageHeight - swidth*self.xScale)/2
		self.imageY = y + (self.imageHeight - sheight*self.yScale)/2
	end
]]