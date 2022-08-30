local class = require('lib.middleclass')
local game = require('game')
local gui = require('gui.gui')
local dropdown = require('gui.dropdown')

local context = class('context', dropdown)

function context:initialize(x, y, width, height, contents, target, backgroundColor, outlineWidth, outlineColor, textColor)
	if #contents == 0 then return end
	self.target = target
	self.alpha = backgroundColor[4]
	local contextItems = {}
	for _, task in ipairs(contents) do
		local nt = {
			task:getContext(),
			function()
				if love.keyboard.isDown('lshift') then
					self.target:queueTask(task)
				else
					self.target:setTask(task)
				end
				self:deselect()
			end
		}
		table.insert(contextItems, nt)
	end
	dropdown.initialize(self, x, y, width, height, "context menu", contextItems, backgroundColor, outlineWidth, outlineColor, textColor)
	self:select()
end

function context:update(dt)
	if self.selected then
		local mx, my = gui:getMousePos()
		if self:inBounds(mx, my) then
			self:setAlpha(self.alpha)
		else
			local falloff = 15
			local left = self.x - mx - falloff
			local top = self.y - my - falloff
			local right = self.x + self.contentWidth + falloff - mx
			local bottom = self.y + self.contentHeight + falloff - my
			local dx, dy = 0, 0

			if left > 0 then dx = left end
			if right < 0 then dx = right end
			if top > 0 then dy = top end
			if bottom < 0 then dy = bottom end

			local dist = math.sqrt(dx^2 + dy^2)
			if dist > 50 then
				self:deselect()
			elseif dist < falloff then
				self:setAlpha(self.alpha)
			else
				self:setAlpha(1/math.sqrt(dist))
			end
		end

		dropdown.update(self, dt)
	end
end

function context:setAlpha(a)
	self.backgroundColor[4] = a
	self.outlineColor[4] = a
	self.textColor[4] = a
	for _, content in ipairs(self.contents) do
		content.backgroundColor[4] = a
		content.outlineColor[4] = a
		content.textColor[4] = a
	end
end

-- function context:handleClick(x, y)
-- 	local content = self:contentsInBounds(x, y)
-- 	if content then
-- 		if love.keyboard.isDown('lshift') and self.state:getSelection() then
-- 			self.target:queueTask(content)
-- 		else
-- 			self.target:setTask(content)
-- 		end
-- 		self:deselect()
-- 	end
-- end

return context