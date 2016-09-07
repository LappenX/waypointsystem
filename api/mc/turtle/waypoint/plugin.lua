--[[

function Waypoint.Plugin:goto()
function Waypoint.Plugin:return_()

Waypoint.Plugin.Storage.new(chest_rotation)
function Waypoint.Plugin.Storage:unload(slot, count)
function Waypoint.Plugin.Storage:unloadAll()

]]--

loader.include("api/util/serialize.lua")
loader.include("api/util/math/vec.lua")
loader.include("api/util/string.lua")
loader.include("api/mc/turtle/turtle.lua")
loader.include("api/mc/net.lua")
loader.include("api/mc/turtle/waypoint.lua")



Waypoint.Plugin = {}
Waypoint.Plugin.__index = Waypoint.Plugin

function Waypoint.Plugin:goto()
	self.return_rotation = Turtle.Abs.getRotation()
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

loader.include("api/mc/turtle/waypoint/plugins/storage.lua")
loader.include("api/mc/turtle/waypoint/plugins/miningstation.lua")