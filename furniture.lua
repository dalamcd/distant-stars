local class = require('middleclass')
local drawable = require('drawable')

furniture = class('furniture', drawable)

-- Interaction points are calculated as offsets from the furniture's base position
function furniture:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, map, posX, posY, tileWidth, tileHeight, interactPoints)
	drawable.initialize(self, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, posX, posY, tileWidth, tileHeight)
	
	self.map = map

	local interactTiles = {}

	if not interactPoints then
		local points = {{x=posX+1, y=posY}, {x=posX-1, y=posY}, {x=posX, y=posY+1}, {x=posX, y=posY-1}}
		interactTiles = self.map:getTilesFromPoints(points)
	else
		for _, p in ipairs(interactPoints) do
			table.insert(interactTiles, self.map:getTile(posX + p.x, posY + p.y))
		end
	end

	for _, t in ipairs(interactTiles) do
		print(name.."["..self.uid.."]", t.x, t.y)
	end

	self.name = name
	self.inventory = {}
	self.output = {}
	self.interactTiles = interactTiles
end

function furniture:draw()
	drawable.draw(self, (self.x - 1)*TILE_SIZE, (self.y - 1)*TILE_SIZE)
	for _, tile in ipairs(self:getInteractionTiles()) do
		circ("fill", tile:getWorldCenterX(), tile:getWorldCenterY(), 2)
	end
end

function furniture:getPossibleTasks()
	local tasks = {}
	if #self:getInventory() > 0 then
		for _, item in ipairs(self:getInventory()) do
			local t = self:getRemoveFromInventoryTask(item)
			table.insert(tasks, t)
		end
	end
	return tasks
end

function furniture:getAddToInventoryTask(item, parentTask)
	function startFunc(tself)
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

	function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end

	function endFunc(tself)
		local p = tself:getParams()
		p.entity:removeFromInventory(item)
		self:addToInventory(item)
	end

	function contextFunc(tself)
		return "Put " .. item.name .. " in " .. self.name
	end

	function strFunc(tself)
		return "Putting " .. item.name .. " in " .. self.name
	end

	local depositTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
	return depositTask
end

function furniture:getRemoveFromInventoryTask(item, parentTask)
	function startFunc(tself)
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

	function runFunc(tself)
		local p = tself:getParams()
		if not p.entity.walking and p.entity.x == p.dest.x and p.entity.y == p.dest.y then
			tself:complete()
		elseif not p.routeFound then
			tself.finished = true
		end
	end

	function endFunc(tself)
		local p = tself:getParams()
		self:removeFromInventory(item)
		p.entity:addToInventory(item)
	end

	function contextFunc(tself)
		return "Take " .. item.name .. " from " .. self.name
	end

	function strFunc(tself)
		return "Taking " .. item.name .. " from " .. self.name
	end

	local retrieveTask = task:new(nil, contextFunc, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, parentTask)
	return retrieveTask
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