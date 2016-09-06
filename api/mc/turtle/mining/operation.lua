--[[

Mine.Operation.Deposit.new(initial_orientation)
Mine.Operation.BranchS.new(branch_length, branch_num, branch_separation, right)
Mine.Operation.Box.new(width, height, length)

function Mine.Operation:add_plugin(plugin)

]]--



loader.include("api/util/functional.lua")
loader.include("api/util/filter.lua")
loader.include("api/util/math/math.lua")
loader.include("api/util/math/vec.lua")
loader.include("api/mc/turtle/turtle.lua")
loader.include("api/util/datastructs/list.lua")
loader.include("api/mc/blocks.lua")

Mine = {}




Mine.Operation = {}
Mine.Operation.__index = Mine.Operation

function Mine.Operation:add_plugin(plugin)
	if not self.plugins then self.plugins = ArrayList.new() end
	plugin.plugin_operation = self
	self.plugins:append(plugin)
end

function Mine.Operation:set_parent_operation(operation)
	self.parent_operation = operation
	return self
end

function Mine.Operation:do_plugins(calling_operation, func_name, ...)
	assert(calling_operation, "No calling operation given!")
	if not self.plugins then self.plugins = ArrayList.new() end
	
	for plugin in self.plugins:it() do
		local func = plugin[func_name]
		if func then
			func(plugin, calling_operation, unpack(arg)) -- oop call
		end
	end

	if self.parent_operation and func_name ~= "init" then self.parent_operation:do_plugins(calling_operation, func_name, unpack(arg)) end
end

function Mine.Operation:append(next_operation)
	if self.next_operation then
		self.next_operation:append(next_operation)
	else
		self.next_operation = next_operation
		next_operation:set_parent_operation(self)
	end
end

function Mine.Operation:dig(orientation)
	local success, data = Turtle.Rel.inspect(orientation)
	if success then
		self:do_plugins(self, "pre_dig", orientation, Blocks.get(data.name), data.metadata)
		turtle.select(1)
		Turtle.Rel.dig(orientation, true)
		self:do_plugins(self, "post_dig", orientation, Blocks.get(data.name), data.metadata)
	end
end

function Mine.Operation:move(length, orientation, f_pre, f_post)
	for i = 1, math.abs(length) do
		self:dig(if_(length > 0, orientation, Turtle.Rel.opposite(orientation)))
		self:do_plugins(self, "pre_move", orientation)
		if f_pre then f_pre() end
		Turtle.Rel.move(sign(length), orientation, true)
		if f_post then f_post() end
		self:do_plugins(self, "post_move", orientation)
	end
end




Mine.Operation.Deposit = {}
Mine.Operation.Deposit.__index = Mine.Operation.Deposit
setmetatable(Mine.Operation.Deposit, {__index = Mine.Operation})

function Mine.Operation.Deposit.new(initial_orientation)
	local result = {}
	setmetatable(result, Mine.Operation.Deposit)
	
	result.name = "deposit"
	result.initial_orientation = initial_orientation or ORIENTATION_FRONT
	
	return result
end

function Mine.Operation.Deposit:run()
	assert(not self.next_operation, "Operation does not support appended operation!")
	self.abort = false
	self:do_plugins(self, "init")
	
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
	
	local action_stack = ArrayList.new()
	function deposit_helper(orientation)
		if self.abort then return end
		
		-- inspect block (again)
		local success, data = Turtle.Rel.inspect(orientation)
		if deposit_is_liquid then
			if Blocks.get(data.name) == 9 then data.name = Blocks.get(8) end -- water
			if Blocks.get(data.name) == 11 then data.name = Blocks.get(10) end -- lava
		end

		if success and Blocks.get(deposit_block_id) == data.name and
							(
							-- solid deposits
							not deposit_is_liquid and (last_block_metadata == data.metadata) or -- same metadata
							-- liquid deposits
							deposit_is_liquid and (	last_block_metadata == INF or -- first block
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
					
					if success and Blocks.get(deposit_block_id) == data.name and (last_block_metadata == data.metadata or deposit_is_liquid) then
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
	
	return self
end






Mine.Operation.BranchS = {}
Mine.Operation.BranchS.__index = Mine.Operation.BranchS
setmetatable(Mine.Operation.BranchS, {__index = Mine.Operation})

function Mine.Operation.BranchS.new(branch_length, branch_num, branch_separation, right)
	local result = {}
	setmetatable(result, Mine.Operation.BranchS)
	
	result.name = "branch_s"
	result.branch_length = branch_length
	result.branch_num = branch_num
	result.branch_separation = branch_separation
	result.right = right
	
	return result
end

function Mine.Operation.BranchS:run()
	self.abort = false
	self:do_plugins(self, "init")
	
	-- branching including deposits
	local branch_helper = function(length)
		self.way_along_branch = 0
		for i = 1, length do
			self:dig(ORIENTATION_FRONT)
			self:move(1, ORIENTATION_FRONT, function() self.way_along_branch = self.way_along_branch + 1 end)
			
			if self.abort then return end
		end
	end
	
	self.current_n = 0
	self.current_right = self.right
	while self.current_n < self.branch_num and not self.abort do
		self.current_n = self.current_n + 1
		
		-- Mine branch
		self.digging_main_branch = true
		branch_helper(self.branch_length)
		
		-- Goto next branch
		if self.current_n < self.branch_num then
			Turtle.Rel.rotate_by(if_(self.current_right, 1, -1))
			self.digging_main_branch = false
			branch_helper(self.branch_separation)
			Turtle.Rel.rotate_by(if_(self.current_right, 1, -1))
			
			self.current_right = not self.current_right
		end
	end
	
	if self.next_operation then self.next_operation:run() else self:goto_start() end
end

function Mine.Operation.BranchS:goto_start()
	if self.digging_main_branch then
		-- digging main branch
		if self.current_n % 2 == 1 then
			-- way to opposite side
			Turtle.Rel.rotate_by(2)
			Turtle.Rel.move(self.way_along_branch, ORIENTATION_FRONT, true)
		else
			-- way to correct side
			Turtle.Rel.move(self.branch_length - self.way_along_branch, ORIENTATION_FRONT, true)
		end
	else
		-- digging separation branch
		if self.current_n % 2 == 1 then
			-- on opposite side
			Turtle.Rel.rotate_by(2)
			Turtle.Rel.move(self.way_along_branch, ORIENTATION_FRONT, true)
			Turtle.Rel.rotate_by(if_(self.right, -1, 1))
			Turtle.Rel.move(self.branch_length, ORIENTATION_FRONT, true)
		else
			-- on correct side
			Turtle.Rel.rotate_by(2)
			Turtle.Rel.move(self.way_along_branch, ORIENTATION_FRONT, true)
			Turtle.Rel.rotate_by(if_(self.right, -1, 1))
		end
	end
	
	Turtle.Rel.rotate_by(if_(self.right, 1, -1))
	Turtle.Rel.move((self.current_n - 1) * self.branch_separation, ORIENTATION_FRONT, true)
	Turtle.Rel.rotate_by(if_(self.right, 1, -1))
	
	if self.parent_operation then self.parent_operation:goto_start() end
end

function Mine.Operation.BranchS:goto_mine()
	if self.parent_operation then self.parent_operation:goto_mine() end

	Turtle.Rel.rotate_by(if_(self.right, 1, -1))
	Turtle.Rel.move((self.current_n - 1) * self.branch_separation, ORIENTATION_FRONT, true)
	Turtle.Rel.rotate_by(if_(self.right, 1, -1))

	if self.digging_main_branch then
		-- digging main branch
		if self.current_n % 2 == 1 then
			-- way to opposite side
			Turtle.Rel.rotate_by(2)
			Turtle.Rel.move(self.way_along_branch, ORIENTATION_FRONT, true)
		else
			-- way to correct side
			Turtle.Rel.move(self.branch_length - self.way_along_branch, ORIENTATION_BACK, ORIENTATION_FRONT, true)
		end
	else
		-- digging separation branch
		if self.current_n % 2 == 1 then
			-- on opposite side
			Turtle.Rel.rotate_by(2)
			Turtle.Rel.move(self.branch_length, ORIENTATION_FRONT, true)
			Turtle.Rel.rotate_by(if_(self.right, 1, -1))
			Turtle.Rel.move(self.way_along_branch, ORIENTATION_FRONT, true)
		else
			-- on correct side
			Turtle.Rel.rotate_by(if_(self.right, -1, 1))
			Turtle.Rel.move(self.way_along_branch, ORIENTATION_FRONT, true)
		end
	end
end

function Mine.Operation.BranchS:size()
	return Vec.new(self.branch_num * self.branch_separation * if_(self.right, 1, -1), self.branch_separation, self.branch_length + self.branch_separation)
end













Mine.Operation.Box = {}
Mine.Operation.Box.__index = Mine.Operation.Box
setmetatable(Mine.Operation.Box, {__index = Mine.Operation})

function Mine.Operation.Box.new(width, height, length)
	local result = {}
	setmetatable(result, Mine.Operation.Box)
	assert(width ~= 0 and length ~= 0 and height ~= 0, "Invalid box dimensions!")
	
	result.name = "box"
	result.width = width
	result.height = height
	result.length = length
	
	return result
end

function Mine.Operation.Box:run()
	self.abort = false
	self:do_plugins(self, "init")
	
	-- helper function
	local function dig_layer(height, length)
		assert(math.abs(height) <= 3 and height ~= 0, "Invalid layer height!")

		-- box behind turtle
		if self.length < 0 then Turtle.Rel.rotate_by(2) self.rel_rotation = self.rel_rotation + 2 end
		
		local right = (self.width > 0) == (self.length > 0) -- first turn
		
		local dig_helper = function(rotate, dig_front, move, rel_location_updater)
			if self.abort then return end
			if height >= 2 or height == -3 then self:dig(ORIENTATION_UP) end
			if height == 3 or height <= -2 then
				self:dig(ORIENTATION_DOWN)
				self:dig(ORIENTATION_UP) -- repeat up for falling blocks
			end
			
			if rotate then Turtle.Rel.rotate_by(if_(right, 1, -1)) self.rel_rotation = self.rel_rotation + if_(right, 1, -1) end 
			if dig_front then
				self:dig(ORIENTATION_FRONT)
				if height >= 2 or height == -3 then self:dig(ORIENTATION_UP) end -- repeat up for falling blocks
			end
			if move then self:move(1, ORIENTATION_FRONT, rel_location_updater) end
		end
		
		for x = 1, math.abs(self.width) do
			-- dig row
			for z = 1, math.abs(self.length) - 1 do
				self.rel_rotation = mod_(self.rel_rotation, 4)
				assert(self.rel_rotation == 0 or self.rel_rotation == 2, "Invalid rel_rotation: " .. tostring(self.rel_rotation))
				dig_helper(false, true, true, function() self.rel_location = self.rel_location:add_to(2, if_(self.rel_rotation == 0, 1, -1)) end)
				if self.abort then break end
			end
			
			if x < math.abs(self.width) then
				-- move to next row
				self.rel_rotation = mod_(self.rel_rotation, 4)
				dig_helper(true, true, true, function() self.rel_location = self.rel_location:add_to(0, if_(self.rel_rotation == 1, 1, -1)) end)
				Turtle.Rel.rotate_by(if_(right, 1, -1))
				self.rel_rotation = self.rel_rotation + if_(right, 1, -1)
			else
				-- dig last blocks
				dig_helper(false, false, false)
			end
			right = not right
			if self.abort then break end
		end
		
		if self.length < 0 and not self.abort then Turtle.Rel.rotate_by(2) self.rel_rotation = self.rel_rotation + 2 end
	end
	
	self.current_y = 0
	self.layer = 0
	self.rel_location = Vec.new(0, 0, 0)
	self.rel_rotation = 0
	while self.layer * 3 < math.abs(self.height) and not self.abort do
		local layer_height = math.min(3, math.abs(self.height) - self.layer * 3)
		local target_y = (self.layer * 3 + select_(layer_height - 1, 0, 0, 1)) * sign(self.height)
		layer_height = layer_height * sign(self.height)
		
		-- move to layer
		self:move(target_y - self.current_y, ORIENTATION_UP, function() self.rel_location = self.rel_location:add_to(1, sign(self.height)) end)
		self.current_y = target_y

		-- dig layer
		dig_layer(layer_height)
		self.layer = self.layer + 1
		
		if self.abort then break end

		Turtle.Rel.rotate_by(2)
		self.rel_rotation = self.rel_rotation + 2
		if mod_(self.width, 2) == 0 then
			self.width = -self.width
		end
	end
	
	if self.next_operation then self.next_operation:run() else self:goto_start() end
end

function Mine.Operation.Box:goto_start()
	Turtle.Rel.rotate_by(-self.rel_rotation)
	Turtle.Rel.move(self.rel_location:get(0), ORIENTATION_LEFT, true)
	Turtle.Rel.move(self.rel_location:get(2), ORIENTATION_BACK, true)
	Turtle.Rel.move(self.rel_location:get(1), ORIENTATION_DOWN, true)
	
	if self.parent_operation then self.parent_operation:goto_start() end
end

function Mine.Operation.Box:goto_mine()
	if self.parent_operation then self.parent_operation:goto_mine() end

	Turtle.Rel.move(self.rel_location:get(1), ORIENTATION_UP, true)
	Turtle.Rel.move(self.rel_location:get(2), ORIENTATION_FRONT, true)
	Turtle.Rel.move(self.rel_location:get(0), ORIENTATION_RIGHT, true)
	Turtle.Rel.rotate_by(self.rel_rotation)
end

function Mine.Operation.Box:size()
	return Vec.new(self.width, self.height, self.length)
end









Mine.Operation.Line = {}
Mine.Operation.Line.__index = Mine.Operation.Line
setmetatable(Mine.Operation.Line, {__index = Mine.Operation})

function Mine.Operation.Line.new(length)
	local result = {}
	setmetatable(result, Mine.Operation.Line)
	assert(length ~= 0, "Invalid line length!")
	
	result.name = "line"
	result.length = length
	
	return result
end

function Mine.Operation.Line:run()
	self.abort = false
	self:do_plugins(self, "init")
	
	self.length_moved = 0
	for i = 1, math.abs(self.length) do
		self:dig(if_(self.length > 0, ORIENTATION_FRONT, ORIENTATION_BACK))
		self:move(sign(self.length), ORIENTATION_FRONT, function() self.length_moved = self.length_moved + 1 end)
		
		if self.abort then break end
	end
	
	if self.next_operation then self.next_operation:run() else self:goto_start() end
end

function Mine.Operation.Line:goto_start()
	Turtle.Rel.move(self.length_moved * sign(self.length), ORIENTATION_BACK, true)
	
	if self.parent_operation then self.parent_operation:goto_start() end
end

function Mine.Operation.Line:goto_mine()
	if self.parent_operation then self.parent_operation:goto_mine() end

	Turtle.Rel.move(self.length_moved * sign(self.length), ORIENTATION_FRONT, true)
end

function Mine.Operation.Line:size()
	return Vec.new(1, 1, self.length)
end







Mine.Operation.Offset = {}
Mine.Operation.Offset.__index = Mine.Operation.Offset
setmetatable(Mine.Operation.Offset, {__index = Mine.Operation})

function Mine.Operation.Offset.new(f_goto_start, f_goto_mine)
	local result = {}
	setmetatable(result, Mine.Operation.Offset)
	
	result.name = "offset"
	result.f_goto_start = f_goto_start
	result.f_goto_mine = f_goto_mine
	
	return result
end

function Mine.Operation.Offset:run()
	self.abort = false
	self:do_plugins(self, "init")
	
	self:goto_mine()
	
	if self.next_operation then self.next_operation:run() else self:goto_start() end
end

function Mine.Operation.Offset:goto_start()
	self.f_goto_start(function(length, orientation) return self:move(length, orientation) end)
	
	if self.parent_operation then self.parent_operation:goto_start() end
end

function Mine.Operation.Offset:goto_mine()
	if self.parent_operation then self.parent_operation:goto_mine() end

	self.f_goto_mine(function(length, orientation) return self:move(length, orientation) end)
end
