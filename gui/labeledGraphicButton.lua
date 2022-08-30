require('utils')
local class = require('lib.middleclass')
local gui = require('gui.gui')
local button = require('gui.button')

local labeledGraphicButton = class('labeledGraphicButton', button)

function labeledGraphicButton:initialize(x, y, width, height, text, tileset, sprite, clickFunc, backgroundColor, outlineWidth, outlineColor, textColor)
	button.initialize(self, x, y, width, height, text, clickFunc, backgroundColor, outlineWidth, outlineColor)

	textColor = textColor or {1, 1, 1, 1}

	local _, _, swidth, sheight = sprite:getViewport()
	self.imageHeight = math.floor(height*0.75)
	self.imageWidth = math.floor(width*0.8) - 2
	self.sprite = sprite
	self.textColor = textColor
	self.angle = 0
	if sheight > swidth then
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageHeight, self.imageWidth)
		self.yScale = self.xScale
		self.angle = math.pi/2
		self.xs = swidth*math.cos(self.angle)
		self.ys = sheight*math.sin(self.angle)
		self.imageX = (width - sheight*self.yScale)/2 + 1
	else
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageWidth, self.imageHeight)
		self.xScale = self.yScale
		self.imageX = (width - swidth*self.xScale)/2
	end
	self.imageY = 2--+ self.imageHeight
	self.tileset = tileset
	self.sprite = sprite
	self.textX = (width - love.graphics.getFont():getWidth(text))/2 - 1
	self.textY = height - love.graphics.getFont():getHeight() - 2
end

function labeledGraphicButton:draw()
	gui:drawRect(self.x, self.y, self.width, self.height, self.backgroundColor, self.outlineWidth, self.outlineColor)
	love.graphics.draw(self.tileset, self.sprite, self.x + self.imageX, self.y + self.imageY, self.angle, self.xScale, self.yScale, self.xs, self.ys)
	love.graphics.push("all")
	love.graphics.setColor(unpack(self.textColor))
	love.graphics.print(self.label, self.x + self.textX, self.y + self.textY)
	love.graphics.pop()
end

function labeledGraphicButton:getType()
	return button.getType(self) .. "[[labeledGraphicButton]]"
end

return labeledGraphicButton