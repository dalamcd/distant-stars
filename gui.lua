function drawRect(x, y, width, height, color, outline)

	color = color or {r=0.0, g=0.0, b=0.0, a=1.0}
	outline = outline or true

	love.graphics.push("all")
	if outline then
		love.graphics.setColor(1, 1, 1, color.a)
		love.graphics.rectangle("line", x, y, width, height)
		love.graphics.setColor(color.r, color.g, color.b, color.a)
		love.graphics.rectangle("fill", x + 1, y + 1, width - 2, height - 2)
	else
		love.graphics.setColor(color.r, color.g, color.b, color.a)
		love.graphics.rectangle("fill", x, y, width, height)
	end
	love.graphics.pop()
end

function drawButton(x, y, width, height, text)
	drawRect(x, y, width, height)
	local buttonX = x + (width - love.graphics.getFont():getWidth(text))/2
	local buttonY = y + (height - love.graphics.getFont():getHeight())/2
	love.graphics.print(text, buttonX, buttonY)
end