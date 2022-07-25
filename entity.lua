local class = require('middleclass')
local game = require('game')
local drawable = require('drawable')
local task = require('task')

entity = class('entity', drawable)

entity.static.base_tile_walk_distance = 30

function entity:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, map, posX, posY)
	drawable.initialize(self, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, posX, posY, 1, 1)
	self.map = map
	self.steps = 0
	self.route = {}
	self.walkXOffset = 0
	self.walkYOffset = 0
	self.destination = nil
	self.tasks = {}
	self.jobs = {}
	self.inventory = {}
	self.name = name
	self.speed = 1
	self.idleTime = 0
end

function entity:draw()
	local c = self.map.camera
	drawable.draw(self, c:getRelativeX((self.x - 1)*TILE_SIZE + self.walkXOffset), c:getRelativeY((self.y - 1)*TILE_SIZE + self.walkYOffset), c.scale)
--	drawable.draw(self, (self.x - 1)*TILE_SIZE + self.walkXOffset, (self.y - 1)*TILE_SIZE + self.walkYOffset)
	
	if #self.inventory > 0 then
		for _, item in ipairs(self.inventory) do
			item:draw()
		end
	end
	self:drawRoute()
end

function entity:drawRoute()
	if #self.route > 1 then
		for i=1, #self.route - 1 do
			local startX = self.route[i]:getWorldCenterX()
			local startY = self.route[i]:getWorldCenterY()
			local endX = self.route[i+1]:getWorldCenterX()
			local endY = self.route[i+1]:getWorldCenterY()
			drawRouteLine({x=startX, y=startY}, {x=endX, y=endY})
		end
	end

	if #self.route > 0 then
		local startX = self.route[#self.route]:getWorldCenterX()
		local startY = self.route[#self.route]:getWorldCenterY()
		local endX = (self.x - 1/2)*TILE_SIZE + self.translationXOffset + self.map.mapTranslationXOffset
		local endY = (self.y - 1/2)*TILE_SIZE + self.translationYOffset + self.map.mapTranslationYOffset
		drawRouteLine({x=startX, y=startY}, {x=endX, y=endY})
	end
end

function entity:update(dt)

	for _, item in ipairs(self.inventory) do
		item:setPos(self.x, self.y, self.xOffset + self.translationXOffset, self.yOffset + self.translationYOffset)
	end

	self:handleWalking()
	self:handleTasks()

	if self:isIdle() and not self.walking and #self.tasks == 0 then
		local entities = self.map:getEntitiesInTile(self.map:getTile(self.x, self.y))
		
		-- Handle multiple entities residing in (i.e, not just passing through) the same tile by dispersing them
		if #entities > 1 then
			for _, ent in ipairs(entities) do
				if not ent.walking and ent.uid ~= self.uid then
					local t = self.map:getWalkableTileInRadius(self.x, self.y, 1)
					if not t then
						-- If there is not a tile we can escape to immediately around us, expand the search radius
						for i=2, 10 do
							t = self.map:getWalkableTileInRadius(self.x, self.y, i)
							if t then break end
						end
					end
					
					if not t then print("entity "..self.name.."("..self.uid..")".."is very thoroughly trapped") break end
					local walkTask = self:getWalkTask(t)
					walkTask.params.map = self.map
					self:pushTask(walkTask)
					self.walking = true
					break
				end
			end
		end
	end

	if self:isIdle() and (self.idleTime / 60) % 10 == 0 then
			self:wanderAimlessly()
	end
	drawable.update(self, dt)
end

function entity:isIdle()
	return self.idleTime > 0
end

function entity:wanderAimlessly()
	local tile = self.map:getRandomWalkableTileInRadius(self.x, self.y, 2)
	if self.map:isOccupied(tile.x, tile.y) then return end
	local walkTask = self:getWalkTask(tile)
	walkTask.params.map = self.map

	function strFunc(tself)
		return "Wandering aimlessly"
	end

	walkTask.strFunc = strFunc
	walkTask.keepIdle = true

	self:setTask(walkTask)
end

function entity:setJobList(jlist)
	self.jobs = jlist
end

function entity:getNextJob()
	if #self.jobs > 0 then
		self:setTask(self.jobs[#self.jobs])
		self.map:removeJobFromJobList(self.jobs[#self.jobs])
	end
end

function entity:handleTasks()

	if #self.tasks > 0 then
		local t = self.tasks[#self.tasks]
		if t.keepIdle then
			self.idleTime = self.idleTime + 1
		else
			self.idleTime = 0
		end
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
	else
		self.idleTime = self.idleTime + 1
	end
end

function entity:getTasks()
	return self.tasks
end

function entity:pushTask(task)
	task.params.entity = self
	table.insert(self.tasks, task)
end

function entity:queueTask(task)
	task.params.entity = self
	table.insert(self.tasks, 1, task)
end

function entity:setTask(task)
	local count = #self.tasks
	if count > 0 then
		-- Save a copy of the current task then clear the task list
		local t = self.tasks[#self.tasks]
		for i=0, count do self.tasks[i]=nil end
		t:abandon()
		-- We add the abandoned task back to the task list so the entity can properly dispose of it
		self:pushTask(t)
		-- Then queue the task we are replacing it with
		self:queueTask(task)

	else
		self:pushTask(task)
	end
end

function entity:addToInventory(item)
	if #self.inventory > 0 then
		self:removeFromInventory(self.inventory[1])
	end
	table.insert(self.inventory, item)
	item:addedToInventory(self)
end

function entity:removeFromInventory(item)
	for i, invItem in ipairs(self.inventory) do
		if item.uid == invItem.uid then
			table.remove(self.inventory, i)
			item:removedFromInventory(self)
		end	
	end
end

function entity:getPossibleTasks(tile)
	local tasks = {}

	if self.map:isWalkable(tile.x, tile.y) then
		for _, item in ipairs(self.inventory) do
			local dropTask = item:getDropTask()
			dropTask.params.dest = tile
			table.insert(tasks, dropTask)
		end
	end

	for _, furn in ipairs(self.map:getFurnitureInTile(tile)) do
		for _, item in ipairs(self.inventory) do
			if furn:hasAvailableInventorySpace(item) then
				local depositTask = furn:getAddToInventoryTask(item)
				table.insert(tasks, depositTask)
			end
		end
	end

	return tasks
end

function entity:setDestination(tile)
	self.destination = tile
end

function entity:getWalkTask(destination, parentTask)

	function strFunc(tself)
		return "Going to tile " .. destination.x .. ", " .. destination.y
	end

	function startFunc(tself)
		local p = tself:getParams()
		local route = p.map:pathfind({x=self.x, y=self.y}, destination)
		if route then
			p.routeFound = true
			self:setDestination(destination)
			self:setRoute(route)
		else
			p.routeFound = false
			tself.finished = true
		end
	end

	function runFunc(tself)
		if #self.route == 0 then
			tself:complete()
		end
	end

	function abandonFunc(tself)
		if self.walking then
			-- Clear the route of everything but the next closest tile
			local count = #self.route
			local nextRoute = self.route[count]
			for i=1, count do self.route[i]=nil end
			table.insert(self.route, nextRoute)
		end
	end

	function contextFunc(tself)
		return "Walk here"
	end

	local t = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, nil, abandonFunc, parentTask)
	return t
end

function entity:handleWalking()
	if self.moveFuncParams and self.moveFuncParams.stepCount then
		local p = self.moveFuncParams
		if p.stepCount >= p.steps then
			self.walking = false
			self.x = p.destX
			self.y = p.destY
			table.remove(self.route)
		end
	end

	if not self.walking and #self.route > 0 then
		local t = self.route[#self.route]
		local tile = self.map:getTile(t.x, t.y)
		local furniture = self.map:getFurnitureInTile(tile)
		local blocked = false

		for _, f in ipairs(furniture) do
			if f:getType() == "door" then
				if not f:isOpen() then
					blocked = true
					if not f:isOpening() or f:isClosing() then
						f:openDoor(true)
					end
				else
					f:holdOpenFor(self.uid)
				end
			end
		end
		if not blocked then
			self:walkToAdjacentTile(t.x, t.y, self.speed)
		end
	end

end

function entity:walkToAdjacentTile(x, y, speed)
	
	local dx = x - self.x
	local dy = y - self.y
	
	if math.abs(dx) > 1 or math.abs(dy) > 1 then
		error("pawn attempted to walk a distance longer than 1 tile")
	end

	if dy < 0 then
		self.sprite = self.northFacingQuad
	elseif dy > 0 then
		self.sprite = self.southFacingQuad
	end

	if dx > 0 then
		self.sprite = self.eastFacingQuad
	elseif dx < 0 then
		self.sprite = self.westFacingQuad
	end

	function moveFunc(eself, x)
		return 0
	end

	self.walking = true
	local steps = entity.base_tile_walk_distance / speed
	self:translate(x, y, steps, moveFunc)
end

function entity:moveToTile(x, y, speed, steps)
	local dx = TILE_SIZE*(x - self.x)
	local dy = TILE_SIZE*(y - self.y)

	if dy < 0 then
		self.sprite = self.northFacingQuad
	elseif dy > 0 then
		self.sprite = self.southFacingQuad
	end

	if dx > 0 then
		self.sprite = self.eastFacingQuad
	elseif dx < 0 then
		self.sprite = self.westFacingQuad
	end

	self.previousX = self.x
	self.previousY = self.y
	self.x = x
	self.y = y
	self.steps = steps / speed
	self.walking = true
	self.walkXOffset = -dx
	self.walkYOffset = -dy

	self.xStep = dx/self.steps
	self.yStep = dy/self.steps
end

function entity:setRoute(route)
	self.route = route
	self:handleWalking()
end

function entity:getType()
	return "entity"
end

function entity:__tostring()
	return "Entity(".. self.name .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return entity