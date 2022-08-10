local class = require('middleclass')
local task = require('tasks.task')

local walkTask = class('walkTask', task)

local function strFunc(self)
	return "Going to tile " .. self.destination.x .. ", " .. self.destination.y
end

local function startFunc(self)
	local p = self:getParams()
	local route = self.entity.map:pathfind({x=self.entity.x, y=self.entity.y}, self.destination)
	if route then
		p.routeFound = true
		self.entity:setDestination(self.destination)
		self.entity:setRoute(route)
	else
		p.routeFound = false
		self.finished = true
	end
end

local function runFunc(self)
	if #self.entity.route == 0 then
		self:complete()
	end
end

local function abandonFunc(self)
	if self.entity.walking then
		-- Clear the route of everything but the next closest tile
		local count = #self.entity.route
		local nextRoute = self.entity.route[count]
		for i=1, count do self.entity.route[i]=nil end
		table.insert(self.entity.route, nextRoute)
	end
end

local function contextFunc(self)
	return "Walk here"
end

function walkTask:initialize(destination, parentTask)
	if not destination then error("walkTask initialized with no destination") end

	self.destination = destination
	task.initialize(self, nil, contextFunc, strFunc, nil, startFunc, runFunc, nil, abandonFunc, parentTask)
end

return walkTask