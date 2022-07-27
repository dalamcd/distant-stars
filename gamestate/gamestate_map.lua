local gamestate = require('gamestate/gamestate')
local context = require('context')
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
end

local function mousereleased(gself, x, y, button)
	local t = gself.map:getTileAtWorld(getMousePos(gself.map.camera))
	local e = gself.map:getEntitiesAtWorld(getMousePos(gself.map.camera))[1]
	local i = gself.map:getItemsAtWorld(getMousePos(gself.map.camera))[1]
	local f = gself.map:getFurnitureAtWorld(getMousePos(gself.map.camera))[1]
	local s = gself.map:getStockpileAtWorld(getMousePos(gself.map.camera))

	if button == 1 then
		if getGameContext().active and getGameContext():inBounds(x, y) then
			getGameContext():handleClick(x, y)
		else
			if s then setMouseSelection(s) end
			if f then setMouseSelection(f) end
			if i then setMouseSelection(i) end
			if e then setMouseSelection(e) end
		end
	end

	if button == 2 then
		if getMouseSelection() and t and getMouseSelection():isType("entity") then
			local tlist = gself.map:getPossibleTasks(t, getMouseSelection())
			getGameContext():set(x, y, tlist)
		end
	end

	if button == 4 then
		for i, r in ipairs(gself.map.rooms) do
			print(i, #r.tiles)
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
		if not passthrough then
			local b = background:new(500)
			gself.background = b
		end

		local ctx = context:new()
		setGameContext(ctx)
	end

	local function drawFunc(gself)
		if gself.background then
			gself.background:draw()
		end
		gself.map:draw()
		getGameContext():draw()
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

		d:updateTextField("Objects under mouse", objStr)
		getGameContext():update()

		gself.map:update(dt)
	end

	local gs = gamestate:new(name, loadFunc, updateFunc, drawFunc, nil, inputFunc, passthrough, passthrough)
	return gs
end