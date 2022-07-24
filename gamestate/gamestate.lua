local class = require('middleclass')

gamestate = class('gamestate')

gamestate.static._stack = {}
gamestate.static._drawStack = {}
gamestate.static._updateStack = {}
gamestate.static._input = {}

function gamestate.static:push(gs)
	local tmp = self._stack[#self._stack]
	if tmp then
		tmp.parent = gs
		gs.child = tmp
		tmp.top = false
	end
	gs.top = true
	table.insert(self._stack, gs)

	self:rebuild()
end

function gamestate.static:pop()
	local peek = self._stack[#self._stack]
	if #self._stack > 1 then
		local gs = table.remove(self._stack)
		if peek then
			self._stack[#self._stack].top = true
		end
		self:rebuild()
		return gs
	else
		return peek
	end
end

function gamestate.static:rebuild()

	-- Clear the update and draw stacks
	for i=0, #self._updateStack do self._updateStack[i]=nil end
	for i=0, #self._drawStack do self._drawStack[i]=nil end
	
	-- Always update and draw the topmost state
	local g = self._stack[#self._stack]
	table.insert(self._updateStack, g)
	table.insert(self._drawStack, g)

	for i=#self._stack, 1, -1 do
		if self._stack[i-1] and self._stack[i].updateBelow then
			table.insert(self._updateStack, self._stack[i-1])
		else
			break
		end
	end

	for i=#self._stack, 1, -1 do
		if self._stack[i-1] and self._stack[i].drawBelow then
			table.insert(self._drawStack, self._stack[i-1])
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
	
	for i=#self._updateStack, 1, -1 do
		self._updateStack[i]:update(dt)
	end

	for k, _ in pairs(self._input) do
		self._input[k] = nil
	end
end

function gamestate.static:draw()
	for i=#self._drawStack, 1, -1 do
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

return gamestate