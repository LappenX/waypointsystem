loader.include("api/mc/turtle/operation.lua")

Operation.Plugin.UnloadAtWaypoint = {}
Operation.Plugin.UnloadAtWaypoint.__index = Operation.Plugin.UnloadAtWaypoint

function Operation.Plugin.UnloadAtWaypoint.new(storage_wp)
	local result = {}
	setmetatable(result, Operation.Plugin.UnloadAtWaypoint)
	
	assert(storage_wp, "No waypoint given!")
	assert(storage_wp:has_plugin(Waypoint.Plugin.Storage), "Waypoint must have Storage plugin!")
	result.storage_wp = storage_wp
	
	return result
end

function Operation.Plugin.UnloadAtWaypoint:init()
	assert(self.plugin_operation.goto_start_impl and self.plugin_operation.goto_mine_impl, "Operation does not support this plugin!")
	assert(Turtle.Abs.isCalibrated(), "Turtle must be calibrated!")
	assert(Waypoint.isCalibrated(), "Waypoint must be calibrated!")
end

function Operation.Plugin.UnloadAtWaypoint:post_dig(calling_operation, orientation, block_id, block_metadata)
	assert(calling_operation, "No calling operation given")
	if not calling_operation.goto_start_impl or not calling_operation.goto_mine_impl or calling_operation:isInGoto() then return end
	
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