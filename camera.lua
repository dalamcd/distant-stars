local class = require('middleclass')
local game = require('game')
local utils = require('utils')

camera = class('camera')

local scaleFactor = 0.1
local maxZoom = 3.5
local minZoom = 0.5

function camera:initialize()
	self.xOffset = 0
	self.yOffset = 0
	self.scale = 1
end

function camera:moveXOffset(offset)
	self.xOffset = self.xOffset + offset
end

function camera:moveYOffset(offset)
	self.yOffset = self.yOffset + offset
end

function camera:getRelativeX(x)
	return self.scale*x + self.xOffset
end

function camera:getRelativeY(y)
	return self.scale*y + self.yOffset
end

function camera:getRelativePos(x, y)
	return self.scale*x + self.xOffset, self.scale*y + self.yOffset
end

function camera:zoomIn()
	local ox = (love.graphics.getWidth()/2 - self.xOffset) / self.scale
	local oy = (love.graphics.getHeight()/2 - self.yOffset) / self.scale

	self.scale = clamp(self.scale + scaleFactor, minZoom, maxZoom)

	local nx = (love.graphics.getWidth()/2 - self.xOffset) / self.scale
	local ny = (love.graphics.getHeight()/2 - self.yOffset) / self.scale

	self:moveXOffset((nx - ox)*self.scale)
	self:moveYOffset((ny - oy)*self.scale)
end

function camera:zoomOut()
	local ox = (love.graphics.getWidth()/2 - self.xOffset) / self.scale
	local oy = (love.graphics.getHeight()/2 - self.yOffset) / self.scale

	self.scale = clamp(self.scale - scaleFactor, minZoom, maxZoom)

	local nx = (love.graphics.getWidth()/2 - self.xOffset) / self.scale
	local ny = (love.graphics.getHeight()/2 - self.yOffset) / self.scale

	self:moveXOffset((nx - ox)*self.scale)
	self:moveYOffset((ny - oy)*self.scale)
end

return camera