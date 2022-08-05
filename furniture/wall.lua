local class = require('middleclass')
local furniture = require('furniture.furniture')

local wall = class('wall', furniture)

function wall:initialize(name, map, posX, posY)
	furniture.initialize(self, name, map, posX, posY)

	self.health = 100
end

function wall:damage(amt)
	self.health = self.health - amt
end

function wall:isWall()
	return true
end

function wall:getType()
	return furniture.getType(self) .. "[[wall]][[" .. self.name .. "]]"
end

return wall