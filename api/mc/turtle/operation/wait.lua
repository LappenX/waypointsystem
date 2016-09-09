loader.include("api/mc/turtle/operation.lua")

Operation.Wait = {}
Operation.Wait.__index = Operation.Wait
setmetatable(Operation.Wait, {__index = Operation})

function Operation.Wait.new(seconds)
	local result = {}
	setmetatable(result, Operation.Wait)
	
	result.name = "Wait"
	result.seconds = seconds
	
	return result
end

function Operation.Wait:run_impl()
	os.sleep(self.seconds)
end

function Operation.Wait:goto_start_impl()
end

function Operation.Wait:goto_mine_impl()
end