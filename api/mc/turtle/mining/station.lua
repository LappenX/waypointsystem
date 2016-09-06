loader.include("api/util/serialize.lua")
loader.include("api/util/math/vec.lua")
loader.include("api/util/string.lua")
loader.include("api/mc/turtle/turtle.lua")
loader.include("api/mc/net.lua")
loader.include("api/mc/turtle/waypoint.lua")

Mine.Station = {}
Mine.Station.__index = Mine.Station

local HOST_NAME = "host"

local StationCommand = {CLIENT_START = 1, CLIENT_FINISH = 2}

--dirs(minmin, minmaj, maj), rectangle_size(minmin, minmaj, optional maj)
function Mine.Station.new(operation, name, directions, rectangle_size, operation_rotation, starting_wp)
	local result = {}
	setmetatable(result, Mine.Station)
	assert(operation.size, "Mining operation must have size() function!")
	
	result.operation = operation
	result.name = name
	result.save_file = "disk/local/" .. name .. "_save.txt"
	result.protocol = "protocol_" .. name
	result.directions = directions
	result.starting_wp = starting_wp
	result.rectangle_size = rectangle_size
	result.operation_rotation = operation_rotation
	
	return result
end

function Mine.Station:save()
	os.sleep(1)
	assert(peripheral.find("drive"), "No disk drive found!")
	assert(peripheral.find("drive").isDiskPresent(), "No disk found!")
	assert(peripheral.find("drive").hasData(), "No floppy disk found!")
	
	assert(self.next_pos, "Must load before saving!")
	local file = fs.open(self.save_file, "w")
	file.write(serialize(self.next_pos.values))
	file.close()
end

function Mine.Station:load_(no_wait)
	if not no_wait then os.sleep(1) end
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

function Mine.Station:get_next_pos()
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

function Mine.Station:run(client_terminate_condition)
	if turtle then
		self:run_client(client_terminate_condition)
	else
		self:run_server()
	end
end

function Mine.Station:run_client(client_terminate_condition)
	local return_wp = Waypoint.current()
	
	print("Starting station client with id " .. tostring(os.getComputerID()))
	
	Net.init()
	local server_id = nil
	if peripheral.find("modem") then
		server_id = rednet.lookup(self.protocol, HOST_NAME)
	end
	if server_id then
		print("Found station server!")
	else
		print("Running without station server!")
		Net.deinit()
	end
	
	while not client_terminate_condition:passes() do
		local initial_fuel = turtle.getFuelLevel()
		local next_pos = self:get_next_pos()
		if not next_pos then return end
		print("Starting operation at position=(" .. tostring(next_pos) .. ")")
		
		if server_id then Net.send(server_id, self.protocol, StationCommand.CLIENT_START, next_pos.values, turtle.getFuelLevel()) end
		
		-- leaving disk drive
		self.starting_wp:goto()
		Turtle.Abs.rotate_to(self.operation_rotation)
		
		local size = self.operation:size()
		local offset_op = Mine.Operation.Offset.new(
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
		offset_op:add_plugin(Mine.Plugin.EvadeTurtles.new())
		offset_op:append(self.operation)
		
		offset_op:run()
		
		return_wp:goto()
		-- returned to disk drive
		
		if server_id then Net.send(server_id, self.protocol, StationCommand.CLIENT_FINISH, turtle.getFuelLevel()) end
		
		print("Finished. Fuel consumption: " .. tostring(initial_fuel - turtle.getFuelLevel()))
	end
	
	Net.deinit()
	print("Terminate condition reached!")
end

function Mine.Station:run_server()
	self:load_()

	local clients = ListMap.new()
	local function redraw()
		term.clear()
		term.setCursorPos(1, 1)
		print("Station server " .. tostring(self.name))
		print("Next position: " .. tostring(self.next_pos))
		print("")
		print(" -- Clients -- ")
		print(make_length("id", 5, false) .. make_length("position", 10, false) .. make_length("init fuel", 12, false) .. make_length("time (sec)", 10, false))
		for client in clients:values_it() do
			print(make_length(tostring(client.id), 5, false) .. make_length(tostring(client.pos), 10, false) .. make_length(tostring(client.initial_fuel), 12, false) .. make_length(tostring(math.floor(os.clock() - client.start_time)), 10, false))
		end
	end

	parallel.waitForAll(
		function()
			local net_receiver = NetReceiver.new(self.protocol)
			net_receiver:addHandler(StationCommand.CLIENT_START,
				function(client_id_, pos_values, initial_fuel_)
					local pos_ = Vec.new()
					pos_.values = pos_values
					clients:put(client_id_, {id = client_id_, pos = pos_, initial_fuel = initial_fuel_, start_time = os.clock()})
					
					self:load_(true)
					
					redraw()
				end
			)
			net_receiver:addHandler(StationCommand.CLIENT_FINISH,
				function(client_id, final_fuel)
					local fuel_consumption = final_fuel - clients:get(client_id).initial_fuel
					local operation_duration = os.clock() - clients:get(client_id).start_time
				
					clients:remove(client_id)
					
					redraw()
				end
			)
			
			Net.init()
			rednet.host(self.protocol, HOST_NAME)
			
			net_receiver:run()
			
			rednet.unhost(self.protocol, HOST_NAME)
			Net.deinit()
		end,
		function()
			while true do
				redraw()
				os.sleep(1)
			end
		end
	)
end