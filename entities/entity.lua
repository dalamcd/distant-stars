local class = require('lib.middleclass')
local game = require('game')
local drawable = require('drawable')
local mapObject = require('mapObject')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local dropTask = require('tasks.task_item_drop')
local eatTask = require('tasks.task_entity_eat')
local depositTask = require('tasks.task_furniture_deposit')
local vacTask = require('tasks.task_entity_vacuum')
local corpse = require('items.corpse')
local priorities = require('entities.priorities')
local schedule = require('entities.schedule')
local gui = require('gui.gui')
local event = require('event')

local entity = class('entity', mapObject)

entity.static.base_tile_walk_distance = 30

entity.static._loaded_entities = {}

function entity.static:load(obj)
	local internalItem = self._loaded_entities[obj.name]

	if internalItem then
		return internalItem
	else
		self._loaded_entities[obj.name] = obj
	end
end

function entity.static:retrieve(name)
	return self._loaded_entities[name] or false
end

function entity.static:retrieveAll()
	return self._loaded_entities
end

function entity:initialize(name, label, map, posX, posY)
	local obj = entity:retrieve(name)
	if label == "" then label = name end
	if obj then
		mapObject.initialize(self, obj, name, label, map, posX, posY, 1, 1, false)
	else
		error("attempted to initialize " .. name .. " but no item with that name was found")
	end

	event:addListener("fart",
		function(evt)
			if evt.payload.uid ~= self.uid then
				print(evt.payload.label .. " farted and " .. self.label .. " noticed immediately")
			end
		end
	)

	self.map = map
	self.steps = 0
	self.route = {}
	self.destination = nil
	self.tasks = {}
	self.jobs = {}
	self.inventory = {}
	self.priorities = priorities:new()
	self.schedule = schedule:new()

	self.oneSecondTimer = 0
	self.rotation = 0

	self.dead = false
	self.health = obj.health or 100
	self.satiation = obj.satiation or 100
	self.comfort = obj.comfort or 0
	self.oxygenStarvation = obj.oxygenStarvation or 0
	self.speed = obj.speed or 1
	self.idleTime = 0
	self.inVacuum = false

	self.sitting = false
	self.seat = nil
end

function entity:update(dt)

	if self.dead then
		mapObject.update(self, dt)
		return
	end

	if self.map:isVoid(self.x, self.y) and not self.inVacuum then
		self.inVacuum = true
		local vt = vacTask:new()
		self:setTask(vt)
	end

	self:handleWalking()
	self:handleTasks()

	if self:isIdle() and not self.walking and #self.tasks == 0 then
		local entities = self.map:getEntitiesInTile(self.map:getTile(self.x, self.y))

		-- Handle multiple entities residing in (i.e, not just passing through) the same tile by dispersing them
		if #entities > 1 then
			for _, ent in ipairs(entities) do
				if not ent.walking and not ent.dispersing and ent.uid ~= self.uid then
					local t = self.map:getWalkableTileInRadius(self.x, self.y, 1)
					if not t then
						-- If there is not a tile we can escape to immediately around us, expand the search radius
						for i=2, 10 do
							t = self.map:getWalkableTileInRadius(self.x, self.y, i)
							if t then break end
						end
					end

					if not t then print("entity "..self.label.."("..self.uid..")".." is very thoroughly trapped") break end
					
					local function strFunc(tself)
						return "Moving away from occupied tile"
					end

					local function endFunc(tself)
						self.dispersing = false
					end

					local wt = walkTask:new(t)
					wt.strFunc = strFunc
					wt.endFunc = endFunc
					self:setTask(wt)
					self.dispersing = true
					break
				end
			end
		end
		if #self.jobs > 0 then
			self:getNextJob()
		end
	end

	if self:isIdle() and (self.idleTime / 60) % 10 == 0 then
			self:wanderAimlessly()
	end
	mapObject.update(self, dt)

	if self.oneSecondTimer >= 60 then
		self.oneSecondTimer = 0
		self:handleNeeds()
	end

	self.oneSecondTimer = self.oneSecondTimer + 1
end

function entity:draw()
	local c = self.map.camera
	local x = self:getWorldX()
	local y = self:getWorldY()
	mapObject.draw(self, c:getRelativeX(x), c:getRelativeY(y), c.scale, self.rotation)

	if #self.inventory > 0 then
		for _, item in ipairs(self.inventory) do
			item:draw(self)
		end
	end
	if self.selected then
		self:drawRoute()
	end
end

function entity:fart()
	local evt = event:new(self)
	event:dispatchEvent("fart", evt)
end

function entity:drawRoute()
	local c = self.map.camera
	if #self.route > 1 then
		for i=1, #self.route - 1 do
			local startX = c:getRelativeX(self.route[i]:getWorldCenterX())
			local startY = c:getRelativeY(self.route[i]:getWorldCenterY())
			local endX = c:getRelativeX(self.route[i+1]:getWorldCenterX())
			local endY = c:getRelativeY(self.route[i+1]:getWorldCenterY())
			gui:drawLine(startX, startY, endX, endY, {1, 1, 1, 0.3}, 3)
		end
	end

	if #self.route > 0 then
		local startX = c:getRelativeX(self.route[#self.route]:getWorldCenterX())
		local startY = c:getRelativeY(self.route[#self.route]:getWorldCenterY())
		local endX = c:getRelativeX((self.x - 1/2)*TILE_SIZE + self.translationXOffset + self.map.mapTranslationXOffset)
		local endY = c:getRelativeY((self.y - 1/2)*TILE_SIZE + self.translationYOffset + self.map.mapTranslationYOffset)
		gui:drawLine(startX, startY, endX, endY, {1, 1, 1, 0.3}, 3)
	end
end

function entity:adjustOffset(x, y)
	self.x = self.x + x
	self.y = self.y + y
	if self.moveFuncParams then
		self.moveFuncParams.destX = self.moveFuncParams.destX + x
		self.moveFuncParams.destY = self.moveFuncParams.destY + y
	end
end
function entity:isIdle()
	return self.idleTime > 0
end

function entity:die(cause)
	local c = corpse:new(entity, self.name, "corpse of " .. self.label, self.map, self.x - self.map.xOffset, self.y - self.map.yOffset)
	local t = self.tasks[#self.tasks]
	if cause then print(string.format("entity %s died from cause: %s", self.label, cause)) end
	if t then
		t:abandon()
	end

	self.dead = true
	self.map:addItem(c)
	self.map:removeEntity(self)
end

function entity:wanderAimlessly()
	local tile = self.map:getRandomWalkableTileInRadius(self.x, self.y, 2)
	if self.map:isOccupied(tile.x, tile.y) then return end
	local wt = walkTask:new(tile)

	local function strFunc(tself)
		return "Wandering aimlessly"
	end

	wt.strFunc = strFunc
	wt.keepIdle = true

	self:setTask(wt)
end

function entity:setJobList(jlist)
	self.jobs = jlist
end

function entity:getNextJob()
	if #self.jobs > 0 then
		self:setTask(self.jobs[#self.jobs])
		self.map:removeJobFromJobList(self.jobs[#self.jobs])
		table.remove(self.jobs, #self.jobs)
	end
end

function entity:printTasks()
	for _, t in ipairs(self.tasks) do
		print(t.uid.. ": " ..t:strFunc())
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

function entity:handleNeeds()
	self.satiation = clamp(self.satiation - 1, 0, 100)
	self.comfort = clamp(self.comfort - 0.1, -100, 100)

	self:breathe()

	if self.idleTime > 0 and self.satiation < 80 then
		local edible = self.map:getNearbyUnreservedObject('food', self.x, self.y)
		if edible and self.idleTime > 0 and not self.walking then
			local et = eatTask:new(edible)
			self:pushTask(et)
		end
	end

	if self.satiation < 10 then
		if self.satiation == 0 then
			self:adjustHealth(-5, "starvation")
		else
			self:adjustHealth(-1, "malnutrition")
		end
	end

	if self.sitting then
		if self.comfort < self.seat.maxComfort then
			self.comfort = clamp(self.comfort + self.seat.comfortFactor, -100, self.seat.maxComfort)
		end
	end
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
		local furniture = self.map:getFurnitureInTile(t)
		local blocked = false

		for _, f in ipairs(furniture) do
			if f:isType("door") then
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

function entity:wiggle(angle, speed)
	angle = angle or math.pi/4
	speed = speed or 10
	if not self.wiggleRot then
		self.wiggleOrigRot = self.rotation
		self.wiggleRot = 0
		self.wiggleMax = self.rotation + angle
		self.wiggleMin = self.rotation - angle
		self.wiggleDir = 0
		self.wiggleFactor = speed/100
	end
	if self.wiggleDir == 0 then
		if self.wiggleRot < self.wiggleMax then
			self.wiggleRot = self.wiggleRot + self.wiggleFactor
		else
			self.wiggleDir = 1
		end
	elseif self.wiggleRot > self.wiggleMin then
		self.wiggleRot = self.wiggleRot - self.wiggleFactor
	else
		self.wiggleDir = 0
	end
	self.rotation = self.wiggleRot
end

function entity:breathe()
	if not self.dead then 
		local r = self.map:inRoom(self.x, self.y)
		if r then
			-- Adjust oxygen down, allowing it to go below zero
			r:adjustAttribute("base_oxygen", -5)
			if r:getAttribute("base_oxygen") < 0 then
				-- If it is below zero, increase our oxygen starvation (subtracting a negative value)
				self.oxygenStarvation = self.oxygenStarvation - r:getAttribute("base_oxygen")*r:getTileCount()
				if self.oxygenStarvation >= 100 then
					self:die("suffocated")
				elseif self.oxygenStarvation < 0.01 then
					self.oxygenStarvation = 0
				end
				-- Reset oxygen back to 0 because negative attributes don't make sense
				r:setAttribute('base_oxygen', 0)
			elseif self.oxygenStarvation > 0 then
				self.oxygenStarvation = clamp(self.oxygenStarvation - 10, 0, math.huge)
			end
		end
	end
end

function entity:adjustHealth(amt, cause)
	self.health = clamp(self.health + amt, 0, 100)
	if self.health == 0 then
		if cause then
			self:die(cause)
		else
			self:die("lost " .. amt .. " health and died without cause")
		end
	end
end

function entity:adjustSatiation(amt)
	self.satiation = clamp(self.satiation + amt, 0, 100)
end

function entity:getTasks()
	return self.tasks
end

function entity:pushTask(task)
	task.entity = self
	table.insert(self.tasks, task)
end

function entity:queueTask(task)
	task.entity = self
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
			local dt = dropTask:new(item, tile)
			table.insert(tasks, dt)
		end
	end

	for _, furn in ipairs(self.map:getFurnitureInTile(tile)) do
		for _, item in ipairs(self.inventory) do
			if furn:hasAvailableInventorySpace(item) then
				local dt = depositTask:new(item, furn)
				table.insert(tasks, dt)
			end
		end
	end

	return tasks
end

function entity:setDestination(tile)
	self.destination = tile
end

function entity:walkToAdjacentTile(x, y, speed)

	local dx = x - self.x
	local dy = y - self.y

	if math.abs(dx) > 1 or math.abs(dy) > 1 then
		print("ERR: pawn '".. self.label .."' attempted to walk a distance longer than 1 tile: " .. dx .. ", " .. dy)
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

	local function moveFunc(eself, x)
		return 0
	end

	self.walking = true
	local steps = entity.base_tile_walk_distance / speed
	self:translate(x, y, steps, moveFunc)
end

function entity:sitOn(furniture)
	if furniture:beOccupiedBy(self) then
		self.seat = furniture
		self.sitting = true
		return true
	end
	return false
end

function entity:getUp(furniture)
	if self.seat and self.seat.uid == furniture.uid then
		furniture:beUnnocupiedBy(self)
		self.seat = nil
		self.sitting = false
	end
end

function entity:setRoute(route)
	self.route = route
	self:handleWalking()
end

function entity:getType()
	return drawable.getType(self) .. "[[entity]]"
end

function entity:getClass()
	return entity
end

function entity:getClassName()
	return 'entity'
end

function entity:getClassPath()
	return 'entities.entity'
end

function entity:__tostring()
	return "Entity(".. self.label .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return entity