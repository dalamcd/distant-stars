local class = require('middleclass')
local game = require('game')

tile = class('tile')

function tile:initialize(tileType, x, y, index)
	
	if tileType == 1 then
		self.sprite = love.graphics.newImage("sprites/metalWall.png")
	elseif tileType == 2 then
		self.sprite = love.graphics.newImage("sprites/metalTile.png")
	else
		love.graphics.newImage("sprites/default.png")
	end

	self.x = x
	self.y = y
	self.index = index

end

function tile:inBounds(x, y)
	if( x - self:getWorldX() <= self.sprite:getWidth() 
      and x - self:getWorldX() >= 0) then
		if( y - self:getWorldY() <= self.sprite:getHeight()
        and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function tile:getWorldX()
	return (self.x - 1)*self.sprite:getWidth()
end

function tile:getWorldY()
	return (self.y - 1)*self.sprite:getHeight()
end

function tile:draw()
	draw(self.sprite, (self.x - 1)*self.sprite:getWidth(), (self.y - 1)*self.sprite:getHeight())
end

function tile:__tostring()
	return "Tile(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.index) .. ")"
end

return tile