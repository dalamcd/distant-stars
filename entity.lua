local class = require('middleclass')
local game = require('game')
local task = require('task')

entity = class('entity')

entity.static.base_tile_walk_distance = 30

function entity:initialize(imgPath, x, y, name)
	name = name or "unknown entity"
	self.sprite = love.graphics.newImage(imgPath)
	self.x = x
	self.y = y
	self.xOffset = 0
	self.yOffset = 0
	self.imgYOffset = TILE_SIZE - self.sprite:getHeight()
	self.imgXOffset = (TILE_SIZE - self.sprite:getWidth())/2
	self.steps = 0
	self.route = {}
	self.tasks = {}
	self.inventory = {}
	self.name = name
	self.speed = 1
end

function entity:draw()
	
	self:drawRoute()
	draw(self.sprite, (self.x - 1)*TILE_SIZE + self.xOffset + self.imgXOffset, (self.y - 1)*TILE_SIZE + self.yOffset + self.imgYOffset)

	if #self.inventory > 0 then
		for _, item in ipairs(self.inventory) do
			item:draw()
		end
	end
end

function entity:drawRoute()
	if #self.route > 1 then
		for i=#self.route, 2, -1 do
			if i == #self.route then
				drawRouteLine({x=self:getWorldCenterX(), y=self:getWorldCenterY()},
							{x=self.route[i]:getWorldCenterX(), y=self.route[i]:getWorldCenterY()})
			end
			drawRouteLine({x=self.route[i-1]:getWorldCenterX(), y=self.route[i-1]:getWorldCenterY()},
						{x=self.route[i]:getWorldCenterX(), y=self.route[i]:getWorldCenterY()})
		end
	elseif #self.route == 1 then
		drawRouteLine({x=self:getWorldCenterX(), y=self:getWorldCenterY()},
					{x=self.route[1]:getWorldCenterX(), y=self.route[1]:getWorldCenterY()})

	end
end
function entity:update(dt)
	self:handleWalking()
	self:handleTasks()

	for _, item in ipairs(self.inventory) do
		item:setPos(self.x, self.y, self.xOffset, self.yOffset)
	end
end

function entity:handleTasks()

	if #self.tasks > 0 then
		local t = self.tasks[#self.tasks]
		if not t.started then
			t:start()
			-- This recursion works currently, but needs more testing
			self:handleTasks()
			return
		else
			if t.finished then
				table.remove(self.tasks)
				-- This recursion works currently, but needs more testing
				self:handleTasks()
				return
			else
				t:run()
			end
		end
	end
end

function entity:getTasks()
	return self.tasks
end

function entity:pushTask(task)
	table.insert(self.tasks, task)
end

function entity:queueTask(task)
	table.insert(self.tasks, 1, task)
end

function entity:inBounds(x, y)
	if(x - self:getWorldX() <= self.sprite:getWidth() and x - self:getWorldX() >= 0) then
		if(y - self:getWorldY() <= self.sprite:getHeight() and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function entity:getWorldX()
	return (self.x - 1)*TILE_SIZE + self.xOffset + self.imgXOffset
end

function entity:getWorldY()
	return (self.y - 1)*TILE_SIZE + self.yOffset + self.imgYOffset
end

function entity:getWorldCenterY()
	return (self.y - 1/2)*TILE_SIZE + self.yOffset + self.imgXOffset
end

function entity:getWorldCenterX()
	return (self.x - 1/2)*TILE_SIZE + self.xOffset + self.imgYOffset
end

function entity:getPos()
	return {x=self.x, y=self.y}
end

function entity:pickUp(item)
	table.insert(self.inventory, item)
end

function entity:drop(item)
	for i, invItem in ipairs(self.inventory) do
		if item == invItem then
			table.remove(self.inventory, i)
			item:beDropped(self)
		end
	end
end

function entity:getPossibleTasks(map, tile)
	local tasks = {}
	local params = {}
	params.startFunc = {}
	params.startFunc.routeFound = true

	-- DROP CARRIED ITEM
	for _, item in ipairs(self.inventory) do
		
		function runFunc(tself)
			if not self.walking and self.x == tile.x and self.y == tile.y then
				self:drop(item)
				tself:complete()
			elseif not tself.params.startFunc.routeFound then
				tself.finished = true
			end
		end
		
		function startFunc(tself)
			if self.x ~= tile.x or self.y ~= tile.y then
				self:walkRoute(map, {x=tile.x, y=tile.y}, false, params)
			else
				self:drop(item)
				tself:complete()
			end
		end

		function contextFunc(tself)
			return "Drop " .. item.name
		end

		function strFunc(tself)
			return "Dropping " .. item.name
		end

		local dropTask = task:new(contextFunc, strFunc, nil, startFunc, runFunc, nil, params)
		table.insert(tasks, dropTask)
	end
	-- END DROP CARRIED ITEM

	return tasks
end

function entity:moveToTile(x, y, speed, steps)
	local dx = TILE_SIZE*(x - self.x)
	local dy = TILE_SIZE*(y - self.y)

	self.destX = x
	self.destY = y
	self.steps = steps / speed
	self.walking = true

	self.xStep = dx/self.steps
	self.yStep = dy/self.steps

end

function entity:setRoute(route)
	self.route = route
	self:handleWalking()
end

function entity:walkRoute(map, destination, queue, params)

	queue = queue or false
	params = params or nil

	if self.x == destination.x and self.y == destination.y then
		return
	end

	function strFunc(tself)
		return "Going to tile " .. destination.x .. ", " .. destination.y
	end

	function startFunc(tself)
		local route = map:pathfind({x=self.x, y=self.y}, destination)
		if route then
			self:setRoute(route)
		else
			params.startFunc.routeFound = false
			tself.finished = true
		end
	end

	function runFunc(tself)
		if #self.route == 0 then
			tself.finished = true
		end
	end

	local t = task:new(nil, strFunc, nil, startFunc, runFunc, nil, nil)
	if queue then self:queueTask(t)
	else self:pushTask(t) end
end

function entity:handleWalking()
	if self.steps > 1 then
		self.steps = self.steps - 1
		self.xOffset = self.xOffset + self.xStep
		self.yOffset = self.yOffset + self.yStep
	elseif self.walking then
		self.walking = false
		self.steps = 0
		self.xOffset = 0
		self.yOffset = 0
		self.x = self.destX
		self.y = self.destY
		table.remove(self.route)
	end

	if not self.walking and table.getn(self.route) > 0 then
		local t = self.route[#self.route]
		self:moveToTile(t.x, t.y, self.speed, entity.base_tile_walk_distance)
	end
end

function entity:__tostring()
	return "Entity(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ")"
end

return entity