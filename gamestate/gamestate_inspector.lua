local class = require('lib.middleclass')
local gamestate = require('gamestate.gamestate')
local gui = require('gui.gui')
local inputField = require('gui.inputField')
local labeledInputField = require('gui.labeledInputField')
local utils = require('utils')
local dropdown = require('gui.dropdown')

local inspector = class('inspector', gamestate)

local function generateInputsForPair(x, y, k, v, count)
	local f = love.graphics.getFont()
	local fields = {}
	if type(v) == "string" then
		local field = labeledInputField:new(x, y, f:getWidth(tostring(v)) + 5, nil, tostring(k))
		field:setText(tostring(v))
		table.insert(fields, field)
		count = count + 1
	end
	if type(v) == "number" then
		local field = labeledInputField:new(x, y, f:getWidth(tostring(v)) + 5, nil, tostring(k), "0123456789.")
		field:setText(tostring(v))
		table.insert(fields, field)
		count = count + 1
	end
	if type(v) == "table" then
		local contents = {}
		for nk, nv in pairs(v) do
			local nt = {nk .. ": " .. tostring(nv), function() print(nv) end}
			table.insert(contents, nt)
		end
		local dd = dropdown:new(x, y, f:getWidth(tostring(v)) + 5, f:getHeight() + 6, "table " .. tostring(k), contents)
		table.insert(fields, dd)
		count = count + 1
	end
	return fields, count
end

local function updateFunc(self, dt)

end

local function drawFunc(self)

	gui:drawRect(30, 30, love.graphics.getWidth() - 60, love.graphics.getHeight() - 60)
	-- Draw in reverse order to dropdowns draw over each other
	for i=#self.inputFields, 1, -1 do
		if self.inputFields[i].y > 30 and self.inputFields[i].y < love.graphics.getHeight() - 60 then
			self.inputFields[i]:draw()
		end
	end
end

local function loadFunc(self)
	self.textX = 35
	self.textY = 35
	local count = 0
	local fields = {}
	for k, v in pairs(self.obj) do
		local f = love.graphics.getFont()
		local x = self.textX
		local y = self.textY + (love.graphics.getFont():getHeight() + 15)*count
		local field, c = generateInputsForPair(x, y, k, v, count)
		count = c
		fields = concatTables(fields, field)
	end
	self.inputFields = concatTables(self.inputFields, fields)
end

local function exitFunc(self)

end

local function inputFunc(self, input)
	local mx, my = gui:getMousePos()

	if self.selectedInput and self.selectedInput.selected and self.selectedInput:isType("labeledInputField") then
		self.selectedInput:handleInput(input)
	end

	if input.keypressed then
		if input.keypressed.key == 'q' then
			gamestate:pop()
		end
	end

	if input.mousereleased then
		if input.mousereleased.button == 1 then

			local inputSelected = false
			for _, field in ipairs(self.inputFields) do
				if field:inBounds(mx, my) then
					field:select()
					self.selectedInput = field
					inputSelected = true
				else
					field:deselect()
				end
			end

			if not inputSelected then
				self.selectedInput = nil
			end
		end
	end

	if input.wheelmoved and self.scrollable then
		local y = input.wheelmoved.y
		if y < 0 then
			for i=1, math.abs(y) do
				local oldOffset = self.scrollOffset
				self.scrollOffset = clamp(self.scrollOffset - 10, -self.maxOffset, 0)
				local diff = self.scrollOffset - oldOffset
				for _, field in ipairs(self.inputFields) do
					field:adjustPos(0, diff)
				end
			end
		elseif y > 0 then
			for i=1, math.abs(y) do
				local oldOffset = self.scrollOffset
				self.scrollOffset = clamp(self.scrollOffset + 10, -self.maxOffset, 0)
				local diff = self.scrollOffset - oldOffset
				for _, field in ipairs(self.inputFields) do
					field:adjustPos(0, diff)
				end
			end
		end
	end
end

function inspector:initialize(obj)
	self.obj = obj
	self.scrollOffset = 0
	self.scrollable = true
	self.maxOffset = math.huge
	self.inputFields = {}

	gamestate.initialize(self, "inspector", loadFunc, updateFunc, drawFunc, exitFunc, inputFunc, false, true)
end

return inspector