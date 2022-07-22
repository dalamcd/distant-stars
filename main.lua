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

	m = map:new()
	m:load('newmap.txt')
	setGameMap(m)

	local p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Dylan", 6, 7)
	m:addEntity(p)

	p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Barnaby", 4, 5)


	p = entity:new("entity", TILE_SIZE*2, 0, TILE_SIZE, TILE_SIZE + 9, "Diocletian", 6, 3)
	m:addEntity(p)
	
	p = entity:new("entity", TILE_SIZE*4, 0, TILE_SIZE*2, TILE_SIZE+10, "cow", 8, 5)
	m:addEntity(p)
	
	local i = item:new("item", 0, 0, TILE_SIZE, TILE_SIZE, "yummy chicken", 2, 7)
	m:addItem(i)

	i = item:new("item", TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, "yummy pizza", 3, 8)
	m:addItem(i)
	
	--i = item:new("item", TILE_SIZE*2, 0, TILE_SIZE + 15, TILE_SIZE*2, "street light", 2, 10)
	--m:addItem(i)
	
	local f = furniture:new("furniture", 0, 0, TILE_SIZE*2, TILE_SIZE+14, "dresser", 7, 2, 2, 1)
	m:addFurniture(f)

	local tmp = m:getTilesInRectangle(2, 5, 3, 3)
	table.insert(tmp, m:getTile(8, 7))

	local sp = stockpile:new(tmp, "new stockpile")
	m:addStockpile(sp)

	local b = background:new(500)
	setBackground(b)

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
		if not paused then
			getBackground():update(dt)
			m:update(dt)
		end
		delta = delta - 1/(60 * gameSpeed)
	end

	getGameContext():update()
end

local nr, nb, ng = 1, 1, 1

function love.draw()

	getBackground():draw()
	m:draw()
	d:draw()

	if getMouseSelection() then
		if getMouseSelection():getType() ~= "stockpile" then
			drawSelectionBox()
		end
		drawSelectionDetails()
	end

	getGameContext():draw()

	
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
	local t = m:getTileAtWorld(getMousePos())
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