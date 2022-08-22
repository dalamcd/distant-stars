local class = require('lib.middleclass')
local utils = require('utils')
local drawable = require('drawable')
local item = require('items.item')
local entity = require('entities.entity')
local furniture = require('furniture.furniture')
local tile = require('tile')
local attribute = require('rooms.attribute')

local data = class('data')

function data.static:setBase(base)
	self.__base = base
end

function data.static:getBase()
	return self.__base
end

function data:initialize()

	drawable:addTileset("entity", "sprites/tilesheets/entities.png")
	drawable:addTileset("item", "sprites/tilesheets/items.png")
	drawable:addTileset("furniture", "sprites/tilesheets/furniture.png")
	drawable:addTileset("floorTile", "sprites/tilesheets/tiles.png")

	self:loadBaseTileData("data/base_tiles.lua")
	self:loadBaseItemData("data/base_items.lua")
	self:loadBaseEntityData("data/base_entities.lua")
	self:loadBaseFurnitureData("data/base_furniture.lua")
	self:loadBaseAttributeData("data/base_attributes.lua")
end

function data:loadBaseTileData(fname)
	local status, tileData = pcall(love.filesystem.load, fname)
	if not status then
		error(tostring(tileData))
	else
		for _, newTile in ipairs(tileData()) do
			tile:load(newTile.name, newTile.tileset, newTile.spriteX, newTile.spriteY, newTile.spriteWidth, newTile.spriteHeight)
		end
	end
end

function data:loadBaseItemData(fname)
	local status, itemData = pcall(love.filesystem.load, fname)
	if not status then
		error(tostring(itemData))
	else
		for _, newItem in ipairs(itemData()) do
			item:load(newItem.name, newItem.tileset, newItem.spriteX, newItem.spriteY, newItem.spriteWidth, newItem.spriteHeight)
		end
	end
end

function data:loadBaseEntityData(fname)
	local status, entityData = pcall(love.filesystem.load, fname)
	if not status then
		error(tostring(entityData))
	else
		for _, newEntity in ipairs(entityData()) do
			newEntity.attributes = newEntity.attributes or {}
			entity:load(newEntity.name, newEntity.tileset, newEntity.spriteX, newEntity.spriteY, newEntity.spriteWidth, newEntity.spriteHeight, newEntity.attributes)
		end
	end
end

function data:loadBaseFurnitureData(fname)
	local status, furnitureData = pcall(love.filesystem.load, fname)
	if not status then
		error(tostring(furnitureData))
	else
		for _, newFurniture in ipairs(furnitureData()) do
			furniture:load(newFurniture.name, newFurniture.tileset, newFurniture.spriteX, newFurniture.spriteY,
						newFurniture.spriteWidth, newFurniture.spriteHeight, newFurniture.tileWidth, newFurniture.tileHeight,
						newFurniture.interactTiles)
		end
	end
end

function data:loadBaseAttributeData(fname)
	local status, attributeData = pcall(love.filesystem.load, fname)
	if not status then
		error(tostring(attributeData))
	else
		for _, newAttribute in ipairs(attributeData()) do
			attribute:load(newAttribute.name, newAttribute.label, newAttribute.min, newAttribute.max)
		end
	end
end

function data:getRandomMaleName()
	if self.maleNameList then
		return self.maleNameList[math.random(#self.maleNameList)]
	else
		io.input("data/names-male.txt")
		self.maleNameList = {}
		local line = io.read("*line")
		while line ~= nil do
			if line:sub(1, 1) ~= "#" then
				table.insert(self.maleNameList, line)
			end
			line = io.read("*line")
		end
		return self.maleNameList[math.random(#self.maleNameList)]
	end
end

function data:getRandomFemaleName()
	if self.femaleNameList then
		return self.femaleNameList[math.random(#self.femaleNameList)]
	else
		io.input("data/names-female.txt")
		self.femaleNameList = {}
		local line = io.read("*line")
		while line ~= nil do
			if line:sub(1, 1) ~= "#" then
				table.insert(self.femaleNameList, line)
			end
			line = io.read("*line")
		end
		return self.femaleNameList[math.random(#self.femaleNameList)]
	end
end

function data:getRandomLastName()
	if self.lastNameList then
		return self.lastNameList[math.random(#self.lastNameList)]
	else
		io.input("data/names-last.txt")
		self.lastNameList = {}
		local line = io.read("*line")
		while line ~= nil do
			if line:sub(1, 1) ~= "#" then
				table.insert(self.lastNameList, line)
			end
			line = io.read("*line")
		end
		return self.lastNameList[math.random(#self.lastNameList)]
	end
end

function data:getRandomFullName(gender)

	if gender and gender == 'male' then
		return self:getRandomMaleName() .. " " .. self:getRandomLastName()
	elseif gender and gender == 'female' then
		return self:getRandomFemaleName() .. " " .. self:getRandomLastName()
	else
		if math.random() > 0.5 then
			return self:getRandomMaleName() .. " " .. self:getRandomLastName()
		else
			return self:getRandomFemaleName() .. " " .. self:getRandomLastName()
		end
	end
end

return data