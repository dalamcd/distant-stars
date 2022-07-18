local class = require('middleclass')
local drawable = require('drawable')

furniture = class('furniture', drawable)

function furniture:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, posX, posY, tileWidth, tileHeight)
	drawable.initialize(self, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, posX, posY, tileWidth, tileHeight)
	
	name = name or "unknown furniture"
	self.name = name
	self.contents = {}
	self.output = {}
end

function furniture:draw()
	drawable.draw(self, (self.x - 1)*TILE_SIZE, (self.y - 1)*TILE_SIZE)
end

function furniture:getPossibleTasks()
	return {}
end

function furniture:getType()
	return "furniture"
end

function furniture:__tostring()
	return "Furniture(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ")"
end

return furniture