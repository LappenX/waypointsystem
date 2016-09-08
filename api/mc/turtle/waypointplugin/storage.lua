loader.include("api/util/datastructs/map.lua")

Waypoint.Plugin.Storage = {}
Waypoint.Plugin.Storage.__index = Waypoint.Plugin.Storage
setmetatable(Waypoint.Plugin.Storage, {__index = Waypoint.Plugin})

function Waypoint.Plugin.Storage.new(chest_rotation)
	local result = {}
	setmetatable(result, Waypoint.Plugin.Storage)
	
	result.chest_rotation = chest_rotation
	result.plugin_type = Waypoint.Plugin.Storage
	
	return result
end

function Waypoint.Plugin.Storage:unload(slot, count)
	assert(Waypoint.current() == self.wp, "Turtle is not at plugin waypoint!")
	Turtle.Abs.drop(self.chest_rotation, count, slot)
	return self
end

function Waypoint.Plugin.Storage:unloadAll(keep_amounts) -- keep_amounts: item_id -> amount
	assert(Waypoint.current() == self.wp, "Turtle is not at plugin waypoint!")
	
	local has_kept_amounts
	if keep_amounts then
		has_kept_amounts = TableMap.new()
		for item_id in keep_amounts:keys_it() do
			has_kept_amounts:put(item_id, 0)
		end
	end
	
	for i = 1, 16 do
		local data = turtle.getItemDetail(i)
		local item_id = Items.get(data.name)
		
		if keep_amounts then
			local keep_amount = keep_amounts:get(item_id)
			local has_kept_amount = has_kept_amounts:get(item_id)
			if keep_amount or has_kept_amount then
				assert(has_kept_amount and keep_amount, "Inconsistent maps!")
				local slot_keep_amount = math.max(0, math.min(keep_amount - has_kept_amount, turtle.getItemCount(i)))
				if slot_keep_amount < turtle.getItemCount(i) then
					Turtle.Abs.drop(self.chest_rotation, turtle.getItemCount(i) - slot_keep_amount, i)
				end
				has_kept_amounts:put(item_id, has_kept_amount + slot_keep_amount)
			else
				Turtle.Abs.drop(self.chest_rotation, nil, i)
			end
		else
			Turtle.Abs.drop(self.chest_rotation, nil, i)
		end
	end

	return self
end