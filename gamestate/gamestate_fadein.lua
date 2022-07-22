local gamestate = require('gamestate/gamestate')

function gamestate.static:getFadeinState()
		
	function loadFunc(gself)
		gself.fade = 0
	end

	function drawFunc(gself)
		gself.fade = clamp(gself.fade + 0.2, 0, 0.85)
		love.graphics.setColor(0.0, 0.0, 0.0, gself.fade)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	end

	local gs = gamestate:new("fadeinstate", loadFunc, nil, drawFunc, false, true)
	return gs
end