local furniture = require('furniture.furniture')
local comfort = require('furniture.furniture_comfort')
local station = require('furniture.station')
local defstation = require('furniture.station_default')
local wall = require('furniture.wall')
local hull = require('furniture.hull')
local generator = require('furniture.generator')
local door      = require('furniture.door')

return {
	{
		name = "dresser",
		class = furniture,
		tileset = "furniture",
		tilesetX = 0,
		tilesetY = 0,
		spriteWidth = TILE_SIZE*2,
		spriteHeight = TILE_SIZE+14,
		tileWidth = 2,
		tileHeight = 1,
		interactTiles =  {
			{x=0, y=1},
			{x=1, y=1}
		},
	},
	{
		name = "station",
		class = station,
		tileset = "furniture",
		tilesetX = TILE_SIZE*7,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE+13,
		tileWidth = 1,
		tileHeight = 1,
		loadFunc = defstation.loadFunc,
		updateFunc = defstation.updateFunc,
		drawFunc = defstation.drawFunc,
		inputFunc = defstation.inputFunc,
	},
	{
		name = "bigthing",
		class = furniture,
		tileset = "furniture",
		tilesetX = TILE_SIZE*9,
		tilesetY = 0,
		spriteWidth = TILE_SIZE*2,
		spriteHeight = TILE_SIZE*4,
		tileWidth = 2,
		tileHeight = 4
	},
	{
		name = "o2gen",
		class = generator,
		tileset = "furniture",
		tilesetX = TILE_SIZE*13,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE+11,
		tileWidth = 1,
		tileHeight = 1,
		attribute = "base_oxygen",
		outputAmount = 14/60
	},
	{
		name = "door",
		class = door,
		tileset = "furniture",
		tilesetX = TILE_SIZE*5,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1
	},
	{
		name = "stool",
		class = comfort,
		tileset = "furniture",
		tilesetX = TILE_SIZE*5,
		tilesetY = TILE_SIZE*2,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1,
		interactPoints = {{x=0, y=0}},
		sittable = true,
		maxComfort = 50,
		comfortFactor = 15
	},
	{
		name = "hull",
		class = hull,
		tileset = "floorTile",
		tilesetX = TILE_SIZE*2,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1
	},
	{
		name = "hullBotLeft",
		class = hull,
		tileset = "floorTile",
		tilesetX = 0,
		tilesetY = TILE_SIZE,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1
	},
	{
		name = "hullTopRight",
		class = hull,
		tileset = "floorTile",
		tilesetX = TILE_SIZE,
		tilesetY = TILE_SIZE,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1
	},
	{
		name = "hullTopLeft",
		class = hull,
		tileset = "floorTile",
		tilesetX = 0,
		tilesetY = TILE_SIZE*2,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1
	},
	{
		name = "hullBotRight",
		class = hull,
		tileset = "floorTile",
		tilesetX = TILE_SIZE,
		tilesetY = TILE_SIZE*2,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1
	},
	{
		name = "wall",
		class = wall,
		tileset = "floorTile",
		tilesetX = TILE_SIZE,
		tilesetY = 0,
		spriteWidth = TILE_SIZE,
		spriteHeight = TILE_SIZE,
		tileWidth = 1,
		tileHeight = 1
	},
}