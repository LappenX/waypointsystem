INF = math.huge

function mod_(x, y)
	val = math.fmod(x, y)
	if val < 0 then
		return val + 4
	else
		return val
	end
end

function sign(x)
	if x > 0 then return 1
	elseif x == 0 then return 0
	else return -1
	end
end

function round(num, decimal_places)
  local mult = 10 ^ (decimal_places or 0)
  return math.floor(num * mult + 0.5) / mult
end