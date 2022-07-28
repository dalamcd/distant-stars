local gamestate = require('gamestate/gamestate')
local gui = require("gui")

function gamestate.static:getInventoryState(source, destination)

	local function loadFunc(gself)

		if not source then
			error("inventory state loaded with no source")
		end

		local str = "Viewing the contents of " .. source.name

		if destination then
			str = destination.name .. " is viewing the contents of " .. source.name
		end

		gself.topMargin = love.graphics.getHeight()*0.15
		gself.leftMargin = love.graphics.getWidth()*0.15
		gself.width = love.graphics.getWidth() - gself.leftMargin*2
		gself.height = love.graphics.getHeight() - gself.topMargin*2
		gself.headerText = str
		gself.headerPos = gself.leftMargin + (gself.width - love.graphics.getFont():getWidth(str))/2 - 1
		gself.textHeight = love.graphics.getFont():getHeight()
		gself.items = source:getInventory()
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
		for i, item in ipairs(gself.items) do
			love.graphics.print(item.name, gself.leftMargin + 20, gself.topMargin + 20 + (gself.textHeight + 5)*i)
		end
	end

	local gs = gamestate:new("inventory for " .. source.name, loadFunc, nil, drawFunc, nil, inputFunc, false, true)
	return gs
end