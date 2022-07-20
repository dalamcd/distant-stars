local class = require('middleclass')
local game = require('game')
local utils = require('utils')

drawable = class('drawable')

drawable.static._tilesets = {}

function drawable.static:addTileset(name, texture)
	self._tilesets[name] = love.graphics.newImage(texture)
end

function drawable.static:getTileset(name)
	return self._tilesets[name] or nil
end

function drawable:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, posX, posY, tileWidth, tileHeight)

	local ts = drawable:getTileset(tileset)

	if ts then
		local distanceRight = math.ceil(spriteWidth / TILE_SIZE) * TILE_SIZE
		local distanceDown = math.ceil(spriteHeight / TILE_SIZE) * TILE_SIZE
		local southFacingQuad = love.graphics.newQuad(tilesetX, tilesetY, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
		local northFacingQuad = love.graphics.newQuad(tilesetX + distanceRight, tilesetY, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
		local westFacingQuad = love.graphics.newQuad(tilesetX, tilesetY + distanceDown, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
		local eastFacingQuad = love.graphics.newQuad(tilesetX + distanceRight, tilesetY + distanceDown, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
		self.uid = getUID()
		self.tileset = ts
		self.sprite = southFacingQuad
		self.northFacingQuad = northFacingQuad
		self.southFacingQuad = southFacingQuad
		self.westFacingQuad = westFacingQuad
		self.eastFacingQuad = eastFacingQuad
		self.spriteWidth = spriteWidth
		self.spriteHeight = spriteHeight
		self.x = posX
		self.y = posY
		self.width = tileWidth
		self.height = tileHeight
		self.xOffset = (TILE_SIZE*self.width - spriteWidth)/2
		self.yOffset = TILE_SIZE*self.height - spriteHeight
		self.origXOffset = self.xOffset
		self.origYOffset = self.yOffset
		self.selected = false
	else
		error("drawable initialized, but no matching tileset named " .. tileset .. " was found")
	end
end

function drawable:draw(x, y, nx, ny, nw, nh)
	if nx and ny and nw and nh then
		local ox, oy, ow, oh = self.sprite:getViewport()
		self.sprite:setViewport(nx, ny, nw, nh)
		draw(self.tileset, self.sprite, x + self.xOffset, y + self.yOffset)
		self.sprite:setViewport(ox, oy, ow, oh)
	else
		draw(self.tileset, self.sprite, x + self.xOffset, y + self.yOffset)
	end
end

function drawable:update(dt)

end

function drawable:inBounds(worldX, worldY)
	if(worldX - self:getWorldX() <= self.spriteWidth and worldX - self:getWorldX() >= 0) then
		if(worldY - self:getWorldY() <= self.spriteHeight and worldY - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function drawable:inTile(tileX, tileY)
	if tileX - self.x < self.width and tileX - self.x >= 0 then
		if tileY - self.y < self.height and tileY - self.y >= 0 then
			return true
		end
	end
	return false
end

function drawable:getWorldX()
	return (self.x - 1)*TILE_SIZE + self.xOffset
end

function drawable:getWorldY()
	return (self.y - 1)*TILE_SIZE + self.yOffset
end

function drawable:getWorldCenterY()
	return (self.y - 1)*TILE_SIZE + self.spriteHeight/2 + self.yOffset
end

function drawable:getWorldCenterX()
	return (self.x - 1)*TILE_SIZE + self.spriteWidth/2 + self.xOffset
end

function drawable:getPos()
	return {x=self.x, y=self.y}
end

function drawable:getType()
	return "drawable"
end

function drawable:isWalkable()
	return true
end

function drawable:select()
	self.selected = true
end

function drawable:deselect()
	self.selected = false
end

function drawable:getPossibleTasks()
	return {}
end

function drawable:getPossibleJobs()
	return {}
end

return drawable