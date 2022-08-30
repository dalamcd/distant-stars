require('utils')
local class = require('lib.middleclass')
local gui = require('gui.gui')
local button = require('gui.button')

local graphicButton = class('graphicButton', button)

function graphicButton:initialize(x, y, width, height, tileset, sprite, clickFunc, backgroundColor, outlineWidth, outlineColor)
	button.initialize(self, x, y, width, height, "", clickFunc, backgroundColor, outlineWidth, outlineColor)

	local _, _, swidth, sheight = sprite:getViewport()
	self.imageHeight = math.floor(height*0.8)
	self.imageWidth = math.floor(width*0.8) - 2
	self.sprite = sprite
	self.angle = 0
	if sheight > swidth then
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageHeight, self.imageWidth)
		self.yScale = self.xScale
		self.angle = math.pi/2
		self.xs = swidth*math.cos(self.angle)
		self.ys = sheight*math.sin(self.angle)
		self.imageX = x + (width - sheight*self.yScale)/2 + 1
		self.imageY = y + (height - swidth*self.yScale)/2
	else
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageWidth, self.imageHeight)
		self.xScale = self.yScale
		self.imageX = x + (width - swidth*self.xScale)/2
		self.imageY = y + (height - sheight*self.yScale)/2
	end
	self.tileset = tileset
	self.sprite = sprite
end

function graphicButton:draw()
	gui:drawRect(self.x, self.y, self.width, self.height, self.backgroundColor, self.outlineWidth, self.outlineColor)
	love.graphics.draw(self.tileset, self.sprite, self.imageX, self.imageY, self.angle, self.xScale, self.yScale, self.xs, self.ys)
end

function graphicButton:getType()
	return button.getType(self) .. "[[graphicButton]]"
end

return graphicButton