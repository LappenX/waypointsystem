loader.include("api/mc/turtle/operation.lua")

Operation.Plugin.RefuelLava = {}
Operation.Plugin.RefuelLava.__index = Operation.Plugin.RefuelLava

function Operation.Plugin.RefuelLava.new(abort_on_fuel_limit)
	local result = {}
	setmetatable(result, Operation.Plugin.RefuelLava)
	
	result.abort_on_fuel_limit = abort_on_fuel_limit
	
	return result
end

function Operation.Plugin.RefuelLava:init()
	self.bucket_slot = Turtle.Inv.find_first(Items.get("minecraft:bucket"))
	assert(self.bucket_slot, "Operation.Plugin.RefuelLava needs an empty bucket in the turtle's inventory!")
end

function Operation.Plugin.RefuelLava:pre_dig(calling_operation, orientation, block_id, block_metadata)
	if Blocks.get(block_id) == "minecraft:flowing_lava" and block_metadata == 0 then
		turtle.select(self.bucket_slot)
		Turtle.Rel.place(orientation)
		turtle.refuel()
		if self.abort_on_fuel_limit and turtle.getFuelLevel() >= turtle.getFuelLimit() then self.plugin_operation.abort = true end
	end
end