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

	local bg = background:new(450)
	local ps = playerstate:new()

	local loadedMap = map:retrieve("base_destroyer")
	loadedMap:setOffset(5, 5)
	ps:addMap(loadedMap)
	ps:setCurrentMap(loadedMap)

	gamestate:push(bg)
	gamestate:push(ps)

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
		loadedMap:setOffset(0, 7)
		top:addMap(loadedMap)
		-- top:setCurrentMap(loadedMap)
	end

	local gs = gamestate:peek()

	if key == '3' then
		gs.currentMap:addAlert("HULL BREACH")
	end

	local e = gs:getSelection()
	local t = gs.currentMap:getTileAtWorld(getMousePos())
	if key == 'e' and e and t then
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