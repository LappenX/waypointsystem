loader.include("api/util/math/vec.lua")
loader.include("api/util/datastructs/list.lua")
loader.include("api/util/datastructs/map.lua")
loader.include("api/util/string.lua")

CLI = {}



CLI.Number = {}
CLI.Number.__index = CLI.Number

function CLI.Number.new(name, integer, default)
	local result = {}
	setmetatable(result, CLI.Number)
	
	result.name = name
	result.default = default
	result.integer = integer
	
	return result
end

function CLI.Number:parse(token)
	local result = tonumber(token)
	if not result then
		return nil, "Invalid number"
	elseif self.integer and result % 1 ~= 0 then
		return nil, "Number is not an integer"
	end
	return result, ""
end

CLI.String = {}
CLI.String.__index = CLI.String

function CLI.String.new(name, default)
	local result = {}
	setmetatable(result, CLI.String)
	
	result.name = name
	result.default = default
	
	return result
end

function CLI.String:parse(token)
	return token, ""
end




CLI.Command = {}
CLI.Command.__index = CLI.Command

function CLI.Command.new(name, func, ...)
	local result = {}
	setmetatable(result, CLI.Command)
	
	result.arguments = ArrayList.new(arg)
	result.name = name
	result.func = func
	
	return result
end

function CLI.Command:exec(tokens)
	if tokens:size() - 1 > self.arguments:size() then
		print("Expected at most " .. tostring(self.arguments:size()) .. " arguments, got " .. tostring(tokens:size() - 1))
		return false
	end

	local args = {}
	for i = 0, self.arguments:size() - 1 do
		local arg = self.arguments:get(i)
		
		if i + 1 < tokens:size() then
			local arg_value, err_msg = arg:parse(tokens:get(i + 1))
			if arg_value then
				table.insert(args, arg_value)
			else
				assert(err_msg)
				print("Invalid argument '" .. arg.name .. "': " .. err_msg)
				return false
			end
		elseif arg.default then
			table.insert(args, arg.default)
		else
			print("Argument '" .. arg.name .. "' does not have a default value")
			return false
		end
	end
	
	self.func(unpack(args))
	
	return true
end







CLI.__index = CLI

function CLI.new(prefix)
	local result = {}
	setmetatable(result, CLI)
	
	result.commands = TableMap.new()
	result.prefix = prefix
	
	return result
end

function CLI:addCommand(command)
	self.commands:put(command.name, command)
end

function CLI:exec(input)
	local tokens = map(trim, split(input, " "))
	
	local command = self.commands:get(tokens:get(0))
	if not command then
		print("Invalid command '" .. tokens:get(0) .. "'")
	else
		command:exec(tokens)
	end
end

function CLI:run(once)
	repeat
		term.write(self.prefix .. "> ")
		self:exec(read())
	until once
end
