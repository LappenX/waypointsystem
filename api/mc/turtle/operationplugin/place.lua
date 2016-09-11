loader.include("api/mc/turtle/operation.lua")
loader.include("api/mc/blocks.lua")

Operation.Plugin.Place = {}
Operation.Plugin.Place.__index = Operation.Plugin.Place

function Operation.Plugin.Place.new(orientation, place_filter)
	local result = {}
	setmetatable(result, Operation.Plugin.Place)
	
	result.not_as_parent = true
	result.orientation = orientation
	result.place_filter = place_filter
	
	return result
end

function Operation.Plugin.Place:pre_move(calling_operation, orientation)
	assert(calling_operation, "No calling operation given")
	if calling_operation:isInGoto() or Turtle.Rel.detect(self.orientation) then return end

	local first_slot = turtle.getSelectedSlot() - 1
	for i = 0, 15 do
		local cur_slot = ((first_slot + i) % 16) + 1
		
		local data = turtle.getItemDetail(cur_slot)
		if data and self.place_filter:passes(Items.get(data.name), data.damage) then
			turtle.select(cur_slot)
			calling_operation:place(self.orientation)
			return
		end
	end
	error("No placable items left!")
end