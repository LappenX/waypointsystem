loader.include("api/util/string.lua")
loader.include("api/util/datastructs/map.lua")

Blocks = {}

BLOCKS_FILE = "data/block.csv"

local loaded_blocks = false
local blocks = TableMap.new()

function Blocks.load()
	if loaded_blocks then return end
	
	local file = fs.open(BLOCKS_FILE, "r")
	file.readLine() -- skip header line
	
	while true do
		local line = file.readLine()
		if not line then break end

		local tokens = split(line, ",")
		local id = tonumber(tokens:get(1))
		blocks:put(id, tokens:get(0))
	end
	
	file.close()
	loaded_blocks = true
end

-- id:number or name:string
function Blocks.get(identifier)
	Blocks.load()
	if type(identifier) == "number" then
		return blocks:get(identifier)
	else
		return blocks:key_by_value(identifier)
	end
end

Items = {}

ITEMS_FILE = "data/itempanel.csv"
local loaded_items = false
local items = TableMap.new()

function Items.load()
	if loaded_items then return end
	
	local file = fs.open(ITEMS_FILE, "r")
	file.readLine() -- skip header line
	
	while true do
		local line = file.readLine()
		if not line then break end
		
		local tokens = split(line, ",")
		local id_ = tonumber(tokens:get(1))
		local metadata_ = tonumber(tokens:get(2))
		
		items:put(id_, {id = id_, metadata = metadata_, name = tokens:get(0), display_name = tokens:get(4)})
	end
	
	file.close()
	loaded_items = true
end

function Items.get_display_name(item_id, item_metadata)
	Items.load()
	for item in items:values_it() do
		if item.id == item_id and item.metadata == item_metadata then
			return item.display_name
		end
	end
	return nil
end

-- id:number or name:string
function Items.get(identifier)
	Items.load()
	if type(identifier) == "number" then
		return items:get(identifier).name
	else
		for item in items:values_it() do
			if item.name == identifier then
				return item.id
			end
		end
		return nil
	end
end

ORES = ArrayList.new({14, 15, 16, 21, 56, 73, 129, 153, 180, 209, 431, 437})
SAPLINGS = ArrayList.new({6, 210, 4205})
LEAVES = ArrayList.new({18, 161, 211})
LOGS = ArrayList.new({17, 162, 198, 204})
TURTLES = ArrayList.new({169, 176, 177})