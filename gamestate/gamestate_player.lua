local class = require('lib.middleclass')
local gamestate = require('gamestate.gamestate')
local fade = require('gamestate.gamestate_fade')
local inspector = require('gamestate.gamestate_inspector')
local context = require('context')
local camera = require('camera')
local furniture = require('furniture.furniture')
local unfinished = require('furniture.unfinished')
local ghost = require('ghost')
local hull = require('furniture.hull')
local entity = require('entities.entity')
local data = require('data')
local labeledGraphicButton = require('gui.labeledGraphicButton')
local graphicButton = require('gui.graphicButton')
local transTask = require('tasks.task_entity_map_trans')
local installTask = require('tasks.task_entity_install')
local map = require('map.map')
local gui = require('gui.gui')
local dropdown = require('gui.dropdown')
local bundle = require('items.bundle')
local event = require('event')

local playerstate = class('playerstate', gamestate)

function playerstate:initialize()

	local c = camera:new()

	self.label = "base playerstate"
	self.camera = c
	self.maps = {}
	self.mapButtons = {}
	self.context = nil
	self.currentMap = nil
	self.ghost = nil
	self.selection = nil
	self.selectionBoxWidth = 300
	self.selectionBoxHeight = 100
	self.selectionBoxX = love.graphics.getWidth() - self.selectionBoxWidth
	self.selectionBoxY = love.graphics.getHeight() - self.selectionBoxHeight
	self.selectionBoxPadding = 10
	self.selectionItems = 0

	event:addListener(
		"fart",
		function(evt)
			print(evt.payload.label .. " farted and it was so bad the playerstate noticed")
		end
		)

	event:addListener(
		"base_event_buildRequested",
		function(evt)
			self.ghost = ghost:new(evt.payload.bundle.data, "build ghost")
			self.ghost.bundle = evt.payload.bundle
			self.ghost.map = evt.payload.map
			self.ghost.entity = evt.payload.entity
		end
	)

	event:addListener(
		"base_event_buildSubmitted",
		function(evt)
			local unf = unfinished:new(evt.payload.bundle.data.name, evt.payload.bundle.label, evt.payload.map, evt.payload.tile.x - evt.payload.map.xOffset, evt.payload.tile.y - evt.payload.map.yOffset)
			unf:rotate(evt.payload.bundle.rotation)
			local walkTile = unf:getWalkableTileAround()
			local insTask = installTask:new(evt.payload.bundle, walkTile, evt.payload.map, unf)
			evt.payload.map:addFurniture(unf)
			evt.payload.entity:pushTask(insTask)
			-- local f = self.ghost:convertToMapObject(pay.label, pay.map, pay.x, pay.y)
			-- self.currentMap:addFurniture(f)
		end
	)

	gamestate.initialize(self, "playerstate", nil, nil, nil, nil, nil, true, true)
end

function playerstate:update(dt)
	-- Update debug text area
	if self.currentMap then
		local rx, ry = gui:getMousePos()
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

	if self.context then
		if self.context.selected then
			self.context:update(dt)
		else
			self.context = nil
		end
	end

	if self.ghost then
		self.ghost:update(dt)
	end

	self.camera:update(dt)

	for _, m in ipairs(self.maps) do
		m:update(dt)
	end
end

function playerstate:draw()
	local mx, my = gui:getMousePos()

	if self.background then
		self.background:draw()
	end
	for _, m in ipairs(self.maps) do
		m:draw()
	end
	for _, mapButton in ipairs(self.mapButtons) do
		mapButton:draw()
	end

	if self.selection then
		self:drawSelectionBox()
		self:drawSelectionDetails()
	end
	self:drawRoomDetails()

	if self.context then
		self.context:draw()
	end

	if self.ghost then
		self.ghost:draw(mx, my, self.camera.scale)
	end

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
		local t = self.currentMap:getTileAtWorld(gui:getMousePos())
		if t then
			local r = self.currentMap:inRoom(t.x, t.y)
			if r then
				local x = love.graphics.getWidth() - 200
				local y = 20
				gui:drawRect(x, 20, 180, 100)
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
		local c = self.camera
		gui:drawRect(c:getRelativeX(self.selection:getWorldX()), c:getRelativeY(self.selection:getWorldY()),
					c.scale*self.selection.spriteWidth, c.scale*self.selection.spriteHeight, {0,0,0,0})
	end
end

function playerstate:drawSelectionDetails()

	gui:drawRect(self.selectionBoxX - self.selectionBoxPadding,
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
		t = self.currentMap:getTileAtWorld(gui:getMousePos())
		e = self.currentMap:getEntitiesAtWorld(gui:getMousePos())[1]
		i = self.currentMap:getItemsAtWorld(gui:getMousePos())[1]
		f = self.currentMap:getFurnitureAtWorld(gui:getMousePos())[1]
		s = self.currentMap:getStockpileAtWorld(gui:getMousePos())
	end
	if key =='g' and e then
		e:die("removed with extreme prejudice")
	end

	if key == 'f' and t then
		local ent = entity:new("pawn", data:getBase():getRandomFullName(), self.currentMap, t.x - self.currentMap.xOffset, t.y - self.currentMap.yOffset)
		self.currentMap:addEntity(ent)
	end

	if key == 'n' and t then
		local bund = bundle:new(furniture:retrieve("dresser"), "nice dresser", self.currentMap, 5, 2)
		self.currentMap:addItem(bund)
	end

	if key == 'm' and t then
		local bund = bundle:new(furniture:retrieve("bigthing"), "nice dresser", self.currentMap, 6, 2)
		self.currentMap:addItem(bund)
	end

	-- if key == 'm' and i and i:isType('bundle') then
	-- 	self.ghost = ghost:new(i.data, i.label)
	-- end

	if key == 'j' and e then
		e:fart()
	end

	if key == 'u' then
		local unf = unfinished:new("bigthing", "dresser", self.currentMap, 6, 7)
		self.currentMap:addFurniture(unf)
	end

	if key == 'y' and f then
		if f:isType('unfinished') then
			local unf = f:convertToFurniture()
			self.currentMap:addFurniture(unf)
		end
	end

	if key == 'r' then
		-- local m = map:new("loaded map", 0, 0)
		-- m:loadMapTable("shipdata.lua")
		-- self:addMap(m)
		if self.ghost then self.ghost:rotate() end
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
		t = self.currentMap:getTileAtWorld(gui:getMousePos())
		objects = self.currentMap:getObjectsAtWorld(gui:getMousePos())
	end
	if not self.ct then self.ct = t end
	if not self.cti then self.cti = 1 end

	if button == 1 then
		local thisMap = self.currentMap

		if self.ghost and t then
			bundle.rotation = self.ghost.rotation
			local evt = event:new({bundle=self.ghost.bundle, map=self.ghost.map, entity=self.ghost.entity, tile=t})
			event:dispatchEvent("base_event_buildSubmitted", evt)
			self.ghost = nil
			-- local f = self.ghost:convertToMapObject("test", self.currentMap, t.x - self.currentMap.xOffset, t.y - self.currentMap.yOffset)
			-- self.currentMap:addFurniture(f)
		end

		if self.context then
			self.context:mousereleased(x, y, button)
			return
		end

		for _, mb in ipairs(self.mapButtons) do
			if mb:inBounds(gui:getMousePos()) then
				mb:clickFunc()
				return
			end
		end

		for _, m in ipairs(self.maps) do
			if m:inBounds(gui:getMousePos()) and (not thisMap or m.uid ~= thisMap.uid) then
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
			-- elseif self.context.active and self.context:inBounds(x, y) then
			-- 	self.context:handleClick(x, y)
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
			self.context = context:new(x, y, 1, 1, tlist, selection, {0.1, 0.1, 0.1, 0.75})
			self.context.state = self
		end

		if self.ghost then
			self.ghost = nil
		end
	end

	if button == 3 then
		if t then
			local objs = self.currentMap:getObjectsInTile(t)
			if #objs > 0 then
				local ins = inspector:new(objs[1])
				local f = gamestate:getFadeState()
				gamestate:push(f)
				gamestate:push(ins)
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

function playerstate:addMap(mapObj)
	mapObj.camera = self.camera
	table.insert(self.maps, mapObj)
	self:addMapButton(mapObj)
end

function playerstate:removeMap(mapObj)
	for idx, m in ipairs(self.maps) do
		if m.uid == mapObj.uid then
			table.remove(self.maps, idx)
			break
		end
	end
end

function playerstate:addMapButton(mapObj)

	local function clickFunc()
		self:setCurrentMap(mapObj)
	end

	local width, height = 150, 90
	local x, y = 20, 30 + (height + 10)*#self.mapButtons
	local button = labeledGraphicButton:new(x, y, width, height, mapObj.label, mapObj.tileset, mapObj.sprite, clickFunc)
	table.insert(self.mapButtons, button)
end

function playerstate:setCurrentMap(mapObj)
	if self.currentMap then self.currentMap:deselect() end
	self.currentMap = mapObj
	self.currentMap:select()
	local t = self.currentMap:getCentermostTile()
	self.camera:translate(t:getWorldCenterX(), t:getWorldCenterY(), 1.25)
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