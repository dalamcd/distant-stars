local class = require('lib.middleclass')

local gamestate = class('gamestate')

gamestate.static._stack = {}
gamestate.static._drawStack = {}
gamestate.static._updateStack = {}
gamestate.static._input = {}

function gamestate.static:peek()
	local peek = self._stack[#self._stack]
	if peek then
		return peek
	end
	error("attempted to peek at an empty stack")
end

function gamestate.static:push(gs)
	local peek = self._stack[#self._stack]
	if peek then
		peek.parent = gs
		gs.child = peek
		peek.top = false
	end
	gs.top = true
	table.insert(self._stack, gs)
	self:rebuild()
	gs:loadFunc()
end

function gamestate.static:pop()
	local peek = self._stack[#self._stack]
	if #self._stack > 0 then
		local gs = table.remove(self._stack)
		if self._stack[#self._stack] then
			self._stack[#self._stack].top = true
		end
		self:rebuild()
		return gs
	else
		return peek
	end
end

function gamestate.static:rebuild()

	self.rebuilt = true
	-- Clear the update and draw stacks
	for i=1, #self._updateStack do self._updateStack[i]=nil end
	for i=1, #self._drawStack do self._drawStack[i]=nil end

	-- Always update and draw the topmost state
	local g = self._stack[#self._stack]
	table.insert(self._updateStack, g)
	table.insert(self._drawStack, g)

	for i=#self._stack, 1, -1 do
		if self._stack[i-1] and self._stack[i].updateBelow then
			table.insert(self._updateStack, 1, self._stack[i-1])
		else
			break
		end
	end

	for i=#self._stack, 1, -1 do
		if self._stack[i-1] and self._stack[i].drawBelow then
			table.insert(self._drawStack, 1, self._stack[i-1])
		else
			break
		end
	end
end

function gamestate.static:update(dt)

	-- Only the topmost state processes inputs
	-- TODO: allow the state to pass input to child states? although this is probably easily doable in the state
	-- itself by accessing the gamestate.child object (which I should test to see if it even works)
	self._updateStack[#self._updateStack]:inputFunc(self._input)

	--update from the top of the stack to the bottom so the most recent stack is always updated first
	for i=#self._updateStack, 1, -1 do
		if not self.rebuilt then
			self._updateStack[i]:update(dt)
		else
			self.rebuilt = false
			self:update(dt)
			return
		end
	end

	for k, _ in pairs(self._input) do
		self._input[k] = nil
	end
end

function gamestate.static:draw()
	--draw from the bottom of the stack to the top so they layer properly
	for i=1, #self._drawStack do
		love.graphics.push("all")
		self._drawStack[i]:draw()
		love.graphics.pop()
	end
end

function gamestate.static:input(name, value)
	self._input[name] = value
end

function gamestate:initialize(name, loadFunc, updateFunc, drawFunc, exitFunc, inputFunc, updateBelow, drawBelow)

	name = name or "unknown gamestate"
	loadFunc = loadFunc or function () return end
	updateFunc = updateFunc or function () return end
	drawFunc = drawFunc or function () return end
	exitFunc = exitFunc or function () return end
	inputFunc = inputFunc or function () return end

	updateBelow = updateBelow or false
	drawBelow = drawBelow or false

	self.uid = getUID()
	self.name = name
	self.loadFunc = loadFunc
	self.updateFunc = updateFunc
	self.drawFunc = drawFunc
	self.exitFunc = exitFunc
	self.inputFunc = inputFunc
	self.updateBelow = updateBelow
	self.drawBelow = drawBelow
	self:loadFunc()
end

function gamestate:update(dt)
	self:updateFunc(dt)
end

function gamestate:draw()
	self:drawFunc()
end

function gamestate:exit()
	self:exitFunc()
end

function gamestate:getName()
	if self.name == "fadestate" then
		if self.child then
			return "fade atop of " .. self.child:getName()
		end
	end

	return self.name
end

return gamestate