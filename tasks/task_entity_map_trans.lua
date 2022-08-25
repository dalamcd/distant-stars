local class = require('lib.middleclass')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local sitTask = require('tasks.task_entity_sit')
local timer = require('timer')
local drawable = require('drawable')

local transTask = class('transTask', task)

local function startFunc(self)
	if self.entity.x ~= self.thisTile.x or self.entity.y ~= self.thisTile.y then
		local wt = walkTask:new(self.entity.map:getTile(self.thisTile.x, self.thisTile.y), self)
		self.entity:pushTask(wt)
	else
		self:complete()
	end
end

local function runFunc(self)
	if not self.entity.walking and self.entity.x == self.entity.destination.x and self.entity.y == self.entity.destination.y then
		self:complete()
	end
end

local function endFunc(self)
	self.entity.map:removeEntity(self.entity)
	self.entity.x = self.thatTile.x - self.thatMap.xOffset
	self.entity.y = self.thatTile.y - self.thatMap.yOffset
	self.thatMap:addEntity(self.entity)
end

local function abandonFunc(self)

end

-- local function strFunc(self)

-- end

local function contextFunc(self)
	return "<transition between maps>"
end

local function initFunc(self)
	if self.thisTile.x ~= self.thatTile.x and self.thisTile.y ~= self.thatTile.y then
		print("trans task tiles do not align for transition")
		self:abandon()
		self:complete()
	end

	self.dy, self.dx = 0, 0
	if self.thisTile.x == self.thatTile.x then
		self.dy = self.thisTile.y - self.thatTile.y
		if self.dy < -1 or self.dy > 1 then
			print("trans task aligns along x axis but is greater than 1 tile away from destination along y axis")
			self:abandon()
			self:complete()
		end
	end

	if self.thisTile.y == self.thatTile.y then
		self.dx = self.thisTile.x - self.thatTile.x
		if self.dx < -1 or self.dx > 1 then
			print("trans task aligns along y axis but is greater than 1 tile away from destination along x axis")
			self:abandon()
			self:complete()
		end
	end
end

---comment require a reference to the destination map, and the tiles from current map and destination map
function transTask:initialize(map, thisTile, thatTile, parentTask)
	if not map then error("transTask initialized with no map") end
	print(thisTile, thatTile)
	if not thisTile or not thatTile then error("transTask initialized with out one or both destination tiles") end

	self.thatMap = map
	self.thisTile = thisTile
	self.thatTile = thatTile
	task.initialize(self, nil, contextFunc, nil, initFunc, startFunc, runFunc, endFunc, abandonFunc, parentTask)
end

return transTask