local class = require('lib.middleclass')
local utils = require('utils')

local button = class('button')

function button:initialize(x, y, width, height, text, clickFunc)

	clickFunc = clickFunc or function () return end
	text = text or ""

	self.uid = getUID()
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.text = text
	self.clickFunc = clickFunc
end

function button:update(dt)

end

function button:draw(color)
	local r, g, b, a = love.graphics.getColor()
	color = color or {r=1.0, g=1.0, b=1.0, a=1.0}
	--love.graphics.setColor(color.r, color.g, color.b, color.a)
	drawRect(self.x, self.y, self.width, self.height, color)
	local tx = self.x + (self.width - love.graphics.getFont():getWidth(self.text))/2 - 1
	local ty = self.y + (self.height - love.graphics.getFont():getHeight())/2 - 1
	love.graphics.print(self.text, tx, ty)
	love.graphics.setColor(r, g, b, a)
end

function button:inBounds(x, y)
	if(x - self.x <= self.width and x - self.x >= 0) then
		if(y - self.y <= self.height and y - self.y >= 0) then
			return true
		end
	end
	return false
end

return button