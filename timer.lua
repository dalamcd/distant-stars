local class = require('lib.middleclass')

local timer = class('timer')

function timer:initialize(duration)
	self.duration = duration
	self.ticks = 0
	local function timerFunc()
		for i = 1, duration, 1 do
			coroutine.yield(i)
		end
	end
	self.func = coroutine.create(timerFunc)
end

function timer:tick()
	local err, count = coroutine.resume(self.func)
	if not err then error(count) end
	local status = coroutine.status(self.func)
	if status == 'suspended' then
		return true, count
	elseif status == 'dead' then
		return false, count
	end
end

return timer