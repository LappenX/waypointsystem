loader.include("api/mc/turtle/operation.lua")

Operation.Plugin.PlaceSapling = {}
Operation.Plugin.PlaceSapling.__index = Operation.Plugin.PlaceSapling

function Operation.Plugin.PlaceSapling.new()
	local result = {}
	setmetatable(result, Operation.Plugin.PlaceSapling)
	
	result.not_as_parent = true
	
	return result
end

function Operation.Plugin.PlaceSapling:init()
	assert(self.plugin_operation.goto_start_impl and self.plugin_operation.goto_mine_impl, "Operation does not support this plugin!")
	assert(Turtle.Abs.hasWorldCoord(), "Turtle must be calibrated!")
	assert(Waypoint.isCalibrated(), "Waypoint must be calibrated!")
end

function Operation.Plugin.PlaceSapling:post_move(calling_operation, orientation)
	assert(calling_operation, "No calling operation given")
	if calling_operation:isInGoto() then return end

	if not Turtle.Rel.detect(ORIENTATION_DOWN) then
		local sapling_index = Turtle.Inv.find_first_passing(Filter.new(function (item_id, item_metadata) return SAPLINGS:contains(item_id) end))
		assert(sapling_index, "No saplings found!")
		turtle.select(sapling_index)
		
		Turtle.Rel.place(ORIENTATION_DOWN)
	end
end