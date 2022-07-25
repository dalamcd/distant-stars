local class = require('middleclass')
local game = require('game')
local utils = require('utils')

stockpile = class('stockpile')

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

function stockpile:detectEdgeTiles()

	for _, tile in ipairs(self.tiles) do
		local right = self.map:getTile(tile.x + 1, tile.y) 
		local bottom = self.map:getTile(tile.x, tile.y + 1) 
		local left = self.map:getTile(tile.x - 1, tile.y) 
		local top = self.map:getTile(tile.x, tile.y - 1)

		if right and not self:inTile(right.x, right.y) then
			table.insert(self.edges, {tile.x, tile.y-1, tile.x, tile.y})
		end
		if bottom and not self:inTile(bottom.x, bottom.y) then
			table.insert(self.edges, {tile.x-1, tile.y, tile.x, tile.y})
		end
		if left and not self:inTile(left.x, left.y) then
			table.insert(self.edges, {tile.x-1, tile.y-1, tile.x-1, tile.y})
		end
		if top and not self:inTile(top.x, top.y) then
			table.insert(self.edges, {tile.x-1, tile.y-1, tile.x, tile.y-1})
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
	table.insert(self.contents, item)
end

function stockpile:inStockpile(item)
	for _, i in ipairs(self.contents) do
		if i.uid == item.uid then
			return true
		end
	end 
end

function stockpile:inBounds(worldX, worldY)
	for _, tile in ipairs(self.tiles) do
		if tile:inBounds(worldX, worldY) then
			return true
		end
	end
	return false
end

function stockpile:inTile(x, y)
	for _, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return true
		end
	end
	return false
end

function stockpile:getType()
	return "stockpile"
end

function stockpile:select()
	self.selected = true
end

function stockpile:deselect()
	self.selected = false
end

return stockpile