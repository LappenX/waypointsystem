loader.include("api/util/datastructs/list.lua")
loader.include("api/util/string.lua")

local MAX_OPTIONS_PER_SCREEN = 8

MenuOption = {}
MenuOption.__index = MenuOption

function MenuOption.new(text, func, check)
	local result = {}
	setmetatable(result, MenuOption)
	
	result.text = text
	result.func = func
	result.check = check
	
	return result
end

Menu = {}
Menu.__index = Menu

function Menu.new(title, has_exit_option, ...)
	local result = {}
	setmetatable(result, Menu)
	
	result.options = ArrayList.new()
	for i, v in ipairs(arg) do
        result.options:append(v)
    end
	result.title = title
	result.has_exit_option = has_exit_option
	
	return result
end

function Menu.check(question)
	term.clear()
	term.setCursorPos(1, 1)
	print(question)
	print("Are you sure? (y/n)")
	local check_input = read()
	return check_input == "y"
end

function Menu:add_option(option)
	self.options:append(option)
end

function Menu:show(repeated)
	local message = nil
	repeat
		local current_option = self:show_with_option(message)
		if not current_option then break end
		local do_option = true
		if current_option.check then do_option = Menu.check("Option: " .. current_option.text) end
		if do_option then
			local status, err = pcall(function() message = current_option.func() end)
			if not status then message = "Failed option with error: " .. tostring(err) end
		else
			message = "Option cancelled!"
		end
    until not repeated
	
	term.clear()
	term.setCursorPos(1, 1)
	if message then print(message) end
end

function Menu:show_with_option(message)
	local result_option = nil
	local menu_offset = 0
	while not result_option do
		-- show menu
		term.clear()
		term.setCursorPos(1, 1)
		if self.title and self.title ~= "" then print(self.title) end
		local exit_option_index = 1
		for i = menu_offset, self.options:size() - 1 do
			if i >= menu_offset + MAX_OPTIONS_PER_SCREEN then break end
			
			local opt = self.options:get(i)
			print(tostring(i + 1) .. ". " .. opt.text)
			exit_option_index = i + 2
		end
		if self.has_exit_option and exit_option_index <= menu_offset + MAX_OPTIONS_PER_SCREEN then print(tostring(exit_option_index) .. ". Exit") end
		print("")
		if message then print(message) print("") end
		message = nil
		
		-- input
		term.write("Option: ")
		local read_result = nil
		local read_thread = coroutine.wrap(function() read_result = read() os.queueEvent("event_read_finished") end)
		local event = {}
		while true do
			read_thread(unpack(event))
			
			event = {os.pullEvent()}
			if event[1] == "event_read_finished" then break end
			if event[1] == "key" and (event[2] == 200 or event[2] == 208) then
				if event[2] == 200 then -- arrow up
					menu_offset = menu_offset - 1
				elseif event[2] == 208 then -- arrow down
					menu_offset = menu_offset + 1
				end
				menu_offset = math.max(0, math.min(self.options:size() - MAX_OPTIONS_PER_SCREEN + if_(self.has_exit_option, 1, 0), menu_offset))
				break
			end
		end

		-- input handling
		if read_result then
			local input = tonumber(read_result)
			if not input or input < 1 or input > self.options:size() + 1 then
				-- invalid option selected
				message = "Invalid option!"
			elseif self.has_exit_option and input == self.options:size() + 1 then
				-- exit option selected
				result_option = nil
				break
			else
				-- valid option selected
				result_option = self.options:get(input - 1)
			end
		end
	end
	return result_option
end

function Menu:show_with_func_result(message)
	local option = self:show_with_option(message)
	if option then return option.func() else return nil end
end