Waypoint.Plugin.RepeatStation = {}
Waypoint.Plugin.RepeatStation.__index = Waypoint.Plugin.RepeatStation
setmetatable(Waypoint.Plugin.RepeatStation, {__index = Waypoint.Plugin})

function Waypoint.Plugin.RepeatStation.new(name, operation, operation_rotation)
	local result = {}
	setmetatable(result, Waypoint.Plugin.RepeatStation)
	
	result.name = name
	result.operation = operation
	result.operation_rotation = operation_rotation
	
	result.plugin_type = Waypoint.Plugin.RepeatStation
	
	return result
end

function Waypoint.Plugin.RepeatStation:run()
	assert(self.wp, "Something went wrong, plugin waypoint not found!")
	assert(Waypoint.current() == self.wp, "Turtle is not at plugin waypoint!")
	
	print("Starting " .. self.name .. " client with turtle id " .. tostring(os.getComputerID()))
	local num = 0
	while true do
		local initial_fuel = turtle.getFuelLevel()
		
		Turtle.Abs.rotate_to(self.operation_rotation)
		self.operation:run()
		
		print("Finished round. Fuel consumption: " .. tostring(initial_fuel - turtle.getFuelLevel()))
	end
end