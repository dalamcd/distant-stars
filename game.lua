---@diagnostic disable: lowercase-global
local gameCamera
local gameMap
local gameContext

local mouseSelection = nil

local fonts = {}
local bg

function rect(mode, x, y, width, height, camera)
	love.graphics.rectangle(mode,
							camera:getRelativeX(x),
							camera:getRelativeY(y),
							camera.scale*width,
							camera.scale*height)
end

function line(x1, y1, x2, y2, camera)
	love.graphics.line(camera:getRelativeX(x1), camera:getRelativeY(y1),
						camera:getRelativeX(x2), camera:getRelativeY(y2))
end

function circ(mode, x, y, r, camera)
	love.graphics.circle(mode, camera:getRelativeX(x), camera:getRelativeY(y), camera.scale*r)
end

function drawRouteLine(startPoint, endPoint, camera)
	love.graphics.setLineWidth(2*camera.scale)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.line(camera:getRelativeX(startPoint.x),
					camera:getRelativeY(startPoint.y),
					camera:getRelativeX(endPoint.x),
					camera:getRelativeY(endPoint.y))

	love.graphics.reset()
end

function setGameContext(ctx)
	gameContext = ctx
end

function getGameContext()
	return gameContext
end

function addFont(font, name)
	table.insert(fonts, {font=font, name=name})
end

function getFont(name)
	for _, font in ipairs(fonts) do
		if font.name == name then
			return font.font
		end
	end
	return love.graphics.getFont()
end

function getMousePos()
	local mx = love.mouse.getX()
	local my = love.mouse.getY()
	return mx, my
end