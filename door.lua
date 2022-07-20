local class = require('middleclass')
local furniture = require('furniture')

door = class("door", furniture)

door.static.base_open_speed = 50

function door:initialize(tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, posX, posY, tileWidth, tileHeight)
	tileWidth = tileWidth or 1
	tileHeight = tileHeight or 1
	furniture.initialize(self, tileset, tilesetX, tilesetY, spriteWidth, spriteHeight, name, posX, posY, tileWidth, tileHeight)
	self.open = false
	self.opening = false
	self.closing = false
	self.reclose = false
	self.recloseBlocked = false
	self.openAmount = 0
	self.openStep = 0
	self.openSpeed = 1
	self.stopAmount = self.spriteWidth*0.85
	self.holdOpen = false
end

function door:openDoor(reclose)

	if reclose == nil then
		reclose = false
	end

	if self.opening then
		return
	else
		self.opening = true
		self.closing = false
		self.reclose = reclose
		self.closeBlocked = false
		self.openStep = (self.spriteWidth / door.base_open_speed) * self.openSpeed
	end
end

function door:closeDoor(force)

	if self.holdOpen and not force then
		return
	end

	local objects = getGameMap():getObjectsInTile(getGameMap():getTile(self.x, self.y))
	
	if #objects > 1 then
		self.closeBlocked = true
		return
	end

	if self.closing then
		return
	else
		self.closing = true
		self.open = false
		self.openStep = (self.spriteWidth / door.base_open_speed) * self.openSpeed
	end
end

function door:draw()
	local x, y, w, h = self.sprite:getViewport()

	x = x + self.openAmount
	w = w - self.openAmount

	drawable.draw(self, (self.x - 1)*TILE_SIZE, (self.y - 1)*TILE_SIZE, x, y, w, h)
end

function door:update(dt)

	if self.closeBlocked then
		self.closeBlocked = false
		self:closeDoor()
	end

	furniture.update(self, dt)
	if self.opening or self.closing then
		self:handleState()
	end
end

function door:handleState()
	if self.opening then
		self.openAmount = self.openAmount + self.openStep
	elseif self.closing then
		self.openAmount = self.openAmount - self.openStep
	end

	if self.openAmount >= self.stopAmount or self.openAmount <= 0 then
		if self.opening then
			self.opening = false
			self.open = true
			self.openAmount = self.stopAmount
			if self.reclose then
				self.closeBlocked = true
			end
		else
			self.closing = false
			self.open = false
			self.openAmount = 0
		end
	end
end

function door:isOpen()
	return self.open
end

function door:isOpening()
	return self.opening
end

function door:isClosing()
	return self.closing
end

function door:isWalkable()
	return true
end

function door:isWall()
	return true
end

function door:getType()
	return "door"
end

function door:__tostring()
	if self.open then
		return "Door(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ") (open)"
	else
		return "Door(" .. self.name .. ", " .. self.x .. ", " .. self.y .. ") (closed)"
	end
end

return door