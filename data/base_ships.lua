local data = require('data')
local entity = require('entities.entity')
local station = require('furniture.station')
local comfort = require('furniture.furniture_comfort')
local generator = require('furniture.generator')
local defstation = require('furniture.station_default')
return {
	{
		name = "base_shuttlecraft",
		map = "shuttlecraft.txt",
		label = "Shuttlecraft",
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
				name = "station",
				label = "station",
				class = station,
				x = 3,
				y = 2,
				args = {
					defstation.loadFunc,
					defstation.updateFunc,
					defstation.drawFunc,
					nil,
					defstation.inputFunc
				}
			},
			{
				name = "o2gen",
				label = "Oxygen Generator",
				class = generator,
				x = 2,
				y = 6,
				args = {
					"base_oxygen",
					15/60
				}
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
		}
	},
}