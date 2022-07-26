local gamestate = require('gamestate/gamestate')
local gui = require('gui')

function gamestate.static:getStationState(station, entity)
	local function loadFunc(gself)

		if not station or not entity then
			error("station state loaded with no station or no entity")
		end

		local str = entity.dname .. " is working on " .. station.name

		gself.topMargin = love.graphics.getHeight()*0.15
		gself.leftMargin = love.graphics.getWidth()*0.15
		gself.width = love.graphics.getWidth() - gself.leftMargin*2
		gself.height = love.graphics.getHeight() - gself.topMargin*2
		gself.headerText = str
		gself.headerPos = gself.leftMargin + (gself.width - love.graphics.getFont():getWidth(str))/2 - 1
		gself.textHeight = love.graphics.getFont():getHeight()
	end

	local function inputFunc(gself, input)
		if input.mousereleased then
			if input.mousereleased.button == 1 then
				if input.mousereleased.x > gself.leftMargin and input.mousereleased.x < gself.leftMargin + gself.width and
					input.mousereleased.y > gself.topMargin and input.mousereleased.y < gself.topMargin + gself.height then
					return
				else
					gamestate:pop()
				end
			end
		end
	end

	local function drawFunc(gself)
		drawRect(gself.leftMargin, gself.topMargin, gself.width, gself.height)
		love.graphics.print(gself.headerText, gself.headerPos, gself.topMargin + 20)
		love.graphics.print("X Velocity: " .. station.map.velX, gself.leftMargin + 20, gself.topMargin + 20 + (gself.textHeight + 5))
		love.graphics.print("Y Velocity: " .. station.map.velY, gself.leftMargin + 20, gself.topMargin + 20 + (gself.textHeight + 5)*2)
		drawButton(gself.leftMargin + 20, gself.topMargin + 20 + (gself.textHeight + 5)*3, 40, 20, "test")
	end

	local gs = gamestate:new("view station " .. station.name, loadFunc, nil, drawFunc, nil, inputFunc, false, true)
	return gs
end