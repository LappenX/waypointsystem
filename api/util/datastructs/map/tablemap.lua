TableMap = {}
TableMap.__index = TableMap
setmetatable(TableMap, {__index = Map})


function TableMap.new(wp, chest_rotation)
	local result = {}
	setmetatable(result, TableMap)
	
	result.table = {}
	
	return result
end

function TableMap:put(k, v)
	self.table[k] = v
end

function TableMap:remove(k)
	result = self.table[k]
	self.table[k] = nil
	return result
end

function TableMap:get(k)
	return self.table[k]
end

function TableMap:contains_key(k)
	return self.table[k] ~= nil
end

function TableMap:size()
	local count = 0
	for _ in pairs(self.table) do count = count + 1 end
	return count
end

function TableMap:keys_it()
	local last_key = nil
	return function()
		last_key = next(self.table, last_key)
		return last_key
	end
end

function TableMap:values_it()
	local last_key = nil
	return function()
		local v
		last_key, v = next(self.table, last_key)
		return v
	end
end