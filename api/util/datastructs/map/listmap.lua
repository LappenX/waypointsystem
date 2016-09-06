ListMap = {}
ListMap.__index = ListMap
setmetatable(ListMap, {__index = Map})


function ListMap.new(wp, chest_rotation)
	local result = {}
	setmetatable(result, ListMap)
	
	result.pairs = ArrayList.new()
	
	return result
end

function ListMap:put(k, v)
	for pair in self.pairs:it() do
		if pair.key == k then
			pair.value = v
			return
		end
	end
	self.pairs:append({key = k, value = v})
end

function ListMap:remove(k)
	for i = 0, self.pairs:size() - 1 do
		if self.pairs:get(i).key == k then
			return self.pairs:remove(i).value
		end
	end
	return nil
end

function ListMap:get(k)
	for pair in self.pairs:it() do
		if pair.key == k then
			return pair.value
		end
	end
	return nil
end

function ListMap:contains_key(k)
	for pair in self.pairs:it() do
		if pair.key == k then
			return true
		end
	end
	return false
end

function ListMap:size()
	return self.pairs:size()
end

function ListMap:keys_it()
	local cur_index = -1
	return function()
		cur_index = cur_index + 1
		if cur_index < self:size() then return self.pairs:get(cur_index).key end
	end
end

function ListMap:values_it()
	local cur_index = -1
	return function()
		cur_index = cur_index + 1
		if cur_index < self:size() then return self.pairs:get(cur_index).value end
	end
end