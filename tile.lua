local class = require('middleclass')
local game = require('game')

tile = class('tile')

function tile:initialize(tileType, x, y, index)
	
	if tileType == 1 then
		self.sprite = love.graphics.newImage("sprites/metalWall.png")
		self.walkable = false
	elseif tileType == 2 then
		self.sprite = love.graphics.newImage("sprites/metalTile.png")
		self.walkable = true
	else
		love.graphics.newImage("sprites/default.png")
	end

	self.x = x
	self.y = y
	self.index = index

end

function tile:inBounds(x, y)
	if( x - self:getWorldX() <= TILE_SIZE 
      and x - self:getWorldX() >= 0) then
		if( y - self:getWorldY() <= TILE_SIZE
        and y - self:getWorldY() >= 0) then
			return true
		end
	end
	return false
end

function tile:isWalkable()
	return self.walkable
end

function tile:getWorldX()
	return (self.x - 1)*TILE_SIZE
end

function tile:getWorldY()
	return (self.y - 1)*TILE_SIZE
end

function tile:getWorldCenterY()
	return (self.y - 1 + 1/2)*TILE_SIZE
end

function tile:getWorldCenterX()
	return (self.x - 1 + 1/2)*TILE_SIZE
end

function tile:getPossibleTasks(map, entity)
	local tasks = {}
	-- WALK TO TILE
	
	if self:isWalkable() then
		if entity.x ~= self.x or entity.y ~= self.y then
			function strFunc(tself)
				return "Going to tile " .. self.x .. ", " .. self.y
			end

			function startFunc(tself)
				local route = map:pathfind({x=entity.x, y=entity.y}, self)
				if route then
					entity:setRoute(route)
				else
					tself.finished = true
				end
			end

			function runFunc(tself)
				if #entity.route == 0 then
					tself.finished = true
				end
			end

			function contextFunc(tself)
				return "Walk here"
			end

			local walkTask = task:new(contextFunc, strFunc, nil, startFunc, runFunc, nil, nil)
			table.insert(tasks, walkTask)
		end
	end
	-- WALK TO TILE
	return tasks
end

function tile:draw()
	draw(self.sprite, (self.x - 1)*TILE_SIZE, (self.y - 1)*TILE_SIZE)
end

function tile:__tostring()
	return "Tile(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.index) .. ")"
end

return tile