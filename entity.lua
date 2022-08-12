local class = require('lib.middleclass')
local game = require('game')
local drawable = require('drawable')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local dropTask = require('tasks.task_item_drop')
local eatTask = require('tasks.task_entity_eat')
local depositTask = require('tasks.task_furniture_deposit')
local corpse = require('items.corpse')

local entity = class('entity', drawable)

entity.static.base_tile_walk_distance = 30

entity.static._loaded_entities = {}

function entity.static:load(name, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight)
	local internalItem = self._loaded_entities[name]

	if internalItem then
		return internalItem
	else
		self._loaded_entities[name] = {
			tileset = tileset,
			tilesetX = tilesetX,
			tilesetY = tilesetY,
			spriteWidth = spriteWidth,
			spriteHeight = spriteHeight,
		}
	end
end

function entity.static:retrieve(name)
	return self._loaded_entities[name] or false
end

function entity:initialize(name, displayName, map, posX, posY)
	local i = entity:retrieve(name)
	if i then
		drawable.initialize(self, i.tileset, i.tilesetX, i.tilesetY, i.spriteWidth, i.spriteHeight, posX, posY, 1, 1)
	else
		error("attempted to initialize " .. name .. " but no entity with that name was found")
	end

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
	self.dname = displayName

	self.oneSecondTimer = 0

	self.dead = false
	self.health = 100
	self.satiation = 100
	self.comfort = 0
	self.oxygenStarvation = 0
	self.speed = 1
	self.idleTime = 0

	self.sitting = false
	self.seat = nil
end

function entity:update(dt)

	if self.dead then
		drawable.update(self, dt)
		return
	end

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
				if not ent.walking and not ent.dispersing and ent.uid ~= self.uid then
					local t = self.map:getWalkableTileInRadius(self.x, self.y, 1)
					if not t then
						-- If there is not a tile we can escape to immediately around us, expand the search radius
						for i=2, 10 do
							t = self.map:getWalkableTileInRadius(self.x, self.y, i)
							if t then break end
						end
					end

					if not t then print("entity "..self.dname.."("..self.uid..")".." is very thoroughly trapped") break end
					
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
	end

	if self:isIdle() and (self.idleTime / 60) % 10 == 0 then
			self:wanderAimlessly()
	end
	drawable.update(self, dt)

	if self.oneSecondTimer >= 60 then
		self.oneSecondTimer = 0
		self:handleNeeds()
	end

	self.oneSecondTimer = self.oneSecondTimer + 1
end

function entity:draw()
	local c = self.map.camera
	local r, g, b, a = love.graphics.getColor()
	if self.dead then
		love.graphics.setColor(1.0, 0.0, 0.0, 1.0)
	end
	drawable.draw(self, c:getRelativeX((self.x - 1)*TILE_SIZE + self.walkXOffset), c:getRelativeY((self.y - 1)*TILE_SIZE + self.walkYOffset), c.scale)
	love.graphics.setColor(r, g, b, a)

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
			drawRouteLine({x=startX, y=startY}, {x=endX, y=endY}, self.map.camera)
		end
	end

	if #self.route > 0 then
		local startX = self.route[#self.route]:getWorldCenterX()
		local startY = self.route[#self.route]:getWorldCenterY()
		local endX = (self.x - 1/2)*TILE_SIZE + self.translationXOffset + self.map.mapTranslationXOffset
		local endY = (self.y - 1/2)*TILE_SIZE + self.translationYOffset + self.map.mapTranslationYOffset
		drawRouteLine({x=startX, y=startY}, {x=endX, y=endY}, self.map.camera)
	end
end

function entity:isIdle()
	return self.idleTime > 0
end

function entity:die()
	print(self.name)
	local c = corpse:new(self:getClass(), self.name, self.map, self.x - self.map.xOffset, self.y - self.map.yOffset)
	c.name = "corpse of " .. self.dname
	self.map:addItem(c)
	if self.map:getMouseSelection() and self.map:getMouseSelection().uid == self.uid then
		self.map:setMouseSelection(c)
	end
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

	if self.satiation < 80 then
		local edible = self.map:getNearbyObject('food', self.x, self.y)
		if edible and self.idleTime > 0 and not self.walking then
			local et = eatTask:new(edible)
			self:pushTask(et)
		end
		if self.satiation < 10 then
			self:adjustHealth(-1)
			if self.satiation == 0 then
				self:adjustHealth(-5)
			end
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
		local tile = self.map:getTile(t.x, t.y)
		local furniture = self.map:getFurnitureInTile(tile)
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

function entity:breathe()
	if not self.dead then 
		local r = self.map:inRoom(self.x, self.y)
		if r then
			r:adjustAttribute("oxygen", -5, -5)
			if r:getAttribute("oxygen") < 0 then
				self.oxygenStarvation = self.oxygenStarvation - r:getAttribute("oxygen")
				if self.oxygenStarvation >= 100 then
					self:die()
				end
			elseif self.oxygenStarvation > 0 then
				self.oxygenStarvation = clamp(self.oxygenStarvation - 1, 0, math.huge)
			end
		end
	end
end

function entity:adjustHealth(amt)
	self.health = clamp(self.health + amt, 0, 100)
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
		error("pawn '".. self.dname .."' attempted to walk a distance longer than 1 tile: " .. dx .. ", " .. dy)
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

function entity:__tostring()
	return "Entity(".. self.dname .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return entity