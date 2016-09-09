loader.include("api/mc/turtle/operation.lua")

Operation.MineLine = {}
Operation.MineLine.__index = Operation.MineLine
setmetatable(Operation.MineLine, {__index = Operation})

function Operation.MineLine.new(length)
	local result = {}
	setmetatable(result, Operation.MineLine)
	assert(length ~= 0, "Invalid line length!")
	
	result.name = "line"
	result.length = length
	
	return result
end

function Operation.MineLine:run_impl()
	self.length_moved = 0
	for i = 1, math.abs(self.length) do
		self:dig(if_(self.length > 0, ORIENTATION_FRONT, ORIENTATION_BACK))
		self:move(sign(self.length), ORIENTATION_FRONT, function() self.length_moved = self.length_moved + 1 end)
		
		if self.abort then break end
	end
end

function Operation.MineLine:goto_start_impl()
	self:move(self.length_moved * sign(self.length), ORIENTATION_BACK)
end

function Operation.MineLine:goto_mine_impl()
	self:move(self.length_moved * sign(self.length), ORIENTATION_FRONT)
end

function Operation.MineLine:size()
	return Vec.new(1, 1, self.length)
end