local class = require('lib.middleclass')

local attribute = class('attribute')

attribute.static._loaded_attributes = {}

function attribute.static:load(name, label, min, max)
	local internalItem = self._loaded_attributes[name]

	if internalItem then
		return internalItem
	else
		self._loaded_attributes[name] = {
			label = label,
			min = min,
			max = max
		}
	end
end

function attribute.static:retrieve(name)
	return self._loaded_attributes[name] or false
end

function attribute:initialize(name)
	local obj = attribute:retrieve(name)
	if not obj then
		error("attempted to initialize " .. name .. " but no attribute with that name was found")
	end

	self.name = name
	self.label = obj.label
	self.min = obj.min
	self.max = obj.max
	self.amount = 0
end

function attribute:getAmount()
	return self.amount
end

function attribute:getMax()
	return self.max
end

function attribute:getMin()
	return self.min
end

function attribute:adjustAmount(amt)
	self.amount = clamp(self.amount + amt, self.min, self.max)
	return self.amount
end

function attribute:setAmount(amt)
	self.amount = clamp(amt, self.min, self.max)
	return self.amount
end

function attribute:__add(attr)
	if type(attr) == 'table' then
		return self.amount + attr.amount
	elseif type(attr) == 'number' then
	 	return self.amount + attr
	end
end

function attribute:__lt(attr)
	if type(attr) == 'table' then
		return self.amount < attr.amount
	elseif type(attr) == 'number' then
	 	return self.amount < attr
	end
end

function attribute:__le(attr)
	if type(attr) == 'table' then
		return self.amount <= attr.amount
	elseif type(attr) == 'number' then
	 	return self.amount <= attr
	end
end

function attribute:__mul(attr)
	if type(attr) == 'table' then
		return self.amount*attr.amount
	elseif type(attr) == 'number' then
	 	return self.amount*attr
	end
end

return attribute