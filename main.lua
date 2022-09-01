local map = require('map.map')
local game = require('game')
local debugtext = require('debugtext')
local gamestate = require('gamestate.gamestate')
local playerstate = require('gamestate.gamestate_player')
local background = require('gamestate.gamestate_background')
local builder = require('gamestate.gamestate_builder')
local data = require('data')
local gui = require('gui.gui')

TILE_SIZE = 32

local previousTime
local delta = 0
local paused = false
local gameSpeed = 1
local gdata


---@diagnostic disable-next-line: lowercase-global
d = debugtext:new()
function love.load()

	love.window.setMode(1025,768, {vsync=true})

	love.graphics.setDefaultFilter('nearest', 'nearest')
	math.randomseed(love.timer.getTime())

	gdata = data:new()

	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("MouseTest", "")
	d:addTextField("Tile under mouse", "")
	d:addTextField("Objects under mouse", "")
	d:addTextField("Map under mouse", "")
	d:addTextField("topEdge", "")

	local bg = background:new(450)
	local ps = playerstate:new()

	local loadedMap = map:retrieve("base_destroyer")
	--local loadedMap = map:retrieve("base_moonmoon")
--	loadedMap:setOffset(5, 5)
	loadedMap:setOffset(15, 15)
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

	--love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end

function love.textinput(text)
	gamestate:addInput("textinput", {text=text})
end

local popped = nil
local debugly = false
function love.keypressed(key)
	gamestate:addInput("keypressed", {key=key})

	if key == 'f4' then
		debugly = not debugly
	end

	if key == '=' then
		gameSpeed = clamp(gameSpeed + 1, 1, 3)
	end

	if key == '-' then
		gameSpeed = clamp(gameSpeed - 1, 1, 3)
	end

	if key == 'p' and debugly then
		popped = gamestate:pop()
	end

	if key == '[' and debugly then
		gamestate:push(popped)
	end

	if key == '1' and debugly then
		local top = gamestate:peek()
		local loadedMap = map:retrieve("base_shuttlecraft")
--		loadedMap:setOffset(0, 7)
		loadedMap:setOffset(0, 0)
		top:addMap(loadedMap)
		-- top:setCurrentMap(loadedMap)
	end

	if key == 'b' and gamestate:peek().label ~= "map builder" then
		local build = builder:new()
		gamestate:push(build)
	end

	local gs = gamestate:peek()

	if gs.label == "playerstate" then
		if key == '3' then
			gs.currentMap:addAlert("HULL BREACH")
		end

		local e = gs:getSelection()
		local t = gs.maps[1]:getTileAtWorld(gui:getMousePos())
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
end

function love.wheelmoved(x, y)
	gamestate:addInput("wheelmoved", {x=x, y=y})
end

function love.mousereleased(x, y, button)
	gamestate:addInput("mousereleased", {x=x, y=y, button=button})
end