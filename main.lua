local map = require('map')
local tile = require('tile')
local game = require('game')
local camera = require('camera')
local debugtext = require('debugtext')
local entity = require('entity')
local item = require('item')
local furniture = require('furniture')
local task = require('task')
local context = require('context')
local door = require('door')

TILE_SIZE = 32

local pawns = {}

local previousTime
local tickUnit = 10^6.0 / 60
local delta = 0
local pause = false
local gameSpeed = 1

d = debugtext:new()

function love.load()

	--love.window.setMode(1025,768, {vsync=true})

	love.graphics.setDefaultFilter('nearest')

	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("MouseRel", "")
	d:addTextField("Tile under mouse", "")
	d:addTextField("Objects under mouse", "")

	local c = camera:new()
	setGameCamera(c)
	c:moveXOffset(love.graphics.getWidth()/3.2)
	c:moveYOffset(love.graphics.getHeight()/5)

	setMouseSelection(p)
	
	drawable:addTileset("entity", "sprites/tilesheets/entities.png")
	drawable:addTileset("item", "sprites/tilesheets/items.png")
	drawable:addTileset("furniture", "sprites/tilesheets/furniture.png")
	drawable:addTileset("floorTile", "sprites/tilesheets/tiles.png")

	m = map:new()
	m:load('map.txt')
	setGameMap(m)

	local p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Barnaby", 2, 3)
	m:addEntity(p)

	p = entity:new("entity", TILE_SIZE, 0, TILE_SIZE, TILE_SIZE + 9, "Diocletian", 6, 8)
	m:addEntity(p)
	
	p = entity:new("entity", TILE_SIZE*2, 0, TILE_SIZE*2, TILE_SIZE+10, "cow", 7, 3)
	m:addEntity(p)
	
	local i = item:new("item", 0, 0, TILE_SIZE, TILE_SIZE, "yummy chicken", 2, 7)
	m:addItem(i)

	i = item:new("item", TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, "yummy pizza", 5, 3)
	m:addItem(i)
	
	i = item:new("item", TILE_SIZE*2, 0, TILE_SIZE + 15, TILE_SIZE*2, "street light", 2, 10)
	m:addItem(i)

	local newDoor = door:new("furniture", TILE_SIZE*2, 0, TILE_SIZE, TILE_SIZE, "door", 2, 4)
	m:addFurniture(newDoor)
	
	local f = furniture:new("furniture", 0, 0, TILE_SIZE*2, TILE_SIZE+14, "dresser", 7, 2, 2, 1)
	m:addFurniture(f)

	font = love.graphics.newFont("fonts/Instruction.otf")
	addFont(font, "robot")

	local ctx = context:new(font)
	setGameContext(ctx)

	previousTime = love.timer.getTime()
end

function love.update(dt)

	mx = love.mouse.getX()
	my = love.mouse.getY()
	local rx, ry = getMousePos()

	d:updateTextField("MousePos", "(" .. mx .. ", " .. my .. ")")
	d:updateTextField("MouseRel", "(" .. rx .. ", " .. ry .. ")")
	d:updateTextField("Tile under mouse", tostring(m:getTileAtWorld(rx, ry)))
	
	local objStr = ""
	local objects = m:getObjectsAtWorld(rx, ry)
	for idx, obj in ipairs(objects) do
		if idx ~= #objects then
			objStr = objStr .. tostring(obj) .. ", "
		else
			objStr = objStr .. tostring(obj)
		end
	end
	d:updateTextField("Objects under mouse", objStr)

	if love.keyboard.isDown('w') then
		getGameCamera():moveYOffset(3*getGameCamera().scale)
	end
	if love.keyboard.isDown('a') then
		getGameCamera():moveXOffset(3*getGameCamera().scale)
	end
	if love.keyboard.isDown('s') then
		getGameCamera():moveYOffset(-3*getGameCamera().scale)
	end
	if love.keyboard.isDown('d') then
		getGameCamera():moveXOffset(-3*getGameCamera().scale)
	end
	if love.keyboard.isDown('q') then
		getGameContext():clear()
	end

	local now = love.timer.getTime()
  	delta = delta + (now - previousTime)
  	previousTime = now

	while delta >= 1/(60 * gameSpeed) do
		if not paused then
			m:update(dt)
		end
		delta = delta - 1/(60 * gameSpeed)
	end

	getGameContext():update()
end

function love.draw()

	m:draw()
	d:draw()
	getGameContext():draw()

	if getMouseSelection() then
		drawSelectionBox()
		drawSelectionDetails()
	end
end

function love.keypressed(key)
	local f = m:getFurnitureAtWorld(getMousePos())[1]

	if key == 'space' then
	  paused = not paused
	end
	
	if key == '=' then
	  gameSpeed = clamp(gameSpeed + 1, 1, 3)
	end
	
	if key == '-' then
	  gameSpeed = clamp(gameSpeed - 1, 1, 3)
	end
	
	if key == 'f11' then
	  --gui.switchFullscreen()
	end

	if key == 'q' and f and f:getType() == "door" then
		if f:isOpen() then
			f:closeDoor()
		else
			f:openDoor()
		end
	end
end

function love.wheelmoved(x, y)
	if y > 0 then
		for i=1, y do
			getGameCamera():zoomIn()
		end
	elseif y < 0 then
		for i=1, math.abs(y) do
			getGameCamera():zoomOut()
		end
	end
end

function love.mousereleased(x, y, button)
	local t = m:getTileAtWorld(getMousePos())
	local e = m:getEntitiesAtWorld(getMousePos())[1]
	local i = m:getItemsAtWorld(getMousePos())[1]
	local f = m:getFurnitureAtWorld(getMousePos())[1]

	if button == 1 then
		if getGameContext().active and getGameContext():inBounds(x, y) then
			getGameContext():handleClick(x, y)
		else
			if i then setMouseSelection(i) end
			if f then setMouseSelection(f) end
			if e then setMouseSelection(e) end
		end
	end

	if button == 2 then
		if getMouseSelection() and t and getMouseSelection():getType() == "entity" then
			local tlist = m:getPossibleTasks(t, getMouseSelection())
			getGameContext():set(x, y, tlist)
		end
	end
end