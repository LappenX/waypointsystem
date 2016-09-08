--[[ DOC

Implementations: ListMap

-- map --
function Map:put(k, v)
function Map:get(k)
function Map:contains_key(k)
function Map:size()
function Map:key_by_value(value)
function Map:remove(k)

function Map:keys_it()
function Map:values_it()
function Map:pairs_it()

--]]

Map = {}
Map.__index = Map

function Map:key_by_value(value)
	for k, v in self:pairs_it() do
		if v == value then
			return k
		end
	end
	return nil
end

function Map:pairs_it()
	local itk = self:keys_it()
	local itv = self:values_it()
	return function()
		local key = itk()
		local value = itv()
		assert(not key and not value or key and value, "Inconsistent map iterators!")
		if key then return key, value end
	end
end

loader.include("api/util/datastructs/map/listmap.lua")
loader.include("api/util/datastructs/map/tablemap.lua")
