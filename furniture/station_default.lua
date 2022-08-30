local gamestate = require('gamestate.gamestate')
local gui = require('gui.gui')

local function loadFunc(sself, gstate, entity)
	local str = entity.label .. " is working on " .. sself.label

	gstate.topMargin = love.graphics.getHeight()*0.15
	gstate.leftMargin = love.graphics.getWidth()*0.15
	gstate.width = love.graphics.getWidth() - gstate.leftMargin*2
	gstate.height = love.graphics.getHeight() - gstate.topMargin*2
	gstate.headerText = str
	gstate.headerPos = gstate.leftMargin + (gstate.width - love.graphics.getFont():getWidth(str))/2 - 1
	gstate.textHeight = love.graphics.getFont():getHeight()
end

local function drawFunc(sself, gstate)
	gui:drawRect(gstate.leftMargin, gstate.topMargin, gstate.width, gstate.height)
	love.graphics.print(gstate.headerText, gstate.headerPos, gstate.topMargin + 20)
	love.graphics.print("X Velocity: " .. sself.map.velX, gstate.leftMargin + 20, gstate.topMargin + 20 + (gstate.textHeight + 5))
	love.graphics.print("Y Velocity: " .. sself.map.velY, gstate.leftMargin + 20, gstate.topMargin + 20 + (gstate.textHeight + 5)*2)
end

local function inputFunc(sself, gstate, entity, input)
	if input.mousereleased then
		if input.mousereleased.button == 1 then
			if input.mousereleased.x > gstate.leftMargin and input.mousereleased.x < gstate.leftMargin + gstate.width and
				input.mousereleased.y > gstate.topMargin and input.mousereleased.y < gstate.topMargin + gstate.height then
				return
			else
				gamestate:pop()
			end
		end
	end
end

local function updateFunc(sself, gstate, entity, dt)
	--entity.map.velX = clamp(entity.map.velX + 0.01, -3, 3)
end

local station_defaultTable = {
	loadFunc = loadFunc,
	inputFunc = inputFunc,
	drawFunc = drawFunc,
	updateFunc = updateFunc
}

return station_defaultTable