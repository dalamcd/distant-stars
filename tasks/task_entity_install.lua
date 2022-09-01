local class = require('lib.middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local pickupTask = require('tasks.task_item_pickup')
local dropTask = require('tasks.task_item_drop')
local timer = require('timer')
local drawable = require('drawable')
local event = require('event')

local installTask = class('installTask', task)

local function startFunc(self)
	if not self.buildSite then
		local evt = event:new({bundle=self.bundle, map=self.map, entity=self.entity})
		event:dispatchEvent("base_event_buildRequested", evt)
		self:abandon()
	else
		local p = self:getParams()
		if not self.bundle.owned then
			p.pickup = pickupTask:new(self.bundle, self)
			p.drop = dropTask:new(self.bundle, self.destinationTile, self)
			self.entity:pushTask(p.drop)
			self.entity:pushTask(p.pickup)
		elseif self.entity.x ~= self.destinationTile.x or self.entity.y ~= self.destinationTile.y then
			p.drop = dropTask:new(self.bundle, self.destinationTile, self)
			self.entity:pushTask(p.drop)
		else
			self:complete()
		end
	end
end

local function runFunc(self)
	if not self.abandoned and not self.entity.walking and self.entity.x == self.destinationTile.x and self.entity.y == self.destinationTile.y then
		self:complete()
	end
end

local function endFunc(self)
	if not self.abandoned then
		self.entity.map:removeItem(self.bundle)
		self.buildSite:startWork()
	end
end

local function abandonFunc(self)
	self:complete()
end

local function strFunc(self)
	return "Installing " .. self.bundle.origLabel
end

local function contextFunc(self)
	return "Install " .. self.bundle.origLabel
end

local function initFunc(self)

end

function installTask:initialize(bundle, destinationTile, map, buildSite, parentTask)
	assert(bundle and map, "installTask initialized without one of obj or map")
	assert( not buildSite or (buildSite and destinationTile), "installTask initialized without destiniationTile")
	self.bundle = bundle
	self.destinationTile = destinationTile
	self.map = map
	self.buildSite = buildSite
	task.initialize(self, nil, contextFunc, strFunc, initFunc, startFunc, runFunc, endFunc, abandonFunc, parentTask)
end

return installTask