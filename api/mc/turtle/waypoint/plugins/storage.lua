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

function Waypoint.Plugin.Storage:unloadAll()
	assert(Waypoint.current() == self.wp, "Turtle is not at plugin waypoint!")
	for i = 1, 16 do
		Turtle.Abs.drop(self.chest_rotation, nil, i)
	end
	return self
end