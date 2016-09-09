loader.include("api/mc/turtle/operation.lua")
loader.include("api/mc/blocks.lua")

Operation.Plugin.Dig = {}
Operation.Plugin.Dig.__index = Operation.Plugin.Dig

function Operation.Plugin.Dig.new(orientation, block_filter)
	local result = {}
	setmetatable(result, Operation.Plugin.Dig)
	
	assert(block_filter.passes, "Invalid filter")
	
	result.not_as_parent = true
	result.orientation = orientation
	result.block_filter = block_filter
	
	return result
end

function Operation.Plugin.Dig:pre_move(calling_operation, orientation)
	assert(calling_operation, "No calling operation given")
	if calling_operation:isInGoto() then return end

	local success, data = Turtle.Rel.inspect(self.orientation)
	if success and self.block_filter:passes(Blocks.get(data.name), data.metadata) then
		calling_operation:dig(self.orientation)
	end
end