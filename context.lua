local class = require('middleclass')
local game = require('game')
local gui = require('gui')

context = class('context')

local innerPadding = 5
local bottomPadding = 3
local textTopPadding = 5
local textInnerPadding = 3

function context:initialize(font)
	font = font or love.graphics.getFont()
	self.font = font
	self.opacity = 1
end

function context:set(x, y, items)

	if not items or #items == 0 then 
		self:clear()
		return 
	end

	self.x = x
	self.y = y
	self.items = items

	local longest = 0
	local txt = ""
	for i, item in ipairs(self.items) do
		item.highlight = false
		item.left = 0
		item.top = 0
		item.right = 0
		item.bottom = 0

		if #item:getContext() > longest then
			longest = #item:getContext()
			txt = item:getContext()
		end
	end
	love.graphics.setFont(self.font)
	self.txtWidth = love.graphics.getFont():getWidth(txt)
	self.fontHeight = love.graphics:getFont():getHeight()
	self.txtHeight = (#items)*(self.fontHeight + textTopPadding) + bottomPadding
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
	self.fontHeight = 0
	self.opacity = 1
end

function context:handleClick(x, y)
	for i, item in ipairs(self.items) do
		if self:inBounds(x, y, item) then
			getMouseSelection():setTask(item)
			self:clear()
		end
	end
end

function context:update()
	if self.active then
		local mx, my = love.mouse.getPosition()
		if self:inBounds(mx, my) then
			self.opacity = 1
		else
			local falloff = 20
			local left = self.x - mx - falloff
			local top = self.y - my - falloff
			local right = self.x + self.txtWidth + falloff - mx
			local bottom = self.y + self.txtHeight + falloff - my
			local dx, dy = 0, 0
			
			if left > 0 then dx = left end
			if right < 0 then dx = right end
			if top > 0 then dy = top end
			if bottom < 0 then dy = bottom end

			local dist = math.sqrt(dx^2 + dy^2)
			if dist < falloff then
				self.opacity = 1
			end
			if dist > 50 then
				self:clear()
			else
				self.opacity = 1/math.sqrt(dist)
			end
		end

		for _, item in ipairs(self.items) do
			if self:inBounds(mx, my, item) then
				item.highlight = true
			else
				item.highlight = false
			end
		end
	end
end

function context:inBounds(x, y, item)
	item = item or nil
	if not item then
		if(x - self.x <= self.txtWidth and x - self.x >= 0) then
			if(y - self.y <= self.txtHeight and y - self.y >= 0) then
				return true
			end
		end
	else
		if(x - item.left <= item.right and x - item.left >= 0) then
			if(y - item.top <= item.bottom and y - item.top >= 0) then
				return true
			end
		end
	end
	return false
end

function context:draw()

	if self.active then
		drawRect(self.x, self.y, self.txtWidth + innerPadding*2, self.txtHeight + bottomPadding, nil, nil, nil, self.opacity)
		for i, item in ipairs(self.items) do
			self:drawMenuItem(item, i)
		end
	end
end

function context:drawMenuItem(item, index)

	item.left = self.x + innerPadding
	item.top = self.y + (index-1)*(self.fontHeight + textTopPadding)
	item.right = self.txtWidth + textInnerPadding*2
	item.bottom = self.fontHeight + textTopPadding

	if item.highlight then
		drawRect(item.left, item.top, item.right, item.bottom, 0.15, 0.15, 0.15, self.opacity)
	else
		drawRect(item.left, item.top, item.right, item.bottom, nil, nil, nil, self.opacity)
	end

	love.graphics.setFont(self.font)
	love.graphics.setColor(1, 1, 1, self.opacity)
	love.graphics.print(item:getContext(), item.left + textInnerPadding, item.top)
	love.graphics.reset()

end

return context