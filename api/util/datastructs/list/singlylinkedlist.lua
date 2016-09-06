SinglyLinkedList = {}
SinglyLinkedList.__index = SinglyLinkedList
setmetatable(SinglyLinkedList, {__index = List})


function SinglyLinkedList.new()
	local result = {}
	setmetatable(result, ArrayList)
	
	result.size_ = 0
	result.head = {next = nil, value = nil}
	
	return result
end

function SinglyLinkedList:insert(index, val)
	if index > self:size() then error("List index out of bounds!", 2) end
	
	local prev = self.head
	while index > 0 do
		index = index - 1
		prev = prev.next
	end
	
	assert(prev)
	prev.next = {next = prev.next, value = val}
	
	self.size_ = self.size_ + 1
	
	return val
end

function SinglyLinkedList:remove(index)
	if index >= self:size() then error("List index out of bounds!", 2) end
	
	local prev = self.head
	while index > 0 do
		index = index - 1
		prev = prev.next
	end
	
	assert(prev)
	local result = prev.next.value
	prev.next = prev.next.next
	
	self.size_ = self.size_ - 1
	
	return result
end

function SinglyLinkedList:get(index)
	if index >= self:size() then error("List index out of bounds!", 2) end
	
	local cur = self.head.next
	while index > 0 do
		index = index - 1
		cur = cur.next
	end
	
	assert(cur)
	return cur.value
end

function SinglyLinkedList:size()
	return self.size_
end

function SinglyLinkedList:it()
	local cur = self.head
	return function()
		cur = cur.next
		if cur then return cur.value end
	end
end
