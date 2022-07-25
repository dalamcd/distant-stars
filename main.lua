local map = require('map/map')
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
local stockpile = require('stockpile')
local background = require('background')
local gamestate = require('gamestate/gamestate')
local fadein = require('gamestate/gamestate_fade')
local inventory = require('gamestate/gamestate_inventory')
local mapstate = require('gamestate/gamestate_map')

TILE_SIZE = 32

local previousTime
local delta = 0
local paused = false
local gameSpeed = 1

d = debugtext:new()
tmpTiles = {}
local oTmpTiles = {}

function love.load()

	--love.window.setMode(1025,768, {vsync=true})

	love.graphics.setDefaultFilter('nearest', 'nearest')
	love.math.setRandomSeed(-love.timer.getTime(), love.timer.getTime())

	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("MouseRel", "")
	d:addTextField("Tile under mouse", "")
	d:addTextField("Objects under mouse", "")
	d:addTextField("Is walkable", "")
	
	drawable:addTileset("entity", "sprites/tilesheets/entities.png")
	drawable:addTileset("item", "sprites/tilesheets/items.png")
	drawable:addTileset("furniture", "sprites/tilesheets/furniture.png")
	drawable:addTileset("floorTile", "sprites/tilesheets/tiles.png")

	local font = love.graphics.newFont("fonts/Instruction.otf")
	addFont(font, "robot")

	local m = map:new("main map", 13, 2)
	m:load('newmap.txt')
	setGameMap(m)
	
	local p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Dylan", m, 6, 7)
	m:addEntity(p)

	p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Barnaby", m, 4, 5)
	m:addEntity(p)

	p = entity:new("entity", TILE_SIZE*2, 0, TILE_SIZE, TILE_SIZE + 9, "Diocletian", m, 6, 3)
	m:addEntity(p)
	
	p = entity:new("entity", TILE_SIZE*4, 0, TILE_SIZE*2, TILE_SIZE+10, "cow", m, 8, 5)
	m:addEntity(p)
	
	local i = item:new("item", 0, 0, TILE_SIZE, TILE_SIZE, "yummy chicken", m, 2, 7)
	m:addItem(i)

	i = item:new("item", TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, "yummy pizza", m, 3, 8)
	m:addItem(i)

	local tmp = {{x=0, y=1}, {x=1, y=1}}
	local f = furniture:new("furniture", 0, 0, TILE_SIZE*2, TILE_SIZE+14, "dresser", m, 7, 2, 2, 1, tmp)
	i = item:new("item", TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, "yummy pizza", m, 3, 8)
	m:addItem(i)
	f:addToInventory(i)
	m:addFurniture(f)
	
	local tmp = m:getTilesInRectangle(2, 5, 3, 3)
	table.insert(tmp, m:getTile(8, 7))

	--local sp = stockpile:new(m, tmp, "new stockpile")
	--m:addStockpile(sp)

	local c = camera:new()
	setGameCamera(c)
	--c:moveXOffset(love.graphics.getWidth()/3.2)
	--c:moveYOffset(love.graphics.getHeight()/5)

	local gs = gamestate:getMapState("main map", m, c)
	gs.camera = c

	gamestate:push(gs)

	previousTime = love.timer.getTime()
end

function love.update(dt)

	local mx = love.mouse.getX()
	local my = love.mouse.getY()
	local rx, ry = getMousePos()
	
	d:updateTextField("MousePos", "(" .. mx .. ", " .. my .. ")")
	d:updateTextField("MouseRel", "(" .. rx .. ", " .. ry .. ")")

	if love.keyboard.isDown('q') then
		getGameContext():clear()
	end
	
	local now = love.timer.getTime()
	delta = delta + (now - previousTime)
	previousTime = now
	
	while delta >= 1/(60 * gameSpeed) do
		gamestate:update(dt)
		delta = delta - 1/(60 * gameSpeed)
	end
end

local nr, nb, ng = 1, 1, 1

function love.draw()

	gamestate:draw()

	if getMouseSelection() then
		if getMouseSelection():getType() ~= "stockpile" then
			drawSelectionBox()
		end
		drawSelectionDetails()
	end

	if oTmpTiles ~= tmpTiles then
		oTmpTiles = tmpTiles
		nr = math.random(50, 100)/100
		ng = math.random(50, 100)/100
		nb = math.random(50, 100)/100
	end

	for _, t in ipairs(tmpTiles) do
		local br, bg, bb, ba = love.graphics.getColor() 
		love.graphics.setColor(nr, ng, nb, 1)
		circ("fill", (t.x-1/2)*TILE_SIZE, (t.y-1/2)*TILE_SIZE, 2)
		love.graphics.setColor(br, bg, bb, ba)
	end

	d:draw()

	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end

function love.keypressed(key)
	gamestate:input("keypressed", {key=key})
	local t = getGameMap():getTileAtWorld(getMousePos())
	local f = getGameMap():getFurnitureAtWorld(getMousePos())[1]
	
	if key == 'space' then
		paused = not paused
	end
	
	if key == '=' then
		gameSpeed = clamp(gameSpeed + 1, 1, 3)
	end

	if key == 'o' then
		local fade = gamestate:getFadeState()
		local inv = gamestate:getInventoryState(getGameMap():getFurnitureInTile(getGameMap():getTile(12, 2))[1])
		gamestate:push(fade)
		gamestate:push(inv)
	end

	if key == 'p' then
		gamestate:pop()
	end

	if key == '1' then
		local top = gamestate:peek()
		local newMap = map:new("testmap", 1, 1)
		local p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Dylan", newMap, 6, 7)
		local cam = camera:new()
		cam.scale = top.map.camera.scale
		cam.xOffset = top.map.camera.xOffset
		cam.yOffset = top.map.camera.yOffset
		newMap:load("map.txt")
		newMap:addEntity(p)
		local gs = gamestate:getMapState("testmap", newMap, cam, true)
		gamestate:push(gs)
	end
	
	if key == '-' then
		gameSpeed = clamp(gameSpeed - 1, 1, 3)
	end

	if key == 'q' and f and f:getType() == "door" then
		if f:isOpen() then
			f:closeDoor()
		else
			f:openDoor()
		end
	end

	if key == 'e' and getMouseSelection() then
		local e = getMouseSelection()
		local dist = math.sqrt((t.x - e.x)^2 + (t.y - e.y)^2)
		function moveFunc(eself, x)
			local p = eself.moveFuncParams
			--p.smoothstep = true
					
			local y = -math.sin(math.pi*(1-p.percentComplete))*math.abs(p.tileDistance*5)
			--local y = 0
			return y
		end
		getMouseSelection():translate(t.x, t.y, 30*math.sqrt(dist), moveFunc)
	end
end

function love.wheelmoved(x, y)
	gamestate:input("wheelmoved", {x=x, y=y})
end

function love.mousereleased(x, y, button)
	gamestate:input("mousereleased", {x=x, y=y, button=button})
end