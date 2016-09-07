--[[

Mine.Plugin.RefuelLava.new(abort_on_fuel_limit)
Mine.Plugin.MineSurroundingDeposits.new(orientations, deposit_filter)
Mine.Plugin.DropExcessBlocks.new(drop_filter, drop_interval)
Mine.Plugin.UnloadAtWaypoint.new(storage_wp) // storage_wp:has_plugin(Waypoint.Plugin.Storage)
Mine.Plugin.EvadeTurtles.new(timeout)




virtual function Mine.Plugin:init()
virtual function Mine.Plugin:pre_dig(calling_operation, orientation, block_id, block_metadata)
virtual function Mine.Plugin:post_dig(calling_operation, orientation, block_id, block_metadata)
virtual function Mine.Plugin:pre_move(calling_operation, orientation_move)
virtual function Mine.Plugin:post_move(calling_operation, orientation_moved)

]]--


Mine.Plugin = {}

Mine.Plugin.RefuelLava = {}
Mine.Plugin.RefuelLava.__index = Mine.Plugin.RefuelLava

function Mine.Plugin.RefuelLava.new(abort_on_fuel_limit)
	local result = {}
	setmetatable(result, Mine.Plugin.RefuelLava)
	
	result.abort_on_fuel_limit = abort_on_fuel_limit
	
	return result
end

function Mine.Plugin.RefuelLava:init()
	self.bucket_slot = Turtle.Inv.find_first(Items.get("minecraft:bucket"))
	assert(self.bucket_slot, "Mine.Plugin.RefuelLava needs an empty bucket in the turtle's inventory!")
end

function Mine.Plugin.RefuelLava:pre_dig(calling_operation, orientation, block_id, block_metadata)
	if Blocks.get(block_id) == "minecraft:flowing_lava" and block_metadata == 0 then
		turtle.select(self.bucket_slot)
		Turtle.Rel.place(orientation)
		turtle.refuel()
		if self.abort_on_fuel_limit and turtle.getFuelLevel() >= turtle.getFuelLimit() then self.plugin_operation.abort = true end
	end
end







local TURTLE_MAX_RANDOM_TEST_TIME = 10.0
local TURTLE_EVADE_DURATION = 5.0
local TURTLE_EVADE_TIMEOUT = 120

Mine.Plugin.EvadeTurtles = {}
Mine.Plugin.EvadeTurtles.__index = Mine.Plugin.EvadeTurtles

function Mine.Plugin.EvadeTurtles.new(dig)
	local result = {}
	setmetatable(result, Mine.Plugin.EvadeTurtles)
	
	result.dig = dig
	
	return result
end

function Mine.Plugin.EvadeTurtles:pre_dig(calling_operation, orientation, block_id, block_metadata)
	if block_id == 204 or block_id == 205 then -- is turtle
		local waited = 0
		while true do
			local wait_time = math.random() * TURTLE_MAX_RANDOM_TEST_TIME
			os.sleep(wait_time)
			waited = waited + wait_time
			
			-- evade
			if Turtle.Rel.detect(orientation) then
				-- goto avoid orientation -> wait TURTLE_EVADE_TIME -> go back
				local evaded = false
				-- evade to free spot
				for evade_orientation in ORIENTATIONS:it() do
					if evade_orientation ~= orientation and not Turtle.Rel.detect(evade_orientation) then
						-- found free block next to turtle
						Turtle.Rel.move(1, evade_orientation)
						os.sleep(TURTLE_EVADE_DURATION)
						Turtle.Rel.move(-1, evade_orientation)
						evaded = true
						break
					end
				end
				-- if not successful: dig and evade there
				if not evaded and self.dig then
					for evade_orientation in ORIENTATIONS:it() do
						if evade_orientation ~= orientation then
							local success, data = Turtle.Rel.inspect(evade_orientation)
							local new_block_id = Blocks.get(data.name)
							if block_id ~= 204 and block_id ~= 205 then -- not turtle
								-- found block that can be dug
								Turtle.Rel.move(1, evade_orientation, true)
								os.sleep(TURTLE_EVADE_DURATION)
								Turtle.Rel.move(-1, evade_orientation)
								break
							end
						end
					end
				end
			else
				break
			end
			
			if waited > TURTLE_EVADE_TIMEOUT then
				print("Failed evading turtle on calling operation '" .. calling_operation.name .. "'!")
				local file = fs.open("local/turtle_evade.log", "a")
				file.writeLine("Failed evading with: location=" .. tostring(Turtle.Abs.getLocation()) .. " calling_operation=" .. tostring(calling_operation.name))
				file.close()
				assert(false)
				break
			end
		end
	end
end






Mine.Plugin.MineSurroundingDeposits = {}
Mine.Plugin.MineSurroundingDeposits.__index = Mine.Plugin.MineSurroundingDeposits

function Mine.Plugin.MineSurroundingDeposits.new(deposit_filter)
	local result = {}
	setmetatable(result, Mine.Plugin.MineSurroundingDeposits)
	
	result.orientations = ArrayList.new({ORIENTATION_LEFT, ORIENTATION_FRONT, ORIENTATION_RIGHT, ORIENTATION_UP, ORIENTATION_DOWN})
	result.deposit_filter = deposit_filter
	
	return result
end

function Mine.Plugin.MineSurroundingDeposits:post_move(calling_operation, orientation_moved)
	assert(calling_operation, "No calling operation given!")
	if not calling_operation:isInGoto() and not self.disabled then
		for orientation in self.orientations:it() do
			local success, data = Turtle.Rel.inspect(orientation)
			if success and self.deposit_filter:passes(Blocks.get(data.name), data.metadata) then
				self.disabled = true
				Mine.Operation.Deposit.new(orientation):set_parent_operation(calling_operation):run()
				self.disabled = nil
			end
		end
	end
end







Mine.Plugin.DropExcessBlocks = {}
Mine.Plugin.DropExcessBlocks.__index = Mine.Plugin.DropExcessBlocks

function Mine.Plugin.DropExcessBlocks.new(drop_filter, drop_interval)
	local result = {}
	setmetatable(result, Mine.Plugin.DropExcessBlocks)
	
	result.drop_filter = drop_filter
	result.drop_interval = drop_interval or 8
	
	return result
end

function Mine.Plugin.DropExcessBlocks:init()
	self.dig_counter = 0
end

function Mine.Plugin.DropExcessBlocks:post_dig(calling_operation, orientation, block_id, block_metadata)
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







Mine.Plugin.UnloadAtWaypoint = {}
Mine.Plugin.UnloadAtWaypoint.__index = Mine.Plugin.UnloadAtWaypoint

function Mine.Plugin.UnloadAtWaypoint.new(storage_wp)
	local result = {}
	setmetatable(result, Mine.Plugin.UnloadAtWaypoint)
	
	assert(storage_wp, "No waypoint given!")
	assert(storage_wp:has_plugin(Waypoint.Plugin.Storage), "Waypoint must have Storage plugin!")
	result.storage_wp = storage_wp
	
	return result
end

function Mine.Plugin.UnloadAtWaypoint:init()
	assert(self.plugin_operation.goto_start_impl and self.plugin_operation.goto_mine_impl, "Operation does not support this plugin!")
	assert(Turtle.Abs.isCalibrated(), "Turtle must be calibrated!")
	assert(Waypoint.isCalibrated(), "Waypoint must be calibrated!")
end

function Mine.Plugin.UnloadAtWaypoint:post_dig(calling_operation, orientation, block_id, block_metadata)
	assert(calling_operation, "No calling operation given")
	if not calling_operation.goto_start or not calling_operation.goto_mine or calling_operation:isInGoto() then return end
	
	local inventory_full = true -- TODO when to empty inventory
	for i = 1, 16 do
		if turtle.getItemCount(i) == 0 then
			inventory_full = false
			break
		end
	end
	
	if inventory_full then
		print("Unloading inventory at storage... ")
	
		-- mine -> mine_start -> unload inventory at storage wp -> mine_start -> mine
		calling_operation:goto_start()
		self.storage_wp:plugin(Waypoint.Plugin.Storage):goto():unloadAll():return_()
		calling_operation:goto_mine()
		
		print("Done!")
	end
end