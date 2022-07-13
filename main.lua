local map = require('map')
local tile = require('tile')
local game = require('game')
local camera = require('camera')
local debugtext = require('debugtext')
local entity = require('entity')
local task = require('task')

TILE_SIZE = 32

local pawns = {}

local previousTime
local tickUnit = 10^6.0 / 60
local delta = 0
local pause = false
local gameSpeed = 1

function love.load()

	m = map:new()
	m:load('map.txt')

	d = debugtext:new()
	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("MouseRel", "")
	d:addTextField("Tile under mouse", "")
	d:addTextField("Entity under mouse", "")
	d:addTextField("Task", "")

	local c = camera:new()
	setGameCamera(c)
	c:moveXOffset(love.graphics.getWidth()/3.2)
	c:moveYOffset(love.graphics.getHeight()/5)

	p = entity:new("sprites/man.png", 2, 3, "Barnaby")
	m:addEntity(p)

	p = entity:new("sprites/man.png", 6, 8, "Diocletian")
	m:addEntity(p)

	previousTime = love.timer.getTime()
end

function love.update(dt)

	mx = love.mouse.getX()
	my = love.mouse.getY()
	local rx, ry = getMousePos()

	d:updateTextField("MousePos", "(" .. mx .. ", " .. my .. ")")
	d:updateTextField("MouseRel", "(" .. rx .. ", " .. ry .. ")")
	d:updateTextField("Tile under mouse", tostring(m:getTileAtPos(rx, ry)))
	d:updateTextField("Entity under mouse", tostring(m:getEntityAtPos(rx, ry)))

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
		love.mouse.setPosition(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
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


end

function love.draw()

	m:draw()
	d:draw()

	if getMouseSelection() then
		drawSelectionBox()
		drawSelectionDetails()
	end

end

function love.keypressed(key)
  
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
	  gui.switchFullscreen()
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
	local t = m:getTileAtPos(getMousePos())
	local e = m:getEntityAtPos(getMousePos())
	if button == 1 then
		if e then
			setMouseSelection(e)
		end
	end

	if button == 2 then
		if getMouseSelection() and t then
			local route = m:pathfind(getMouseSelection():getPos(), {x=t.x, y=t.y})
			if route then
				getMouseSelection():walkRoute(route, t)
			end
		end
	end
end