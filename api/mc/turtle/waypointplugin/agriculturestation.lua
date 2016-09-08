Waypoint.Plugin.AgricultureStation = {}
Waypoint.Plugin.AgricultureStation.__index = Waypoint.Plugin.AgricultureStation
setmetatable(Waypoint.Plugin.AgricultureStation, {__index = Waypoint.Plugin})

function Waypoint.Plugin.AgricultureStation.new(operation_rotation, right, width, length)
	local result = {}
	setmetatable(result, Waypoint.Plugin.AgricultureStation)
	
	result.operation = Mine.Operation.BranchS.new(length, width, 1, right)
	result.operation_rotation = operation_rotation
	result.rectangle_size = rectangle_size
	
	result.plugin_type = Waypoint.Plugin.AgricultureStation
	
	return result
end

function Waypoint.Plugin.AgricultureStation:run()
	assert(self.wp, "Something went wrong, plugin waypoint not found!")
	assert(Waypoint.current() == self.wp, "Turtle is not at plugin waypoint!")
	
	print("Starting agriculture client with turtle id " .. tostring(os.getComputerID()))
	local num = 0
	while true do
		local initial_fuel = turtle.getFuelLevel()
		
		Turtle.Abs.rotate_to(self.operation_rotation)
		self.operation:run()
		
		print("Finished. Fuel consumption: " .. tostring(initial_fuel - turtle.getFuelLevel()))
	end
end