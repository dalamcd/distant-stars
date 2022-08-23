local class = require('lib.middleclass')
local furniture = require('furniture.furniture')

local wall = class('wall', furniture)

function wall:initialize(name, label, map, posX, posY)
	furniture.initialize(self, name, label, map, posX, posY)

	self.health = 100
end

function wall:damage(amt)
	self.health = self.health - amt
end

function wall:isWall()
	return true
end

function wall:getType()
	return furniture.getType(self) .. "[[wall]][[" .. self.label .. "]]"
end

return wall