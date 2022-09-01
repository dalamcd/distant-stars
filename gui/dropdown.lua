local class = require('lib.middleclass')
local button = require('gui.button')
local gui = require('gui.gui')

local dropdown = class('dropdown', button)

function dropdown:initialize(x, y, width, height, label, contents, backgroundColor, outlineWidth, outlineColor, textColor)
	button.initialize(self, x, y, width, height, label, nil, backgroundColor, outlineWidth, outlineColor, textColor)
	self.contents = {}
	local count = 0
	local f = love.graphics.getFont()
	self.contentSpacingX = 7
	self.contentSpacingY = f:getHeight() + 10
	local longest = 0
	for _, content in ipairs(contents) do
		if f:getWidth(content[1]) > longest then
			longest = f:getWidth(content[1])
		end
		local btnx = x + self.contentSpacingX
		local btny = y + self.contentSpacingX + (self.contentSpacingX + self.contentSpacingY)*count
		local btnheight = self.contentSpacingY
		local btnwidth = 1 -- Dummy width just to give it a value; width is calulated based on longest button
		local btn = button:new(btnx, btny, btnwidth, btnheight, content[1], content[2])
		table.insert(self.contents, btn)
		count = count + 1
	end
	self.buttonWidth = longest + self.contentSpacingX
	self.contentWidth = longest + 3*self.contentSpacingX
	self.contentHeight = self.contentSpacingX*(#self.contents + 1) + self.contentSpacingY*#self.contents
	for _, content in ipairs(self.contents) do
		local bg = self.backgroundColor
		content:setBackgroundColor({bg[1]+0.15, bg[2]+0.15, bg[3]+0.15, 1})
		content.width = self.buttonWidth
	end
	self.selected = false
end

function dropdown:update(dt)
	if self.selected then
		for _, content in ipairs(self.contents) do
			content.selected = false
		end
		local mx, my = gui:getMousePos()
		local content = self:contentsInBounds(mx, my)
		if content then
			content.selected = true
		end
	end
end

function dropdown:draw()
	if self.selected then
		local width, height, label = self.width, self.height, self.label
		self.width = self.contentWidth
		self.height = self.contentHeight
		self.label = ""
		button.draw(self)
		self.width, self.height, self.label = width, height, label
		for _, content in ipairs(self.contents) do
			if content.selected then
				local bg = content.backgroundColor
				content:setBackgroundColor({bg[1]+0.25, bg[2]+0.25, bg[3]+0.25, 1})
				content:draw()
				content:setBackgroundColor(bg)
			else
				content:draw()
			end
		end
	else
		button.draw(self)
	end
end

function dropdown:adjustPos(x, y)
	self.x = self.x + x
	self.y = self.y + y
	for _, content in ipairs(self.contents) do
		content.x = content.x + x
		content.y = content.y + y
	end
end

function dropdown:mousereleased(x, y, button)
	if button == 1 then
		local content = self:contentsInBounds(x, y)
		if content then
			content:click()
			self:deselect()
		end
	end
end

function dropdown:contentsInBounds(mx, my)
	for _, content in ipairs(self.contents) do
		if content:inBounds(mx, my) then
			return content
		end
	end
	return false
end

function dropdown:select()
	self.selected = true
end

function dropdown:deselect()
	self.selected = false
end

function dropdown:getType()
	return button.getType(self) .. "[[dropdown]]"
end

return dropdown