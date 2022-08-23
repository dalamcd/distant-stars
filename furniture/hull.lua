local class = require('lib.middleclass')
local furniture = require('furniture.furniture')

local hull = class('hull', furniture)

function hull:initialize(name, label, map, posX, posY)
	furniture.initialize(self, name, label, map, posX, posY)

	self.health = 100
end

function hull:update(dt)
	if self.health == 0 then
		self.map:hullDestroyed(self)
	end
end

function hull:damage(amt)
	self.health = self.health - amt
end

function hull:getType()
	return furniture.getType(self) .. "[[hull]]"
end

return hull