local class = require('middleclass')
local utils = require('utils')

local task = class('task')

function task:initialize(params, contextFunc, strFunc, initFunc, startFunc, runFunc, endFunc, abandonFunc, parent)
		
		strFunc = strFunc or function () return "<no description function>" end
		contextFunc = contextFunc or function () return "<no context function>" end
		startFunc = startFunc or function () self:runFunc() end
		runFunc = runFunc or function () return end
		endFunc = endFunc or function () return end
		initFunc = initFunc or function () return end
		abandonFunc = abandonFunc or function () return end
		params = params or {}

		self.uid = getUID()
		self.params = params
		self.parent = parent
		self.runFunc = runFunc
		self.startFunc = startFunc
		self.endFunc = endFunc
		self.initFunc = initFunc
		self.strFunc = strFunc
		self.contextFunc = contextFunc
		self.abandonFunc = abandonFunc
		self.started = false
		self.finished = false
		self.abandoned = false
		self:initFunc()
end

function task:start()
	self.started = true
	self:startFunc()
end

function task:run()
	self:runFunc()
end

function task:complete()
	self.finished = true
	self:endFunc()
end

function task:abandon()
	self.abandoned = true
	self:abandonFunc()
	if self.parent then
		self.parent:abandon()
	end
end

function task:getDesc()
	if self.parent then
		return self.parent:strFunc()
	else
		return self:strFunc()
	end
end

function task:getContext()
	return self:contextFunc()
end

function task:getParams()
	if self.parent then
		return self.parent:getParams()
	else
		return self.params
	end
end

function task:isChild()
	if self.parent then
		return true
	end
	
	return false
end

function task:__tostring()
	return self:getDesc()
end

return task