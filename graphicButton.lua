require('utils')
local class = require('lib.middleclass')
local button = require('button')

local graphicButton = class('graphicButton', button)

function graphicButton:initialize(x, y, width, height, text, tileset, sprite, clickFunc)
	button.initialize(self, x, y, width, height, text, clickFunc)

	local _, _, swidth, sheight = sprite:getViewport()
	self.imageHeight = math.floor(height*0.75)
	self.imageWidth = math.floor(width*0.8) - 2
	self.sprite = sprite
	self.angle = 0
	if sheight > swidth then
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageHeight, self.imageWidth)
		self.angle = math.pi/2
		self.xs = swidth*math.cos(self.angle)
		self.ys = sheight*math.sin(self.angle)
		self.imageX = x + (width - sheight*self.yScale)/2 + 1
	else
		self.xScale, self.yScale = convertQuadToScale(self.sprite, self.imageWidth, self.imageHeight)
		self.imageX = x + (width - swidth*self.xScale)/2
	end
	self.imageY = y + height - self.imageHeight - 5
	self.tileset = tileset
	self.sprite = sprite
	self.textX = x + (width - love.graphics.getFont():getWidth(text))/2 - 1
	self.textY = y + 2
end

function graphicButton:draw()
	drawRect(self.x, self.y, self.width, self.height)
	love.graphics.draw(self.tileset, self.sprite, self.imageX, self.imageY, self.angle, self.xScale, self.yScale, self.xs, self.ys)
	love.graphics.print(self.text, self.textX, self.textY)
end

return graphicButton