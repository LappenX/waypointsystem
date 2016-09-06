loader.include("api/util/math/vec.lua")

ArgumentType = {}
ArgumentType.__index = ArgumentType

function ArgumentType.new(type_, ...)
	local result = {}
	setmetatable(result, ArgumentType)
	
	result.type_ = type_
	result.restrictions = arg
	
	return result
end

function ArgumentType:get()
	if self.type_ == "number" then
		return read_number(unpack(self.restrictions))
	elseif self.type_ == "string" then
		return read()
	elseif self.type_ == "vec" then
		return read_vec(unpack(self.restrictions))
	elseif self.type_ == "selection" then
		return read_selection(unpack(self.restrictions))
	elseif self.type_ == "boolean" then
		return read_boolean(unpack(self.restrictions))
	else
		error("Invalid argument type!")
	end
end

function read_number(name, int)
	local result = nil
	repeat
		term.clearLine()
		term.write(name .. " = ")
		result = tonumber(read())
		if int and result and result % 1 ~= 0 then result = nil end
	until result
	return result
end

function read_boolean(name)
	while true do
		term.clearLine()
		term.write(name .. " = ")
		local result = read()
		if result == "true" or result == "false" or result == "t" or result == "f" then
			return result == "true" or result == "t"
		end
	end
end

function read_selection(name, ...)
	local result = nil
	while true do
		term.clearLine()
		term.write(name .. " = ")
		result = read()
		
		for _, v in ipairs(arg) do
			if v == result then
				return result
			end
		end
	end
end

function read_vec(name, dims, int)
	assert(dims)
	
	print(name .. ":")
	local result = Vec.new()
	for i = 1, dims do
		local dim_name
		if i == 1 then dim_name = "x"
		elseif i == 2 then dim_name = "y"
		elseif i == 3 then dim_name = "z"
		else dim_name = "dim " .. tostring(i)
		end
		table.insert(result.values, read_number(dim_name, true))
	end
	return result
end

function read_args(...)
	local result = {}
	for _, argument_type in ipairs(arg) do
		table.insert(result, argument_type:get())
	end
	return unpack(result)
end
