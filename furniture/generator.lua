local class = require('lib.middleclass')
local furniture = require('furniture.furniture')

local generator = class('generator', furniture)

function generator:initialize(name, map, posX, posY, attribute, outputAmount)
	furniture.initialize(self, name, map, posX, posY)
	self.attr = attribute
	self.outputAmount = outputAmount
	self.room = nil
	self.paused = false
	for _, t in ipairs(self:getTiles()) do
		local room = self.map:inRoom(t.x, t.y)
		if room then
			self.room = room
			break
		end
	end
end

function generator:pause()
	self.paused = not self.paused
end

function generator:update(dt)
	furniture.update(self, dt)

	if self.room and not self.paused then
		self.room:adjustAttribute(self.attr.name, self.outputAmount)
	end
end

function generator:getType()
	return furniture.getType(self) .. "[[generator]]"
end

return generator