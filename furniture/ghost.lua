local class = require('middleclass')
local furniture = require('furniture.furniture')

local ghost = class('ghost', furniture)

function ghost:initialize(objClass, name, map, posX, posY)
	objClass.initialize(self, name, map, posX, posY)
	self.objClass = objClass
end

function ghost:update(dt)
	local t = self.map:getTileAtWorld(getMousePos(self.map.camera))
	if t then 
		self.x = t.x
		self.y = t.y
	end
end

function ghost:draw()
	local ox = self.x
	local oy = self.y
	local adjX, adjY = self:detectCenter()
	if self.rotation == 0 or self.rotation == 1 then
		self.x = self.x - adjX
		self.y = self.y - adjY
	elseif self.rotation == 3 then
		self.x = self.x - adjX
		self.y = self.y - adjY
	else
		self.x = self.x + adjX
		self.y = self.y - adjY
	end
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(0.1, 0.1, 0.1, 0.4)
	furniture.draw(self)
	love.graphics.setColor(r, g, b, a)
	self.x = ox
	self.y = oy
end

function ghost:rotate(reverse)
	if reverse then
		self.rotation = (self.rotation - 1) % 4
	else
		self.rotation = (self.rotation + 1) % 4
	end

	if self.rotation == 0 then
		self.tileWidth = self.originTileWidth
		self.tileHeight = self.originTileHeight
		self.width = self.originTileWidth
		self.height = self.originTileHeight
		self.spriteWidth = self.originSpriteWidth
		self.spriteHeight = self.originSpriteHeight
		self.sprite = self.southFacingQuad
	elseif self.rotation == 1 then
		self.tileWidth = self.originTileHeight
		self.tileHeight = self.originTileWidth
		self.width = self.originTileHeight
		self.height = self.originTileWidth
		self.spriteWidth = self.originSpriteHeight
		self.spriteHeight = self.originSpriteWidth
		self.sprite = self.westFacingQuad
	elseif self.rotation == 2 then
		self.tileWidth = self.originTileWidth
		self.tileHeight = self.originTileHeight
		self.width = self.originTileWidth
		self.height = self.originTileHeight
		self.spriteWidth = self.originSpriteWidth
		self.spriteHeight = self.originSpriteHeight
		self.sprite = self.northFacingQuad
	elseif self.rotation == 3 then
		self.tileWidth = self.originTileHeight
		self.tileHeight = self.originTileWidth
		self.width = self.originTileHeight
		self.height = self.originTileWidth
		self.spriteWidth = self.originSpriteHeight
		self.spriteHeight = self.originSpriteWidth
		self.sprite = self.eastFacingQuad
	end
	self.xOffset = TILE_SIZE*self.tileWidth - self.spriteWidth
	self.yOffset = TILE_SIZE*self.tileHeight - self.spriteHeight
end

function ghost:place()
	local obj = self.objClass:new(self.name, self.map, self.x - self.map.xOffset, self.y - self.map.yOffset)
	self.map:addFurniture(obj)
end

function ghost:detectCenter()
	local xAdjust = math.ceil(self.width/2) - 1
	local yAdjust = math.ceil(self.height/2) - 1
	return xAdjust, yAdjust
end

function ghost:getPossibleTasks()
	return {}
end

function ghost:isWall()
	return false
end

function ghost:isWalkable()
	return true
end

function ghost:isHull()
	return false
end

return ghost