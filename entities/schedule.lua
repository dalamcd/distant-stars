local class = require('lib.middleclass')

local schedule = class('schedule')

--- sleep: 0, work: 1, play: 2, anything: 3
function schedule:initialize()

	self.list = {
		0, -- Midnight to 1 AM
		0, -- 1 AM to 2 AM
		0, -- 2 AM to 3 AM
		0, -- 3 AM to 4 AM
		0, -- 4 AM to 5 AM
		0, -- 5 AM to 6 AM
		0, -- 6 AM to 7 AM
		3, -- 7 AM to 8 AM
		3, -- 8 AM to 9 AM
		3, -- 9 AM to 10 AM
		3, -- 10 AM to 11 AM
		3, -- 11 AM to Noon
		3, -- Noon to 1 PM
		3, -- 1 PM to 2 PM
		3, -- 2 PM to 3 PM
		3, -- 3 PM to 4 PM
		3, -- 4 PM to 5 PM
		3, -- 5 PM to 6 PM
		3, -- 6 PM to 7 PM
		3, -- 7 PM to 8 PM
		3, -- 8 PM to 9 PM
		3, -- 9 PM to 10 PM
		0, -- 10 PM to 11 PM
		0, -- 11 PM to Midnight
	}
end

function schedule:adjustHour(hour, newSchedule)
	self.list[hour] = newSchedule
end

function schedule:getHour(hour)
	return self.list[hour]
end

return schedule