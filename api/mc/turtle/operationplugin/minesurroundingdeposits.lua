loader.include("api/mc/turtle/operation.lua")

Operation.Plugin.MineSurroundingDeposits = {}
Operation.Plugin.MineSurroundingDeposits.__index = Operation.Plugin.MineSurroundingDeposits

function Operation.Plugin.MineSurroundingDeposits.new(deposit_filter)
	local result = {}
	setmetatable(result, Operation.Plugin.MineSurroundingDeposits)
	
	result.orientations = ArrayList.new({ORIENTATION_LEFT, ORIENTATION_FRONT, ORIENTATION_RIGHT, ORIENTATION_UP, ORIENTATION_DOWN})
	result.deposit_filter = deposit_filter
	
	return result
end

function Operation.Plugin.MineSurroundingDeposits:post_move(calling_operation, orientation_moved)
	assert(calling_operation, "No calling operation given!")
	if not calling_operation:isInGoto() and not self.disabled then
		for orientation in self.orientations:it() do
			local success, data = Turtle.Rel.inspect(orientation)
			if success and self.deposit_filter:passes(Blocks.get(data.name), data.metadata) then
				self.disabled = true
				Mine.Operation.Deposit.new(orientation, self.deposit_filter):set_parent_operation(calling_operation):run()
				self.disabled = nil
			end
		end
	end
end