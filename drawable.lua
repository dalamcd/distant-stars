local class = require('middleclass')
local game = require('game')

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
		local quad = love.graphics.newQuad(tilesetX, tilesetY, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
		self.tileset = ts
		self.sprite = quad
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
	return false
end

return drawable