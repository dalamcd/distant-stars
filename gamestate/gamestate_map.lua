local gamestate = require('gamestate/gamestate')

function loadFunc(gself)

	local m = map:new()
	m:load('newmap.txt')
	setGameMap(m)
	gself.m = m

	local p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Dylan", 6, 7)
	m:addEntity(p)

	p = entity:new("entity", 0, 0, TILE_SIZE, TILE_SIZE, "Barnaby", 4, 5)
	m:addEntity(p)

	p = entity:new("entity", TILE_SIZE*2, 0, TILE_SIZE, TILE_SIZE + 9, "Diocletian", 6, 3)
	m:addEntity(p)
	
	p = entity:new("entity", TILE_SIZE*4, 0, TILE_SIZE*2, TILE_SIZE+10, "cow", 8, 5)
	m:addEntity(p)
	
	local i = item:new("item", 0, 0, TILE_SIZE, TILE_SIZE, "yummy chicken", 2, 7)
	m:addItem(i)

	i = item:new("item", TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, "yummy pizza", 3, 8)
	m:addItem(i)
	
	--i = item:new("item", TILE_SIZE*2, 0, TILE_SIZE + 15, TILE_SIZE*2, "street light", 2, 10)
	--m:addItem(i)
	
	local f = furniture:new("furniture", 0, 0, TILE_SIZE*2, TILE_SIZE+14, "dresser", 7, 2, 2, 1)
	m:addFurniture(f)

	local tmp = m:getTilesInRectangle(2, 5, 3, 3)
	table.insert(tmp, m:getTile(8, 7))

	local sp = stockpile:new(tmp, "new stockpile")
	m:addStockpile(sp)

	local b = background:new(500)
	setBackground(b)

	local ctx = context:new(font)
	setGameContext(ctx)
end

function drawFunc(gself)
	getBackground():draw()
	gself.m:draw()
	getGameContext():draw()
end

function updateFunc(gself, dt)
	local rx, ry = getMousePos()
	d:updateTextField("Objects under mouse", objStr)
	d:updateTextField("Tile under mouse", tostring(gself.m:getTileAtWorld(rx, ry)))
	
	local rx, ry = getMousePos()
	local objStr = ""
	local objects = gself.m:getObjectsAtWorld(rx, ry)
	for idx, obj in ipairs(objects) do
		if idx ~= #objects then
			objStr = objStr .. tostring(obj) .. ", "
		else
			objStr = objStr .. tostring(obj)
		end
	end

	getGameContext():update()

	if not paused then
		getBackground():update(dt)
	
		for _, e in ipairs(gself.m.entities) do
			e:update(dt)
		end
		for _, f in ipairs(gself.m.furniture) do
			f:update(dt)
		end
		for _, i in ipairs(gself.m.items) do
			i:update(dt)
		end
	end
end

local gs = gamestate:new("new map", loadFunc, updateFunc, drawFunc, nil, nil, false, false)
return gs