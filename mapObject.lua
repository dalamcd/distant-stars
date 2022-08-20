local class = require('lib.middleclass')
local utils = require('utils')
local drawable = require('drawable')

local mapObject = class('mapObject', drawable)

function mapObject:initialize(mobj, label, map, posX, posY, width, height, invertDimensions)

	drawable.initialize(self, mobj.tileset, mobj.tilesetX, mobj.tilesetY, mobj.spriteWidth, mobj.spriteHeight, width, height, invertDimensions)

	self.map = map
	self.label = label

	self.x = posX
	self.y = posY
	self.mapTranslationXOffset = 0
	self.mapTranslationYOffset = 0
	self.selected = false
	self.reserved = false
	self.reservedFor = nil
	self.scale = 1
end

function mapObject:update(dt)
	if self.map.camera then
		self.scale = self.map.camera.scale
	else
		self.scale = 1
	end
	drawable.update(self, dt)
end

function mapObject:draw(x, y, s, r, nx, ny, nw, nh)
	drawable.draw(self, x, y, s, r, nx, ny, nw, nh)
end

function mapObject:inBounds(worldX, worldY)
	local x = worldX - self.map.camera:getRelativeX(self:getWorldX())
	local y = worldY - self.map.camera:getRelativeY(self:getWorldY())
	if(x <= self.spriteWidth*self.map.camera.scale and x >= 0) then
		if(y <= self.spriteHeight*self.map.camera.scale and y >= 0) then
			return true
		end
	end
	return false
end

function mapObject:inTile(tileX, tileY)
	if tileX - self.x < self.width and tileX - self.x >= 0 then
		if tileY - self.y < self.height and tileY - self.y >= 0 then
			return true
		end
	end
	return false
end

function mapObject:getWorldX()
	return drawable.getWorldX(self) + (self.x - 1)*TILE_SIZE + self.mapTranslationXOffset
end

function mapObject:getWorldY()
	return drawable.getWorldY(self) + (self.y - 1)*TILE_SIZE + self.mapTranslationYOffset
end

function mapObject:getWorldCenterY()
	return drawable.getWorldCenterX(self) + (self.y - 1)*TILE_SIZE + self.mapTranslationYOffset
end

function mapObject:getWorldCenterX()
	return drawable.getWorldCenterY(self) + (self.x - 1)*TILE_SIZE + self.mapTranslationXOffset
end

function mapObject:isWalkable()
	return true
end

function mapObject:unreserve(obj)
	if self.reservedFor and obj.uid == self.reservedFor.uid then
		self.reserved = false
		self.reservedFor = nil
		return true
	end
	if self.reservedFor then
		print("ERR: attempted to unreserve "..self.label.." for "..obj.label.." but was reserved for "..self.reservedFor.label)
	end
	return false
end

function mapObject:reserveFor(obj)
	self.reserved = true
	self.reservedFor = obj
	return true
end

function mapObject:isReserved()
	if self.reservedFor and self.reservedFor.dead then
		self:unreserve(self.reservedFor)
	end

	return self.reserved
end

function mapObject:select()
	self.selected = true
end

function mapObject:deselect()
	self.selected = false
end

function mapObject:getPossibleTasks()
	return {}
end

function mapObject:getPossibleJobs()
	return {}
end

function mapObject:getPos()
	return {x=self.x, y=self.y}
end

function mapObject:getType()
	return "[[mapObject]]"
end

return mapObject