local class = require('lib.middleclass')

local gui = class('gui')

function gui.static:drawRect(x, y, width, height, backgroundColor, outlineWidth, outlineColor)

	backgroundColor = backgroundColor or {0.0, 0.0, 0.0, 1.0}
	outlineColor = outlineColor or {1.0, 1.0, 1.0, 1.0}
	outlineWidth = outlineWidth or 1

	love.graphics.push("all")
	if outlineWidth > 0 then
		love.graphics.setColor(unpack(outlineColor))
		love.graphics.setLineWidth(outlineWidth)
		love.graphics.rectangle("line", x, y, width, height)
		love.graphics.setColor(unpack(backgroundColor))
		love.graphics.rectangle("fill", x + outlineWidth, y + outlineWidth, width - outlineWidth*2, height - outlineWidth*2)
	else
		love.graphics.setColor(unpack(backgroundColor))
		love.graphics.rectangle("fill", x, y, width, height)
	end
	love.graphics.pop()
end

function gui.static:drawLine(x1, y1, x2, y2, color, width)
	color = color or {1, 1, 1, 1}
	width = width or 1
	love.graphics.push("all")
	love.graphics.setLineWidth(width)
	love.graphics.setColor(unpack(color))
	love.graphics.line(x1, y1, x2, y2)
	love.graphics.pop()
end

function gui.static:drawCircle(x, y, r, backgroundColor, outlineWidth, outlineColor)

	backgroundColor = backgroundColor or {0.0, 0.0, 0.0, 1.0}
	outlineColor = outlineColor or {1.0, 1.0, 1.0, 1.0}
	outlineWidth = outlineWidth or 1

	love.graphics.push("all")
	if outlineWidth > 0 then
		love.graphics.setColor(unpack(outlineColor))
		love.graphics.setLineWidth(outlineWidth)
		love.graphics.circle("line", x, y, r)
		love.graphics.setColor(unpack(backgroundColor))
		love.graphics.circle("fill", x, y, r - 1)
	else
		love.graphics.setColor(unpack(backgroundColor))
		love.graphics.circle("fill", x, y, r - 1)
	end
	love.graphics.pop()

end

function gui.static:getMousePos()
	local mx = love.mouse.getX()
	local my = love.mouse.getY()
	return mx, my
end

function gui:initialize()

end

return gui