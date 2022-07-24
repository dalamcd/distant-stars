local gameCamera
local gameMap
local gameContext

local mouseSelection = nil

local fonts = {}
local bg

function rect(mode, x, y, width, height)
	love.graphics.rectangle(mode,
							gameCamera:getRelativeX(x),
							gameCamera:getRelativeY(y),
							gameCamera.scale*width,
							gameCamera.scale*height)
end

function line(x1, y1, x2, y2)
	love.graphics.line(gameCamera:getRelativeX(x1), gameCamera:getRelativeY(y1),
						gameCamera:getRelativeX(x2), gameCamera:getRelativeY(y2))
end

function circ(mode, x, y, r)
	love.graphics.circle(mode, gameCamera:getRelativeX(x), gameCamera:getRelativeY(y), gameCamera.scale*r)
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

	love.graphics.print(mouseSelection.name .."["..mouseSelection.uid.."]",
						love.graphics.getWidth() - width - textPadding,
						love.graphics.getHeight() - height - textPadding)
	
	if mouseSelection:getType() == "entity" then
		local tlist = mouseSelection:getTasks()
		local itemNum = 1
		local idleSeconds = math.floor(mouseSelection.idleTime/60)
		if idleSeconds > 0 then
			love.graphics.print("Idle for " .. idleSeconds .. " seconds",
								love.graphics.getWidth() - width - textPadding,
								love.graphics.getHeight() - height + textPadding*itemNum*3)
			itemNum = itemNum + 1
		end

		for i=#tlist, 1, -1 do
			if not tlist[i]:isChild() then
				love.graphics.print(tlist[i]:getDesc(),
									love.graphics.getWidth() - width - textPadding,
									love.graphics.getHeight() - height + textPadding*itemNum*3)
				itemNum = itemNum + 1
			end
		end
	elseif mouseSelection:getType() == "stockpile" then
		for i, item in ipairs(mouseSelection.contents) do
			love.graphics.print(item.name,
								love.graphics.getWidth() - width - textPadding,
								love.graphics.getHeight() - height + textPadding*i*3)
		end
	end
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

function drawSelectionBox()
	rect("line", mouseSelection:getWorldX(), mouseSelection:getWorldY(),
				mouseSelection.spriteWidth, mouseSelection.spriteHeight)
end

function setGameCamera(c)
	gameCamera = c
end

function setGameContext(ctx)
	gameContext = ctx
end

function getGameMap()
	return gameMap
end

function setGameMap(map)
	gameMap = map
end

function setBackground(background)
	bg = background
end

function getBackground()
	return bg
end

function getGameContext()
	return gameContext
end

function setMouseSelection(item)
	if mouseSelection then
		mouseSelection:deselect()
	end
	item:select()
	mouseSelection = item
end

function clearMouseSelection()
	if mouseSelection then
		mouseSelection:deselect()
	end
	mouseSelection = nil
end

function getMouseSelection()
	return mouseSelection
end

function addFont(font, name)
	table.insert(fonts, {font=font, name=name})
end

function getFont(name)
	for _, font in ipairs(fonts) do
		if font.name == name then
			return font.font
		end
	end
	return love.graphics.getFont()
end

function getMousePos()
	local mx = (love.mouse.getX() - gameCamera.xOffset) / gameCamera.scale
	local my = (love.mouse.getY() - gameCamera.yOffset) / gameCamera.scale
	return mx, my
end