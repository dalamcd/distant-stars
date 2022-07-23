local class = require('middleclass')

gamestate = class('gamestate')

gamestate.static._stack = {}
gamestate.static._drawStack = {}
gamestate.static._updateStack = {}

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
	local gs = table.remove(self._stack)
	local tmp = self._stack[#self._stack]
	if tmp then
		tmp.top = true
	end
	self:rebuild()
	return gs
end

function gamestate.static:rebuild()

	local g = self._stack[#self._stack]

	-- Clear the update and draw stacks
	for i=0, #self._updateStack do self._updateStack[i]=nil end
	for i=0, #self._drawStack do self._drawStack[i]=nil end

	-- Always update and draw the topmost state
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
	for i=#self._updateStack, 1, -1 do
		self._updateStack[i]:update(dt)
	end
end

function gamestate.static:draw()
	for i=#self._drawStack, 1, -1 do
		love.graphics.reset()
		self._drawStack[i]:draw()
	end
end

function gamestate:initialize(name, loadFunc, updateFunc, drawFunc, exitFunc, updateBelow, drawBelow)

	name = name or "unknown gamestate"
	loadFunc = loadFunc or function () return end
	updateFunc = updateFunc or function () return end
	drawFunc = drawFunc or function () return end
	exitFunc = exitFunc or function () return end

	updateBelow = updateBelow or false
	drawBelow = drawBelow or false

	self.uid = getUID()
	self.name = name
	self.loadFunc = loadFunc
	self.updateFunc = updateFunc
	self.drawFunc = drawFunc
	self.exitFunc = exitFunc
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