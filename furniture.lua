local class = require('middleclass')
local drawable = require('drawable')
local gamestate = require('gamestate/gamestate')
local inventory = require('gamestate/gamestate_inventory')
local fade = require('gamestate/gamestate_fade')
local task = require('task')

local furniture = class('furniture', drawable)

furniture.static._loaded_furniture = {}

function furniture.static:load(name, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, tileWidth, tileHeight, interactPoints)
	local internalItem = self._loaded_furniture[name]

	if internalItem then
		return internalItem
	else
		self._loaded_furniture[name] = {
			tileset = tileset,
			tilesetX = tilesetX,
			tilesetY = tilesetY,
			spriteWidth = spriteWidth,
			spriteHeight = spriteHeight,
			tileWidth = tileWidth,
			tileHeight = tileHeight,
			interactPoints = interactPoints
		}
	end
end

function furniture.static:retrieve(name)
	return self._loaded_furniture[name] or false
end

-- Interaction points are calculated as offsets from the furniture's base position
function furniture:initialize(name, map, posX, posY)
	local i = furniture:retrieve(name)
	if i then
		drawable.initialize(self, i.tileset, i.tilesetX, i.tilesetY, i.spriteWidth, i.spriteHeight, posX, posY, i.tileWidth, i.tileHeight)
	else
		error("attempted to initialize " .. self.name .. " but no furniture with that name was found")
	end

	self.map = map

	local interactTiles = {}

	if not i.interactPoints then
		local points = {{x=posX+1, y=posY}, {x=posX-1, y=posY}, {x=posX, y=posY+1}, {x=posX, y=posY-1}}
		interactTiles = self.map:getTilesFromPoints(points, true)
	else
		for _, p in ipairs(i.interactPoints) do
			table.insert(interactTiles, self.map:getTile(posX + p.x + map.xOffset, posY + p.y + map.yOffset))
		end
	end

	self.name = name
	self.inventory = {}
	self.output = {}
	self.interactTiles = interactTiles
end

function furniture:draw()
	local c = self.map.camera
	drawable.draw(self, c:getRelativeX((self.x - 1)*TILE_SIZE), c:getRelativeY((self.y - 1)*TILE_SIZE), c.scale)
	-- for _, tile in ipairs(self:getInteractionTiles()) do
	-- 	circ("fill", tile:getWorldCenterX(), tile:getWorldCenterY(), 2, self.map.camera)
	-- end
end

function furniture:getPossibleTasks()
	local tasks = {self:getViewContentsTask()}

	if #self:getInventory() > 0 then
		for _, item in ipairs(self:getInventory()) do
			local t = self:getRemoveFromInventoryTask(item)
			table.insert(tasks, t)
		end
	end
	return tasks
end

function furniture:getAddToInventoryTask(item, parentTask)
	local function startFunc(tself)
		local p = tself:getParams()
		local inRange = false

		for _, tile in ipairs(self:getInteractionTiles()) do
			if p.entity.x == tile.x and p.entity.y == tile.y then
				inRange = true
				break
			end
		end
	
		if not inRange then
			local tile = self:getAvailableInteractionTile()
			if tile then
				p.dest = tile
				local walkTask = p.entity:getWalkTask(tile, tself)
				p.entity:pushTask(walkTask)	
			end		
		else

			tself:complete()
		end
	end

	local function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end

	local function endFunc(tself)
		local p = tself:getParams()
		p.entity:removeFromInventory(item)
		self:addToInventory(item)
	end

	local function contextFunc(tself)
		return "Put " .. item.name .. " in " .. self.name
	end

	local function strFunc(tself)
		return "Putting " .. item.name .. " in " .. self.name
	end

	local depositTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
	return depositTask
end

function furniture:getRemoveFromInventoryTask(item, parentTask)
	local function startFunc(tself)
		local p = tself:getParams()
		local inRange = false

		for _, tile in ipairs(self:getInteractionTiles()) do
			if p.entity.x == tile.x and p.entity.y == tile.y then
				inRange = true
				break
			end
		end
	
		if not inRange then
			local tile = self:getAvailableInteractionTile()
			if tile then
				p.dest = tile
				local walkTask = p.entity:getWalkTask(tile, tself)
				p.entity:pushTask(walkTask)	
			end		
		else

			tself:complete()
		end
	end

	local function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end

	local function endFunc(tself)
		local p = tself:getParams()
		self:removeFromInventory(item)
		p.entity:addToInventory(item)
	end

	local function contextFunc(tself)
		return "Take " .. item.name .. " from " .. self.name
	end

	local function strFunc(tself)
		return "Taking " .. item.name .. " from " .. self.name
	end

	local retrieveTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
	return retrieveTask
end

function furniture:getViewContentsTask(parentTask)
	local function startFunc(tself)
		local p = tself:getParams()
		local inRange = false

		for _, tile in ipairs(self:getInteractionTiles()) do
			if p.entity.x == tile.x and p.entity.y == tile.y then
				inRange = true
				break
			end
		end
	
		if not inRange then
			local tile = self:getAvailableInteractionTile()
			if tile then
				p.dest = tile
				local walkTask = p.entity:getWalkTask(tile, tself)
				p.entity:pushTask(walkTask)	
			end		
		else
			tself:complete()
		end
	end

	local function runFunc(tself)
		local p = tself:getParams()
		if not p.routeFound then
			tself:abandon()
			tself:complete()
			return
		end
		
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			tself:complete()
		end
	end

	local function endFunc(tself)
		local p = tself:getParams()
		if not tself.abandoned then
			local fade = gamestate:getFadeState()
			local gs = gamestate:getInventoryState(self, p.entity)
			gamestate:push(fade)
			gamestate:push(gs)
		end
	end

	local function contextFunc(tself)
		return "View inventory"
	end

	local function strFunc(tself)
		return "Viewing the inventory of " .. self.name
	end

	local viewTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
	return viewTask
end

function furniture:getInventory()
	return self.inventory
end

function furniture:hasAvailableInventorySpace()
	return true
end

function furniture:addToInventory(item)
	table.insert(self.inventory, item)
	item:addedToInventory(self)
end

function furniture:removeFromInventory(item)
	for i, invItem in ipairs(self:getInventory()) do
		if invItem.uid == item.uid then
			table.remove(self.inventory, i)
			item:removedFromInventory(self)
			return true
		end
	end
	return false
end

function furniture:getInteractionTiles()
	return self.interactTiles
end

function furniture:getAvailableInteractionTile()
	local foundTile = false
	for _, t in ipairs(self:getInteractionTiles()) do
		if t:isWalkable() and not t:isOccupied() then
			foundTile = t
			break
		end
	end

	return foundTile
end

function furniture:getType()
	return "furniture"
end

function furniture:isWalkable()
	return false
end

function furniture:__tostring()
	return "Furniture(".. self.name .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return furniture