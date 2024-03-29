local gamestate = require('gamestate.gamestate')

function gamestate.static:getFadeState(max, step)
	max = max or 0.85
	step = step or 0.2
		
	local function loadFunc(gself)
		gself.fade = 0
	end

	local function drawFunc(gself)
		if gself.top then
			gself.fade = clamp(gself.fade - step, 0, max)
			love.graphics.setColor(0.0, 0.0, 0.0, gself.fade)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
			if gself.fade <= 0 then
				gamestate:pop()
			end
		else
			gself.fade = clamp(gself.fade + step, 0, max)
			love.graphics.setColor(0.0, 0.0, 0.0, gself.fade)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		end
	end

	local gs = gamestate:new("fadestate", loadFunc, nil, drawFunc, nil, nil, true, true)
	return gs
end