local gamestate = require('gamestate/gamestate')

function gamestate.static:getFadeState()
		
	function loadFunc(gself)
		gself.fade = 0
	end

	function drawFunc(gself)
		if gself.top then
			gself.fade = clamp(gself.fade - 0.2, 0, 0.85)
			love.graphics.setColor(0.0, 0.0, 0.0, gself.fade)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
			if gself.fade <= 0 then
				gamestate:pop()
			end
		else
			gself.fade = clamp(gself.fade + 0.2, 0, 0.85)
			love.graphics.setColor(0.0, 0.0, 0.0, gself.fade)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		end
	end

	local gs = gamestate:new("fadeinstate", loadFunc, nil, drawFunc, nil, nil, false, true)
	return gs
end