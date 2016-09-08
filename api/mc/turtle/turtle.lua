--[[ DOC

ORIENTATION_FRONT, ORIENTATION_BACK, ORIENTATION_UP, ORIENTATION_DOWN, ORIENTATION_RIGHT, ORIENTATION_LEFT

ROTATION_SOUTH, ROTATION_WEST, ROTATION_NORTH, ROTATION_EAST, ROTATION_UP, ROTATION_DOWN
ROTATION_POSITIVE_X, ROTATION_NEGATIVE_X, ROTATION_POSITIVE_Y, ROTATION_NEGATIVE_Y, ROTATION_POSITIVE_Z, ROTATION_NEGATIVE_Z

-- logging

function Turtle.log(enabled)


-- tracing

function Turtle.trace()
function Turtle.backtrace()


-- relative

function Turtle.Rel.rotate_by(angle)
function Turtle.Rel.move(distance, orientation, dig, always_forward)
function Turtle.Rel.move_dim(distance, dim, dig, always_forward)

function Turtle.Rel.detect(orientation)
function Turtle.Rel.inspect(orientation)
function Turtle.Rel.place(orientation)
function Turtle.Rel.drop(orientation, count, slot)
function Turtle.Rel.dig(orientation, retry)
function Turtle.Rel.suck(orientation, count)

function Turtle.Rel.drop_all_of(item_id, item_metadata, orientation)

function Turtle.Rel.opposite(orientation)


-- absolute

function Turtle.Abs.rotate_to(target_rot)
function Turtle.Abs.move_by(vec, dig)
function Turtle.Abs.move_to(target_location, dig)

function Turtle.Abs.calibrate(x, y, z, rot)
function Turtle.Abs.isCalibrated()
function Turtle.Abs.getLocation()
function Turtle.Abs.getRotation() FINALIZED

function Turtle.Abs.detect(rotation)
function Turtle.Abs.inspect(rotation)
function Turtle.Abs.place(rotation)
function Turtle.Abs.drop(rotation, count, slot)
function Turtle.Abs.dig(rotation, retry)
function Turtle.Abs.suck(orientation, count)

function Turtle.Abs.opposite(rotation)
function Turtle.Abs.to_orientation(rotation)

-- inventory
function Turtle.Inv.has(item_id, item_metadata)
function Turtle.Inv.find_first(item_id, item_metadata)
function Turtle.Inv.take_all_of(item_id, item_metadata, push_direction)
function Turtle.Inv.take_all_of_first(push_direction, retry)

--]]

loader.include("api/util/functional.lua")
loader.include("api/util/math/math.lua")
loader.include("api/util/math/vec.lua")
loader.include("api/util/datastructs/list.lua")

MOVE_WAITTIME = 0.1
DIG_CHECKTIME = 0.1
TAKE_ALL_WAIT_TIME = 0.5
ORIENTATION_FRONT, ORIENTATION_BACK, ORIENTATION_UP, ORIENTATION_DOWN, ORIENTATION_RIGHT, ORIENTATION_LEFT = 0, 1, 2, 3, 4, 5

ORIENTATIONS = ArrayList.new({ORIENTATION_UP, ORIENTATION_DOWN, ORIENTATION_FRONT, ORIENTATION_RIGHT, ORIENTATION_BACK, ORIENTATION_LEFT}) -- in minimal movement order

Turtle = {}
Turtle.Rel = {}
Turtle.Abs = {}
Turtle.Inv = {}





local turtle_location, turtle_rotation
local turtle_calibrated = false




local LOG_FILE = "local/turtle.log"
local log_enabled = false

function Turtle.log(enabled)
	log_enabled = enabled
end

local function turtle_log()
	if not log_enabled then return end
	
	if Turtle.Abs.isCalibrated() then
		local file = fs.open(LOG_FILE, "w")
		file.writeLine("location=" .. tostring(Turtle.Abs.getLocation()))
		file.writeLine("rotation=" .. tostring(turtle_rotation))
		file.close()
	end
end







local pending_rotation = 0
local function finalize_rotation()
	pending_rotation = mod_(pending_rotation, 4)
	
	-- adjust rotation variable
	if turtle_calibrated then turtle_rotation = mod_(turtle_rotation + pending_rotation, 4) end
	
	if (pending_rotation == 3) then
		turtle.turnLeft()
	elseif (pending_rotation > 0) then
		repeat_(pending_rotation, turtle.turnRight)()
	end
	pending_rotation = 0
end

function Turtle.Abs.calibrate(x, y, z, rot)
	turtle_location = Vec.new(x, y, z)
	turtle_rotation = rot
	turtle_calibrated = true
end

function Turtle.Abs.isCalibrated()
	return not not turtle_calibrated
end

function Turtle.Abs.getLocation()
	assert(Turtle.Abs.isCalibrated(), "Turtle must be calibrated to use absolute movement!")
	return turtle_location
end

function Turtle.Abs.getRotation()
	assert(Turtle.Abs.isCalibrated(), "Turtle must be calibrated to use absolute movement!")
	return mod_(turtle_rotation + pending_rotation, 4)
end

function Turtle.Abs.move_by(vec, dig)
	assert(Turtle.Abs.isCalibrated(), "Turtle must be calibrated to use absolute movement!")

	local cur_loc = Turtle.Abs.getLocation()
	local target_loc = cur_loc + vec
	
	while target_loc ~= Turtle.Abs.getLocation() do
		cur_loc = cur_loc + (target_loc - cur_loc):normalize()

		local max_val, max_dim = (cur_loc - Turtle.Abs.getLocation()):abs():max_value()
		max_val = (cur_loc - Turtle.Abs.getLocation()):get(max_dim)
		
		-- move one block in direction max_dim
		if math.abs(max_val) >= 1 then
			Turtle.Abs.rotate_to(ROTATION_POSITIVE_X) -- forward = positive x          right = positive z
			Turtle.Rel.move_dim(sign(max_val), max_dim, dig)
		end
	end
end

function Turtle.Abs.move_to(target_location, dig)
	return Turtle.Abs.move_by(target_location - Turtle.Abs.getLocation(), dig)
end

function Turtle.Abs.rotate_to(target_rot)
	assert(target_rot >= 0 and target_rot < 6, "Invalid rotation!")
	if target_rot < 4 then Turtle.Rel.rotate_by(target_rot - Turtle.Abs.getRotation()) end
end

function Turtle.Abs.detect(rotation)
	return Turtle.Rel.detect(Turtle.Abs.to_orientation(rotation))
end

function Turtle.Abs.inspect(rotation)
	return Turtle.Rel.inspect(Turtle.Abs.to_orientation(rotation))
end

function Turtle.Abs.place(rotation)
	return Turtle.Rel.place(Turtle.Abs.to_orientation(rotation))
end

function Turtle.Abs.drop(rotation, count, slot)
	return Turtle.Rel.drop(Turtle.Abs.to_orientation(rotation), count, slot)
end

function Turtle.Abs.suck(rotation, count)
	return Turtle.Rel.suck(Turtle.Abs.to_orientation(rotation), count)
end

function Turtle.Abs.dig(rotation, retry)
	return Turtle.Rel.dig(Turtle.Abs.to_orientation(rotation), retry)
end

function Turtle.Abs.opposite(rotation)
	return select_(rotation,
		ROTATION_NORTH,					-- case ROTATION_SOUTH
		ROTATION_EAST, 					-- case ROTATION_WEST
		ROTATION_SOUTH, 				-- case ROTATION_NORTH
		ROTATION_WEST, 					-- case ROTATION_EAST
		ROTATION_DOWN, 					-- case ROTATION_UP
		ROTATION_UP						-- case ROTATION_DOWN
	)
end

function Turtle.Abs.to_orientation(rotation)
	if rotation == ROTATION_UP then return ORIENTATION_UP end
	if rotation == ROTATION_DOWN then return ORIENTATION_DOWN end
	return select_(mod_(rotation - Turtle.Abs.getRotation(), 4),
		ORIENTATION_FRONT,
		ORIENTATION_RIGHT,
		ORIENTATION_BACK,
		ORIENTATION_LEFT
	)
end




local trace_stacks = ArrayList.new()
local backtracing = false

local function push_trace(func)
	if not trace_stacks:is_empty() and not backtracing then
		trace_stacks:top():push(func)
	end
end

function Turtle.trace()
	trace_stacks:push(ArrayList.new())
end

function Turtle.backtrace()
	assert(not trace_stacks:is_empty(), "Cannot backtrace without a trace!")
	
	backtracing = true
	while not trace_stacks:top():is_empty() do
		trace_stacks:top():pop()()
	end
	backtracing = false
	
	trace_stacks:pop()
end








-- schedule rotation by angle, or finalize rotation if angle is nil
function Turtle.Rel.rotate_by(angle)
	if (angle) then
		push_trace(app(Turtle.Rel.rotate_by, -angle))
		pending_rotation = mod_(pending_rotation + angle, 4)
	else
		finalize_rotation()
	end
end

-- (x, y, z) = (forward, up, right), dim in {0, 1, 2}
function Turtle.Rel.move_dim(distance, dim, dig, always_forward)
	assert(0 <= dim and dim <= 2, "Invalid dimension!")
	if distance == 0 then
		return
	end
	if pending_rotation == 2 and dim == 0 then
		Turtle.Rel.rotate_by(2)
		local result = {Turtle.Rel.move_dim(-distance, dim, dig, always_forward)}
		Turtle.Rel.rotate_by(2)
		return unpack(result)
	end
	
	distance = distance or 1
	dim = dim or 0
	dig = dig or false
	always_forward = always_forward or (dim == 0 and pending_rotation % 2 == 1) or (dim == 2 and pending_rotation % 2 == 0)
	
	push_trace(app(Turtle.Rel.move_dim, -distance, dim, dig))
	
	local f_dig =  select_(dim,
					consec(1, finalize_rotation, app(Turtle.Rel.dig, ORIENTATION_FRONT, true)),
					if_(distance > 0, app(Turtle.Rel.dig, ORIENTATION_UP, true), app(Turtle.Rel.dig, ORIENTATION_DOWN, true)),
					consec(1, finalize_rotation, app(Turtle.Rel.dig, ORIENTATION_FRONT, true)))
	local f_move = select_(dim,
					consec(1, finalize_rotation, if_(distance > 0 or always_forward, turtle.forward, turtle.back)),
					if_(distance > 0, turtle.up, turtle.down),
					consec(1, finalize_rotation, turtle.forward))
	
	-- initial orientation
	if always_forward and distance < 0 and dim == 0 then Turtle.Rel.rotate_by(2) end
	local turned_x = false
	if dim == 2 then Turtle.Rel.rotate_by(if_(distance > 0, 1, -1)) end
	
	-- movement
	for i = 1, math.abs(distance) do
		assert(turtle.getFuelLevel() > 0, "No fuel left!")
		while not f_move() do
			-- in x-direction use turtle.back till blocked, then turn around and use turtle.forward
			if dim == 0 and distance < 0 and not turned_x and not always_forward then
				Turtle.Rel.rotate_by(2)
				f_move = consec(1, finalize_rotation, turtle.forward)
				turned_x = true
			end
			
			if dig then f_dig() else os.sleep(MOVE_WAITTIME) end
		end
	end
	
	-- reset orientation
	if always_forward and distance < 0 and dim == 0 then Turtle.Rel.rotate_by(2) end
	if turned_x then Turtle.Rel.rotate_by(2) end
	if dim == 2 then Turtle.Rel.rotate_by(if_(distance > 0, -1, 1)) end
	
	-- adjust location variable
	if turtle_calibrated then
		if dim == 1 then
			turtle_location = turtle_location + Vec.new(0, distance, 0)
		else
			turtle_location = turtle_location + Vec3.new_by_rotation(mod_(Turtle.Abs.getRotation() + if_(dim == 2, 1, 0), 4), distance)
		end
	end
	
	turtle_log()
end

function Turtle.Rel.move(distance, orientation, dig, always_forward)
	distance = distance or 1
	orientation = orientation or ORIENTATION_FRONT
	dig = dig or false

	dim = select_(orientation,
		0, 							-- case ORIENTATION_FRONT
		0, 							-- case ORIENTATION_BACK
		1, 							-- case ORIENTATION_UP
		1, 							-- case ORIENTATION_DOWN
		2, 							-- case ORIENTATION_RIGHT
		2							-- case ORIENTATION_LEFT
	)
	distance = select_(orientation,
		distance, 						-- case ORIENTATION_FRONT
		-distance, 						-- case ORIENTATION_BACK
		distance, 						-- case ORIENTATION_UP
		-distance, 						-- case ORIENTATION_DOWN
		distance, 						-- case ORIENTATION_RIGHT
		-distance						-- case ORIENTATION_LEFT
	)
	return Turtle.Rel.move_dim(distance, dim, dig, always_forward)
end

function Turtle.Rel.opposite(orientation)
	return select_(orientation,
		ORIENTATION_BACK,					-- case ORIENTATION_FRONT
		ORIENTATION_FRONT, 					-- case ORIENTATION_BACK
		ORIENTATION_DOWN, 					-- case ORIENTATION_UP
		ORIENTATION_UP, 					-- case ORIENTATION_DOWN
		ORIENTATION_LEFT, 					-- case ORIENTATION_RIGHT
		ORIENTATION_RIGHT					-- case ORIENTATION_LEFT
	)
end

-- Wrapper functions for turtle api
local function set_orientation(orientation)
	select_(orientation,
		finalize_rotation, 									-- case ORIENTATION_FRONT
		consec(app(Turtle.Rel.rotate_by, 2), finalize_rotation), 	-- case ORIENTATION_BACK
		nop, 												-- case ORIENTATION_UP
		nop, 												-- case ORIENTATION_DOWN
		consec(app(Turtle.Rel.rotate_by, 1), finalize_rotation), 	-- case ORIENTATION_RIGHT
		consec(app(Turtle.Rel.rotate_by, -1), finalize_rotation) 	-- case ORIENTATION_LEFT
	)()
end
local function reset_orientation(orientation)
	select_(orientation,
		nop,								-- case ORIENTATION_FRONT
		app(Turtle.Rel.rotate_by, 2), 				-- case ORIENTATION_BACK
		nop, 								-- case ORIENTATION_UP
		nop, 								-- case ORIENTATION_DOWN
		app(Turtle.Rel.rotate_by, -1), 			-- case ORIENTATION_RIGHT
		app(Turtle.Rel.rotate_by, 1) 				-- case ORIENTATION_LEFT
	)()
end
local function dig(orientation)
	local f_dig = turtle.dig
	local f_digUp = turtle.digUp
	local f_digDown = turtle.digDown
	
	-- miny chunky peripheral fix
	for k, peripheral_side in pairs(peripheral.getNames()) do
		if peripheral.getType(peripheral_side) == "Miny Chunky Module" then
			local miny_chunky_peripheral = peripheral.wrap(peripheral_side)
			f_dig = miny_chunky_peripheral.dig
			f_digUp = miny_chunky_peripheral.digUp
			f_digDown = miny_chunky_peripheral.digDown
			break
		end
	end
	
	return select_(orientation,
		f_dig, 							-- case ORIENTATION_FRONT
		f_dig, 							-- case ORIENTATION_BACK
		f_digUp, 						-- case ORIENTATION_UP
		f_digDown, 						-- case ORIENTATION_DOWN
		f_dig, 							-- case ORIENTATION_RIGHT
		f_dig 							-- case ORIENTATION_LEFT
	)()
end
local function detect(orientation)
	return select_(orientation,
		turtle.detect, 						-- case ORIENTATION_FRONT
		turtle.detect, 						-- case ORIENTATION_BACK
		turtle.detectUp, 					-- case ORIENTATION_UP
		turtle.detectDown, 					-- case ORIENTATION_DOWN
		turtle.detect, 						-- case ORIENTATION_RIGHT
		turtle.detect 						-- case ORIENTATION_LEFT
	)()
end
local function inspect(orientation)
	return select_(orientation,
		turtle.inspect, 					-- case ORIENTATION_FRONT
		turtle.inspect, 					-- case ORIENTATION_BACK
		turtle.inspectUp, 					-- case ORIENTATION_UP
		turtle.inspectDown, 				-- case ORIENTATION_DOWN
		turtle.inspect, 					-- case ORIENTATION_RIGHT
		turtle.inspect 						-- case ORIENTATION_LEFT
	)()
end
local function place(orientation)
	return select_(orientation,
		turtle.place, 						-- case ORIENTATION_FRONT
		turtle.place, 						-- case ORIENTATION_BACK
		turtle.placeUp, 					-- case ORIENTATION_UP
		turtle.placeDown, 					-- case ORIENTATION_DOWN
		turtle.place, 						-- case ORIENTATION_RIGHT
		turtle.place 						-- case ORIENTATION_LEFT
	)()
end
local function suck(orientation)
	return select_(orientation,
		turtle.suck, 						-- case ORIENTATION_FRONT
		turtle.suck, 						-- case ORIENTATION_BACK
		turtle.suckUp, 						-- case ORIENTATION_UP
		turtle.suckDown, 					-- case ORIENTATION_DOWN
		turtle.suck, 						-- case ORIENTATION_RIGHT
		turtle.suck 						-- case ORIENTATION_LEFT
	)()
end
local function drop(orientation, count)
	local func = select_(orientation,
		turtle.drop, 						-- case ORIENTATION_FRONT
		turtle.drop, 						-- case ORIENTATION_BACK
		turtle.dropUp, 						-- case ORIENTATION_UP
		turtle.dropDown, 					-- case ORIENTATION_DOWN
		turtle.drop, 						-- case ORIENTATION_RIGHT
		turtle.drop 						-- case ORIENTATION_LEFT
	)
	if count then
		return func(count)
	else
		return func()
	end
end

function Turtle.Rel.detect(orientation)
	orientation = orientation or ORIENTATION_FRONT
	
	set_orientation(orientation)
	local result = {detect(orientation)}
	reset_orientation(orientation)
	return unpack(result)
end

function Turtle.Rel.inspect(orientation)
	orientation = orientation or ORIENTATION_FRONT
	
	set_orientation(orientation)
	local result = {inspect(orientation)}
	reset_orientation(orientation)
	return unpack(result)
end

function Turtle.Rel.place(orientation)
	orientation = orientation or ORIENTATION_FRONT
	
	set_orientation(orientation)
	local result = {place(orientation)}
	reset_orientation(orientation)
	return unpack(result)
end

function Turtle.Rel.suck(orientation)
	orientation = orientation or ORIENTATION_FRONT
	
	set_orientation(orientation)
	local result = {suck(orientation)}
	reset_orientation(orientation)
	return unpack(result)
end

function Turtle.Rel.drop(orientation, count, slot)
	if (count and count <= 0) or turtle.getItemCount(slot or turtle.getSelectedSlot()) <= 0 then return false end

	orientation = orientation or ORIENTATION_FRONT
	
	local old_slot = nil
	if slot and slot ~= turtle.getSelectedSlot() then
		old_slot = turtle.getSelectedSlot()
		turtle.select(slot)
	end
	
	set_orientation(orientation)
	local result = {drop(orientation, count)}
	reset_orientation(orientation)
	
	if old_slot then
		turtle.select(old_slot)
	end
	
	return unpack(result)
end

function Turtle.Rel.drop_all_of(item_id, item_metadata, orientation)
	orientation = orientation or ORIENTATION_FRONT
	
	for i = 1, 16 do
		local data = turtle.getItemDetail(i)
		if data and data.count > 0 and (not item_id or data.name == Items.get(item_id)) and (not item_metadata or data.damage == item_metadata) then
			turtle.select(i)
			Turtle.Rel.drop(orientation)
		end
	end
end


function Turtle.Rel.dig(orientation, retry)
	retry = retry or false
	
	local has_dug = false
	set_orientation(orientation)
	repeat
		if detect(orientation) then
			has_dug = dig(orientation)
			if retry then os.sleep(DIG_CHECKTIME) end
		else
			break
		end
	until not retry
	reset_orientation(orientation)

	return has_dug
end

function Turtle.Inv.has(item_id, item_metadata)
	return Turtle.Inv.find_first(item_id, item_metadata)
end

function Turtle.Inv.find_first(item_id, item_metadata)
	for i = 1, 16 do
		local data = turtle.getItemDetail(i)
		if data and data.count > 0 and Items.get(data.name) == item_id and (not item_metadata or data.damage == item_metadata) then
			return i
		end
	end
	return nil
end

function Turtle.Inv.find_first_passing(filter) -- filter.passes(item_id, item_metadata)
	assert(filter, "No filter given!")
	assert(filter.passes, "Invalid filter given!")
	
	for i = 1, 16 do
		local data = turtle.getItemDetail(i)
		if data and filter:passes(Items.get(data.name), data.damage) then
			return i
		end
	end
	return nil
end

--[[
function Turtle.Inv.take(item_id, item_metadata, amount, push_direction)
	assert(push_direction or Turtle.Abs.isCalibrated(), "Turtle must be calibrated or push direction must be given!")
	if push_direction and Turtle.Abs.isCalibrated() then assert(Turtle.Abs.opposite(Turtle.Abs.getRotation()) == push_direction, "Given push direction must equal turtle's rotation!") end
	
	Turtle.Rel.rotate_by()
	local chest = peripheral.wrap("front")
	local initial_amount = amount
	for i = 1, chest.getInventorySize() do
		if amount == 0 then break end
		local item = chest.getStackInSlot(i)
		if item and Items.get(item.id) == item_id and (not item_metadata or item.dmg == item_metadata) then
			amount = amount - chest.pushItem(rotation_to_string(push_direction), i, amount)
		end
	end
	return initial_amount - amount
end

function Turtle.Inv.take_all_of(item_id, item_metadata, push_direction)
	assert(push_direction or Turtle.Abs.isCalibrated(), "Turtle must be calibrated or push direction must be given!")
	if push_direction and Turtle.Abs.isCalibrated() then assert(Turtle.Abs.opposite(Turtle.Abs.getRotation()) == push_direction, "Given push direction must equal turtle's rotation!") end
	
	Turtle.Rel.rotate_by()
	local chest = peripheral.wrap("front")
	for i = 1, chest.getInventorySize() do
		local item = chest.getStackInSlot(i)
		if item and Items.get(item.id) == item_id and (not item_metadata or item.dmg == item_metadata) then
			chest.pushItem(rotation_to_string(push_direction), i)
		end
	end
end

function Turtle.Inv.take_all_of_first(push_direction, retry)
	local result = false
	repeat
		Turtle.Rel.rotate_by()
		local chest = peripheral.wrap("front")
		for i = 1, chest.getInventorySize() do
			local item = chest.getStackInSlot(i)
			if item then
				Turtle.Inv.take_all_of(Items.get(item.id), item.dmg, push_direction)
				result = true
				break
			end
		end
		if not result and retry then os.sleep(TAKE_ALL_WAIT_TIME) end
	until result or not retry
	return result
end--]]