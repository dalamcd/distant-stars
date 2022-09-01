local class = require('lib.middleclass')

local event = class('event')

event.static._listeners = {}

function event.static:dispatchEvent(label, evt)
	if self._listeners[label] then
		for _, listener in ipairs(self._listeners[label]) do
			listener(evt)
		end
	end
end

function event.static:addListener(label, listener)
	if self._listeners[label] then
		table.insert(self._listeners[label], listener)
	else
		self._listeners[label] = {listener}
	end
end

function event:initialize(payload)
	self.payload = payload
end

return event