--[[ 
	A bundle is an item representing a dismantled piece of furniture ready to install
]]
local class = require('lib.middleclass')
local item = require('items.item')
local drawable = require('drawable')
local mapObject= require('mapObject')
local installTask = require('tasks.task_entity_install')

local bundle = class('bundle', item)

function bundle:initialize(data, label, map, x, y)
	item.initialize(self, "bundle", label .. " (dismantled)", map, x, y)
	self.obj = drawable:new(data.tileset, data.tilesetX, data.tilesetY, data.spriteWidth, data.spriteHeight, data.tileWidth, data.tileHeight, false)
	self.data = data
	self.origLabel = label
	local bundleFactor = 0.8
	local xs, ys = convertQuadToScale(self.obj.sprite, TILE_SIZE*bundleFactor, TILE_SIZE*bundleFactor)
	if self.obj.spriteWidth > self.obj.spriteHeight then
		self.scalar = xs
	else
		self.scalar = ys
	end
end

function bundle:draw()
	item.draw(self)
	local c = self.map.camera
	local x, y
	if self.owned then
		x = c:getRelativeX(self.owner:getWorldX() + (TILE_SIZE - self.obj.spriteWidth*self.scalar)/2)
		y = c:getRelativeY(self.owner:getWorldY() - TILE_SIZE/8)
	else
		x = c:getRelativeX(self:getWorldX() + (TILE_SIZE - self.obj.spriteWidth*self.scalar)/2 )
		y = c:getRelativeY(self:getWorldY() - TILE_SIZE/8)
	end
	mapObject.draw(self.obj, x, y, self.scalar*c.scale, -math.pi/4)
end

function bundle:convertToFurniture()
	return self.data.class:new(self.data.name, self.label, self.map, self.x - self.map.xOffset, self.y - self.map.yOffset)
end

function bundle:getPossibleTasks()
	local tasks = item.getPossibleTasks(self)
	local insTask = installTask:new(self, nil, self.map)
	table.insert(tasks, insTask)
	return tasks
end

function bundle:getType()
	return item.getType(self) .. "[[bundle]]"
end

return bundle