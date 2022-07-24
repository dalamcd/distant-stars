local gamestate = require('gamestate/gamestate')

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
end

function gamestate.static:getMapState(map, camera, passthrough)
	passthrough = passthrough or false

	function loadFunc(gself)

		gself.map = map
		gself.map.camera = camera
		local b = background:new(500)
		gself.background = b
		--setBackground(b)

		local ctx = context:new(font)
		setGameContext(ctx)
	end

	function drawFunc(gself)
		gself.background:draw()
		gself.map:draw()
		getGameContext():draw()
	end

	function inputFunc(gself, input)
		keysdown(gself)
		if input.wheelmoved then
			wheelmoved(gself, input.wheelmoved.x, input.wheelmoved.y)
		end
	end

	function updateFunc(gself, dt)
		local rx, ry = getMousePos()
		d:updateTextField("Tile under mouse", tostring(gself.map:getTileAtWorld(rx, ry)))
		
		local rx, ry = getMousePos()
		local objStr = ""
		local objects = gself.map:getObjectsAtWorld(rx, ry)
		for idx, obj in ipairs(objects) do
			if idx ~= #objects then
				objStr = objStr .. tostring(obj) .. ", "
			else
				objStr = objStr .. tostring(obj)
			end
		end
		
		d:updateTextField("Objects under mouse", objStr)
		getGameContext():update()

		if not paused then
			gself.background:update(dt)
		
			for _, e in ipairs(gself.map.entities) do
				e:update(dt)
			end
			for _, f in ipairs(gself.map.furniture) do
				f:update(dt)
			end
			for _, i in ipairs(gself.map.items) do
				i:update(dt)
			end
		end
	end

	local gs = gamestate:new("new map", loadFunc, updateFunc, drawFunc, nil, inputFunc, passthrough, passthrough)
	return gs
end