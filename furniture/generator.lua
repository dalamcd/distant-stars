local class = require('lib.middleclass')
local furniture = require('furniture.furniture')
local attribute = require('rooms.attribute')

local generator = class('generator', furniture)

function generator:initialize(name, label, map, posX, posY)
	local mobj = furniture.initialize(self, name, label, map, posX, posY)
	self.attr = attribute:new(mobj.attribute) or nil
	self.outputAmount = mobj.outputAmount or 0
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