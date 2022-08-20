local class = require('lib.middleclass')

local priorities = class('priorities')

-- basic: hauling, cleaning
-- maintenance: repairing ship tiles and equipment
-- duty: man a station
-- doctor: heal the wounded
-- food: cook meals, handle hydroponics(?)
-- guard: stand guard
-- 
function priorities:initialize()

	self.list = {
		build = 3,
		maintenance = 3,
		duty = 3,
		doctor = 3,
		food = 3,
		guard = 3,
	}

end

function priorities:adjustPriority(pri, newPri)
	self.list[pri] = newPri
end

function priorities:getPriority(pri)
	return self.list[pri]
end

return priorities