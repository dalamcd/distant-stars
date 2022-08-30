local class = require('lib.middleclass')
local gui = require('gui.gui')
local inputField = require('gui.inputField')

local labeledInputField = class('labeledInputField', inputField)

local _whitelist = "abcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()_-+ ?[];:,.<>{}~"

function labeledInputField:initialize(x, y, width, height, label, whitelist, blacklist, backgroundColor, outlineWidth, outlineColor, labelColor, textColor)
	inputField.initialize(self, x, y, width, height, whitelist, blacklist, backgroundColor, outlineWidth, outlineColor)
	label = label or ""
	labelColor = labelColor or {1, 1, 1, 1}
	textColor = textColor or {1, 1, 1, 1}

	self.label = label
	self.offset = love.graphics.getFont():getWidth(self.label) + 10
	self.labelColor = labelColor
	self.textColor = textColor
end

function labeledInputField:draw()
	self.textY = self.y + math.ceil((self.height - love.graphics.getFont():getHeight())/2)
	self.cursor.y1 = self.textY
	self.cursor.y2 = self.textY + love.graphics.getFont():getHeight()

	gui:drawRect(self.x + self.offset, self.y, self.width, self.height, self.backgroundColor, self.outlineWidth, self.outlineColor)
	love.graphics.push("all")
	love.graphics.setColor(unpack(self.labelColor))
	love.graphics.print(self.label .. ": ", self.x, self.textY)
	love.graphics.setColor(unpack(self.textColor))
	love.graphics.print(self.text, self.x + 2 + self.offset, self.textY)
	love.graphics.pop()
	if self.selected then
		self.cursor.blink = self.cursor.blink + 1
		if self.cursor.blink >= 20 then
			self.cursor.blink = 0
			self.cursor.hidden = not self.cursor.hidden
		end

		if not self.cursor.hidden then
			gui:drawLine(self.cursor.x + self.offset, self.cursor.y1, self.cursor.x + self.offset, self.cursor.y2)
		end
	end
end

function inputField:inBounds(x, y)
	if(x - self.x - self.offset <= self.width and x - self.x - self.offset >= 0) then
		if(y - self.y <= self.height and y - self.y >= 0) then
			return true
		end
	end
	return false
end

function labeledInputField:getType()
	return inputField.getType(self) .. "[[labeledInputField]]"
end

return labeledInputField