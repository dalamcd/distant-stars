local gamestate = require('gamestate.gamestate')
local context = require('context')
local furniture = require('furniture.furniture')
local ghost = require('furniture.ghost')
local hull = require('furniture.hull')

-- TODO Maximum velocity for map movement, need to think about what to do about this and other basic constants
local MAX_VEL = 3

local function wheelmoved(gself, x, y)
	if y > 0 then
		for i=1, y do
			gself.map.camera:zoomIn()
		end
	elseif y < 0 then
		for i=1, math.abs(y) do
			gself.map.camera:zoomOut()
		end
	end
end

local function keypressed(gself, key)
	local t = gself.map:getTileAtWorld(getMousePos(gself.map.camera))
	local e = gself.map:getEntitiesAtWorld(getMousePos(gself.map.camera))[1]
	local i = gself.map:getItemsAtWorld(getMousePos(gself.map.camera))[1]
	local f = gself.map:getFurnitureAtWorld(getMousePos(gself.map.camera))[1]
	local s = gself.map:getStockpileAtWorld(getMousePos(gself.map.camera))

	if key == 'e' then
		if t then
			local g = ghost:new(hull, "hull", gself.map, t.x, t.y)
			gself.ghost = g
		end
	elseif key == 'r' then
		if gself.ghost then
			gself.ghost:rotate()
		end
	end

	if key == 'q' then
		if gself.ghost then
			gself.ghost:place()
		end
	end

	if key =='t' and i and gself.map:getMouseSelection():isType("item") then
		gself.map:getMouseSelection():mergeWith(i)
	end
end

local function mousereleased(gself, x, y, button)
	local t = gself.map:getTileAtWorld(getMousePos(gself.map.camera))
	local e = gself.map:getEntitiesAtWorld(getMousePos(gself.map.camera))[1]
	local i = gself.map:getItemsAtWorld(getMousePos(gself.map.camera))[1]
	local f = gself.map:getFurnitureAtWorld(getMousePos(gself.map.camera))[1]
	local s = gself.map:getStockpileAtWorld(getMousePos(gself.map.camera))

	if button == 1 then
		local msg = gself.map.alert:inBounds(x, y)
		if msg then
			gself.map.alert:removeAlert(msg)
		elseif gself.context.active and gself.context:inBounds(x, y) then
			gself.context:handleClick(x, y)
		else
			if s then gself.map.mouseSelection = s end
			if f then gself.map.mouseSelection = f end
			if i then gself.map.mouseSelection = i end
			if e then gself.map.mouseSelection = e end
		end
	end

	if button == 2 then
		local selection = gself.map:getMouseSelection()
		if selection and t and selection:isType("entity") and selection.map.uid == t.map.uid then
			local tlist = gself.map:getPossibleTasks(t, selection)
			gself.context:set(x, y, tlist)
		end
	end

	if button == 4 then
		-- for i, r in ipairs(gself.map.rooms) do
		-- 	print(i, #r.tiles)
		-- end
		for _, r in ipairs(gself.map.rooms) do
			r:listAttributes()
		end
	end
end

local function keysdown(gself)
	if love.keyboard.isDown('w') then
		gself.map.camera:moveYOffset(5*gself.map.camera.scale)
	end
	if love.keyboard.isDown('a') then
		gself.map.camera:moveXOffset(5*gself.map.camera.scale)
	end
	if love.keyboard.isDown('s') then
		gself.map.camera:moveYOffset(-5*gself.map.camera.scale)
	end
	if love.keyboard.isDown('d') then
		gself.map.camera:moveXOffset(-5*gself.map.camera.scale)
	end

	if love.keyboard.isDown('l') and gself.top then
		gself.map.velX = clamp(gself.map.velX + 0.1, -MAX_VEL, MAX_VEL)
	end
	if love.keyboard.isDown('k') and gself.top then
		gself.map.velY = clamp(gself.map.velY + 0.1, -MAX_VEL, MAX_VEL)
	end
	if love.keyboard.isDown('j') and gself.top then
		gself.map.velX = clamp(gself.map.velX - 0.1, -MAX_VEL, MAX_VEL)
	end
	if love.keyboard.isDown('i') and gself.top then
		gself.map.velY = clamp(gself.map.velY - 0.1, -MAX_VEL, MAX_VEL)
	end
end

function gamestate.static:getMapState(name, map, camera, passthrough)
	passthrough = passthrough or false

	local function loadFunc(gself)

		gself.name = name
		gself.map = map
		gself.map.camera = camera
		gself.context = context:new(gself.map)
		gself.ghost = nil

		if not passthrough then
			--local b = background:new(500)
			--gself.background = b
		end

		local ctx = context:new()
		setGameContext(ctx)
	end

	local function drawFunc(gself)
		if gself.background then
			gself.background:draw()
		end
		gself.map:draw()
		if gself.ghost then
			gself.ghost:draw()
		end
		gself.context:draw()
	end

	local function inputFunc(gself, input)
		keysdown(gself)
		if input.mousereleased then
			mousereleased(gself, input.mousereleased.x, input.mousereleased.y, input.mousereleased.button)
		end
		if input.keypressed then
			keypressed(gself, input.keypressed.key)
		end
		if input.wheelmoved then
			wheelmoved(gself, input.wheelmoved.x, input.wheelmoved.y)
		end
		if gself.updateBelow and gself.child then
			gself.child:inputFunc(input)
		end
	end

	local function updateFunc(gself, dt)
		local rx, ry = getMousePos(gself.map.camera)
		d:updateTextField("Tile under mouse", tostring(gself.map:getTileAtWorld(rx, ry)))

		local objStr = ""
		local objects = gself.map:getObjectsAtWorld(rx, ry)
		for idx, obj in ipairs(objects) do
			if idx ~= #objects then
				objStr = objStr .. tostring(obj) .. ", "
			else
				objStr = objStr .. tostring(obj)
			end
		end

		if gself.background then
			gself.background:update(dt)
		end

		if gself.ghost then
			gself.ghost:update(self, dt)
		end

		d:updateTextField("Objects under mouse", objStr)
		gself.context:update()

		gself.map:update(dt)
	end

	local gs = gamestate:new(name, loadFunc, updateFunc, drawFunc, nil, inputFunc, passthrough, passthrough)
	return gs
end