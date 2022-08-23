local map = require('map.map')
local tile = require('tile')
local game = require('game')
local camera = require('camera')
local debugtext = require('debugtext')
local entity = require('entities.entity')
local item = require('items.item')
local food = require('items.food')
local corpse = require('items.corpse')
local furniture = require('furniture.furniture')
local comfort = require('furniture.furniture_comfort')
local generator = require('furniture.generator')
local task = require('tasks.task')
local context = require('context')
local door = require('furniture.door')
local drawable = require('drawable')
local stockpile = require('stockpile')
local gamestate = require('gamestate.gamestate')
local playerstate = require('gamestate.gamestate_player')
local fadein = require('gamestate.gamestate_fade')
local inventory = require('gamestate.gamestate_inventory')
local mapstate = require('gamestate.gamestate_map')
local background = require('gamestate.gamestate_background')
local station = require('furniture.station')
local data = require('data')
local attribute = require('rooms.attribute')

TILE_SIZE = 32

local previousTime
local delta = 0
local paused = false
local gameSpeed = 1
local gdata


---@diagnostic disable-next-line: lowercase-global
d = debugtext:new()
function love.load()

	--love.window.setMode(1025,768, {vsync=true})

	love.graphics.setDefaultFilter('nearest', 'nearest')
	math.randomseed(love.timer.getTime())

	gdata = data:new()

	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("MouseTest", "")
	d:addTextField("Tile under mouse", "")
	d:addTextField("Objects under mouse", "")
	d:addTextField("Map under mouse", "")

	-- local m = map:new("main map", 2, 2)
	-- m:load('newmap.txt')

	-- local oxygen = attribute:new("base_oxygen")
	-- local nitrogen = attribute:new("base_nitrogen")

	-- local rando = entity:new("pawn", gdata:getRandomFullName(), m, 3, 7)
	-- local barnaby = entity:new("pawn", "Barnaby", m, 4, 5)
	-- local dio = entity:new("tallpawn", "Diocletian", m, 6, 3)
	-- local cow = entity:new("cow", "cow", m, 8, 5)
	-- local gus = entity:new("pawn", "Gustav", m, 6, 4)
	-- m:addEntity(rando)
	-- m:addEntity(barnaby)
	-- m:addEntity(dio)
	-- m:addEntity(gus)

	-- local chicken = food:new("yummy chicken", m, 3, 2)
	-- local pizza = food:new("yummy pizza", m, 3, 7)
	-- local pizza2 = food:new("yummy pizza", m, 4, 2)

	-- pizza.amount = 10
	-- pizza2.amount = pizza2.maxStack - 5
	-- m:addItem(chicken)
	-- m:addItem(pizza)
	-- m:addItem(pizza2)

	-- local dresser = furniture:new("dresser", m, 7, 2)
	-- local o2gen = generator:new("o2gen", "Oxygen Generator", m, 2, 2, oxygen, 15/60)
	-- local n2gen = generator:new("o2gen", "Nitrogen Generator", m, 7, 7, nitrogen, 2/60)
	-- local stool = comfort:new("stool", "stool", m, 7, 3)
	-- local def = require('furniture/station_default')
	-- local console = station:new("station", "station", m, 3, 3, def.loadFunc, def.updateFunc, def.drawFunc, nil, def.inputFunc)
	-- dresser:addToInventory(pizza)
	-- m:addFurniture(dresser)
	-- m:addFurniture(console)
	-- m:addFurniture(stool)
	-- stool = comfort:new("stool", m, 8, 3)
	-- m:addFurniture(stool)
	-- m:addFurniture(o2gen)
	-- m:addFurniture(n2gen)

	-- local spTiles = m:getTilesFromPoints({{x=2, y=2}, {x=3, y=2}, {x=4, y=2}, {x=5, y=2}, 
	-- 										{x=2, y=3}, {x=3, y=3}, {x=4, y=3}, {x=5, y=3},
	-- 										{x=2, y=4}, {x=3, y=4}, {x=4, y=4}, {x=5, y=4},
	-- 										{x=2, y=5}, {x=3, y=5}, {x=4, y=5}, {x=5, y=5},})
	-- local sp = stockpile:new(m, spTiles, "new stockpile")
	-- m:addStockpile(sp)

	--local c = camera:new()
	local bg = background:new(450)
	--local gs = gamestate:getMapState("main map", m, c, true)
	--gs.camera = c
	local ps = playerstate:new()
	--ps:addMap(m)
	--ps:setCurrentMap(m)

	gamestate:push(bg)
	gamestate:push(ps)

	local loadedMap = map:retrieve("base_shuttlecraft")
	loadedMap:setOffset(5, 5)
	ps:addMap(loadedMap)
	ps:setCurrentMap(loadedMap)

	previousTime = love.timer.getTime()
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
		if not paused then
			gamestate:update(dt)
		end
		delta = delta - 1/(60 * gameSpeed)
	end
end

local nr, nb, ng = 1, 1, 1

function love.draw()

	gamestate:draw()
	d:draw()

	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end

function love.keypressed(key)
	gamestate:addInput("keypressed", {key=key})

	if key == '=' then
		gameSpeed = clamp(gameSpeed + 1, 1, 3)
	end

	if key == '-' then
		gameSpeed = clamp(gameSpeed - 1, 1, 3)
	end

	if key == 'p' then
		gamestate:pop()
	end

	if key == '1' then
		local top = gamestate:peek()
		local loadedMap = map:retrieve("base_shuttlecraft")
		loadedMap:setOffset(-5, -5)
		top:addMap(loadedMap)
		top:setCurrentMap(loadedMap)
	end

	if key == '3' then
		local gs = gamestate:peek()
		gs.currentMap:addAlert("HULL BREACH")
	end

	local gs = gamestate:peek()

	if key == 'e' and gs:getSelection() then
		local e = gs:getSelection()
		local t = gs.currentMap:getTileAtWorld(getMousePos())
		local dist = math.sqrt((t.x - e.x)^2 + (t.y - e.y)^2)
		local function moveFunc(eself, x)
			local p = eself.moveFuncParams
			p.smoothstep = true

			local y = -math.sin(math.pi*(1-p.percentComplete))*math.abs(p.tileDistance*5)
			--local y = 0
			return y
		end
		gs:getSelection():translate(t.x, t.y, 30*math.sqrt(dist), moveFunc)
	end

	if key == '4' then
		local t = gs.currentMap:getCentermostTile()
		gs.camera:translate(t:getWorldCenterX(), t:getWorldCenterY())
	end

end

function love.wheelmoved(x, y)
	gamestate:addInput("wheelmoved", {x=x, y=y})
end

function love.mousereleased(x, y, button)
	gamestate:addInput("mousereleased", {x=x, y=y, button=button})
end