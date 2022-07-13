local class = require('middleclass')

task = class('task')

--[[
	params for a task should look like:
		params = {
			startFunc = {param1, param2, ...},
			runFunc = {param1, param2, ...},
			endFunc = {param1, param2, ...}
		}
]]

function task:initialize(desc, init, startFunc, runFunc, endFunc, params)
		
		startFunc = startFunc or function () self:runFunc() end
		runFunc = runFunc or function () return end
		endFunc = endFunc or function () return end
		params = params or {}

		self.desc = desc
		self.params = params
		self.runFunc = runFunc
		self.startFunc = startFunc
		self.endFunc = endFunc
		self.started = false
		self.finished = false
end

function task:start()
	self.started = true
	self:startFunc(unpack(self.params.startFunc or {}))
end

function task:run()
	self:runFunc(unpack(self.params.runFunc or {}))
end

function task:complete()
	self.finished = true
	self:endFunc(unpack(self.params.endFunc or {}))
end

function task:__tostring()
	return self.desc
end

return task