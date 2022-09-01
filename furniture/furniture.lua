local class = require('lib.middleclass')
local drawable = require('drawable')
local mapObject = require('mapObject')
local gamestate = require('gamestate.gamestate')
local inventory = require('gamestate.gamestate_inventory')
local fade = require('gamestate.gamestate_fade')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local withdrawTask = require('tasks.task_furniture_withdraw')
local viewContentsTask = require('tasks.task_furniture_view_contents')
local gui              = require('gui.gui')

local furniture = class('furniture', mapObject)

furniture.static._loaded_furniture = {}

function furniture.static:load(obj)
	local internalItem = self._loaded_furniture[obj.name]

	if internalItem then
		return internalItem
	else
		self._loaded_furniture[obj.name] = obj
	end
end

function furniture.static:retrieve(name)
	return self._loaded_furniture[name] or false
end

function furniture.static:retrieveAll()
	return self._loaded_furniture
end

-- Interaction points are calculated as offsets from the furniture's base position
function furniture:initialize(name, label, map, posX, posY)
	local obj = furniture:retrieve(name)
	if obj then
		mapObject.initialize(self, obj, name, label, map, posX, posY, obj.tileWidth, obj.tileHeight, true)
	else
		error("attempted to initialize " .. name .. " but no item with that name was found")
	end

	self.map = map

	self.interactPoints = obj.interactPoints

	if not self.interactPoints then
		self.interactPoints = {
			{x = 0, y = 1},
			{x = 1, y = 0},
			{x = 0, y = -1},
			{x = -1, y = 0}
		}
	end

	self.inventory = {}
	self.interactTiles = self:getTilesFromInteractPoints(self.interactPoints)
	self.rotation = 0
	return obj
end

function furniture:draw()
	local c = self.map.camera
	local x = self:getWorldX()
	local y = self:getWorldY()
	mapObject.draw(self, c:getRelativeX(x), c:getRelativeY(y), c.scale)
	for _, tile in ipairs(self:getInteractionTiles()) do
		gui:drawCircle(c:getRelativeX(tile:getWorldCenterX()), c:getRelativeY(tile:getWorldCenterY()), 2*c.scale, {0, 0.2, 0.6, 1})
	end
end

function furniture:getTilesFromInteractPoints(points)
	local tiles = {}
	for _, point in ipairs(points) do
		local t = self.map:getTile(point.x + self.x + self.map.xOffset, point.y + self.y + self.map.yOffset)
		if t then
			table.insert(tiles, t)
		end
	end
	return tiles
end

function furniture:rotate(facing)
	self.rotation = facing
	if facing % 2 == 1 then
		self.width, self.height = self.height, self.width
		self.spriteWidth, self.spriteHeight = self.spriteHeight, self.spriteWidth
	end

	local nt = {}
	if facing == 0 then
		self.sprite = self.southFacingQuad
		for _, point in ipairs(self.interactPoints) do
			table.insert(nt, {x = point.x, y = point.y})
		end
	elseif facing == 1 then
		self.sprite = self.westFacingQuad
		for _, point in ipairs(self.interactPoints) do
			table.insert(nt, {x = -point.y, y = point.x})
		end
	elseif facing == 2 then
		self.sprite = self.northFacingQuad
		for _, point in ipairs(self.interactPoints) do
			table.insert(nt, {x = point.x, y = -point.y})
		end
	elseif facing == 3 then
		self.sprite = self.eastFacingQuad
		for _, point in ipairs(self.interactPoints) do
			table.insert(nt, {x = point.y, y = point.x})
		end
	else
		error("furniture assigned invalid rotation (expected 0 < number < 4, received " .. tostring(facing))
	end
	self.interactTiles = self:getTilesFromInteractPoints(nt)
	self:recalculateOffsets()
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
		if self.map:isWalkable(t.x, t.y) and not t:isOccupied() then
			foundTile = t
			break
		end
	end

	return foundTile
end

function furniture:getTiles()
	return self.map:getTilesInRectangle(self.x, self.y, self.width, self.height)
end

function furniture:getType()
	return drawable.getType(self) .. "[[furniture]]"
end

function furniture:isWalkable()
	return false
end

function furniture:getClassName()
	return 'furniture'
end

function furniture:getClassPath()
	return 'furniture.furniture'
end

function furniture:__tostring()
	return "Furniture(".. self.label .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return furniture