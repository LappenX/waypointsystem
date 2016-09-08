--[[ DOC

Implementations: SinglyLinkedList, ArrayList

-- collection --
function List:insert(index, val)
function List:append(val)
function List:remove(index)
function List:remove_element(element)

function List:get(index)
function List:size()
function List:is_empty()

function List:it()
function List:next(it)


-- stack --
function List:push(val)
function List:top()
function List:pop()

-- queue --
function List:enqueue(val)
function List:dequeue()

--]]

List = {}
List.__index = List

function List:append(val)
	return self:insert(self:size(), val)
end

function List:front()
	return self:get(0)
end

function List:is_empty()
	return self:size() == 0
end

function List:contains(val)
	for value in self:it() do
		if value == val then return true end
	end
	return false
end



function List:push(val)
	return self:append(val)
end

function List:pop()
	return self:remove(self:size() - 1)
end

function List:top()
	return self:get(self:size() - 1)
end



function List:enqueue(val)
	return self:append(val)
end

function List:dequeue()
	return self:remove(0)
end



function List:remove_element(element)
	local index = 0
	for el in self:it() do
		if el == element then
			self:remove(index)
			return index
		end
		index = index + 1
	end
	return nil
end

function List:concat(list)
	local new_list = ArrayList.new() -- TODO generic list
	for el in self:it() do
		new_list:append(el)
	end
	for el in list:it() do
		new_list:append(el)
	end
	return new_list
end


function List:toString(separator)
	separator = separator or ", "
	local result = ""
	local first = true
	for value in self:it() do
		if first then
			first = false
		else
			result = result .. separator
		end
		result = result .. tostring(value)
	end
	return result
end

List.__tostring = function (list)
	return list:toString(", ")
end


function tolist(str, list, splitter)
	if not list then list = ArrayList.new() end -- TODO generic list
	splitter = splitter or ","

	local tokens = split(str, splitter)
	for token in tokens:it() do
		list:append(token)
	end
	
	return list
end




loader.include("api/util/datastructs/list/singlylinkedlist.lua")
loader.include("api/util/datastructs/list/arraylist.lua")


function ArrayList.__concat(list1, list2)
	return list1:concat(list2)
end

function SinglyLinkedList.__concat(list1, list2)
	return list1:concat(list2)
end