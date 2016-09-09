--[[

function Waypoint:distance(wp) ---------------- TODO only neighbours so far --------------------------------

function Waypoint.current()

function Waypoint.get(id)
function Waypoint.add(wp)
function Waypoint.calibrate(wp)
function Waypoint.isCalibrated()
function Waypoint.makeHere(id)

function Waypoint.goto(target_wp)

function Waypoint:plugin(plugin_type)
function Waypoint:has_plugin(plugin_type)







function Waypoint.Plugin:goto()
function Waypoint.Plugin:return_()

Waypoint.Plugin.Storage.new(chest_rotation)
function Waypoint.Plugin.Storage:unload(slot, count)
function Waypoint.Plugin.Storage:unloadAll()

]]--

loader.include("api/util/math/math.lua")
loader.include("api/util/math/vec.lua")
loader.include("api/mc/turtle/turtle.lua")
loader.include("api/util/datastructs/map.lua")
loader.include("api/util/functional.lua")
loader.include("api/util/string.lua")
loader.include("api/util/serialize.lua")
loader.include("api/mc/net.lua")

WAYPOINTS_FILE = "wp/waypoints.txt"
WAYPOINTS_FILE_COMMENT = "#"


Waypoint = {}
Waypoint.__index = Waypoint




local wps_loaded = false
local wps = TableMap.new()
local current_wp = nil

function Waypoint.new(id, location, next_ids, plugin_tokens)
	local result = {}
	setmetatable(result, Waypoint)
	
	if not id then
		id = 0
		while wps:contains_key(id) do
			id = id + 1
		end
	end
	result.id = id
	
	result.location = location
	result.incoming = ArrayList.new()
	result.outgoing = ArrayList.new()
	result.routing_table = ListMap.new() -- map: target_wp -> next_wp
	result.plugins = ListMap.new()
	result.plugin_tokens = plugin_tokens
	
	-- temporary
	result.next_ids = next_ids

	return result
end

function Waypoint:distance(wp)
	return (self.location - wp.location):manhattan_length()
end

function Waypoint.makeHere(id)
	local result = Waypoint.new(id, Turtle.Abs.getWorldLocation(), ArrayList.new(), ArrayList.new())
	Waypoint.add(result)
	if turtle then Waypoint.calibrate(result) end
	return result
end

function Waypoint.makeAt(location, id)
	local result = Waypoint.new(id, location, ArrayList.new(), ArrayList.new())
	Waypoint.add(result)
	if turtle then Waypoint.calibrate(result) end
	return result
end

local function load_waypoints()
	if wps_loaded then return end
	wps_loaded = true

	-- load waypoints
	if not fs.exists(WAYPOINTS_FILE) then error("No waypoints file found!") end -- TODO create?
	local file = fs.open(WAYPOINTS_FILE, "r")
	while true do
		local line = file.readLine()
		if not line then break end
		
		if not starts_with(line, WAYPOINTS_FILE_COMMENT) and trim(line) ~= "" then
			local tokens = map(trim, split(line, ";"))
			
			local id = tonumber(tokens:get(0))
			local location = tovec(tokens:get(1))
			local next_ids = map(compose(tonumber, trim), tolist(tokens:get(2)))
			split(tokens:get(3), "|")
			local plugin_tokens = map(trim, split(tokens:get(3), "|"))
			if plugin_tokens:size() == 1 and plugin_tokens:get(0) == "" then plugin_tokens:remove(0) end

			local wp = Waypoint.new(id, location, next_ids, plugin_tokens)
			assert(not Waypoint.getFromLocation(wp.location), "Waypoint already exists at location " .. tostring(wp.location))
			wps:put(id, wp)
		end
	end
	file.close()

	-- waypoint references
	for wp in wps:values_it() do
		-- adjust incoming + outgoing waypoint references
		for next_id in wp.next_ids:it() do
			local next_wp = wps:get(next_id)
			assert(next_wp, "Wp(" .. tostring(wp.id) .. ") points to invalid wp(" .. tostring(next_id) .. ")")
			wp.outgoing:push(next_wp)
			next_wp.incoming:push(wp)
			assert(next_wp.incoming:size() > 0, "Something went wrong while parsing waypoints!")
		end
		assert(wp.next_ids:size() == wp.outgoing:size(), "Something went wrong while parsing waypoints!")
		wp.next_ids = nil
		
		-- install plugins
		for plugin_token in wp.plugin_tokens:it() do
			local func, err = loadstring("plugin = " .. plugin_token)
			assert(func, "Failed compiling plugin constructor: " .. tostring(plugin_token) .. "\nError: " .. tostring(err))
			
			id = wp.id
			local status, err = pcall(func)
			assert(status, "Failed calling plugin constructor: " .. tostring(plugin_token) .. "\nError: " .. tostring(err))
			
			assert(plugin, "Failed creating plugin!")
			plugin.wp = wp
			
			wp.plugins:put(plugin.plugin_type, plugin)
		end
	end
end

local function save_waypoints()
	local file = fs.open(WAYPOINTS_FILE, "w")
	
	file.writeLine("#\tid\tlocation\tnext_ids\tplugins")
	for wp in wps:values_it() do
		file.writeLine("\t" .. tostring(wp.id) .. ";\t" .. tostring(wp.location) .. ";\t" .. map(function(wp2) return wp2.id end, wp.outgoing):toString(", ") .. ";\t" .. wp.plugin_tokens:toString(" | "))
	end
	file.close()
end

local function calc_routing_to(target_wp, source_wp)
	if target_wp == source_wp then return end

	-- initial distances: dist[target_wp] = 0, dist[other] = INF
	local dist = TableMap.new()
	for wp in wps:values_it() do
		dist:put(wp, INF)
	end
	dist:put(target_wp, 0)
	-- initial shortest_path_tree: empty
	local shortest_path_tree = ArrayList.new()
	
	-- iterate all nodes by min distance
	for i = 0, dist:size() - 1 do
		-- get node with minimal distance not included in shortest_path_tree
		local min_dist = INF
		local min_wp = nil
		for wp in dist:keys_it() do
			if not shortest_path_tree:contains(wp) and dist:get(wp) < min_dist then
				min_dist = dist:get(wp)
				min_wp = wp
			end
		end
		if not min_wp then
			error("No path from " .. tostring(source_wp.id) .. " to " .. tostring(target_wp.id) .. " found!")
		end
		
		-- process node
		shortest_path_tree:append(min_wp)
		for inc_wp in min_wp.incoming:it() do
			local new_dist = min_dist + inc_wp:distance(min_wp)
			if not shortest_path_tree:contains(inc_wp) and min_dist < INF and new_dist < dist:get(inc_wp) then
				-- shortest path: inc_wp -> min_wp ->* target_wp
				inc_wp.routing_table:put(target_wp, min_wp)
				dist:put(inc_wp, new_dist)
				
				-- only calculate routing tables till source_wp is reached
				if source_wp and source_wp == inc_wp then return end
			end
		end
	end
end

function Waypoint.add(wp)
	assert(wp)
	
	load_waypoints()
	assert(not Waypoint.getFromLocation(wp.location), "Waypoint already exists at location " .. tostring(wp.location))
	wps:put(wp.id, wp)
	save_waypoints()
end

function Waypoint.remove(wp)
	assert(wp)
	
	load_waypoints()
	for out in wp.outgoing:it() do
		out.incoming:remove_val(wp)
	end
	for in_ in wp.incoming:it() do
		in_.outgoing:remove_val(wp)
	end
	
	wps:remove(wp.id)
	save_waypoints()
end

function Waypoint.addConnection(from_wp, to_wp)
	load_waypoints()
	from_wp.outgoing:append(to_wp)
	to_wp.incoming:append(from_wp)
	save_waypoints()
end

function Waypoint.removeConnection(from_wp, to_wp)
	load_waypoints()
	from_wp.outgoing:remove_val(to_wp)
	to_wp.incoming:remove_val(from_wp)
	save_waypoints()
end

function Waypoint.get(id)
	load_waypoints()
	return wps:get(id)
end

function Waypoint.getFromLocation(location)
	for wp in wps:values_it() do
		if wp.location == location then
			return wp
		end
	end
	return nil
end

-- wp == nil => find wp by turtle location
function Waypoint.calibrate(wp, rotation)
	load_waypoints()
	
	current_wp = nil
	if wp then
		current_wp = wp
		if Turtle.Abs.hasWorldCoord() then
			assert(current_wp.location == Turtle.Abs.getWorldLocation(), "Waypoint location and turtle location must be equal!")
		else
			assert(rotation, "Rotation must be given since turtle is not calibrated!")
			Turtle.Abs.pushCoord(wp.location:get(0), wp.location:get(1), wp.location:get(2), rotation, true)
		end
	else
		assert(Turtle.Abs.hasWorldCoord(), "Turtle must be calibrated to use waypoints!")
		assert(not rotation or rotation == Turtle.Abs.getWorldRotation(), "Given rotation and turtle rotation must be equal!")
		
		current_wp = Waypoint.getFromLocation(Turtle.Abs.getWorldLocation())
		assert(current_wp, "Couldn't find waypoint at turtle's location!")
	end
end

function Waypoint.isCalibrated()
	return current_wp
end

function Waypoint.current()
	return current_wp
end

function Waypoint:goto()
	assert(Waypoint.isCalibrated(), "Waypoint location not calibrated!")
	assert(Turtle.Abs.getWorldLocation() == Waypoint.current().location, "Incorrect waypoint calibration!")
	
	-- calculate routing table if necessary
	if not current_wp.routing_table:contains_key(self) then 
		calc_routing_to(self, current_wp)
	end

	-- traverse route
	while current_wp ~= self do
		-- get next wp on route
		local next_wp = current_wp.routing_table:get(self)
		assert(next_wp, "No route from wp(" .. tostring(current_wp.id) .. ") to wp(" .. tostring(self.id) .. ") possible!")
		assert(next_wp ~= current_wp, "Invalid route!")

		-- move to next wp without digging
		Turtle.Abs.move_to(next_wp.location, false)
		current_wp = next_wp
		assert(Turtle.Abs.getWorldLocation() == current_wp.location, "Failed moving between waypoints!")
	end
	
	return self
end

function Waypoint:plugin(plugin_type)
	if plugin_type then
		local result = self.plugins:get(plugin_type)
		assert(result, "Plugin not found!")
		return result
	else
		assert(self.plugins:size() == 1, "Invalid number of plugins for this call!")
		return self.plugins:values_it()()
	end
	return 
end

function Waypoint:has_plugin(plugin_type)
	return self.plugins:contains_key(plugin_type)
end














Waypoint.Plugin = {}
Waypoint.Plugin.__index = Waypoint.Plugin

function Waypoint.Plugin:goto()
	self.return_rotation = Turtle.Abs.getWorldRotation()
	self.return_wp = Waypoint.current()
	self.wp:goto()
	return self
end

function Waypoint.Plugin:return_()
	self.return_wp:goto()
	Turtle.Abs.rotate_to(self.return_rotation)
	self.return_wp = nil
	self.return_rotation = nil
	return self
end





loader.include("api/mc/turtle/waypointplugin/storage.lua")
loader.include("api/mc/turtle/waypointplugin/miningstation.lua")