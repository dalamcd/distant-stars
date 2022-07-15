local class = require('middleclass')

furniture = class('furniture')

function furniture:initialize(imgPath, x, y, width, height, name)
	name = name or "unknown furniture"
	self.sprite = love.graphics.newImage(imgPath)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.xOffset = 0
	self.yOffset = 0
	self.imgYOffset = TILE_SIZE*self.height - self.sprite:getHeight()
	self.imgXOffset = (TILE_SIZE*self.width - self.sprite:getWidth())/2
	self.name = name
	self.contents = {}
	self.output = {}
end

function furniture:draw()
	draw(self.sprite, (self.x - 1)*TILE_SIZE + self.xOffset + self.imgXOffset, (self.y - 1)*TILE_SIZE + self.yOffset + self.imgYOffset)
end

function furniture:inBounds(x, y)
	if(x - self:getWorldX() <= TILE_SIZE*self.width and x - self:getWorldX() >= 0) then
		if(y - self:getWorldY() <= TILE_SIZE*self.height and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function furniture:inTile(x, y)
	if x - self.x < self.width and x - self.x >= 0 then
		if y - self.y < self.height and y - self.y >= 0 then
			return true
		end
	end
	return false
end

function furniture:getWorldX()
	return (self.x - 1)*TILE_SIZE + self.xOffset + self.imgXOffset
end

function furniture:getWorldY()
	return (self.y - 1)*TILE_SIZE + self.yOffset
end

function furniture:getWorldCenterY()
	return (self.y - self.height - 1/2)*TILE_SIZE + self.yOffset
end

function furniture:getWorldCenterX()
	return (self.x - self.width - 1/2)*TILE_SIZE + self.xOffset
end

function furniture:__tostring()
	return "Furniture(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ")"
end

return furniture