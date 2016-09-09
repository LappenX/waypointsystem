loader.include("api/util/functional.lua")
loader.include("api/util/string.lua")

Vec = {}
Vec3 = {}

local VECTOR_DIM_ERROR = "Operation invalid on vectors with different dimensions!"

ROTATION_SOUTH = 0
ROTATION_WEST = 1
ROTATION_NORTH = 2
ROTATION_EAST = 3
ROTATION_UP = 4
ROTATION_DOWN = 5

ROTATION_POSITIVE_Z = ROTATION_SOUTH
ROTATION_NEGATIVE_X = ROTATION_WEST
ROTATION_NEGATIVE_Z = ROTATION_NORTH
ROTATION_POSITIVE_X = ROTATION_EAST
ROTATION_POSITIVE_Y = ROTATION_UP
ROTATION_NEGATIVE_Y = ROTATION_DOWN




function Vec.new(...)
	local result = {}
	setmetatable(result, Vec)
	Vec.__index = Vec
	
	result.values = {}
	for i, v in ipairs(arg) do
		table.insert(result.values, v)
	end
	
	return result
end

function Vec.new_by_dims(dims, value)
	value = value or 0

	local result = {}
	setmetatable(result, Vec)
	Vec.__index = Vec
	
	result.values = {}
	for i = 0, dims - 1 do
		table.insert(result.values, value)
	end
	
	return result
end

function Vec3.new_by_rotation(rotation, length)
	length = length or 1
	if rotation == ROTATION_POSITIVE_Z then
		return Vec.new(0, 0, length)
	elseif rotation == ROTATION_NEGATIVE_X then
		return Vec.new(-length, 0, 0)
	elseif rotation == ROTATION_NEGATIVE_Z then
		return Vec.new(0, 0, -length)
	elseif rotation == ROTATION_POSITIVE_X then
		return Vec.new(length, 0, 0)
	elseif rotation == ROTATION_POSITIVE_Y then
		return Vec.new(0, length, 0)
	elseif rotation == ROTATION_NEGATIVE_Y then
		return Vec.new(0, -length, 0)
	else
		error("Invalid rotation value!")
	end
end

function tovec(str, dims)
	if starts_with(str, "[") and ends_with(str, "]") then
		str = str:sub(2, str:len() - 1)
	end

	local tokens = split(str, ",")
	local result = Vec.new()
	for token in tokens:it() do
		table.insert(result.values, tonumber(trim(token)))
	end
	
	if dims then assert(result:dims() == dims, "Invalid dimensions from string!") end
	
	return result
end

function Vec:dims()
	return table.getn(self.values)
end

function Vec:get(index)
	return self.values[index + 1]
end

function Vec:get_by_rotation(rotation)
	if rotation == ROTATION_POSITIVE_Z then
		return self:get(2)
	elseif rotation == ROTATION_NEGATIVE_X then
		return -self:get(0)
	elseif rotation == ROTATION_NEGATIVE_Z then
		return -self:get(2)
	elseif rotation == ROTATION_POSITIVE_X then
		return self:get(0)
	elseif rotation == ROTATION_POSITIVE_Y then
		return self:get(1)
	elseif rotation == ROTATION_NEGATIVE_Y then
		return -self:get(1)
	else
		error("Invalid rotation value!")
	end
end

function Vec:set(index, value)
	self.values[index + 1] = value
	return value
end

function Vec:it()
	local cur_index = -1
	return function()
		cur_index = cur_index + 1
		if cur_index < self:dims() then return self:get(cur_index) end
	end
end

function Vec:add(vec)
	assert(self:dims() == vec:dims(), VECTOR_DIM_ERROR)
	
	local result = Vec.new()
	for i = 0, self:dims() - 1 do
		table.insert(result.values, self:get(i) + vec:get(i))
	end
	
	return result
end

function Vec:add_to(dim, val)
	assert(dim < self:dims(), VECTOR_DIM_ERROR)
	
	local result = Vec.new()
	for i = 0, self:dims() - 1 do
		table.insert(result.values, self:get(i) + if_(i == dim, val, 0))
	end
	
	return result
end

function Vec:subtract(vec)
	assert(self:dims() == vec:dims(), VECTOR_DIM_ERROR)
	
	local result = Vec.new()
	for i = 0, self:dims() - 1 do
		table.insert(result.values, self:get(i) - vec:get(i))
	end
	
	return result
end

function Vec:dot(vec)
	assert(self:dims() == vec:dims(), VECTOR_DIM_ERROR)
	
	local result = 0
	for i = 0, self:dims() - 1 do
		result = result + self:get(i) * vec:get(i)
	end
	
	return result
end

function Vec:scalar_mul(scalar)
	local result = Vec.new()
	for i = 0, self:dims() - 1 do
		table.insert(result.values, scalar * self:get(i))
	end
	
	return result
end

function Vec:scalar_div(scalar)
	local result = Vec.new()
	for i = 0, self:dims() - 1 do
		table.insert(result.values, self:get(i) / scalar)
	end
	
	return result
end

function Vec:length()
	return math.sqrt(self:dot(self))
end

function Vec:manhattan_length()
	return self:abs():trace()
end

function Vec:normalize()
	return self:scalar_div(self:length())
end

function Vec:equals(vec)
	if self:dims() ~= vec:dims() then return false end
	for i = 0, self:dims() do
		if self:get(i) ~= vec:get(i) then return false end
	end
	return true
end

function Vec:trace()
	local sum = 0
	for i = 0, self:dims() - 1 do
		sum = sum + self:get(i)
	end
	return sum
end

function Vec:max_value()
	local max_val = -math.huge
	local max_dim = -1
	for i = 0, self:dims() - 1 do
		if self:get(i) > max_val then
			max_val = self:get(i)
			max_dim = i
		end
	end
	return max_val, max_dim
end

function Vec:min_value()
	local min_val = math.huge
	local min_dim = -1
	for i = 0, self:dims() - 1 do
		if self:get(i) < min_val then
			min_val = self:get(i)
			min_dim = i
		end
	end
	return min_val, min_dim
end

function Vec:abs()
	local result = Vec.new()
	for i = 0, self:dims() - 1 do
		table.insert(result.values, math.abs(self:get(i)))
	end
	return result
end

Vec.__add = function (veca, vecb)
	return veca:add(vecb)
end

Vec.__sub = function (veca, vecb)
	return veca:subtract(vecb)
end

Vec.__mul = function (vec, b)
	if type(b) == "number" then
		return vec:scalar_mul(b)
	elseif type(b) == "table" then
		return vec:dot(vecb)
	else
		error("Invalid operand type!")
	end
end

Vec.__div = function (vec, b)
	return vec:scalar_div(b)
end

Vec.__tostring = function (vec)
	local result = "["
	local first = true
	for value in vec:it() do
		if first then
			first = false
		else
			result = result .. ", "
		end
		result = result .. tostring(round(value, 2))
	end
	result = result .. "]"
	return result
end

Vec.__eq = function (veca, vecb)
	return veca:equals(vecb)
end

function rotation_to_string(rotation)
	if rotation == ROTATION_UP then return "up"
	elseif rotation == ROTATION_DOWN then return "down"
	elseif rotation == ROTATION_NORTH then return "north"
	elseif rotation == ROTATION_SOUTH then return "south"
	elseif rotation == ROTATION_EAST then return "east"
	elseif rotation == ROTATION_WEST then return "west"
	else error("Invalid rotation value!")
	end
end