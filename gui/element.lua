local class = require('lib.middleclass')

local element = class('element')

function element:initialize()

end

function element:getType()
	return "[[element]]"
end

function element:isType(str)
	local found = string.find(self:getType(), "[["..str.."]]", nil, true)
	if found then
		return true
	else
		return false
	end
end

return element