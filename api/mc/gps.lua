os.loadAPI("api/loader")
loader.include("api/mc/net.lua")

if Net.hasModem() then

Gps = {}

function Gps.locate(timeout)
	timeout = timeout or 5
	local x, y, z = gps.locate(timeout)
	assert(x and y and z, "Gps failure!")
	return Vec.new(x, y, z)
end

end