function drawRect(x, y, width, height, r, g, b, opacity, outline)

	r = r or 0
	g = g or 0
	b = b or 0
	outline = outline or true
	opacity = opacity or 1

	love.graphics.push("all")
	if outline then
		love.graphics.setColor(1, 1, 1, opacity)
		love.graphics.rectangle("line", x, y, width, height)
		love.graphics.setColor(r, g, b, opacity)
		love.graphics.rectangle("fill", x + 1, y + 1, width - 2, height - 2)
		love.graphics.reset()
	else
		love.graphics.setColor(r, g, b, opacity)
		love.graphics.rectangle("fill", x, y, width, height)
	end
	love.graphics.pop()
end