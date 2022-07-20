local class = require('middleclass')

background = class('background')

function background:initialize(num)
	self.points = {}
	self.starStep = 1
	self.maxRadius = 1.7

	for i=1, num do
		local x = math.random(love.graphics.getWidth())
		local y = math.random(love.graphics.getHeight())
		local speed = math.random(5)/100
		local r = math.random(self.maxRadius)
		local red, blue = 1, 1
		if math.random(2) > 1 then red = 0.7 else blue = 0.7 end
		local point = {x=x, y=y, r=r, speed=speed, red=red, blue=blue}
		table.insert(self.points, point)
	end
end

function background:update(dt)

	for _, point in ipairs(self.points) do
		point.x = point.x + point.speed
		if point.x > love.graphics.getWidth() then
			point.x = -math.random(50)
			point.y = math.random(love.graphics.getHeight())
		end
	end
end

function background:draw()
	local r = 1
	for _, point in ipairs(self.points) do
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(point.red, 0.9, point.blue, 1)
		love.graphics.circle("fill", point.x, point.y, point.r)
		love.graphics.setColor(r, g, b, a)
	end
end

return background