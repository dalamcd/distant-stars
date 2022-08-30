local class = require('lib.middleclass')
local gui = require('gui.gui')
local element = require('gui.element')

local inputField = class('inputField', element)

local _whitelist = "abcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()_-+ ?[];:,.<>{}~"

function inputField:initialize(x, y, width, height, whitelist, blacklist, backgroundColor, outlineWidth, outlineColor)

	whitelist = whitelist or _whitelist
	blacklist = blacklist or ""
	height = height or love.graphics.getFont():getHeight() + 10

	self.x = x
	self.y = y
	self.textY = self.y + math.ceil((height - love.graphics.getFont():getHeight())/2)
	self.text = ""
	self.width = width
	self.height = height
	self.selected = false
	self.max = 255 -- entirely arbitrary number
	self.cursor = {
		x = self.x + 2,
		y1 = self.textY,
		y2 = self.textY + love.graphics.getFont():getHeight(),
		blink = 0,
		hidden = false,
		col = 0
	}
	self.backgroundColor = backgroundColor
	self.outlineWidth = outlineWidth
	self.outlineColor = outlineColor

	self.allowed = {}
	for i=1, #whitelist do
		self.allowed[whitelist:sub(i, i)] = true
	end
	for i=1, #blacklist do
		self.allowed[blacklist:sub(i, i)] = nil
	end
end

function inputField:update(dt)

end

function inputField:draw()
	gui:drawRect(self.x, self.y, self.width, self.height, self.backgroundColor, self.outlineWidth, self.outlineColor)
	love.graphics.print(self.text, self.x + 2, self.textY)
	if self.selected then
		self.cursor.blink = self.cursor.blink + 1
		if self.cursor.blink >= 20 then
			self.cursor.blink = 0
			self.cursor.hidden = not self.cursor.hidden
		end

		if not self.cursor.hidden then
			gui:drawLine(self.cursor.x, self.cursor.y1, self.cursor.x, self.cursor.y2)
		end
	end
end

function inputField:adjustPos(x, y)
	self.x = self.x + x
	self.y = self.y + y
	self.textY = self.textY + y
	self.cursor.x = self.cursor.x + x
	self.cursor.y1 = self.cursor.y1 + y
	self.cursor.y2 = self.cursor.y2 + y
end

function inputField:handleInput(input)

	if input.keypressed then
		if input.keypressed.key == 'backspace' then
			self:backspace()
		end
		if input.keypressed.key == 'delete' then
			self:delete()
		end
		if input.keypressed.key == 'return' then
			self:deselect()
		end
		if input.keypressed.key == 'left' then
			self:moveCursor(self.cursor.col - 1)
		end
		if input.keypressed.key == 'right' then
			self:moveCursor(self.cursor.col + 1)
		end
	end

	if input.textinput then
		self:addChar(input.textinput.text)
	end
end

function inputField:moveCursor(newCol)
	if newCol < 0 or newCol > self.text:len() then return end
	local dx = self.cursor.col - newCol
	if dx > 0 then
		local diff = self.text:sub(newCol + 1, self.cursor.col)
		self.cursor.x = self.cursor.x - love.graphics.getFont():getWidth(diff)
		self.cursor.col = newCol
		return true
	elseif dx < 0 then
		local diff = self.text:sub(self.cursor.col + 1, newCol)
		self.cursor.x = self.cursor.x + love.graphics.getFont():getWidth(diff)
		self.cursor.col = newCol
		return true
	end
	return false
end

function inputField:setText(str)
	local valid = ""
	self:moveCursor(0)
	for i=1, #str do
		if self.allowed[str:sub(i, i):lower()] then
			valid = valid .. str:sub(i, i)
		end
	end
	self.text = valid
	return self.text
end

function inputField:addChar(char)
	if self.allowed[char:lower()] and self.text:len() < self.max then
		self.text = self.text:sub(1, self.cursor.col) .. char .. self.text:sub(self.cursor.col + 1, self.text:len())
		self:moveCursor(self.cursor.col + 1)
		return true
	end
	return false
end

function inputField:backspace()
	if self.cursor.col == 0 then return end
	self:moveCursor(self.cursor.col - 1)
	self.text = self.text:sub(1, self.cursor.col) .. self.text:sub(self.cursor.col + 2, self.text:len())
end

function inputField:delete()
	if self.cursor.col == self.text:len() then return end
	self.text = self.text:sub(1, self.cursor.col) .. self.text:sub(self.cursor.col + 2, self.text:len())
end

function inputField:select()
	self.selected = true
	self:moveCursor(self.text:len())
end

function inputField:deselect()
	self.selected = false
end

function inputField:inBounds(x, y)
	if(x - self.x <= self.width and x - self.x >= 0) then
		if(y - self.y <= self.height and y - self.y >= 0) then
			return true
		end
	end
	return false
end

function inputField:getType()
	return element.getType(self) .. "[[inputField]]"
end

return inputField