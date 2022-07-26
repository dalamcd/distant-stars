local class = require('middleclass')
local furniture = require('furniture')
local drawable = require('drawable')

local door = class("door", furniture)

door.static.base_open_speed = 50

function door:initialize(name, map, posX, posY)
	furniture.initialize(self, name, map, posX, posY)
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
	self.holdFor = nil
end

function door:update(dt)

	if self.closeBlocked then
		self.closeBlocked = false
		self:closeDoor()
	end

	furniture.update(self, dt)


	if self.holdFor then
		local found = false
		for _, obj in ipairs(self.map:getObjectsInTile(self.map:getTile(self.x, self.y))) do
			if obj.uid == self.holdFor then
				found = true
				self.holdFor = nil
			end
		end
	elseif self.opening or self.closing then
		self:handleState()
	end
end

function door:draw()
	local x, y, w, h = self.sprite:getViewport()
	local c = self.map.camera
	x = x + self.openAmount
	w = w - self.openAmount

	drawable.draw(self, c:getRelativeX((self.x - 1)*TILE_SIZE), c:getRelativeY((self.y - 1)*TILE_SIZE), c.scale, x, y, w, h)
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

	local objects = self.map:getObjectsInTile(self.map:getTile(self.x, self.y))
	
	if #objects > 1 then
		self.closeBlocked = true
		--self:openDoor()
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

function door:holdOpenFor(uid)
	self.holdFor = uid
end

function door:handleState()
	if self.opening then
		self.openAmount = self.openAmount + self.openStep
	elseif self.closing then
		local objects = self.map:getObjectsInTile(self.map:getTile(self.x, self.y))
	
		if #objects > 1 then
			self.closeBlocked = true
			--self:openDoor()
			return
		else
			self.openAmount = self.openAmount - self.openStep
		end
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
		return "Door(".. self.name .."["..self.uid.."], " .. self.x .. ", " .. self.y .. ") (open)"
	else
		return "Door(".. self.name .."["..self.uid.."], " .. self.x .. ", " .. self.y .. ") (closed)"
	end
end

return door