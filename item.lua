local class = require('middleclass')
local game = require('game')

item = class('item')

function item:initialize(imgPath, x, y, name)
	name = name or "unknown item"
	self.sprite = love.graphics.newImage(imgPath)
	self.x = x
	self.y = y
	self.xOffset = 0
	self.yOffset = 0
	self.name = name
end

function item:draw()
	draw(self.sprite, (self.x - 1)*TILE_SIZE + self.xOffset, (self.y - 1)*TILE_SIZE + self.yOffset)
end

function entity:inBounds(x, y)
	if(x - self:getWorldX() <= TILE_SIZE and x - self:getWorldX() >= 0) then
		if(y - self:getWorldY() <= TILE_SIZE and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function item:getWorldX()
	return (self.x - 1)*TILE_SIZE + self.xOffset
end

function item:getWorldY()
	return (self.y - 1)*TILE_SIZE + self.yOffset
end

function item:getWorldCenterY()
	return (self.y - 1 + 1/2)*TILE_SIZE + self.yOffset
end

function item:getWorldCenterX()
	return (self.x - 1 + 1/2)*TILE_SIZE + self.xOffset
end

function item:getPos()
	return {x=self.x, y=self.y}
end

function item:__tostring()
	return "Item(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ")"
end

return item