loader.include("api/util/datastructs/map.lua")

Waypoint.Plugin.FuelStorage = {}
Waypoint.Plugin.FuelStorage.__index = Waypoint.Plugin.FuelStorage
setmetatable(Waypoint.Plugin.FuelStorage, {__index = Waypoint.Plugin})

function Waypoint.Plugin.FuelStorage.new(suck_rotation, drop_rotation)
	local result = {}
	setmetatable(result, Waypoint.Plugin.FuelStorage)
	
	result.suck_rotation = suck_rotation
	result.drop_rotation = drop_rotation
	result.plugin_type = Waypoint.Plugin.FuelStorage
	
	return result
end

function Waypoint.Plugin.FuelStorage:refuel(max_fuel)
	assert(Waypoint.current() == self.wp, "Turtle is not at plugin waypoint!")
	
	while turtle.getFuelLevel() < max_fuel do
		Turtle.Inv.select_first_empty()
		Turtle.Abs.suck(self.suck_rotation)
		assert(turtle.refuel(0), "No fuel left!")
		while turtle.refuel(1) and turtle.getFuelLevel() < max_fuel do end
		if turtle.refuel(0) then
			Turtle.Abs.drop(self.suck_rotation)
		else
			Turtle.Abs.drop(self.drop_rotation)
		end
	end
	return self
end