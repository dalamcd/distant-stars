local class = require('middleclass')

task = class('task')

--[[
	params for a task should look like:
		params = {
			startFunc = {param1, param2, ...},
			runFunc = {param1, param2, ...},
			endFunc = {param1, param2, ...},
			strFunc = {param1, param2, ...},
			initFunc = {param1, param2, ...}
		}
]]

function task:initialize(strFunc, initFunc, startFunc, runFunc, endFunc, params)
		
		strFunc = strFunc or function () return "" end
		startFunc = startFunc or function () self:runFunc() end
		runFunc = runFunc or function () return end
		endFunc = endFunc or function () return end
		initFunc = initFunc or function () return end
		params = params or {}

		self.desc = desc
		self.params = params
		self.runFunc = runFunc
		self.startFunc = startFunc
		self.endFunc = endFunc
		self.initFunc = initFunc
		self.strFunc = strFunc
		self.started = false
		self.finished = false
		self:initFunc(unpack(params.initFunc or {}))
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

function task:getDesc()
	return self:strFunc(unpack(self.params.strFunc or {}))
end

function task:__tostring()
	return self.desc
end

return task