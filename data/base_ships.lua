local data = require('data')
local entity = require('entities.entity')
local station = require('furniture.station')
local comfort = require('furniture.furniture_comfort')
local generator = require('furniture.generator')
local defstation = require('furniture.station_default')
local food = require('items.food')
return {
	{
		name = "base_shuttlecraft",
		map = "shuttlecraft.txt",
		label = "Shuttlecraft",
		roof = {
			tileset = "ships",
			tilesetX = 0,
			tilesetY = 0,
			spriteWidth = TILE_SIZE*5,
			spriteHeight = TILE_SIZE*7,
		},
		width = 5,
		height = 7,
		furniture = {
			{
				name = "stool",
				label = "stool",
				class = comfort,
				x = 3,
				y = 3
			},
			{
				name = "o2gen",
				class = generator,
				label = "Oxygen Generator",
				x = 2,
				y = 6,
			},
			{
				name = "station",
				class = station,
				label = "Cockpit",
				x = 3,
				y = 2,
			}
		},
		entities = {
			{
				name = "pawn",
				class = entity,
				label = data:getBase():getRandomFullName(),
				x = 3,
				y = 4,
			}
		},
		items = {
			{
				name = "yummy chicken",
				class = food,
				label = "yummy chicken",
				x = 3,
				y = 6
			}
		}
	},
	{
		name = "base_destroyer",
		map = "destroyer.txt",
		label = "Destroyer",
		roof = {
			tileset = "ships",
			tilesetX = 0,
			tilesetY = 0,
			spriteWidth = TILE_SIZE*5,
			spriteHeight = TILE_SIZE*7,
		},
		width = 15,
		height = 16,
		furniture = {
			{
				name = "stool",
				label = "stool",
				class = comfort,
				x = 3,
				y = 3
			},
			{
				name = "o2gen",
				class = generator,
				label = "Oxygen Generator",
				x = 2,
				y = 6,
			},
			{
				name = "station",
				class = station,
				label = "Cockpit",
				x = 3,
				y = 2,
			}
		},
		entities = {
			{
				name = "pawn",
				class = entity,
				label = data:getBase():getRandomFullName(),
				x = 3,
				y = 4,
			}
		},
		items = {
			{
				name = "yummy chicken",
				class = food,
				label = "yummy chicken",
				x = 3,
				y = 6,
				amount = 35
			}
		}
	},
}