local map = require('map.map')
local tile = require('tile')
local game = require('game')
local camera = require('camera')
local debugtext = require('debugtext')
local entity = require('entity')
local item = require('items.item')
local food = require('items.food')
local data = require('data')
local corpse = require('items.corpse')
local furniture = require('furniture.furniture')
local comfort = require('furniture.furniture_comfort')
local generator = require('furniture.generator')
local task = require('tasks.task')
local context = require('context')
local door = require('furniture.door')
local drawable = require('drawable')
local stockpile = require('stockpile')
--local background = require('background')
local gamestate = require('gamestate.gamestate')
local fadein = require('gamestate.gamestate_fade')
local inventory = require('gamestate.gamestate_inventory')
local mapstate = require('gamestate.gamestate_map')
local background = require('gamestate.gamestate_background')
local station = require('furniture.station')
local data = require('data')

TILE_SIZE = 32

local previousTime
local delta = 0
local paused = false
local gameSpeed = 1
local gdata

d = debugtext:new()
tmpTiles = {}
local oTmpTiles = {}
function love.load()

	--love.window.setMode(1025,768, {vsync=true})

	love.graphics.setDefaultFilter('nearest', 'nearest')
	math.randomseed(love.timer.getTime())

	gdata = data:new()
	data:setBase(gdata)

	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("Tile under mouse", "")
	d:addTextField("Objects under mouse", "")

	local m = map:new("main map", 0, 0)
	m:load('newmap.txt')

	local rando = entity:new("pawn", gdata:getRandomFullName(), m, 3, 7)
	local barnaby = entity:new("pawn", "Barnaby", m, 4, 5)
	local dio = entity:new("tallpawn", "Diocletian", m, 6, 3)
	--local cow = entity:new("cow", "cow", m, 8, 5)
	--local gus = entity:new("pawn", "Gustav", m, 6, 4)
	m:addEntity(rando)
	--m:addEntity(barnaby)
	--m:addEntity(dio)
	--m:addEntity(gus)

	local chicken = food:new("yummy chicken", m, 2, 7)
	local pizza = food:new("yummy pizza", m, 3, 8)
	local pizza2 = food:new("yummy pizza", m, 3, 8)

	pizza.amount = 10
	pizza2.amount = pizza2.maxStack - 5
	m:addItem(chicken)
	m:addItem(pizza)
	m:addItem(pizza2)


	local dresser = furniture:new("dresser", m, 7, 2)
	local o2gen = generator:new("o2gen", m, 2, 2, "oxygen", 4.95/60)
	local n2gen = generator:new("o2gen", m, 7, 7, "nitrogen", 2/60)
	local stool = comfort:new("stool", m, 7, 3)
	local def = require('furniture/station_default')
	local console = station:new("station", m, 3, 3, def.loadFunc, def.updateFunc, def.drawFunc, nil, def.inputFunc)
	dresser:addToInventory(pizza)
	m:addFurniture(dresser)
	m:addFurniture(console)
	m:addFurniture(stool)
	m:addFurniture(o2gen)
	m:addFurniture(n2gen)

	--local sp = stockpile:new(m, tmp, "new stockpile")
	--m:addStockpile(sp)

	local c = camera:new()
	local bg = background:new(3000)
	local gs = gamestate:getMapState("main map", m, c, true)
	gs.camera = c

	gamestate:push(bg)
	gamestate:push(gs)

	previousTime = love.timer.getTime()
	print(gdata:getRandomFullName('male'))
end

function love.update(dt)

	local mx = love.mouse.getX()
	local my = love.mouse.getY()

	d:updateTextField("MousePos", "(" .. mx .. ", " .. my .. ")")

	local now = love.timer.getTime()
	delta = delta + (now - previousTime)
	previousTime = now

	gamestate:updateInput(dt)

	while delta >= 1/(60 * gameSpeed) do
		gamestate:update(dt)
		delta = delta - 1/(60 * gameSpeed)
	end
end

local nr, nb, ng = 1, 1, 1

function love.draw()

	gamestate:draw()

	-- if getMouseSelection() then
	-- 	if not getMouseSelection():isType("stockpile") then
	-- 		drawSelectionBox()
	-- 	end
	-- 	drawSelectionDetails()
	-- end

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

	if key == 'space' then
		paused = not paused
	end

	if key == '=' then
		gameSpeed = clamp(gameSpeed + 1, 1, 3)
	end

	if key == 'p' then
		gamestate:pop()
	end

	-- if key == 'q' then
	-- 	local gs = gamestate:peek()
	-- 	local furniture = gs.map:getFurnitureAtWorld(getMousePos(gs.map.camera))
	-- 	for _, f in ipairs(furniture) do
	-- 		if f:isType("door") then
	-- 			f:openDoor()
	-- 		end
	-- 	end
	-- end

	if key == '1' then
		local top = gamestate:peek()
		local newMap = map:new("testmap", -10, -10)
		local p = entity:new("tallpawn", "Dylan", newMap, 6, 7)
		local cam = camera:new()
		cam.scale = top.map.camera.scale
		cam.xOffset = top.map.camera.xOffset
		cam.yOffset = top.map.camera.yOffset
		newMap:load("map.txt")
		newMap:addEntity(p)
		local gs = gamestate:getMapState("testmap", newMap, cam, true)
		gamestate:push(gs)
		--gamestate:push(top)
	end

	if key == '3' then
		local gs = gamestate:peek()
		gs.map:addAlert("HULL BREACH")
	end

	if key == '-' then
		gameSpeed = clamp(gameSpeed - 1, 1, 3)
	end

	local gs = gamestate:peek()

	if key == 'e' and gs.map:getMouseSelection() then
		local e = gs.map:getMouseSelection()
		local t = gs.map:getTileAtWorld(getMousePos(gs.map.camera))
		local dist = math.sqrt((t.x - e.x)^2 + (t.y - e.y)^2)
		local function moveFunc(eself, x)
			local p = eself.moveFuncParams
			p.smoothstep = true
			
			local y = -math.sin(math.pi*(1-p.percentComplete))*math.abs(p.tileDistance*5)
			--local y = 0
			return y
		end
		gs.map:getMouseSelection():translate(t.x, t.y, 30*math.sqrt(dist), moveFunc)
	end

end

function love.wheelmoved(x, y)
	gamestate:input("wheelmoved", {x=x, y=y})
end

function love.mousereleased(x, y, button)
	gamestate:input("mousereleased", {x=x, y=y, button=button})
end