local entity = require('entities.entity')
return {
	{
		name = "pawn",
		class = entity,
		tileset = "entity",
		tilesetX = 0,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE
	},
	{
		name = "cow",
		class = entity,
		tileset = "entity",
		tilesetX = TILE_SIZE*4,
		tilesetY = 0,
		spriteWidth = TILE_SIZE*2,
		spriteHeight = TILE_SIZE+10
	},
	{
		name = "tallpawn",
		class = entity,
		tileset = "entity",
		tilesetX = TILE_SIZE*2,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE+9,
	},
}