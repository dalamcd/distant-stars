local class = require('lib.middleclass')
local drawable = require('drawable')

local ghost = class('ghost')

function ghost:initialize(data, label)
	self.obj = drawable:new(data.tileset, data.tilesetX, data.tilesetY, data.spriteWidth, data.spriteHeight, data.tileWidth, data.tileHeight, false)
	self.name = label
	self.data = data
end

function ghost:draw(x, y, s)
	drawable.draw(self.obj, x, y, s)
end

return ghost