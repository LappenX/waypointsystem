loader.include("api/util/serialize.lua")
loader.include("api/util/datastructs/map.lua")

Net = {}

local modem_loaded = false

function Net.init()
	if modem_loaded then return end
	modem_loaded = true
	
	for _, side in ipairs(peripheral.getNames()) do
		if peripheral.getType(side) == "modem" then
			rednet.open(side)
			return
		end
	end
	
	error("No modem found!")
end

function Net.deinit()
	if not modem_loaded then return end
	modem_loaded = false
	
	for _, side in ipairs(peripheral.getNames()) do
		if peripheral.getType(side) == "modem" then
			rednet.close(side)
		end
	end
end

function Net.send(dest_id, protocol, ...)
	Net.init()
	assert(type(dest_id) == "number")
	
	rednet.send(dest_id, serialize(arg), protocol)
end

function Net.recv(protocol, timeout)
	Net.init()
	
	local src_id, message, protocol = rednet.receive(protocol, timeout)
	
	local result = deserialize(message)
	return result, src_id
end



NetReceiver = {}
NetReceiver.__index = NetReceiver

function NetReceiver.new(protocol)
	local result = {}
	setmetatable(result, NetReceiver)
	
	result.protocol = protocol
	result.handlers = ListMap.new()

	return result
end

function NetReceiver:addHandler(command_id, handler)
	assert(type(command_id) == "number", "Command id must be a number!")
	self.handlers:put(command_id, handler)
end

function NetReceiver:run()
	while true do
		local received, src_computer_id = Net.recv(self.protocol)
		local handler = self.handlers:get(received[1])
		if not handler then error("Received invalid command id via rednet!") end
		table.remove(received, 1)
		
		handler(src_computer_id, unpack(received))
	end
end