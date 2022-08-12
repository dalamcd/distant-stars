local class = require('lib.middleclass')
local drawable = require('drawable')
local gamestate = require('gamestate.gamestate')
local inventory = require('gamestate.gamestate_inventory')
local fade = require('gamestate.gamestate_fade')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local withdrawTask = require('tasks.task_furniture_withdraw')
local viewContentsTask = require('tasks.task_furniture_view_contents')

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
		drawable.initialize(self, i.tileset, i.tilesetX, i.tilesetY, i.spriteWidth, i.spriteHeight, posX, posY, i.tileWidth, i.tileHeight, true)
	else
		error("attempted to initialize " .. self.name .. " but no furniture with that name was found")
	end

	self.map = map

	local interactTiles = {}

	if not i.interactPoints then
		local points = {{x=posX+map.xOffset+1, y=posY+map.yOffset},
						{x=posX+map.xOffset-1, y=posY+map.yOffset},
						{x=posX+map.xOffset, y=posY+map.yOffset+1},
						{x=posX+map.xOffset, y=posY+map.yOffset-1}}

		interactTiles = self.map:getTilesFromPoints(points)
	else
		for _, p in ipairs(i.interactPoints) do
			table.insert(interactTiles, self.map:getTile(posX + p.x + map.xOffset, posY + p.y + map.yOffset))
		end
	end

	self.name = name
	self.inventory = {}
	self.output = {}
	self.interactTiles = interactTiles
	self.rotation = 0
	self.originTileWidth = i.tileWidth
	self.originTileHeight = i.tileHeight
	self.originSpriteWidth = i.spriteWidth
	self.originSpriteHeight = i.spriteHeight
end

function furniture:draw()
	local c = self.map.camera
	drawable.draw(self, c:getRelativeX((self.x - 1)*TILE_SIZE), c:getRelativeY((self.y - 1)*TILE_SIZE), c.scale)
	-- for _, tile in ipairs(self:getInteractionTiles()) do
	-- 	circ("fill", tile:getWorldCenterX(), tile:getWorldCenterY(), 2, self.map.camera)
	-- end
end

function furniture:getPossibleTasks()
	local tasks = {}

	if #self:getInventory() > 0 then
		for _, item in ipairs(self:getInventory()) do
			local wt = withdrawTask:new(self, item)
			table.insert(tasks, wt)
		end
	end
	return tasks
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

function furniture:getTiles()
	return self.map:getTilesInRectangle(self.x, self.y, self.width, self.height, true)
end

function furniture:getType()
	return drawable.getType(self) .. "[[furniture]]"
end

function furniture:isWalkable()
	return false
end

function furniture:__tostring()
	return "Furniture(".. self.name .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return furniture