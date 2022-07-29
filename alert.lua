local class = require('middleclass')
local button = require('button')

local alert = class('alert')

function alert:update(dt)
	for _, msg in ipairs(self.messages) do
		if msg.xStep < math.pi then
			msg.steps = msg.steps + 1
			msg.xOffset = -20*math.sin(2*msg.xStep)
			msg.xStep = msg.xStep + self.step
		end
	end
end

function alert:draw()
	for i, msg in ipairs(self.messages) do
		msg.x = self.x + msg.xOffset
		msg:draw({r=1.0, g=0.0, b=0.0, a=0.8})
	end
end

function alert:inBounds(x, y)
	for _, msg in ipairs(self.messages) do
		if msg:inBounds(x, y, self.map.camera) then
			return msg
		end
	end
	return false
end

function alert:initialize(map)
	if not map then error("alert initialized with no map") return end
	self.map = map
	self.width = 100
	self.height = 31
	self.x = love.graphics.getWidth() - self.width - 20
	self.y = love.graphics.getHeight() - self.height - 20
	self.step = math.pi/50
	self.messages = {}
end

function alert:addAlert(str)
	local b = button:new(self.x, self.y - (self.height+10)*#self.messages, self.width, self.height, str)
	b.xOffset = 0
	b.xStep = 0
	b.steps = 0
	table.insert(self.messages, b)
end

function alert:removeAlert(msg)
	for i, m in ipairs(self.messages) do
		if m.uid == msg.uid then
			table.remove(self.messages, i)
		end
	end
end

return alert