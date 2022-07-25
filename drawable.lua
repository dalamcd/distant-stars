local class = require('middleclass')
local game = require('game')
local utils = require('utils')

local drawable = class('drawable')

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
		self.translationXOffset = 0
		self.translationYOffset = 0
		self.mapTranslationXOffset = 0
		self.mapTranslationYOffset = 0
		self.selected = false
		self.moveFunc = function () return 0,0 end
	else
		error("drawable initialized, but no matching tileset named " .. tileset .. " found")
	end
end

function drawable:update(dt)
	if self.moveFuncParams and self.moveFuncParams.stepCount then
		local p = self.moveFuncParams
		if p.stepCount >= p.steps then
			self.moveFunc = function () return 0 end
			self.moveFuncParams = {}
			self.translationXOffset = 0
			self.translationYOffset = 0
			self.x = p.destX
			self.y = p.destY
		else
			p.stepCount = p.stepCount + 1
			p.distanceTraveled = p.stepCount*p.step
			if p.distanceTraveled > p.max then
				p.distanceTraveled = p.max
			end
			p.percentComplete = p.distanceTraveled/p.max
			if p.smoothstep then
				p.percentComplete = smoothstep(p.percentComplete)
			end
			local y = self:moveFunc(p.percentComplete)
			local angle = math.atan(p.dy/p.dx)
			if p.dx < 0 then
				angle = -angle
			end
			self.translationXOffset = sign(p.dx)*p.distanceTraveled*math.cos(angle) - sign(p.dx)*y*math.sin(angle)
			self.translationYOffset = p.distanceTraveled*math.sin(angle) + y*math.cos(angle)
		end
	end
end

function drawable:draw(x, y, s, nx, ny, nw, nh)
	if nx and ny and nw and nh then
		local ox, oy, ow, oh = self.sprite:getViewport()
		self.sprite:setViewport(nx, ny, nw, nh)
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.draw(self.tileset, self.sprite, x + (self.xOffset + self.translationXOffset + self.mapTranslationXOffset)*s, y + (self.yOffset + self.translationYOffset + self.mapTranslationYOffset)*s, 0, s)
		self.sprite:setViewport(ox, oy, ow, oh)
	else
		love.graphics.draw(self.tileset, self.sprite, x + (self.xOffset + self.translationXOffset + self.mapTranslationXOffset)*s, y + (self.yOffset + self.translationYOffset + self.mapTranslationYOffset)*s, 0, s)
	end
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
	return (self.x - 1)*TILE_SIZE + self.xOffset + self.translationXOffset + self.mapTranslationXOffset
end

function drawable:getWorldY()
	return (self.y - 1)*TILE_SIZE + self.yOffset + self.translationYOffset + self.mapTranslationYOffset
end

function drawable:getWorldCenterY()
	return (self.y - 1)*TILE_SIZE + self.spriteHeight/2 + self.yOffset + self.translationYOffset + self.mapTranslationYOffset
end

function drawable:getWorldCenterX()
	return (self.x - 1)*TILE_SIZE + self.spriteWidth/2 + self.xOffset + self.translationXOffset + self.mapTranslationXOffset
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

function drawable:translate(x, y, steps, moveFunc)
	local dx = x - self.x
	local dy = y - self.y
	local distanceActual = math.sqrt(dx^2 + dy^2)
	local max = distanceActual*TILE_SIZE
	local step = max / steps

	self.moveFuncParams = {}
	self.moveFuncParams.dx = dx
	self.moveFuncParams.dy = dy
	self.moveFuncParams.tileDistance = distanceActual
	self.moveFuncParams.startX = self.x
	self.moveFuncParams.destX = x
	self.moveFuncParams.destY = y
	self.moveFuncParams.step = step
	self.moveFuncParams.steps = steps
	self.moveFuncParams.stepCount = 0
	self.moveFuncParams.max = max
	self.moveFuncParams.percentComplete = 0
	self.moveFuncParams.x = 0
	self.moveFuncParams.y = 0

	self.moveFunc = moveFunc
end

return drawable