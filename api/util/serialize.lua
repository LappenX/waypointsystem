loader.include("api/util/string.lua")

local SEPARATOR = ";"

local function format_(str, type_)
	return tostring(str:len()) .. SEPARATOR .. type_ .. SEPARATOR .. str
end

local function parse(str)
	local colon_pos = findFirst(str, SEPARATOR)
	assert(colon_pos, "Invalid serialization! (1, len=" .. tostring(string.len(str)) .. ")")
	local length = tonumber(str:sub(1, colon_pos - 1))
	str = str:sub(colon_pos + 1)

	colon_pos = findFirst(str, SEPARATOR)
	assert(colon_pos, "Invalid serialization! (2, len=" .. tostring(string.len(str)) .. ")")
	local type_ = str:sub(1, colon_pos - 1)
	assert(type_)
	str = str:sub(colon_pos + 1)

	local rest = str:sub(length + 1)
	assert(rest)
	str = str:sub(1, length)
	
	return length, type_, str, rest
end

function serialize(obj)
	if type(obj) == "number" then
		return format_(tostring(obj), "number")
	elseif type(obj) == "string" then
		return format_(obj, "string")
	elseif type(obj) == "nil" then
		return "nil"
	elseif type(obj) == "boolean" then
		return format_(tostring(obj), "boolean")
	elseif type(obj) == "table" then
		local result = "{"
		
		local first = true
		for k, v in pairs(obj) do
			if first then first = false
			else result = result .. "\n" end
			result = result .. serialize(k) .. " -> " .. serialize(v)
		end
		
		result = result .. "}"
		return format_(result, "table")
	else
		error("Cannot serialize an object of type " .. type(obj) .. "!")
	end
end

function deserialize(str)
	assert(string.len(str) > 0, "Cannot deserialize an empty string!")
	str = trim(str)
	
	if str == "nil" then -- nil
		return nil, str:sub(4)
	else
		local length, type_, rest
		length, type_, str, rest = parse(str, true)

		if type_ == "number" then
			local num = tonumber(str)
			assert(num, "Invalid serialization!")
			return num, rest
		elseif type_ == "string" then
			return str, rest
		elseif type_ == "boolean" then
			assert(str == "true" or str == "false", "Invalid serialization! (4)")
			local bool = str == "true"
			return bool, rest
		elseif type_ == "table" then
			assert(string.char(str:byte(1)) == "{" and string.char(str:byte(str:len())) == "}", "Invalid serialization! (6)")
			
			local result = {}
			local elements_string = str:sub(2, str:len() - 1)
			while elements_string ~= "" do
				local k, v, rest_k, rest_v
				k, rest_k = deserialize(elements_string)
				assert(starts_with(rest_k, " -> "), "Invalid serialization! (5)")
				v, rest_v = deserialize(rest_k:sub(5))
				elements_string = rest_v
				if starts_with(elements_string, "\n") then elements_string = elements_string:sub(2) end
				
				result[k] = v
			end
			
			return result, rest
		else
			error("Invalid serialization! (3, type='" .. type_ .. "'")
		end
	end
end
