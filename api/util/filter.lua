Filter = {}
Filter.__index = Filter

function Filter.new(filter_func)
	local result = {}
	setmetatable(result, Filter)
	
	result.filter_func = filter_func
	
	return result
end

function Filter:passes(...)
	return self.filter_func(unpack(arg))
end



AndFilter = {}
AndFilter.__index = AndFilter

function AndFilter.new(filter1, filter2)
	local result = {}
	setmetatable(result, AndFilter)
	
	result.filter1 = filter1
	result.filter2 = filter2
	
	return result
end

function AndFilter:passes(...)
	return self.filter1:passes(unpack(arg)) and self.filter2:passes(unpack(arg))
end


OrFilter = {}
OrFilter.__index = OrFilter

function OrFilter.new(filter1, filter2)
	local result = {}
	setmetatable(result, OrFilter)
	
	result.filter1 = filter1
	result.filter2 = filter2
	
	return result
end

function OrFilter:passes(...)
	return self.filter1:passes(unpack(arg)) or self.filter2:passes(unpack(arg))
end


NotFilter = {}
NotFilter.__index = NotFilter

function NotFilter.new(filter)
	local result = {}
	setmetatable(result, NotFilter)
	
	result.filter = filter
	
	return result
end

function NotFilter:passes(...)
	return not self.filter:passes(unpack(arg))
end


PassAllFilter = {}
PassAllFilter.__index = PassAllFilter

function PassAllFilter.new()
	local result = {}
	setmetatable(result, PassAllFilter)
	
	return result
end

function PassAllFilter:passes(...)
	return true
end


PassNoneFilter = {}
PassNoneFilter.__index = PassNoneFilter

function PassNoneFilter.new()
	local result = {}
	setmetatable(result, PassNoneFilter)
	
	return result
end

function PassNoneFilter:passes(...)
	return false
end


ContainsFilter = {}
ContainsFilter.__index = ContainsFilter

function ContainsFilter.new(list)
	local result = {}
	setmetatable(result, ContainsFilter)
	
	result.list = list
	
	return result
end

function ContainsFilter:passes(element)
	return self.list:contains(element)
end


EqualsFilter = {}
EqualsFilter.__index = EqualsFilter

function EqualsFilter.new(...)
	local result = {}
	setmetatable(result, EqualsFilter)
	
	result.elements = arg
	
	return result
end

function EqualsFilter:passes(...)
	local i = 1
	for _, e in ipairs(arg) do
		if e ~= self.elements[i] then return false end
		i = i + 1
	end
	return true
end