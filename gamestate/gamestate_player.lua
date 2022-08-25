local class = require('lib.middleclass')
local gamestate = require('gamestate.gamestate')
local context = require('context')
local camera = require('camera')
local furniture = require('furniture.furniture')
local ghost = require('furniture.ghost')
local hull = require('furniture.hull')
local entity = require('entities.entity')
local data = require('data')
local graphicButton = require('graphicButton')
local transTask = require('tasks.task_entity_map_trans')

local playerstate = class('playerstate', gamestate)

function playerstate:initialize()

	local c = camera:new()

	self.label = "base playerstate"
	self.camera = c
	self.maps = {}
	self.mapButtons = {}
	self.context = context:new(self)
	self.currentMap = nil
	self.ghost = nil
	self.selection = nil
	self.selectionBoxWidth = 300
	self.selectionBoxHeight = 100
	self.selectionBoxX = love.graphics.getWidth() - self.selectionBoxWidth
	self.selectionBoxY = love.graphics.getHeight() - self.selectionBoxHeight
	self.selectionBoxPadding = 10
	self.selectionItems = 0

	gamestate.initialize(self, "playerstate", nil, nil, nil, nil, nil, true, true)
end

function playerstate:update(dt)
	if self.currentMap then
		local rx, ry = getMousePos()
		d:updateTextField("Tile under mouse", "")
		d:updateTextField("Map under mouse", "")

		local cnt = 0
		for _, m in ipairs(self.maps) do
			if m:inBounds(rx, ry) then
				cnt = cnt + 1
				d:updateTextField("Tile under mouse", tostring(self.currentMap:getTileAtWorld(rx, ry)))
				d:updateTextField("Map under mouse", m.label .. " ("..cnt..")")
			end
		end

		local objStr = ""
		local objects = self.currentMap:getObjectsAtWorld(rx, ry)
		for idx, obj in ipairs(objects) do
			if idx ~= #objects then
				objStr = objStr .. tostring(obj) .. ", "
			else
				objStr = objStr .. tostring(obj)
			end
		end
		d:updateTextField("Objects under mouse", objStr)
	end

	if self.background then
		self.background:update(dt)
	end

	self.context:update(dt)
	self.camera:update(dt)

	for _, map in ipairs(self.maps) do
		map:update(dt)
	end
end

function playerstate:draw()
	if self.background then
		self.background:draw()
	end
	for _, map in ipairs(self.maps) do
		map:draw()
	end
	for _, mapButton in ipairs(self.mapButtons) do
		mapButton:draw()
	end

	if self.selection then
		self:drawSelectionBox()
		self:drawSelectionDetails()
	end
	self:drawRoomDetails()

	self.context:draw()
	self.camera:draw()
end

function playerstate:input(input)
	self:keysdown()
	if input.mousereleased then
		self:mousereleased(input.mousereleased.x, input.mousereleased.y, input.mousereleased.button)
	end
	if input.keypressed then
		self:keypressed(input.keypressed.key)
	end
	if input.wheelmoved then
		self:wheelmoved(input.wheelmoved.x, input.wheelmoved.y)
	end
	if self.updateBelow and self.child then
		self.child:inputFunc(input)
	end
end

function playerstate:drawRoomDetails()
	if self.currentMap then
		local t = self.currentMap:getTileAtWorld(getMousePos())
		if t then
			local r = self.currentMap:inRoom(t.x, t.y)
			if r then
				local x = love.graphics.getWidth() - 200
				local y = 20
				drawRect(x, 20, 180, 100)
				love.graphics.print("Room " .. r.uid, x + 10, y)
				y = y + love.graphics.getFont():getHeight() + 2
				if r.attributes then
					for k, v in pairs(r.attributes) do
						love.graphics.print(v.label..": "..fstr(v:getAmount(), 0), x + 10, y)
						y = y + love.graphics.getFont():getHeight() + 2
					end
				end
			end
		end
	end
end

function playerstate:drawSelectionBox()
	if self.selection:isType('stockpile') then
		self.selection:draw()
	else
		rect("line", self.selection:getWorldX(), self.selection:getWorldY(),
					self.selection.spriteWidth, self.selection.spriteHeight, self.camera)
	end
end

function playerstate:drawSelectionDetails()

	drawRect(self.selectionBoxX -self.selectionBoxPadding,
	self.selectionBoxY - self.selectionBoxPadding,
	self.selectionBoxWidth, self.selectionBoxHeight)
	self.detailIndex = 0

	self:addSelectionDetailText(self.selection.label .."["..self.selection.uid.."]")

	if self.selection:isType("entity") then
		local tlist = self.selection:getTasks()
		local itemNum = 1
		local idleSeconds = math.floor(self.selection.idleTime/60)
		if idleSeconds > 0 then
			self:addSelectionDetailText("Idle for " .. idleSeconds .. " seconds")
		end
		self:addSelectionDetailText("Health: " .. self.selection.health)
		self:addSelectionDetailText("Satiation: " .. self.selection.satiation)
		self:addSelectionDetailText("Comfort: " .. fstr(self.selection.comfort))
		self:addSelectionDetailText("Oxy Starv: " .. fstr(self.selection.oxygenStarvation, 0))

		for i=#tlist, 1, -1 do
			if not tlist[i]:isChild() then
				self:addSelectionDetailText(tlist[i]:getDesc())
			end
		end
	elseif self.selection:isType("stockpile") then
		for i, item in ipairs(self.selection.contents) do
			self:addSelectionDetailText(item.label .. "(" ..item.uid..") " .. #self.selection.contents)
		end
	end
end

function playerstate:addSelectionDetailText(str)
	local f = love.graphics.getFont()
	local x, idx = 0, self.detailIndex
	if self.detailIndex > 5 then
		x = self.selectionBoxWidth/2
		idx = self.detailIndex % 6
	end
	love.graphics.print(str, self.selectionBoxX + x, self.selectionBoxY + f:getHeight()*idx)
	self.detailIndex = self.detailIndex + 1
end

function playerstate:wheelmoved(x, y)
	if y > 0 then
		for i=1, y do
			self.camera:zoomIn()
		end
	elseif y < 0 then
		for i=1, math.abs(y) do
			self.camera:zoomOut()
		end
	end
end

function playerstate:keypressed(key)
	local t, e, i, f, s
	if self.currentMap then
		t = self.currentMap:getTileAtWorld(getMousePos())
		e = self.currentMap:getEntitiesAtWorld(getMousePos())[1]
		i = self.currentMap:getItemsAtWorld(getMousePos())[1]
		f = self.currentMap:getFurnitureAtWorld(getMousePos())[1]
		s = self.currentMap:getStockpileAtWorld(getMousePos())
	end
	if key =='g' and e then
		e:die("removed with extreme prejudice")
	end

	if key == 'f' and t then
		local ent = entity:new("pawn", data:getBase():getRandomFullName(), self.currentMap, t.x - self.currentMap.xOffset, t.y - self.currentMap.yOffset)
		self.currentMap:addEntity(ent)
	end

	if key == '/' and e and #self.maps > 1 then
		-- (5, 11), (6,11)
		local thisShip, thatShip = self.maps[2], self.maps[1]
		local thisTile = thisShip:getTile(5, 11)
		local thatTile = thatShip:getTile(6, 11)
		local tt = transTask:new(thatShip, thisTile, thatTile)
		e:setTask(tt)
	end

	if key == 'up' then
		self.currentMap:setOffset(self.currentMap.xOffset, self.currentMap.yOffset - 1)
	end
	if key == 'down' then
		self.currentMap:setOffset(self.currentMap.xOffset, self.currentMap.yOffset + 1)
	end
	if key == 'left' then
		self.currentMap:setOffset(self.currentMap.xOffset - 1, self.currentMap.yOffset)
	end
	if key == 'right' then
		self.currentMap:setOffset(self.currentMap.xOffset + 1, self.currentMap.yOffset)
	end
end

function playerstate:mousereleased(x, y, button)
	local t, objects
	if self.currentMap then
		t = self.currentMap:getTileAtWorld(getMousePos())
		objects = self.currentMap:getObjectsAtWorld(getMousePos())
	end
	if not self.ct then self.ct = t end
	if not self.cti then self.cti = 1 end

	if button == 1 then
		local thisMap = self.currentMap
		for _, mb in ipairs(self.mapButtons) do
			if mb:inBounds(getMousePos()) then
				mb:clickFunc()
			end
		end

		for _, m in ipairs(self.maps) do
			if m:inBounds(getMousePos()) and (not thisMap or m.uid ~= thisMap.uid) then
				self:clearSelection()
				self:setCurrentMap(m)
				thisMap = false
				break
			end
		end
		if thisMap then
			local msg = self.currentMap.alert:inBounds(x, y)
			if msg then
				self.currentMap.alert:removeAlert(msg)
			elseif self.context.active and self.context:inBounds(x, y) then
				self.context:handleClick(x, y)
			elseif #objects > 0 then
				if self.ct.uid == t.uid then
					if self.cti < #objects then
						self:setSelection(objects[self.cti])
						self.cti = self.cti + 1
					elseif self.cti == #objects then
						self:setSelection(objects[self.cti])
						self.cti = 1
					else
						self.cti = 1
						self:setSelection(objects[self.cti])
					end
				else
					self.cti = 2
					self.ct = t
					self:setSelection(objects[1])
				end
			end
		end
	end

	if button == 2 then
		local selection = self:getSelection()
		if selection and t and selection:isType("entity") and selection.map.uid == self.currentMap.uid then
			local tlist = self.currentMap:getPossibleTasks(t, selection)
			self.context:set(x, y, tlist)
		end
	end

	if button == 3 then
		local t = self.currentMap:getTileAtWorld(getMousePos())
		if t then
			local r = self.currentMap:inRoom(t.x, t.y)
			if r then
				for _, ent in ipairs(r:listEntities()) do
					print(ent.label)
				end
			end
		end
	end

	if button == 4 then
		for i, r in ipairs(self.currentMap.rooms) do
			print(i, #r.tiles)
			r:listAttributes()
		end
	end

end

function playerstate:keysdown()
	if love.keyboard.isDown('w') then
		self.camera:moveYOffset(5*self.camera.scale)
	end
	if love.keyboard.isDown('a') then
		self.camera:moveXOffset(5*self.camera.scale)
	end
	if love.keyboard.isDown('s') then
		self.camera:moveYOffset(-5*self.camera.scale)
	end
	if love.keyboard.isDown('d') then
		self.camera:moveXOffset(-5*self.camera.scale)
	end
end

function playerstate:addMap(map)
	map.camera = self.camera
	table.insert(self.maps, map)
	self:addMapButton(map)
end

function playerstate:removeMap(map)
	for idx, m in ipairs(self.maps) do
		if m.uid == map.uid then
			table.remove(self.maps, idx)
			break
		end
	end
end

function playerstate:addMapButton(map)

	local function clickFunc()
		self:setCurrentMap(map)
	end

	local width, height = 150, 90
	local x, y = 20, 30 + (height + 10)*#self.mapButtons
	local button = graphicButton:new(x, y, width, height, map.label, map.tileset, map.sprite, clickFunc)
	table.insert(self.mapButtons, button)
end

function playerstate:setCurrentMap(map)
	if self.currentMap then self.currentMap:unselect() end
	self.currentMap = map
	self.currentMap:select()
	local t = self.currentMap:getCentermostTile()
	self.camera:translate(t:getWorldCenterX(), t:getWorldCenterY())
end

function playerstate:setSelection(obj)
	if self.selection then
		self.selection:deselect()
	end
	obj:select()
	self.selection = obj
end

function playerstate:clearSelection()
	if self.selection then
		self.selection:deselect()
	end
	self.selection = nil
end

function playerstate:getSelection()
	return self.selection
end

function playerstate:getContext()
	return self.context
end

return playerstate