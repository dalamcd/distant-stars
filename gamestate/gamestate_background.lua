local class = require('lib.middleclass')
local gamestate = require('gamestate.gamestate')

local background = class('background', gamestate)

local function updateFunc(self, dt)

	for _, point in ipairs(self.points) do
		point.x = point.x + point.speed
		if point.x > love.graphics.getWidth() then
			point.x = -math.random(50)
			point.y = math.random()*love.graphics.getHeight() + 1
		end
	end
end

local function drawFunc(self)
	for _, point in ipairs(self.points) do
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(point.red, 0.9, point.blue, 1)
		love.graphics.circle("fill", point.x, point.y, point.r)
		love.graphics.setColor(r, g, b, a)
	end
end

function background:initialize(num)
	self.points = {}
	self.starStep = 1
	self.maxRadius = 2

	for i=1, num do
		local x = math.floor(math.random()*love.graphics.getWidth() + 1)
		local y = math.floor(math.random()*love.graphics.getHeight() + 1)
		local speed = math.random(5)/100
		local r = math.random()*2
		local red, blue = 1, 1
		if math.random(2) > 1 then red = 0.7 else blue = 0.7 end
		local point = {x=x, y=y, r=r, speed=speed, red=red, blue=blue}
		table.insert(self.points, point)
	end

	gamestate.initialize(self, "background", nil, updateFunc, drawFunc, nil, nil, false, false)
end

return background