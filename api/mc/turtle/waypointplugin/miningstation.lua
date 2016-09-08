Waypoint.Plugin.MiningStation = {}
Waypoint.Plugin.MiningStation.__index = Waypoint.Plugin.MiningStation
setmetatable(Waypoint.Plugin.MiningStation, {__index = Waypoint.Plugin})

function Waypoint.Plugin.MiningStation.new(operation, directions, rectangle_size, operation_rotation, client_terminate_condition)
	local result = {}
	setmetatable(result, Waypoint.Plugin.MiningStation)
	
	result.operation = operation
	result.save_file = "disk/local/mining_station_save.txt"
	result.directions = directions
	result.rectangle_size = rectangle_size
	result.operation_rotation = operation_rotation
	result.client_terminate_condition = client_terminate_condition
	
	result.plugin_type = Waypoint.Plugin.MiningStation
	
	return result
end

function Waypoint.Plugin.MiningStation:save()
	os.sleep(1)
	assert(peripheral.find("drive"), "No disk drive found!")
	assert(peripheral.find("drive").isDiskPresent(), "No disk found!")
	assert(peripheral.find("drive").hasData(), "No floppy disk found!")
	
	assert(self.next_pos, "Must load before saving!")
	local file = fs.open(self.save_file, "w")
	file.write(serialize(self.next_pos.values))
	file.close()
end

function Waypoint.Plugin.MiningStation:load_()
	os.sleep(1)
	assert(peripheral.find("drive"), "No disk drive found!")
	assert(peripheral.find("drive").isDiskPresent(), "No disk found!")
	assert(peripheral.find("drive").hasData(), "No floppy disk found!")
	
	if fs.exists(self.save_file) then
		local file = fs.open(self.save_file, "r")
		self.next_pos = Vec.new()
		self.next_pos.values = deserialize(file.readAll())
		file.close()
	else
		self.next_pos = Vec.new_by_dims(self.directions:size(), 0)
	end
end

function Waypoint.Plugin.MiningStation:getNextPos()
	self:load_()

	local result = self.next_pos
	if not result then return nil end
	
	for i = 0, self.next_pos:dims() - 1 do
		self.next_pos = self.next_pos:add_to(i, 1)
		if self.next_pos:get(i) >= self.rectangle_size:get(i) then
			self.next_pos:set(i, 0)
		else
			break
		end
	end
	
	self:save()
	
	return result
end

function Waypoint.Plugin.MiningStation:run()
	assert(self.wp, "Something went wrong, plugin waypoint not found!")
	assert(Waypoint.current() == self.wp, "Turtle is not at plugin waypoint!")
	
	print("Starting station client with turtle id " .. tostring(os.getComputerID()))
	
	local num = 0
	while not self.client_terminate_condition:passes(num) do
		local initial_fuel = turtle.getFuelLevel()
		local next_pos = self:getNextPos()
		if not next_pos then break end
		print("Starting operation at position (" .. tostring(next_pos) .. ")")
		
		-- leaving disk drive
		Turtle.Abs.rotate_to(self.operation_rotation)
		
		local size = self.operation:size()
		local offset_op = Operation.Offset.new(
			function(f_move) -- f_goto_start
				for i = 0, next_pos:dims() - 1 do
					f_move(-math.abs(size:get_by_rotation(self.directions:get(i)) * next_pos:get(i)), Turtle.Abs.to_orientation(self.directions:get(i)))
				end
			end,
			function(f_move) -- f_goto_mine
				for i = 0, next_pos:dims() - 1 do
					f_move(math.abs(size:get_by_rotation(self.directions:get(i)) * next_pos:get(i)), Turtle.Abs.to_orientation(self.directions:get(i)))
				end
			end
		)
		offset_op:add_plugin(Operation.Plugin.EvadeTurtles.new())
		offset_op:append(self.operation)
		
		offset_op:run()
		-- returned to disk drive
		num = num + 1
		print("Finished. Fuel consumption: " .. tostring(initial_fuel - turtle.getFuelLevel()))
	end
	
	print(if_(self.client_terminate_condition:passes(num), "Terminate condition reached!", "No next mining position left!"))
end