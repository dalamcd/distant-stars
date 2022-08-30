local class = require('lib.middleclass')
local gamestate = require('gamestate.gamestate')
local labeledGraphicButton = require('gui.labeledGraphicButton')
local button = require('gui.button')
local tile = require('tile')
local drawable = require('drawable')
local furniture = require('furniture.furniture')
local item = require('items.item')
local entity = require('entities.entity')
local ghost = require('ghost')
local map = require('map.map')
local camera = require('camera')
local utils = require('utils')
local inputField = require('gui.inputField')
local gui = require('gui.gui')
local labeledInputField = require('gui.labeledInputField')
local inspector = require('gamestate.gamestate_inspector')
local dropdown = require('gui.dropdown')

local builder = class('builder', gamestate)

local function updateFunc(self, dt)
	local mx, my = gui:getMousePos()
	d:updateTextField("topEdge", tostring(my > self.topEdge))
	self.camera:update(dt)
	if self.map then
		local t = self.map:getTileAtWorld(mx, my)
		if t then
			d:updateTextField("Tile under mouse", tostring(t))
		end
	end

	if tonumber(self.widthInput.text) and tonumber(self.widthInput.text) > 100 then
		self.widthInput:setText("100")
		self.widthInput:moveCursor(3)
	end
	if tonumber(self.heightInput.text) and tonumber(self.heightInput.text) > 100 then
		self.heightInput:setText("100")
		self.heightInput:moveCursor(3)
	end

end

local function drawFunc(self)
	local mx, my = gui:getMousePos()
	local t
	
	if self.map then
		t = self.map:getTileAtWorld(mx, my)
		self.map:draw()
	end

	gui:drawRect(0, 0, self.rightEdge, love.graphics.getHeight(), {0.5, 0.5, 0.5, 1}, 0)
	self.newMapButton:draw()
	for _, btn in ipairs(self.currentTabButtons) do
		btn:draw()
	end

	-- Draw top tab section
	gui:drawRect(0, 0, self.rightEdge, 95, {0.45, 0.45, 0.45, 1}, 0)
	-- Draw line between tab section and button section
	gui:drawRect(0, 95, self.rightEdge, 2, {0.25, 0.25, 0.25, 1}, 0)
	-- Draw portion directly behind tabs
	gui:drawRect(4, 17, self.rightEdge - 8, 65, {0.4, 0.4, 0.4, 1}, 2, {0.3, 0.3, 0.3, 1})
	for _, btn in ipairs(self.tabButtons) do
		btn:draw()
	end
	for _, input in ipairs(self.textInputs) do
		input:draw()
	end

	if self.ghost and mx > self.rightEdge and t then
		self.ghost:draw(self.camera:getRelativeX(t:getWorldX()), self.camera:getRelativeY(t:getWorldY()), 1)
	end
end

local function inputFunc(self, input)
	self:keysdown()
	local mx, my = gui:getMousePos()

	if input.keypressed then
		if not self.selectedInput then
			if input.keypressed.key == 'q' then
				gamestate:pop()
			end
			if input.keypressed.key == 'e' then
				self:saveMapTable()
			end
			if input.keypressed.key == 'r' then
				self:loadMapTable("shipdata.lua")
			end
		else
			if input.keypressed.key == 'backspace' then
				self.selectedInput:backspace()
			end
			if input.keypressed.key == 'delete' then
				self.selectedInput:delete()
			end
			if input.keypressed.key == 'return' then
				self.selectedInput:deselect()
			end
			if input.keypressed.key == 'left' then
				self.selectedInput:moveCursor(self.selectedInput.cursor.col - 1)
			end
			if input.keypressed.key == 'right' then
				self.selectedInput:moveCursor(self.selectedInput.cursor.col + 1)
			end
		end
	end

	if input.wheelmoved and self.currentTabButtons.scrollable and mx < self.rightEdge then
		local y = input.wheelmoved.y
		if y < 0 then
			for i=1, math.abs(y) do
				local oldOffset = self.currentTabButtons.scrollOffset
				self.currentTabButtons.scrollOffset = clamp(self.currentTabButtons.scrollOffset - 10, -self.currentTabButtons.maxOffset, 0)
				local diff = self.currentTabButtons.scrollOffset - oldOffset
				for _, btn in ipairs(self.currentTabButtons) do
					btn.y = btn.y + diff
				end
			end
		elseif y > 0 then
			for i=1, math.abs(y) do
				local oldOffset = self.currentTabButtons.scrollOffset
				self.currentTabButtons.scrollOffset = clamp(self.currentTabButtons.scrollOffset + 10, -self.currentTabButtons.maxOffset, 0)
				local diff = self.currentTabButtons.scrollOffset - oldOffset
				for _, btn in ipairs(self.currentTabButtons) do
					btn.y = btn.y + diff
				end
			end
		end
	end

	if input.textinput then
		if self.selectedInput then
			self.selectedInput:addChar(input.textinput.text)
		end
	end

	if input.mousereleased then
		if input.mousereleased.button == 1 then

			local inputSelected = false
			for _, input in ipairs(self.textInputs) do
				if input:inBounds(mx, my) then
					input:select()
					self.selectedInput = input
					inputSelected = true
				else
					input:deselect()
				end
			end

			if not inputSelected then
				self.selectedInput = nil
			end

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
			if self.newMapButton:inBounds(mx, my) then
				self:generateVoid("newmap", tonumber(self.widthInput.text), tonumber(self.heightInput.text))
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
		if input.mousereleased.button == 2 then
			if self.ghost then
				self.ghost = nil
			else
				local t = self.map:getTileAtWorld(mx, my)
				if t then
					local objs = self.map:getObjectsInTile(t)
					if #objs > 0 then
						self.map:removeObject(objs[1])
					end
				end
			end
		end
		if input.mousereleased.button == 3 then
			local t = self.map:getTileAtWorld(mx, my)
			if t then
				local objs = self.map:getObjectsInTile(t)
				if #objs > 0 then
					local ins = inspector:new(objs[1])
					gamestate:push(ins)
				end
			end
		end
	end
end

local function loadFunc(self)
	self.width = math.floor(love.graphics.getWidth()/4)
	self.topMargin = 100
	self.leftMargin = 10
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
	self.toolButtons = {}
	self.entityButtons = {}
	self.furnitureButtons = {}
	self.textInputs = {}
	self.currentTabButtons = self.tileButtons
	self.currentTabObjects = self.tiles
	self.ghost = nil
	self.camera = camera:new()

	local f = love.graphics.getFont()
	local function makeButton(x, y, label, func)
		local width = f:getWidth(label) + 15
		local tabBtn = button:new(x, y, width, f:getHeight() + 10, label, func, {0.6, 0.6, 0.6, 1}, 2, {0.35, 0.35, 0.35, 1}, {0, 0, 0, 1})
		return tabBtn, width
	end

	local function btnClick(btn)
		if btn.label == "Tiles" then
			self.currentTabObjects = self.tiles
			self.currentTabButtons = self.tileButtons
		end
		if btn.label == "Furniture" then
			self.currentTabObjects = self.furniture
			self.currentTabButtons = self.furnitureButtons
		end
		if btn.label == "Entities" then
			self.currentTabObjects = self.entities
			self.currentTabButtons = self.entityButtons
		end
		if btn.label == "Items" then
			self.currentTabObjects = self.items
			self.currentTabButtons = self.itemButtons
		end
		if btn.label == "Tools" then
			self.currentTabObjects = {}
			self.currentTabButtons = self.toolButtons
		end
	end

	local nw
	local tabBtn, w = makeButton(self.leftMargin, 25, "Tiles", btnClick)
	table.insert(self.tabButtons, tabBtn)
	tabBtn, nw = makeButton(self.leftMargin + w + 5, 25, "Furniture", btnClick)
	table.insert(self.tabButtons, tabBtn)
	w = w + nw
	tabBtn, nw = makeButton(self.leftMargin + w + 10, 25, "Entities", btnClick)
	table.insert(self.tabButtons, tabBtn)
	w = w + nw
	tabBtn, nw = makeButton(self.leftMargin + w + 15, 25, "Items", btnClick)
	table.insert(self.tabButtons, tabBtn)
	tabBtn, nw = makeButton(self.leftMargin, 54, "Tools", btnClick)
	table.insert(self.tabButtons, tabBtn)

	self.newMapButton = button:new(525, 40, f:getWidth("new map") + 6, f:getHeight(), "new map")
	local selectButton = button:new(self.leftMargin + 2*(TILE_SIZE+5), self.topMargin, 2*TILE_SIZE, TILE_SIZE + f:getHeight() + 20, "Select", nil, nil, 0)
	selectButton:setBackgroundColor({0, 0, 0, 0})
	selectButton:setTextColor({0, 0, 0, 1})
	table.insert(self.toolButtons, selectButton)
	makeButton = function(x, y, label, tileset, sprite, count, func)
		local row = math.floor(count/3) + 1
		local col = count % 3
		local height = TILE_SIZE + f:getHeight() + 20
		local btn = labeledGraphicButton:new(x*col + 10, y*row, 2*TILE_SIZE, height, label, tileset, sprite, func, {0, 0, 0, 0}, 0, nil, {0, 0, 0, 1} )
		return btn
	end


	btnClick = function(btn, idx)
		self.ghost = ghost:new(self.currentTabObjects[idx], self.currentTabObjects[idx].name)
	end

	local count = 0
	local rows = 0
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
	rows = math.floor(count/3) + 1
	if rows > 5 then
		self.tileButtons.scrollable = true
		self.tileButtons.scrollOffset = 0
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
	rows = math.floor(count/3) + 1
	if rows > 5 then
		self.furnitureButtons.scrollable = true
		self.furnitureButtons.rows = rows
		self.furnitureButtons.maxOffset = (rows - 5)*(TILE_SIZE + f:getHeight() + 20)
		self.furnitureButtons.scrollOffset = 0
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

	self.mapNameInput = labeledInputField:new(300, 10, 100, f:getHeight() + 10, "name")
	self.widthInput = labeledInputField:new(450, 10, 100, f:getHeight() + 10, "width", "0123456789")
	self.heightInput = labeledInputField:new(600, 10, 100, f:getHeight() + 10, "height", "0123456789")
	self.widthInput:setText("10")
	self.heightInput:setText("10")
	table.insert(self.textInputs, self.mapNameInput)
	table.insert(self.textInputs, self.widthInput)
	table.insert(self.textInputs, self.heightInput)
end
local function exitFunc(self)

end

function builder:initialize()
	gamestate.initialize(self, "map builder", loadFunc, updateFunc, drawFunc, exitFunc, inputFunc, false, false)
end

function builder:keysdown()
		if not self.mapNameInput.selected then
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
end

function builder:generateVoid(label, width, height)
	self.map = nil
	self.map = map:new(label, 0, 0)
	self.mapNameInput:setText(label)
	self.widthInput:setText(tostring(width))
	self.heightInput:setText(tostring(height))
	self.map.camera = self.camera
	self.map.selected = true
	self.map:generateVoid(width, height)
	local t = self.map:getCentermostTile()
	if t then
		self.camera:translate(t:getWorldCenterX() - self.rightEdge/2, t:getWorldCenterY())
	end
end

function builder:saveMapTable()
	local file = io.output("shipdata.lua")
	local classNames = {}
	local mapStr = "return {\n"
	mapStr = mapStr .. "\twidth = " .. self.map.width .. ",\n"
	mapStr = mapStr .. "\theight = " .. self.map.height .. ",\n"
	mapStr = mapStr .. "\tlabel = '" .. self.mapNameInput.text .. "',\n"
	mapStr = mapStr .. "\ttiles = {\n"
	for _, obj in ipairs(self.map.tiles) do
		classNames[obj:getClassName()] = obj:getClassPath()
		mapStr = mapStr .. "\t\t{\n"
		mapStr = mapStr .. "\t\t\tx = " .. obj.x .. ",\n"
		mapStr = mapStr .. "\t\t\ty = " .. obj.y .. ",\n"
		mapStr = mapStr .. "\t\t\tclass = " .. obj:getClassName() .. ",\n"
		mapStr = mapStr .. "\t\t\tname = '" .. obj.name .. "',\n"
		mapStr = mapStr .. "\t\t\tlabel = '" .. obj.label .. "',\n"
		mapStr = mapStr .. "\t\t},\n"
	end
	mapStr = mapStr .. "\t},\n"
	mapStr = mapStr .. "\tfurniture = {\n"
	for _, obj in ipairs(self.map.furniture) do
		classNames[obj:getClassName()] = obj:getClassPath()
		mapStr = mapStr .. "\t\t{\n"
		mapStr = mapStr .. "\t\t\tx = " .. obj.x .. ",\n"
		mapStr = mapStr .. "\t\t\ty = " .. obj.y .. ",\n"
		mapStr = mapStr .. "\t\t\tclass = " .. obj:getClassName() .. ",\n"
		mapStr = mapStr .. "\t\t\tname = '" .. obj.name .. "',\n"
		mapStr = mapStr .. "\t\t\tlabel = '" .. obj.label .. "',\n"
		mapStr = mapStr .. "\t\t},\n"
	end
	mapStr = mapStr .. "\t},\n"
	mapStr = mapStr .. "\titems = {\n"
	for _, obj in ipairs(self.map.items) do
		classNames[obj:getClassName()] = obj:getClassPath()
		mapStr = mapStr .. "\t\t{\n"
		mapStr = mapStr .. "\t\t\tx = " .. obj.x .. ",\n"
		mapStr = mapStr .. "\t\t\ty = " .. obj.y .. ",\n"
		mapStr = mapStr .. "\t\t\tclass = " .. obj:getClassName() .. ",\n"
		mapStr = mapStr .. "\t\t\tname = '" .. obj.name .. "',\n"
		mapStr = mapStr .. "\t\t\tlabel = '" .. obj.label .. "',\n"
		mapStr = mapStr .. "\t\t},\n"
	end
	mapStr = mapStr .. "\t},\n"
	mapStr = mapStr .. "\tentities = {\n"
	for _, obj in ipairs(self.map.entities) do
		classNames[obj:getClassName()] = obj:getClassPath()
		mapStr = mapStr .. "\t\t{\n"
		mapStr = mapStr .. "\t\t\tx = " .. obj.x .. ",\n"
		mapStr = mapStr .. "\t\t\ty = " .. obj.y .. ",\n"
		mapStr = mapStr .. "\t\t\tclass = " .. obj:getClassName() .. ",\n"
		mapStr = mapStr .. "\t\t\tname = '" .. obj.name .. "',\n"
		mapStr = mapStr .. "\t\t\tlabel = '" .. obj.label .. "',\n"
		mapStr = mapStr .. "\t\t},\n"
	end
	mapStr = mapStr .. "\t},\n"
	mapStr = mapStr .. "}"

	local str = ""
	for k, v in pairs(classNames) do
		str = str .. string.format("local %s = require('%s')\n", k, v)
	end
	mapStr = str .. "\n" .. mapStr

	io.write(mapStr)
end

function builder:loadMapTable(fname)
	local status, mapRaw = pcall(love.filesystem.load, fname)
	if not status then
		error(tostring(mapRaw))
	else
		local mapData = mapRaw()
		assert(mapData.width and mapData.height, "Map table missing either width or height")
		self:generateVoid(mapData.label, mapData.width, mapData.height)
		for _, obj in ipairs(mapData.tiles) do
			local t = obj.class:new(obj.name, obj.label, self.map, obj.x, obj.y)
			self.map:addTile(t, t.index)
		end
		for _, obj in ipairs(mapData.entities) do
			self.map:addEntity(obj.class:new(obj.name, obj.label, self.map, obj.x, obj.y))
		end
		for _, obj in ipairs(mapData.furniture) do
			self.map:addFurniture(obj.class:new(obj.name, obj.label, self.map, obj.x, obj.y))
		end
		for _, obj in ipairs(mapData.items) do
			self.map:addItem(obj.class:new(obj.name, obj.label, self.map, obj.x, obj.y))
		end
	end
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
	serializedData = love.data.pack("string", "c" .. #fmt, fmt) .. serializedData
	serializedData = love.data.pack("string", "T", fmt:len()) .. serializedData
	local file = io.output("shipdata.bin")
    io.write(serializedData)
end

function builder:loadMap()
	local file = io.input("shipdata.bin")
	local m = map:new("loaded map", 0, 0)
	m.camera = self.camera
	local binData = io.read("*all")
	m:deserialize(binData)
	self.map = m
	self.map.selected = true
	self.camera.xOffset = 0
	self.camera.yOffset = 0
	local t = self.map:getCentermostTile()
	self.camera:translate(t:getWorldCenterX() - self.rightEdge/2 + TILE_SIZE/2, t:getWorldCenterY(), 1.25)
end

return builder