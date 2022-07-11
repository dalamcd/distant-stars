local map = require('map')
local tile = require('tile')
local game = require('game')
local camera = require('camera')
local debugtext = require('debugtext')

function love.load()

	m = map:new()
	m:load('map.txt')

	d = debugtext:new()
	d:addTextField("MousePos", "(" .. love.mouse.getX() .. ", " .. love.mouse.getY() .. ")")
	d:addTextField("MouseRel", "")
	d:addTextField("Tile under mouse", "")
	local c = camera:new()
	setGameCamera(c)
	c:moveXOffset(love.graphics.getWidth()/3.2)
	c:moveYOffset(love.graphics.getHeight()/5)

end

function love.update()

	mx = love.mouse.getX()
	my = love.mouse.getY()
	local rx, ry = getMousePos()

	d:updateTextField("MousePos", "(" .. mx .. ", " .. my .. ")")
	d:updateTextField("MouseRel", "(" .. rx .. ", " .. ry .. ")")
	d:updateTextField("Tile under mouse", tostring(m:getTileAtPos(rx, ry)))

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

end

function love.draw()

	m:draw()
	d:draw()

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