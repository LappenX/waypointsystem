ArrayList = {}
ArrayList.__index = ArrayList
setmetatable(ArrayList, {__index = List})


function ArrayList.new(initialization_array)
	local result = {}
	setmetatable(result, ArrayList)
	
	result.array = {}
	if initialization_array then
		local i = 1
		for k, v in ipairs(initialization_array) do
			table.insert(result.array, i, v)
			i = i + 1
		end
	end
	
	return result
end

function ArrayList:insert(index, val)
	if index > self:size() then error("List index out of bounds!", 2) end
	
	table.insert(self.array, index + 1, val)
	
	return val
end

function ArrayList:remove(index)
	if index >= self:size() then error("List index out of bounds!", 2) end
	
	local result = self:get(index)
	table.remove(self.array, index + 1)
	
	return result
end

function ArrayList:get(index)
	if index >= self:size() then error("List index out of bounds!", 2) end
	return self.array[index + 1]
end

function ArrayList:size()
	return table.getn(self.array)
end

function ArrayList:it()
	local cur_index = -1
	return function()
		cur_index = cur_index + 1
		if cur_index < self:size() then return self:get(cur_index) end
	end
end
