local gamestate = require('gamestate/gamestate')
local gui = require('gui')

function gamestate.static:getStationState(station, entity)
	local function loadFunc(gself)
		if not station or not entity then
			error("station state loaded with no station or no entity")
		end
		station:loadFunc(gself, entity)
	end

	local function inputFunc(gself, input)
		station:inputFunc(gself, entity, input)
	end

	local function updateFunc(gself, dt)
		station:updateFunc(gself, entity, dt)
	end

	local function drawFunc(gself)
		station:drawFunc(gself, entity)
	end

	local function exitFunc(gself)
		station:exitFunc(gself, entity)
	end

	local gs = gamestate:new("view station " .. station.name, loadFunc, updateFunc, drawFunc, exitFunc, inputFunc, true, true)
	return gs
end