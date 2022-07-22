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
local stockpile = require('stockpile')
local background = require('background')
local gamestate = require('gamestate/gamestate')
local fadein = require('gamestate/gamestate_fadein')
local fadeout = require('gamestate/gamestate_fadeout')

TILE_SIZE = 32

local pawns = {}

local previousTime
local delta = 0
local pause = false
local gameSpeed = 1

d = debugtext:new()
tmpTiles = {}
local oTmpTiles = {}

function love.load()

	--love.window.setMode(1025,768, {vsync=true})

	love.graphics.setDefaultFilter('nearest')
	love.math.setRandomSeed(-love.timer.getTime(), love.timer.getTime())

	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("MouseRel", "")
	d:addTextField("Tile under mouse", "")
	d:addTextField("Objects under mouse", "")
	d:addTextField("Is walkable", "")

	local c = camera:new()
	setGameCamera(c)
	c:moveXOffset(love.graphics.getWidth()/3.2)
	c:moveYOffset(love.graphics.getHeight()/5)
	
	drawable:addTileset("entity", "sprites/tilesheets/entities.png")
	drawable:addTileset("item", "sprites/tilesheets/items.png")
	drawable:addTileset("furniture", "sprites/tilesheets/furniture.png")
	drawable:addTileset("floorTile", "sprites/tilesheets/tiles.png")

	local font = love.graphics.newFont("fonts/Instruction.otf")
	addFont(font, "robot")
	
	local gs = require('gamestate/gamestate_map')

	gamestate:push(gs)

	previousTime = love.timer.getTime()
end

function love.update(dt)

	local mx = love.mouse.getX()
	local my = love.mouse.getY()
	local rx, ry = getMousePos()
	
	d:updateTextField("MousePos", "(" .. mx .. ", " .. my .. ")")
	d:updateTextField("MouseRel", "(" .. rx .. ", " .. ry .. ")")

	if love.keyboard.isDown('w') then
		getGameCamera():moveYOffset(5*getGameCamera().scale)
	end
	if love.keyboard.isDown('a') then
		getGameCamera():moveXOffset(5*getGameCamera().scale)
	end
	if love.keyboard.isDown('s') then
		getGameCamera():moveYOffset(-5*getGameCamera().scale)
	end
	if love.keyboard.isDown('d') then
		getGameCamera():moveXOffset(-5*getGameCamera().scale)
	end
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

	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end

function love.keypressed(key)
	local t = getGameMap():getTileAtWorld(getMousePos())
	local f = getGameMap():getFurnitureAtWorld(getMousePos())[1]
	
	if key == 'space' then
		paused = not paused
	end
	
	if key == '=' then
		gameSpeed = clamp(gameSpeed + 1, 1, 3)
	end

	if key == 'o' then
		local fadein = gamestate:getFadeinState()
		local inv = require('gamestate/gamestate_inventory')
		gamestate:push(fadein)
		gamestate:push(inv)
	end

	if key == 'p' then
		gamestate:pop()
		gamestate:pop()
		local fadeout = gamestate:getFadeoutState()
		gamestate:push(fadeout)
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
	local m = getGameMap()
	local t = m:getTileAtWorld(getMousePos())
	local e = m:getEntitiesAtWorld(getMousePos())[1]
	local i = m:getItemsAtWorld(getMousePos())[1]
	local f = m:getFurnitureAtWorld(getMousePos())[1]
	local s = m:getStockpileAtWorld(getMousePos())

	if button == 1 then
		if getGameContext().active and getGameContext():inBounds(x, y) then
			getGameContext():handleClick(x, y)
		else
			if s then setMouseSelection(s) end
			if f then setMouseSelection(f) end
			if i then setMouseSelection(i) end
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