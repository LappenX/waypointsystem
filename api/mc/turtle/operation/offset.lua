loader.include("api/mc/turtle/operation.lua")

Operation.Offset = {}
Operation.Offset.__index = Operation.Offset
setmetatable(Operation.Offset, {__index = Operation})

function Operation.Offset.new(f_goto_start, f_goto_mine)
	local result = {}
	setmetatable(result, Operation.Offset)
	
	result.name = "offset"
	result.f_goto_start = f_goto_start
	result.f_goto_mine = f_goto_mine
	
	return result
end

function Operation.Offset:run_impl()
	self:goto_mine_impl()
end

function Operation.Offset:goto_start_impl()
	self.f_goto_start(function(length, orientation) return self:move(length, orientation) end)
end

function Operation.Offset:goto_mine_impl()
	self.f_goto_mine(function(length, orientation) return self:move(length, orientation) end)
end