local gamestate = require('gamestate/gamestate')

function gamestate.static:getFadeoutState()
	
	function loadFunc(gself)
		gself.fade = 0.85
	end

	function drawFunc(gself)
		gself.fade = clamp(gself.fade - 0.2, 0, 0.85)
		love.graphics.setColor(0.0, 0.0, 0.0, gself.fade)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	end

	local gs = gamestate:new("fadeoutstate", loadFunc, nil, drawFunc, true, true)
	return gs
end