loader.include("api/mc/turtle/operation.lua")

Operation.MineDeposit = {}
Operation.MineDeposit.__index = Operation.MineDeposit
setmetatable(Operation.MineDeposit, {__index = Operation})

function Operation.MineDeposit.new(initial_orientation, deposit_filter) -- deposit_filter:passes(item_id, item_metadata) -- item_metadata is nil for liquids
	local result = {}
	setmetatable(result, Operation.MineDeposit)
	
	result.name = "deposit"
	result.initial_orientation = initial_orientation or ORIENTATION_FRONT
	result.deposit_filter = deposit_filter
	
	
	return result
end

function Operation.MineDeposit:run_impl()
	assert(not self.next_operation, "Operation does not support appended operation!")
	-- get deposit type
	local success, data = Turtle.Rel.inspect(self.initial_orientation)
	assert(success, "No deposit in given orientation!")
	local deposit_block_id = Blocks.get(data.name)
	local last_block_metadata = data.metadata
	
	-- flowing/ still liquid fix
	if deposit_block_id == 9 then deposit_block_id = 8 end -- water
	if deposit_block_id == 11 then deposit_block_id = 10 end -- lava
	local deposit_is_liquid = deposit_block_id == 8 or deposit_block_id == 10
	if deposit_is_liquid then last_block_metadata = INF end
	
	if not self.deposit_filter then
		self.deposit_filter = EqualsFilter.new(deposit_block_id, if_(deposit_is_liquid, nil, data.metadata))
	end
	
	
	local action_stack = ArrayList.new()
	function deposit_helper(orientation)
		if self.abort then return end
	
		-- inspect block (again)
		local success, data = Turtle.Rel.inspect(orientation)
		if deposit_is_liquid then
			if Blocks.get(data.name) == 9 then data.name = Blocks.get(8) end -- water
			if Blocks.get(data.name) == 11 then data.name = Blocks.get(10) end -- lava
		end

		if success and self.deposit_filter:passes(Blocks.get(data.name), if_(deposit_is_liquid, nil, data.metadata)) and
							(
							-- liquid deposits
							not deposit_is_liquid or 
												   (last_block_metadata == INF or -- first block
													last_block_metadata == 0 or -- last block was source block
													data.metadata == 0 or -- target is source block
													data.metadata < last_block_metadata and data.metadata < 8 and last_block_metadata < 8 or -- upstream when both mt < 8														decrease mt
													data.metadata < last_block_metadata and data.metadata >= 8 and last_block_metadata >= 8 or -- upstream when both mt >= 8													decrease mt
													data.metadata >= 8 and last_block_metadata < 8 or -- move into block with liquid above: mt < 8 => mt >= 8																	increase mt
													data.metadata < 8 and last_block_metadata >= 8 and orientation == ORIENTATION_UP) -- move from block with liquid above to block without liquid above: mt >= 8 => mt < 8		decrease mt
							)
							then
			last_block_metadata = data.metadata -- for liquids

			-- dig and move
			self:dig(orientation)
			self:move(1, orientation)
			
			-- recursion
			for next_orientation = ORIENTATION_FRONT, ORIENTATION_LEFT do
				if next_orientation ~= Turtle.Rel.opposite(orientation) then
					success, data = Turtle.Rel.inspect(next_orientation)
					
					-- flowing/ still liquid fix
					if success and deposit_is_liquid then
						if Blocks.get(data.name) == 9 then data.name = Blocks.get(8) end -- water
						if Blocks.get(data.name) == 11 then data.name = Blocks.get(10) end -- lava
					end
					
					if success and self.deposit_filter:passes(Blocks.get(data.name), if_(deposit_is_liquid, nil, data.metadata)) then
						action_stack:push(Turtle.backtrace)
						action_stack:push(app(deposit_helper, next_orientation))
						action_stack:push(Turtle.trace)
					end
				end
			end
		end
	end

	-- loop stack operations
	action_stack:push(Turtle.backtrace)
	action_stack:push(app(deposit_helper, self.initial_orientation))
	action_stack:push(Turtle.trace)
	while not action_stack:is_empty() do
		action_stack:pop()()
	end
end