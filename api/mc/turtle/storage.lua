loader.include("api/mc/turtle/turtle.lua")
loader.include("api/util/math/vec.lua")
loader.include("api/mc/blocks.lua")
loader.include("api/mc/net.lua")
loader.include("api/util/datastructs/list.lua")
loader.include("api/util/datastructs/map.lua")
loader.include("api/mc/console/console.lua")
loader.include("api/mc/console/menu.lua")



local SERVER_HOSTNAME = "storage_server"

local StorageNetCommand = {SEND_CHEST_UPDATE = 1, REGISTER_RETRIEVER = 2, UPDATE_CONSTANT_SUPPLY = 3, RETRIEVE_ONCE = 4, REGISTER_SORTER = 5}



Chest = {}
Chest.__index = Chest

function Chest.new(location, storage, slots)
	local result = {}
	setmetatable(result, Chest)
	
	result.location = location
	result.storage = storage
	
	if not slots then
		result.slots = ArrayList.new()
		Turtle.Rel.rotate_by()
		local chest_peripheral = peripheral.wrap("front")
		assert(chest_peripheral, "No chest in front!")
		for i = 1, chest_peripheral.getInventorySize() do
			local item = chest_peripheral.getStackInSlot(i)
			if not item then item = {qty = 0} end
			result.slots:append(item)
		end
	else
		result.slots = slots
	end
	
	-- update on server
	if storage.server_id then
		Net.send(storage.server_id, storage.protocol, StorageNetCommand.SEND_CHEST_UPDATE, result.location.values, result.slots.array)
	end
	
	return result
end

function Chest:has_item(item_id, item_metadata)
	for slot in self.slots:it() do
		if slot.qty > 0 and slot.id == Items.get(item_id) and (not item_metadata or slot.dmg == item_metadata) then
			return true
		end
	end
	return false
end

function Chest:has_space_for(item_id, item_metadata)
	for item in self.slots:it() do
		if item.qty == 0 or (item.id == Items.get(item_id) and item.qty < item.max_size and (not item_metadata or item.dmg == item_metadata)) then
			return true
		end
	end
	return false
end




Storage = {}
Storage.__index = Storage

function Storage.new(goto_chest_func, return_from_chest_func, sorter_push_direction, protocol, storage_chests_push_direction, retriever_pull_direction)
	local result = {}
	setmetatable(result, Storage)
	
	result.goto_chest_func = goto_chest_func
	result.return_from_chest_func = return_from_chest_func
	result.sorter_push_direction = sorter_push_direction
	result.protocol = protocol
	result.storage_chests_push_direction = storage_chests_push_direction
	result.retriever_pull_direction = retriever_pull_direction
	result.chests = ArrayList.new()
	
	return result
end

function Storage:find_next_usable(item_id, item_metadata)
	for chest_state in self.chests:it() do
		if chest_state:has_space_for(item_id, item_metadata) then
			return chest_state
		end
	end
	error("Not enough empty space!")
end

function Storage:get_chest_by_location(location)
	for chest in self.chests:it() do
		if chest.location == location then
			return chest
		end
	end
	return nil
end

function Storage:add_chest(location, slots)
	self.chests:append(Chest.new(location, self, slots))
end

function Storage:drop_all_of(item_id, item_metadata, chest)
	chest = chest or self:find_next_usable(item_id, item_metadata)
	
	self.goto_chest_func(chest.location)
	Turtle.Rel.drop_all_of(item_id, item_metadata, ORIENTATION_FRONT)
	
	-- update chest state locally and remotely
	chest.slots = Chest.new(chest.location, self).slots
	
	self.return_from_chest_func(chest.location)
end

function Storage:drop_all()
	for i = 1, 16 do
		local data = turtle.getItemDetail(i)
		if data and data.count > 0 then
			while Turtle.Inv.has(Items.get(data.name), data.damage) do
				self:drop_all_of(Items.get(data.name), data.damage)
			end
		end
	end
end

function Storage:take(item_id, item_metadata, amount)
	while amount > 0 do
		for chest in self.chests:it() do
			if chest:has_item(item_id, item_metadata) then
				self.goto_chest_func(chest.location)
				amount = amount - Turtle.Inv.take(item_id, item_metadata, amount, self.storage_chests_push_direction)
				
				-- update chest state locally and remotely
				chest.slots = Chest.new(chest.location, self).slots
				
				self.return_from_chest_func(chest.location)
				if amount == 0 then return 0 end
			end
		end
	end
	return amount
end

function Storage:run_sorter(retrieve_chest_states_func)
	Net.init()
	local next_id
	self.server_id, next_id = rednet.lookup(self.protocol, SERVER_HOSTNAME)
	
	assert(self.server_id, "Storage server not found!")
	assert(not next_id, "Too many storage servers found!")
	
	-- register with server
	Net.send(self.server_id, self.protocol, StorageNetCommand.REGISTER_SORTER, os.getComputerID())
	
	retrieve_chest_states_func(self)
	
	parallel.waitForAll(function() -- sorting
		while true do
			if Turtle.Inv.take_all_of_first(self.sorter_push_direction, true) then
				self:drop_all()
			end
		end
	end,
	function() -- network
		local net = NetReceiver.new(self.protocol)
		net:addHandler(StorageNetCommand.SEND_CHEST_UPDATE, function (chest_location_values, chest_slots_array)
			local chest_location = Vec.new(unpack(chest_location_values))
			local chest_slots = ArrayList.new(chest_slots_array)
			
			local chest = self:get_chest_by_location(chest_location)
			if chest then
				chest.slots = chest_slots
			else
				self:add_chest(chest_location, chest_slots)
			end
		end)
		net:run()
	end)
	
	
	
	Net.deinit()
end

function Storage:run_server()
	Net.init()
	rednet.host(self.protocol, SERVER_HOSTNAME)
	
	local sorters = ArrayList.new()
	local retrievers = ArrayList.new()
	local clients = ArrayList.new()
	local constant_supply = ListMap.new()
	
	parallel.waitForAll(
		function() -- network
			local net = NetReceiver.new(self.protocol)
			net:addHandler(StorageNetCommand.SEND_CHEST_UPDATE, function (chest_location_values, chest_slots_array)
				local chest_location = Vec.new(unpack(chest_location_values))
				local chest_slots = ArrayList.new(chest_slots_array)
				
				local chest = self:get_chest_by_location(chest_location)
				if chest then
					chest.slots = chest_slots
				else
					self:add_chest(chest_location, chest_slots)
				end
				
				for client in clients:it() do
					if client ~= src_computer_id then
						Net.send(client, self.protocol, StorageNetCommand.SEND_CHEST_UPDATE, chest_location_values, chest_slots_array)
					end
				end
			end)
			net:addHandler(StorageNetCommand.REGISTER_RETRIEVER, function (retriever_id)
				retrievers:append(retriever_id)
				clients:append(retriever_id)
				
				for chest in self.chests:it() do
					Net.send(retriever_id, self.protocol, StorageNetCommand.SEND_CHEST_UPDATE, chest.location.values, chest.slots.array)
				end
			end)
			net:addHandler(StorageNetCommand.REGISTER_SORTER, function (sorter_id)
				sorters:append(sorter_id)
				clients:append(sorter_id)
				
				for chest in self.chests:it() do
					Net.send(retriever_id, self.protocol, StorageNetCommand.SEND_CHEST_UPDATE, chest.location.values, chest.slots.array)
				end
			end)
			net:run()
		end,
		function() -- menu
			local get_item_and_amount = function()
				local item_id = read_number("Item id", true)
				local item_metadata = read_number("Item metadata", true)
				local display_name = Items.get_display_name(item_id, item_metadata)
				assert(display_name, "This id+metadata does not belong to any item!")
				
				local amount = read_number("Amount", true)
				if amount <= 0 then amount = nil end
				
				return item_id, item_metadata, display_name, amount
			end
		
		
			local menu = Menu.new("", false,
				MenuOption.new("Add constant supply", function()
					if retrievers:size() == 0 then return "No retrievers present!" end
				
					local item_id, item_metadata, display_name, amount = get_item_and_amount()
					constant_supply:put(Vec.new(item_id, item_metadata), amount)
					
					for retriever_id in retrievers:it() do
						Net.send(retriever_id, self.protocol, StorageNetCommand.UPDATE_CONSTANT_SUPPLY, item_id, item_metadata, amount)
					end
					
					if amount then
						return "Added constant supply for " .. tostring(amount) .. " " .. display_name .. "!"
					else
						return "Removed constant supply for " .. display_name .. "!"
					end
				end),
				MenuOption.new("Retrieve once", function()
					if retrievers:size() == 0 then return "No retrievers present!" end
					
					local item_id, item_metadata, display_name, amount = get_item_and_amount()
					if not amount then return "Cannot retrieve amounts equal to or less than zero!" end
					
					Net.send(retrievers:get(0), self.protocol, StorageNetCommand.RETRIEVE_ONCE, item_id, item_metadata, amount)
					
					return "Retrieving " .. tostring(amount) .. " " .. display_name .. "!"
				end)
			)
			menu:show(true)
		end
	)
	
	rednet.unhost(self.protocol, SERVER_HOSTNAME)
	Net.deinit()
end

function Storage:run_retriever()
	Net.init()
	local next_id
	self.server_id, next_id = rednet.lookup(self.protocol, SERVER_HOSTNAME)
	
	assert(self.server_id, "Storage server not found!")
	assert(not next_id, "Too many storage servers found!")
	
	local constant_supply = ListMap.new()
	
	-- register with server
	Net.send(self.server_id, self.protocol, StorageNetCommand.REGISTER_RETRIEVER, os.getComputerID())
	
	local net = NetReceiver.new(self.protocol)
	net:addHandler(StorageNetCommand.RETRIEVE_ONCE, function (item_id, item_metadata, amount)
		print("Retrieving: " .. tostring(amount) .. " of " .. tostring(item_id) .. ":" .. tostring(item_metadata))
		
		local left_amount = self:take(item_id, item_metadata, amount)
		Turtle.Rel.drop_all_of()
		
		if left_amount > 0 then
			-- TODO couldnt get needed amount
		end
	end)
	net:addHandler(StorageNetCommand.UPDATE_CONSTANT_SUPPLY, function (retriever_id)
		print("Setting constant supply: " .. tostring(amount) .. " of " .. tostring(item_id) .. ":" .. tostring(item_metadata))
	end)
	net:addHandler(StorageNetCommand.SEND_CHEST_UPDATE, function (chest_location_values, chest_slots_array)
		local chest_location = Vec.new(unpack(chest_location_values))
		local chest_slots = ArrayList.new(chest_slots_array)
		
		local chest = self:get_chest_by_location(chest_location)
		if chest then
			chest.slots = chest_slots
		else
			self:add_chest(chest_location, chest_slots)
		end
	end)
	net:run()
	
	Net.deinit()
end
