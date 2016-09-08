loader.include("api/mc/turtle/operation.lua")

Operation.Plugin.DropExcessBlocks = {}
Operation.Plugin.DropExcessBlocks.__index = Operation.Plugin.DropExcessBlocks

function Operation.Plugin.DropExcessBlocks.new(drop_filter, drop_interval)
	local result = {}
	setmetatable(result, Operation.Plugin.DropExcessBlocks)
	
	result.drop_filter = drop_filter
	result.drop_interval = drop_interval or 8
	
	return result
end

function Operation.Plugin.DropExcessBlocks:init()
	self.dig_counter = 0
end

function Operation.Plugin.DropExcessBlocks:post_dig(calling_operation, orientation, block_id, block_metadata)
	self.dig_counter = self.dig_counter + 1
	if self.dig_counter == self.drop_interval then
		self.dig_counter = 0
		for i = 1, 16 do
			local data = turtle.getItemDetail(i)
			if data and self.drop_filter:passes(Blocks.get(data.name), data.metadata) then
				Turtle.Rel.drop(ORIENTATION_FRONT, 64, i)
				break
			end
		end
	end
end