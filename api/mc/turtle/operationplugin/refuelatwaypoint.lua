loader.include("api/mc/turtle/operation.lua")

Operation.Plugin.RefuelAtWaypoint = {}
Operation.Plugin.RefuelAtWaypoint.__index = Operation.Plugin.RefuelAtWaypoint

function Operation.Plugin.RefuelAtWaypoint.new(fuelstorage_wp, min_fuel, max_fuel)
	local result = {}
	setmetatable(result, Operation.Plugin.RefuelAtWaypoint)
	
	assert(fuelstorage_wp, "No waypoint given!")
	result.fuelstorage_wp = fuelstorage_wp
	result.min_fuel = min_fuel or 10000
	result.max_fuel = max_fuel or turtle.getFuelLimit()
	
	return result
end

function Operation.Plugin.RefuelAtWaypoint:init()
	assert(self.fuelstorage_wp:has_plugin(Waypoint.Plugin.FuelStorage), "Waypoint must have FuelStorage plugin!")
	assert(self.plugin_operation.goto_start_impl and self.plugin_operation.goto_mine_impl, "Operation does not support this plugin!")
	assert(Turtle.Abs.hasWorldCoord(), "Turtle must be calibrated!")
	assert(Waypoint.isCalibrated(), "Waypoint must be calibrated!")
end

function Operation.Plugin.RefuelAtWaypoint:pre_move(calling_operation, orientation)
	assert(calling_operation, "No calling operation given")
	if not calling_operation.goto_start_impl or not calling_operation.goto_mine_impl or calling_operation:isInGoto() then return end
	
	if turtle.getFuelLevel() < self.min_fuel then
		print("Refueling at fuel-storage... ")
	
		-- mine -> mine_start -> refuel at wp -> mine_start -> mine
		calling_operation:goto_start()
		self.fuelstorage_wp:plugin(Waypoint.Plugin.FuelStorage):goto():refuel(self.max_fuel):return_()
		calling_operation:goto_mine()
		
		print("Done!")
	end
end