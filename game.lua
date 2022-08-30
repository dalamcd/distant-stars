---@diagnostic disable: lowercase-global
local gameCamera
local gameMap
local gameContext

local mouseSelection = nil

local fonts = {}
local bg

function drawRouteLine(startPoint, endPoint, camera)
	love.graphics.setLineWidth(2*camera.scale)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.line(camera:getRelativeX(startPoint.x),
					camera:getRelativeY(startPoint.y),
					camera:getRelativeX(endPoint.x),
					camera:getRelativeY(endPoint.y))

	love.graphics.reset()
end