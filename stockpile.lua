local class = require('lib.middleclass')
local game = require('game')
local utils = require('utils')
local room = require('room')

local stockpile = class('stockpile', room)

function stockpile:initialize(map, tiles, name)

	if not map then
		error("stockpike initialized with no map")
	end

	if not tiles or #tiles == 0 then
		error("stockpile initialized with no tiles")
	end

	self.uid = getUID()
	self.tiles = tiles
	self.name = name
	self.contents = {}
	self.color = {r=1.0, g=0.0, b=0.0, a=0.3}
	self.map = map

	self.edges = {}

	for _, tile in ipairs(tiles) do
		for _, item in ipairs(self.map:getItemsInTile(tile)) do
			table.insert(self.contents, item)
		end
	end

	self:detectEdgeTiles()
end

function stockpile:update(dt)

end

function stockpile:draw()
	for _, tile in ipairs(self.tiles) do
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(1.0, 0.0, 0.0, 0.3)
		rect("fill", (tile.x - 1)*TILE_SIZE, (tile.y - 1)*TILE_SIZE, TILE_SIZE, TILE_SIZE)
		if self.selected then
			love.graphics.setColor(0.0, 1.0, 0.0, 1.0)
			for _, edge in ipairs(self.edges) do
				line(edge[1]*TILE_SIZE, edge[2]*TILE_SIZE, edge[3]*TILE_SIZE, edge[4]*TILE_SIZE)
			end
		end
		love.graphics.setColor(r, g, b, a)
	end
end

function stockpile:removeFromStockpile(itemToRemove)
	for i, item in ipairs(self.contents) do
		if item.uid == itemToRemove.uid then
			table.remove(self.contents, i)
		end
	end
end

function stockpile:addToStockpile(item)
	table.insert(self.contents, item)
end

function stockpile:getType()
	return room.getType(self) .. "[[stockpile]]"
end

function stockpile:select()
	self.selected = true
end

function stockpile:deselect()
	self.selected = false
end

return stockpile