local class = require('lib.middleclass')
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

function drawable:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, tileWidth, tileHeight, invertDimensions)

	local ts = drawable:getTileset(tileset)

	if ts then
		local distanceRight = math.ceil(spriteWidth / TILE_SIZE) * TILE_SIZE
		local distanceDown = math.ceil(spriteHeight / TILE_SIZE) * TILE_SIZE
		local southFacingQuad
		local northFacingQuad
		local westFacingQuad
		local eastFacingQuad
		if invertDimensions then
			southFacingQuad = love.graphics.newQuad(tilesetX, tilesetY, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
			northFacingQuad = love.graphics.newQuad(tilesetX + distanceRight, tilesetY, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
			westFacingQuad = love.graphics.newQuad(tilesetX, tilesetY + distanceDown, spriteHeight, spriteWidth, ts:getWidth(), ts:getHeight())
			eastFacingQuad = love.graphics.newQuad(tilesetX + distanceDown, tilesetY + distanceDown, spriteHeight, spriteWidth, ts:getWidth(), ts:getHeight())
		else
			southFacingQuad = love.graphics.newQuad(tilesetX, tilesetY, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
			northFacingQuad = love.graphics.newQuad(tilesetX + distanceRight, tilesetY, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
			westFacingQuad = love.graphics.newQuad(tilesetX, tilesetY + distanceDown, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
			eastFacingQuad = love.graphics.newQuad(tilesetX + distanceRight, tilesetY + distanceDown, spriteWidth, spriteHeight, ts:getWidth(), ts:getHeight())
		end
		
		self.uid = getUID()
		self.tileset = ts
		self.sprite = southFacingQuad
		self.northFacingQuad = northFacingQuad
		self.southFacingQuad = southFacingQuad
		self.westFacingQuad = westFacingQuad
		self.eastFacingQuad = eastFacingQuad
		self.spriteWidth = spriteWidth
		self.spriteHeight = spriteHeight
		self.width = tileWidth
		self.height = tileHeight
		self.xOffset = TILE_SIZE*self.width - spriteWidth
		self.yOffset = TILE_SIZE*self.height - spriteHeight
		self.origXOffset = self.xOffset
		self.origYOffset = self.yOffset
		self.translationXOffset = 0
		self.translationYOffset = 0
		self.moveFunc = function () return 0,0 end
	else
		error("drawable initialized, but no matching tileset named " .. tileset .. " found")
	end
end

function drawable:update(dt)
	if self.moveFuncParams and self.moveFuncParams.stepCount then
		local p = self.moveFuncParams
		if p.stepCount >= p.steps then
			self.moveFunc = function (_, _) return 0 end -- dummy parameters to quiet an erroneous Intellisense warning
			self.moveFuncParams = nil
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
			local x = 1
			local angle = math.atan(p.dy/p.dx)
			if p.dx < 0 then
				angle = -angle
			end
			self.translationXOffset = sign(p.dx)*x*p.distanceTraveled*math.cos(angle) - sign(p.dx)*y*math.sin(angle)
			self.translationYOffset = p.distanceTraveled*x*math.sin(angle) + y*math.cos(angle)
		end
	end
end

function drawable:draw(x, y, s, r, nx, ny, nw, nh)
	r = r or 0
	if nx and ny and nw and nh then
		local ox, oy, ow, oh = self.sprite:getViewport()
		self.sprite:setViewport(nx, ny, nw, nh, self.tileset:getWidth(), self.tileset:getHeight())
		--love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.draw(self.tileset, self.sprite, math.floor(x), math.floor(y), r, s)
		self.sprite:setViewport(ox, oy, ow, oh, self.tileset:getWidth(), self.tileset:getHeight())
	else
		if r == 0 then
			love.graphics.draw(self.tileset, self.sprite, math.floor(x), math.floor(y), r, s)
		elseif r == math.pi/2 then
			local ox = self.spriteWidth
			love.graphics.draw(self.tileset, self.sprite, math.floor(x), math.floor(y), r, s, s, 0, ox)
		end
	end
end

function drawable:drawSubText(text, x, y, s)
	local fh = love.graphics.getFont():getHeight()
	local fw = love.graphics.getFont():getWidth(text)
	-- Adjust x to the middle of the tile
	x = x + (TILE_SIZE - fw)*s/2
	-- Adjust y to the bottom of the tile
	y = y + (TILE_SIZE - fh)*s
	love.graphics.print(text, x, y, 0, s)
end

function drawable:recalculateOffsets()
	self.xOffset = TILE_SIZE*self.width - self.spriteWidth
	self.yOffset = TILE_SIZE*self.height - self.spriteHeight
end

function drawable:getWorldX()
	return self.xOffset + self.translationXOffset
end

function drawable:getWorldY()
	return self.yOffset + self.translationYOffset
end

function drawable:getWorldCenterY()
	return self.spriteHeight/2 + self.yOffset + self.translationYOffset
end

function drawable:getWorldCenterX()
	return self.spriteWidth/2 + self.xOffset + self.translationXOffset
end

function drawable:getType()
	return "[[drawable]]"
end

function drawable:getClass()
	error("a subclass of drawable has not implemented getClass()")
end

function drawable:isType(str)
	local found = string.find(self:getType(), "[["..str.."]]", nil, true) 
	if found then
		return true
	else
		return false
	end
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