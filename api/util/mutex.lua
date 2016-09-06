
Mutex = {}
Mutex.__index = Mutex

function Mutex.new()
	local result = {}
	setmetatable(result, Mutex)
	
	result.locked = false
	
	return result
end

function Mutex:lock()
	while self.locked do
		coroutine.yield()
	end
	self.locked = true
end

function Mutex:unlock()
	self.locked = false
end