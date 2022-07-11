local gameCamera

function draw(image, x, y)
	love.graphics.draw(image, 
					gameCamera.scale*x + gameCamera.xOffset,
					gameCamera.scale*y + gameCamera.yOffset,
					0,
					gameCamera.scale)
end

function setGameCamera(c)
	gameCamera = c
end

function getGameCamera()
	return gameCamera
end 

function getMousePos()
	local mx = (love.mouse.getX() - gameCamera.xOffset) / gameCamera.scale
	local my = (love.mouse.getY() - gameCamera.yOffset) / gameCamera.scale
	return mx, my
end