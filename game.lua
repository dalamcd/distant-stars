local gameCamera
local gameMap

local mouseSelection = nil

function draw(image, x, y)
	love.graphics.draw(image, 
					gameCamera:getRelativeX(x),
					gameCamera:getRelativeY(y),
					0,
					gameCamera.scale)
end

function rect(mode, x, y, width, height)
	love.graphics.rectangle(mode,
							gameCamera:getRelativeX(x),
							gameCamera:getRelativeY(y),
							gameCamera.scale*width,
							gameCamera.scale*height)
end

function drawSelectionDetails()

	local width = 300
	local height = 100
	local padding = 10
	local textPadding = 5

	love.graphics.rectangle("line", love.graphics.getWidth() - width - padding, 
									love.graphics.getHeight() - height - padding, 
									width, 
									height)
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", love.graphics.getWidth() - width - padding + 1, 
									love.graphics.getHeight() - height - padding + 1, 
									width - 1, 
									height -1)
	love.graphics.reset()

	love.graphics.print(mouseSelection.name,
						love.graphics.getWidth() - width - textPadding,
						love.graphics.getHeight() - height - textPadding)
	
	for i=#mouseSelection:getTasks(), 1, -1 do
		local idx = #mouseSelection:getTasks() - i + 1
		love.graphics.print(mouseSelection:getTasks()[i].desc,
							love.graphics.getWidth() - width - textPadding,
							love.graphics.getHeight() - height + textPadding*idx*3)
	end
end

function drawSelectionBox()
	rect("line", mouseSelection:getWorldX(), mouseSelection:getWorldY(), TILE_SIZE, TILE_SIZE)
end

function setGameCamera(c)
	gameCamera = c
end

function getGameCamera()
	return gameCamera
end

function setMouseSelection(item)
	mouseSelection = item
end

function clearMouseSelection()
	mouseSelection = nil
end

function getMouseSelection()
	return mouseSelection
end

function drawRouteLine(startPoint, endPoint)
	love.graphics.setLineWidth(2*gameCamera.scale)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.line(gameCamera:getRelativeX(startPoint.x),
					gameCamera:getRelativeY(startPoint.y),
					gameCamera:getRelativeX(endPoint.x),
					gameCamera:getRelativeY(endPoint.y))

	love.graphics.reset()
end

function getMousePos()
	local mx = (love.mouse.getX() - gameCamera.xOffset) / gameCamera.scale
	local my = (love.mouse.getY() - gameCamera.yOffset) / gameCamera.scale
	return mx, my
end