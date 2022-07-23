local gamestate = require('gamestate/gamestate')

function gamestate.static:getInventoryState()

	function loadFunc(gself)
	end

	function inputFunc(gself, input)
		if input.mousereleased then
			if input.mousereleased.button == 2 then
				print("yayyy")
			end
		end
	end

	function drawFunc(gself)
		local sideAmt = love.graphics.getWidth()*0.15
		local topAmt = love.graphics.getHeight()*0.15
		
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.rectangle("line", sideAmt, topAmt, love.graphics.getWidth() - sideAmt*2, love.graphics.getHeight() - topAmt*2)
		love.graphics.setColor(0.0, 0.0, 0.0, 1.0)
		love.graphics.rectangle("fill", sideAmt+1, topAmt+1, love.graphics.getWidth() - sideAmt*2 - 2, love.graphics.getHeight() - topAmt*2 - 2)
	end

	local gs = gamestate:new("inventory", nil, nil, drawFunc, nil, inputFunc, false, true)
	return gs
end