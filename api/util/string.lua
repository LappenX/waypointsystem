loader.include("api/util/datastructs/list.lua")

function split(str, splitter)
	local result = ArrayList.new()
	local index = 0
	local lastindex = 0
	while index <= string.len(str) or index == 0 do
		lastindex = index
		index = string.find(str, splitter, lastindex + string.len(splitter))
		if not index then index = string.len(str) + 1 end
		
		result:append(string.sub(str, lastindex + string.len(splitter), index - 1))
	end
	return result
end

function toString(obj)
	if type(obj) == "table" then
		local result = "{"
		local first = true
		for k, v in pairs(obj) do
			if not first then result = result .. ", " else first = false end
			result = result .. "(" .. toString(k) .. "->" .. toString(v) .. ")"
		end
		result = result .. "}"
		return result
	else
		return tostring(obj)
	end
end

function trim(str)
  return tostring(str:gsub("^%s*(.-)%s*$", "%1"))
end

function starts_with(str, start)
	assert(str and start)
	return not (str:len() < start:len()) and string.sub(str, 1, string.len(start)) == start
end

function make_length(str, length, leading, insert_char)
	leading = leading or true
	insert_char = insert_char or " "

	while str:len() < length do
		if leading then
			str = str .. insert_char
		else
			str = insert_char .. str
		end
	end
	if str:len() > length then
		str = str:sub(1, length)
	end
	return str
end