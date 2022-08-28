local class = require('lib.middleclass')
local gamestate = require('gamestate.gamestate')
local gbutton = require('graphicButton')
local button = require('button')
local tile = require('tile')
local drawable = require('drawable')
local furniture = require('furniture.furniture')
local item = require('items.item')
local entity = require('entities.entity')
local ghost = require('ghost')
local map = require('map.map')
local camera = require('camera')
local utils = require('utils')

local builder = class('builder', gamestate)

local function updateFunc(self, dt)
	local mx, my = getMousePos()
	d:updateTextField("topEdge", tostring(my > self.topEdge))
	self.camera:update(dt)
	if self.map then
		local t = self.map:getTileAtWorld(mx, my)
		if t then
			d:updateTextField("Tile under mouse", tostring(t))
		end
	end
end

local function drawFunc(self)
	local mx, my = getMousePos()

	if self.map then
		self.map:draw()
	end

	drawRect(0, 0, self.rightEdge, love.graphics.getHeight())
	love.graphics.print("width         " .. self.mapWidth, 400, love.graphics.getFont():getHeight())
	love.graphics.print("height         " .. self.mapHeight, 600, love.graphics.getFont():getHeight())
	self.leftWidthButton:draw()
	self.rightWidthButton:draw()
	self.leftHeightButton:draw()
	self.rightHeightButton:draw()
	self.newMapButton:draw()
	for _, btn in ipairs(self.tabButtons) do
		btn:draw()
	end
	for _, btn in ipairs(self.currentTabButtons) do
		btn:draw()
	end

	if self.ghost and mx > self.rightEdge then
		self.ghost:draw(mx, my, 1)
	end
end

local function inputFunc(self, input)
	self:keysdown()

	if input.keypressed then
		if input.keypressed.key == 'q' then
			gamestate:pop()
		end

		if input.keypressed.key == 'e' then
			self:saveMap()
		end
		if input.keypressed.key == 'r' then
			self:loadMap()
		end
	end

	if input.mousereleased then
		if input.mousereleased.button == 1 then
			local mx, my = getMousePos()
			for _, btn in ipairs(self.tabButtons) do
				if btn:inBounds(mx, my) then
					btn:click()
				end
			end
			for idx, btn in ipairs(self.currentTabButtons) do
				if btn:inBounds(mx, my) then
					btn:click(idx)
				end
			end
			if self.leftWidthButton:inBounds(mx, my) then
				self.mapWidth = clamp(self.mapWidth - 1, 1, 1000)
			end
			if self.rightWidthButton:inBounds(mx, my) then
				self.mapWidth = clamp(self.mapWidth + 1, 1, 1000)
			end
			if self.leftHeightButton:inBounds(mx, my) then
				self.mapHeight = clamp(self.mapHeight - 1, 1, 1000)
			end
			if self.rightHeightButton:inBounds(mx, my) then
				self.mapHeight = clamp(self.mapHeight + 1, 1, 1000)
			end
			if self.newMapButton:inBounds(mx, my) then
				self:generateVoid(self.mapWidth, self.mapHeight)
			end

			if mx > self.rightEdge and my > self.topEdge then
				if self.ghost and self.map then
					local t = self.map:getTileAtWorld(mx, my)
					if t.name ~= "truevoid" then
						local obj = self.ghost.data.class:new(self.ghost.name, self.ghost.name, self.map, t.x, t.y)
						if obj:isType("item") then
							self.map:addItem(obj)
						end
						if obj:isType("entity") then
							self.map:addEntity(obj)
						end
						if obj:isType("furniture") then
							self.map:addFurniture(obj)
						end
						if obj:isType("tile") then
							self.map:addTile(obj, t.index)
						end
					end
				end
			end
		end
	end
end

local function loadFunc(self)
	self.width = math.floor(love.graphics.getWidth()/4)
	self.topMargin = 100
	self.leftMargin = 20
	self.rightEdge = 6*(TILE_SIZE+5) + TILE_SIZE
	self.topEdge = 45
	self.mapWidth = 10
	self.mapHeight = 10

	self.map = nil
	self.tiles = {}
	self.items = {}
	self.entities = {}
	self.furniture = {}
	self.tabButtons = {}
	self.tileButtons = {}
	self.itemButtons = {}
	self.entityButtons = {}
	self.furnitureButtons = {}
	self.currentTabButtons = self.tileButtons
	self.currentTabObjects = self.tiles
	self.ghost = nil
	self.camera = camera:new()

	local f = love.graphics.getFont()
	local function makeButton(x, y, label, func)
		local width = f:getWidth(label) + 15
		local tabBtn = button:new(x, y, width, f:getHeight() + 10, label, func)
		return tabBtn, width
	end

	local function btnClick(btn)
		if btn.text == "Tiles" then
			self.currentTabObjects = self.tiles
			self.currentTabButtons = self.tileButtons
		end
		if btn.text == "Furniture" then
			self.currentTabObjects = self.furniture
			self.currentTabButtons = self.furnitureButtons
		end
		if btn.text == "Entities" then
			self.currentTabObjects = self.entities
			self.currentTabButtons = self.entityButtons
		end
		if btn.text == "Items" then
			self.currentTabObjects = self.items
			self.currentTabButtons = self.itemButtons
		end
	end

	local nw
	local tabBtn, w = makeButton(self.leftMargin, 35, "Tiles", btnClick)
	table.insert(self.tabButtons, tabBtn)
	tabBtn, nw = makeButton(self.leftMargin + w + 5, 35, "Furniture", btnClick)
	table.insert(self.tabButtons, tabBtn)
	w = w + nw
	tabBtn, nw = makeButton(self.leftMargin + w + 10, 35, "Entities", btnClick)
	table.insert(self.tabButtons, tabBtn)
	w = w + nw
	tabBtn, nw = makeButton(self.leftMargin + w + 15, 35, "Items", btnClick)
	table.insert(self.tabButtons, tabBtn)

	local lao = tile:retrieve("leftArrow") 
	local leftArrow = drawable:new(lao.tileset, lao.tilesetX, lao.tilesetY, lao.spriteWidth, lao.spriteHeight)
	local rao = tile:retrieve("rightArrow") 
	local rightArrow = drawable:new(rao.tileset, rao.tilesetX, rao.tilesetY, rao.spriteWidth, rao.spriteHeight)

	self.leftWidthButton = gbutton:new(400 + f:getWidth("width "), f:getHeight(), TILE_SIZE, TILE_SIZE, "", leftArrow.tileset, leftArrow.sprite)
	self.rightWidthButton = gbutton:new(400 + f:getWidth("width         ") + TILE_SIZE/2, f:getHeight(), TILE_SIZE, TILE_SIZE, "", rightArrow.tileset, rightArrow.sprite)
	self.leftHeightButton = gbutton:new(600 + f:getWidth("height "), f:getHeight(), TILE_SIZE, TILE_SIZE, "", leftArrow.tileset, leftArrow.sprite)
	self.rightHeightButton = gbutton:new(600 + f:getWidth("height         ") + TILE_SIZE/2, f:getHeight(), TILE_SIZE, TILE_SIZE, "", rightArrow.tileset, rightArrow.sprite)
	self.newMapButton = button:new(525, f:getHeight(), f:getWidth("new map") + 6, f:getHeight(), "new map")

	makeButton = function(x, y, label, tileset, sprite, count, func)
		local row = math.floor(count/3) + 1
		local col = count % 3
		local height = TILE_SIZE + f:getHeight() + 20
		local btn = gbutton:new(x*col, y*row, TILE_SIZE+TILE_SIZE, height, label, tileset, sprite, func)
		return btn
	end

	local function ghostClick()
		return
	end

	btnClick = function(btn, idx)
		self.ghost = ghost:new(self.currentTabObjects[idx], self.currentTabObjects[idx].name)
	end

	local count = 0
	for key, tileData in pairs(tile:retrieveAll()) do
		local obj = drawable:new(tileData.tileset, tileData.tilesetX, tileData.tilesetY, tileData.spriteWidth, tileData.spriteHeight, 1, 1, false)
		tileData.name = key
		local x = self.leftMargin + 2*(TILE_SIZE+5)
		local y = self.topMargin
		local btn = makeButton(x, y, key, obj.tileset, obj.sprite, count, btnClick)
		btn.obj = obj
		table.insert(self.tiles, tileData)
		table.insert(self.tileButtons, btn)
		count = count + 1
	end
	count = 0
	for key, furnData in pairs(furniture:retrieveAll()) do
		local obj = drawable:new(furnData.tileset, furnData.tilesetX, furnData.tilesetY, furnData.spriteWidth, furnData.spriteHeight, furnData.tileWidth, furnData.tileHeight, false)
		furnData.name = key
		local x = self.leftMargin + 2*(TILE_SIZE+5)
		local y = self.topMargin
		local btn = makeButton(x, y, key, obj.tileset, obj.sprite, count, btnClick)
		table.insert(self.furniture, furnData)
		table.insert(self.furnitureButtons, btn)
		count = count + 1
	end
	count = 0
	for key, itemData in pairs(item:retrieveAll()) do
		local obj = drawable:new(itemData.tileset, itemData.tilesetX, itemData.tilesetY, itemData.spriteWidth, itemData.spriteHeight, 1, 1, false)
		itemData.name = key
		local x = self.leftMargin + 2*(TILE_SIZE+5)
		local y = self.topMargin
		local btn = makeButton(x, y, key, obj.tileset, obj.sprite, count, btnClick)
		table.insert(self.items, itemData)
		table.insert(self.itemButtons, btn)
		count = count + 1
	end
	count = 0
	for key, entityData in pairs(entity:retrieveAll()) do
		local obj = drawable:new(entityData.tileset, entityData.tilesetX, entityData.tilesetY, entityData.spriteWidth, entityData.spriteHeight, 1, 1, false)
		entityData.name = key
		local x = self.leftMargin + 2*(TILE_SIZE+5)
		local y = self.topMargin
		local btn = makeButton(x, y, key, obj.tileset, obj.sprite, count, btnClick)
		table.insert(self.entities, entityData)
		table.insert(self.entityButtons, btn)
		count = count + 1
	end
end
-- function graphicButton:initialize(x, y, width, height, text, tileset, sprite, clickFunc)
local function exitFunc(self)

end

function builder:initialize()
	gamestate.initialize(self, "map builder", loadFunc, updateFunc, drawFunc, exitFunc, inputFunc, false, false)
end

function builder:keysdown()
	if love.keyboard.isDown('w') then
		self.camera:moveYOffset(5*self.camera.scale)
	end
	if love.keyboard.isDown('a') then
		self.camera:moveXOffset(5*self.camera.scale)
	end
	if love.keyboard.isDown('s') then
		self.camera:moveYOffset(-5*self.camera.scale)
	end
	if love.keyboard.isDown('d') then
		self.camera:moveXOffset(-5*self.camera.scale)
	end
end

function builder:generateVoid(width, height)
	self.map = nil
	self.map = map:new("mapBuilder map", 0, 0)
	self.map.camera = self.camera
	self.map.selected = true
	self.map:generateVoid(self.mapWidth, self.mapHeight)
end

function builder:saveMap()
	-- Data format so far:
	-- T: length of format string
	-- s[T]: format string
	-- h: map width
	-- h: map height
	-- h: number of following tiles
		-- n: xPos
		-- n: yPos
		-- c[x]: tile name
		-- c[x]: tile label  
	local serializedData, fmt = self.map:serialize()
	local fmtFinal = fmt
	serializedData = love.data.pack("string", "c" .. #fmtFinal, fmtFinal) .. serializedData
	serializedData = love.data.pack("string", "T", fmtFinal:len()) .. serializedData
	local file = io.output("shipdata.bin")
    io.write(serializedData)
end

function builder:loadMap()
	local file = io.input("shipdata.bin")
	local m = map:new("loaded map", 0, 0)
	m.camera = self.camera
	local binData = io.read("*a")
	m:deserialize(binData)
	self.map = m
	self.map.selected = true
	self.camera.xOffset = 0
	self.camera.yOffset = 0
	local t = self.map:getCentermostTile()
	self.camera:translate(t:getWorldCenterX() - self.rightEdge/2 + TILE_SIZE/2, t:getWorldCenterY(), 1.25)
end

return builder