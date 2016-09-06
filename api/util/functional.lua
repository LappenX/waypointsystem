nop = function() end
identity = function(argument) return argument end

-- ? ternary operator
function if_(condition, onTrue, onFalse)
	if (condition) then
		return onTrue
	else
		return onFalse
	end
end

function select_(n, ...)
	return arg[n + 1]
end








function repeat_(n, func)
	return function()
		for i = 1, n do
			func()
		end
	end
end

function not_(func)
	return function()
		return not func()
	end
end

function const(val)
	return function() return val end
end

-- consecutive execution
function consec(...)
	return function()
		local result = nil
		first = true
		result_index = -1
		for i, v in ipairs(arg) do
			if first and type(v) == "number" then
				result_index = v + 2
			else
				current = v()
				if i == result_index then result = current end
			end
			first = false
		end
		return result
	end
end

-- (partial) application
function app(func, x, ...)
	if arg.n == 0 then
		return function() return func(x) end
	else
		return app(function (...)  return func(x, unpack(arg)) end,
			unpack(arg))
	end
end

-- function composition
function compose(func, ...)
	if not func then
		return identity
	else
		return function(argument)
			return func(compose(unpack(arg))(argument))
		end
	end
end

function curry(func)
	return function (x)
		return function (...)
			return f(x, unpack(arg))
		end
	end
end

function map(func, list)
	local result = ArrayList.new()
	
	for el in list:it() do
		result:append(func(el))
	end

	return result
end