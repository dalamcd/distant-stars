local class = require('lib.middleclass')
local utils = require('utils')
local gui = require('gui.gui')
local element = require('gui.element')

local button = class('button', element)

function button:initialize(x, y, width, height, label, clickFunc, backgroundColor, outlineWidth, outlineColor, textColor)

	label = label or ""
	clickFunc = clickFunc or function () end
	backgroundColor = backgroundColor or {0, 0, 0, 1}
	outlineWidth = outlineWidth or 1
	outlineColor = outlineColor or {1, 1, 1, 1}
	textColor = textColor or {1, 1, 1, 1}

	self.uid = getUID()
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.label = label
	self.clickFunc = clickFunc
	self.backgroundColor = backgroundColor
	self.outlineWidth = outlineWidth
	self.outlineColor = outlineColor
	self.textColor = textColor
end

function button:update(dt)

end

function button:draw()
	gui:drawRect(self.x, self.y, self.width, self.height, self.backgroundColor, self.outlineWidth, self.outlineColor)
	local tx = self.x + (self.width - love.graphics.getFont():getWidth(self.label))/2 - 1
	local ty = self.y + (self.height - love.graphics.getFont():getHeight())/2 - 1
	love.graphics.push("all")
	love.graphics.setColor(unpack(self.textColor))
	love.graphics.print(self.label, tx, ty)
	love.graphics.pop()
end

function button:setBackgroundColor(color)
	self.backgroundColor = color
end

function button:setOutlineColor(color)
	self.outlineColor = color
end

function button:setTextColor(color)
	self.textColor = color
end

function button:setOutlineWidth(width)
	self.outlineWidth = width
end

function button:click(p)
	self:clickFunc(p)
end

function button:inBounds(x, y)
	if(x - self.x <= self.width and x - self.x >= 0) then
		if(y - self.y <= self.height and y - self.y >= 0) then
			return true
		end
	end
	return false
end

function button:getType()
	return element.getType(self) .. "[[button]]"
end

return button