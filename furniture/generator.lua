local class = require('lib.middleclass')
local furniture = require('furniture.furniture')

local generator = class('generator', furniture)

function generator:initialize(name, map, posX, posY, outputType, outputAmount)
	furniture.initialize(self, name, map, posX, posY)
	outputType = outputType or "unknown"
	outputAmount = outputAmount or 0
	self.outputType = outputType
	self.outputAmount = outputAmount
	self.room = nil
	for _, t in ipairs(self:getTiles()) do
		local room = self.map:inRoom(t.x, t.y)
		if room then
			self.room = room
			break
		end
	end
end

function generator:update(dt)
	furniture.update(self, dt)

	if self.room then
		self.room:adjustAttribute(self.outputType, self.outputAmount)
	end
end

return generator