local class = require('middleclass')
local game = require('game')
local task = require('task')

entity = class('entity')

function entity:initialize(imgPath, x, y, name)
	name = name or "unknown entity"
	self.sprite = love.graphics.newImage(imgPath)
	self.x = x
	self.y = y
	self.xOffset = 0
	self.yOffset = 0
	self.steps = 0
	self.route = {}
	self.tasks = {}
	self.name = name
end

function entity:draw()
	
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

		--drawRouteLine({x=self.route[i-1]:getWorldCenterX(), y=self.route[i-1]:getWorldCenterY()},
					--{x=self.route[i]:getWorldCenterX(), y=self.route[i]:getWorldCenterY()})		
	end
	draw(self.sprite, (self.x - 1)*TILE_SIZE + self.xOffset, (self.y - 1)*TILE_SIZE + self.yOffset)
end

function entity:update(dt)
	self:handleWalking()
	self:handleTasks()
end

function entity:handleTasks()

	if #self.tasks > 0 then
		local t = self.tasks[#self.tasks]
		if not t.started then
			t:start()
		else
			if t.finished then
				table.remove(self.tasks)
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
	if(x - self:getWorldX() <= TILE_SIZE and x - self:getWorldX() >= 0) then
		if(y - self:getWorldY() <= TILE_SIZE and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function entity:getWorldX()
	return (self.x - 1)*TILE_SIZE + self.xOffset
end

function entity:getWorldY()
	return (self.y - 1)*TILE_SIZE + self.yOffset
end

function entity:getWorldCenterY()
	return (self.y - 1 + 1/2)*TILE_SIZE + self.yOffset
end

function entity:getWorldCenterX()
	return (self.x - 1 + 1/2)*TILE_SIZE + self.xOffset
end

function entity:getPos()
	return {x=self.x, y=self.y}
end

function entity:moveToTile(x, y)
	local dx = TILE_SIZE*(x - self.x)
	local dy = TILE_SIZE*(y - self.y)

	self.destX = x
	self.destY = y
	self.steps = 30
	self.walking = true

	self.xStep = dx/self.steps
	self.yStep = dy/self.steps

end

function entity:setRoute(route)
	self.route = route
end

function entity:walkRoute(map, destination)	
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
			tself.finished = true
		end
	end

	function runFunc(tself)
		if #self.route == 0 then
			tself.finished = true
		end
	end

	local t = task:new(strFunc, nil, startFunc, runFunc, nil, nil)
	self:queueTask(t)
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
		self:moveToTile(t.x, t.y)
	end
end

function entity:__tostring()
	return "Entity(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ")"
end

return entity