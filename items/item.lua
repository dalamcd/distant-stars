local class = require('lib.middleclass')
local game = require('game')
local task = require('tasks.task')
local walkTask = require('tasks.task_entity_walk')
local pickupTask = require('tasks.task_item_pickup')
local dropTask = require('tasks.task_item_drop')
local drawable = require('drawable')
local mapObject = require('mapObject')

local item = class('item', mapObject)

item.static._loaded_items = {}

function item.static:load(obj)
	local internalItem = self._loaded_items[obj.name]

	if internalItem then
		return internalItem
	else
		self._loaded_items[obj.name] = obj
	end
end

function item.static:retrieve(name)
	return self._loaded_items[name] or false
end

function item.static:retrieveAll()
	return self._loaded_items
end

function item:initialize(name, label, map, posX, posY)
	local obj = item:retrieve(name)
	if obj then
		mapObject.initialize(self, obj, name, label, map, posX, posY, 1, 1, false)
	else
		error("attempted to initialize " .. name .. " but no item with that name was found")
	end


	self.map = map
	self.amount = obj.amount or 1
	self.maxStack = obj.maxStack or 1
	return obj
end

function item:draw(ent)
	local c = self.map.camera
	local x, y
	if ent then
		x = c:getRelativeX(ent:getWorldX())
		y = c:getRelativeY(ent:getWorldY())
	else
		x = c:getRelativeX(self:getWorldX())
		y = c:getRelativeY(self:getWorldY())
	end
	mapObject.draw(self, x, y, c.scale)
	if self.amount > 1 then
		drawable.drawSubText(self, self.amount, x, y, c.scale)
	end
end

function item:removedFromInventory(entity)
	self.owner = nil
	self.owned = false
	self.x = entity.x
	self.y = entity.y
	self.xOffset = self.origXOffset
	self.yOffset = self.origYOffset
end

function item:addedToInventory(entity)
	self.owner = entity
	self.owned = true
	self.x = entity.x
	self.y = entity.y
end

function item:adjustAmount(amt)
	self.amount = clamp(self.amount + amt, -math.huge, self.maxStack)
	if self.amount <= 0 then
		self:delete()
	end
	return self.amount
end

function item:setAmount(amt)
	self.amount = clamp(amt, -math.huge, self.maxStack)
	if self.amount <= 0 then
		self:delete()
	end
	return self.amount
end

function item:addedToTile()
	for _, mapItem in ipairs(self.map:getItemsInTile(self.map:getTile(self.x, self.y))) do
		if mapItem.uid ~= self.uid then
			local tmp = self:mergeWith(mapItem)
			if tmp ~= 0 then
				local t = self.map:getRandomWalkableTileInRadius(self.x, self.y, 1)
				self.x = t.x
				self.y = t.y
				self:addedToTile()
			end
		end
	end
end

function item:mergeWith(mergeItem)

	if self:getType() ~= mergeItem:getType() or mergeItem.uid == self.uid then return false end

	if self.amount + mergeItem.amount < self.maxStack then
		self:adjustAmount(mergeItem.amount)
		mergeItem:delete()
		return 0
	elseif self.amount < self.maxStack then
		local diff = self.maxStack - self.amount
		mergeItem.amount = mergeItem.amount - (self.maxStack - self.amount)
		self.amount = self.maxStack
		return diff
	end
	return -1
end

function item:split(amt)
	if self.amount >= amt then
		local tmp = self:getClass():new(self.name, self.label, self.map, self.x, self.y, amt)
		self:adjustAmount(-amt)
		return tmp
	else
		print(string.format("tried to split %s into an amount greater than its total (%d > %d)", self.label, amt, self.amount))
		return false
	end
end

function item:delete()
	if self.owned then
		self.owner:removeFromInventory(self)
	end
	if self.map then
		self.map:removeItem(self)
	end
end

function item:getAvailableJobs()
	local tasks = {}
	if not self:isReserved() then
		local sp = self.map:checkStockpileAvailableFor(self)
		if sp and not sp:inStockpile(self) then
			local function startFunc(tself)
				local t = sp:getAvailableTileFor(self)
				if t then
					local p = tself:getParams()
					self:reserveFor(tself.entity)
					t:reserveFor(tself.entity)
					p.pickup = pickupTask:new(self, tself)
					p.drop = dropTask:new(self, t, tself)
					p.dest = t
					if not self.owned then
						tself.entity:pushTask(p.drop)
						tself.entity:pushTask(p.pickup)
					else
						tself.entity:pushTask(p.drop)
					end
				else
					tself:abandon()
					tself:complete()
				end
			end

			local function abandonFunc(tself)
				local p = tself:getParams()
				self:unreserve(tself.entity)
				if p.dest then
					p.dest:unreserve(tself.entity)
				end
			end

			local function endFunc(tself)
				local p = tself:getParams()
				if p.dest then
					p.dest:unreserve(tself.entity)
				end
			end

			local function runFunc(tself)
				local p = tself:getParams()
				if p.dropped then
					self:unreserve(tself.entity)
					p.dest:unreserve(tself.entity)
					tself:complete()
				end
			end

			local function strFunc(tself)
				local p = tself:getParams()
				if not p.dropped and p.dest then
					return "Hauling " .. self.label .. " to tile (".. p.dest.x ..", "..p.dest.y..")"
				else
					return ""
				end
			end

			local haulTask = task:new(nil, nil, strFunc, nil, startFunc, runFunc, endFunc, abandonFunc, nil)
			table.insert(tasks, haulTask)
		end
	end
	return tasks
end

function item:getPossibleTasks()
	local tasks = {}

	if self.owned then return {} end

	local pt = pickupTask:new(self)
	table.insert(tasks, pt)

	return tasks
end

function item:getType()
	return mapObject.getType(self) .. "[[item]][[" .. self.label .. "]]"
end

function item:getClass()
	return item
end

function item:getPluralName()
	return self.label + "s"
end

function item:__tostring()
	return "Item(".. self.amount .. " of " .. self.label .."["..self.uid.."], "..self.x..", "..self.y..")"
end

return item