local item = require('items.item')
local food = require('items.food')
return {
	{
		name = "yummy chicken",
		class = food,
		tileset = "item",
		tilesetX = 0,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		maxStack = 50,
		nourishment = 50
	},
	{
		name = "yummy pizza",
		class = food,
		tileset = "item",
		tilesetX = TILE_SIZE,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		maxStack = 50,
		nourishment = 50
	},
}