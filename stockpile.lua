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
	self.walls = {}

	self:detectEdgeTiles()
end

function stockpile:update(dt)
	-- We do not want to update the base class and start sharing atmo
end

function stockpile:draw()
	for _, tile in ipairs(self.tiles) do
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(1.0, 0.0, 0.0, 0.3)
		rect("fill", tile:getWorldX(), tile:getWorldY(), TILE_SIZE, TILE_SIZE, self.map.camera)
		if self.selected then
			love.graphics.setColor(0.0, 1.0, 0.0, 1.0)
			for _, edge in ipairs(self.edges) do
				line(edge[1]*TILE_SIZE, edge[2]*TILE_SIZE, edge[3]*TILE_SIZE, edge[4]*TILE_SIZE, self.map.camera)
			end
		end
		love.graphics.setColor(r, g, b, a)
	end
end

function stockpile:updateContents()
	self.contents = {}
	for _, tile in ipairs(self.tiles) do
		for _, item in ipairs(self.map:getItemsInTile(tile)) do
			print(item, #self.contents)
			if not self:inStockpile(item) then
				self:addToStockpile(item)
			end
			print(item, #self.contents)
		end
	end
end

function stockpile:inStockpile(item)
	for _, inv in ipairs(self.contents) do
		if inv.uid == item.uid then
			return true
		end
	end
end

-- TODO: Make this check if there is an already available stack to merge with
function stockpile:getAvailableTileFor(it)
	for _, tile in ipairs(self.tiles) do
		if #self.map:getItemsInTile(tile) == 0 and self.map:isWalkable(tile.x, tile.y) then
			return tile
		end
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
	print("added to sp: ", item)
	table.insert(self.contents, item)
end

function stockpile:getWorldX()
	return self:getCentermostTile():getWorldX()
end

function stockpile:getWorldY()
	return self:getCentermostTile():getWorldY()
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