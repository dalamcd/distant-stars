local class = require('lib.middleclass')

local debugtext = class('debugtext')

function debugtext:initialize()

	self.textFields = {}

end

function debugtext:addTextField(label, value)

	local newField = {}
	newField.label = label
	newField.value = value
	table.insert(self.textFields, newField)

end

function debugtext:updateTextField(label, value)

	for _, textField in ipairs(self.textFields) do
		if textField.label == label then
			textField.value = value
		end
	end
end

function debugtext:draw()

	local xPadding = 16
	local yPadding = love.graphics.getHeight() - 16
	local textSpacing = 16

	for i, field in ipairs(self.textFields) do
		love.graphics.print(field.label .. ": " .. field.value,
							xPadding,
							yPadding - i*textSpacing)
	end

end

return debugtext