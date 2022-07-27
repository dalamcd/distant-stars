local class = require('middleclass')
local furniture = require('furniture/furniture')

local hull = class('hull', furniture)

function hull:initialize(name, map, posX, posY)
	furniture.initialize(self, name, map, posX, posY)

	self.health = 100
end

function hull:damage(amt)
	self.health = self.health - amt
end

function hull:getType()
	return furniture.getType(self) .. "[[hull]]"
end

return hull