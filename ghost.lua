local class = require('lib.middleclass')
local drawable = require('drawable')

local ghost = class('ghost')

function ghost:initialize(data, label)
	self.obj = drawable:new(data.tileset, data.tilesetX, data.tilesetY, data.spriteWidth, data.spriteHeight, data.tileWidth, data.tileHeight, true)
	self.name = label
	self.data = data
	self.rotation = 0
end

function ghost:update(dt)

end

function ghost:draw(x, y, s)
	drawable.draw(self.obj, x, y, s, s)
end

function ghost:rotate(reverse)
	if reverse then
		self.rotation = (self.rotation - 1) % 4
	else
		self.rotation = (self.rotation + 1) % 4
	end

	if self.rotation == 0 then
		self.obj.sprite = self.obj.southFacingQuad
	elseif self.rotation == 1 then
		self.obj.sprite = self.obj.westFacingQuad
	elseif self.rotation == 2 then
		self.obj.sprite = self.obj.northFacingQuad
	elseif self.rotation == 3 then
		self.obj.sprite = self.obj.eastFacingQuad
	end

	self.obj.spriteWidth, self.obj.spriteHeight = self.obj.spriteHeight, self.obj.spriteWidth
	self.obj.width, self.obj.height = self.obj.height, self.obj.width
end

function ghost:convertToMapObject(label, map, x, y)
	local obj = self.data.class:new(self.data.name, label, map, x, y)
	if obj:isType('furniture') then
		obj:rotate(self.rotation)
	end
	return obj
end

return ghost