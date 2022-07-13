local class = require('middleclass')
local game = require('game')

context = class('context')

local yPadding = 5
local xPadding = 5
local textPadding = 5

function context:initialize(font)
	font = font or love.graphics.getFont()
	self.font = font
	self.opacity = 1
end

function context:set(x, y, items)
	self.x = x
	self.y = y
	self.items = items

	local longest = 0
	local txt = ""
	for i, item in ipairs(items) do
		if #item > longest then
			longest = #item
			txt = item
		end
	end
	love.graphics.setFont(self.font)
	self.txtWidth = love.graphics.getFont():getWidth(txt)
	self.fontHeight = love.graphics:getFont():getHeight()
	self.txtHeight = (#items)*(self.fontHeight + textPadding)
	self.active = true
	love.graphics.reset()
end

function context:clear()
	self.active = false
	self.x = 0
	self.y = 0
	self.items = {}
	self.txtWidth = 0
	self.txtHeight = 0
	self.opacity = 1
end

function context:update()
	if self.active then
		local mx, my = love.mouse.getPosition()
		if self:inBounds(mx, my) then
			self.opacity = 1
		else
			local left = self.x - mx
			local top = self.y - my
			local right = self.x + self.txtWidth - mx
			local bottom = self.y + self.txtHeight - my
			local dx, dy = 0, 0
			
			if left > 0 then dx = left end
			if right < 0 then dx = right end
			if top > 0 then dy = top end
			if bottom < 0 then dy = bottom end

			local dist = math.sqrt(dx^2 + dy^2)

			if dist > 100 then
				self:clear()
			elseif dist > 30 then
				self.opacity = 1/math.sqrt(dist - 30)
			end
		end
	end
end

function context:inBounds(x, y)
	if(x - self.x <= self.txtWidth and x - self.x >= 0) then
		if(y - self.y <= self.txtHeight and y - self.y >= 0) then
			return true
		end
	end
	return false
end

function context:draw()
	if self.active then
		love.graphics.setColor(1, 1, 1, self.opacity)
		love.graphics.rectangle("line",
								self.x,
								self.y,
								self.txtWidth + xPadding*2,
								self.txtHeight + yPadding*1)
		
		love.graphics.setColor(0, 0, 0, self.opacity)

		love.graphics.rectangle("fill",
								self.x + 1,
								self.y + 1,
								self.txtWidth + xPadding*2 - 1,
								self.txtHeight + yPadding*1 - 1)
		love.graphics.reset()
		love.graphics.setColor(1, 1, 1, self.opacity)
		love.graphics.setFont(self.font)
		for i, item in ipairs(self.items) do
			love.graphics.print(item, self.x + xPadding, self.y + (i-1)*(self.fontHeight + textPadding) + yPadding)
		end
		love.graphics.reset()
	end
end

return context