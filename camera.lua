local class = require('lib.middleclass')
local game = require('game')
local utils = require('utils')

local camera = class('camera')

local scaleFactor = 0.1
local maxZoom = 3.5
local minZoom = 0.5

function camera:initialize()
	self.xOffset = 0
	self.yOffset = 0
	self.xVel = 0
	self.yVel = 0
	self.scale = 1
	self.angle = 0
end

function camera:update()
	if self.translating then
		self.xMoved = self.xMoved + math.abs(self.xVel)
		self.yMoved = self.yMoved + math.abs(self.yVel)
		if self.xMoved < self.xTarget or self.yMoved < self.yTarget then
			self.xOffset = self.xOffset - self.xVel
			self.yOffset = self.yOffset - self.yVel
		else
			self.xOffset = self.xTargetOffset
			self.yOffset = self.yTargetOffset
			self.translating = false
		end
	end
end

-- TODO: replace the circle--which indicates the direction of the angle--with an arrow
function camera:draw()
	if self.angle then
		local y = love.graphics.getHeight()/2
		local x = 40
		local endY = y - 30*math.sin(self.angle)
		local endX = 40 + 30*math.cos(self.angle)
		love.graphics.line(x, y, endX, endY)
		love.graphics.circle("fill", endX, endY, 3)
		local newAngle = self.angle + math.pi/4
	end
end

function camera:moveXOffset(offset)
	self.translating = false
	self.xOffset = self.xOffset + offset
end

function camera:moveYOffset(offset)
	self.translating = false
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

function camera:translate(x, y, speed)
	local dx = self:getRelativeX(x) - love.graphics:getWidth()/2
	local dy = self:getRelativeY(y) - love.graphics:getHeight()/2
	local moveCf = (dx^2 + dy^2)^(1/4)
	local angle = math.atan(-dy/dx)
	if dx < 0 then
		angle = angle + math.pi
	end
	self.translating = true
	self.angle = angle
	self.xTarget = math.abs(dx)
	self.yTarget = math.abs(dy)
	self.xTargetOffset = self.xOffset - dx
	self.yTargetOffset = self.yOffset - dy
	self.xMoved = 0
	self.yMoved = 0
	self.xVel = math.cos(angle)*moveCf
	self.yVel = -math.sin(angle)*moveCf
end

return camera