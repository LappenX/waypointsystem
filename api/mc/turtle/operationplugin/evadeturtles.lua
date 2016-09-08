loader.include("api/mc/turtle/operation.lua")

local TURTLE_MAX_RANDOM_TEST_TIME = 10.0
local TURTLE_EVADE_DURATION = 5.0
local TURTLE_EVADE_TIMEOUT = 120

Operation.Plugin.EvadeTurtles = {}
Operation.Plugin.EvadeTurtles.__index = Operation.Plugin.EvadeTurtles

function Operation.Plugin.EvadeTurtles.new(dig)
	local result = {}
	setmetatable(result, Operation.Plugin.EvadeTurtles)
	
	result.dig = dig
	
	return result
end

function Operation.Plugin.EvadeTurtles:pre_dig(calling_operation, orientation, block_id, block_metadata)
	if block_id == 204 or block_id == 205 then -- is turtle
		local waited = 0
		while true do
			local wait_time = math.random() * TURTLE_MAX_RANDOM_TEST_TIME
			os.sleep(wait_time)
			waited = waited + wait_time
			
			-- evade
			if Turtle.Rel.detect(orientation) then
				-- goto avoid orientation -> wait TURTLE_EVADE_TIME -> go back
				local evaded = false
				-- evade to free spot
				for evade_orientation in ORIENTATIONS:it() do
					if evade_orientation ~= orientation and not Turtle.Rel.detect(evade_orientation) then
						-- found free block next to turtle
						Turtle.Rel.move(1, evade_orientation)
						os.sleep(TURTLE_EVADE_DURATION)
						Turtle.Rel.move(-1, evade_orientation)
						evaded = true
						break
					end
				end
				-- if not successful: dig and evade there
				if not evaded and self.dig then
					for evade_orientation in ORIENTATIONS:it() do
						if evade_orientation ~= orientation then
							local success, data = Turtle.Rel.inspect(evade_orientation)
							local new_block_id = Blocks.get(data.name)
							if block_id ~= 204 and block_id ~= 205 then -- not turtle
								-- found block that can be dug
								Turtle.Rel.move(1, evade_orientation, true)
								os.sleep(TURTLE_EVADE_DURATION)
								Turtle.Rel.move(-1, evade_orientation)
								break
							end
						end
					end
				end
			else
				break
			end
			
			if waited > TURTLE_EVADE_TIMEOUT then
				print("Failed evading turtle on calling operation '" .. calling_operation.name .. "'!")
				local file = fs.open("local/turtle_evade.log", "a")
				file.writeLine("Failed evading with: location=" .. tostring(Turtle.Abs.getLocation()) .. " calling_operation=" .. tostring(calling_operation.name))
				file.close()
				assert(false)
				break
			end
		end
	end
end