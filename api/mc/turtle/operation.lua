--[[

Operation.Deposit.new(initial_orientation)
Operation.BranchS.new(branch_length, branch_num, branch_separation, right)
Operation.Box.new(width, height, length)
Operation.Line.new(length)
Operation.Offset.new(f_goto_start, f_goto_mine)



function Operation:run(plugin)
function Operation:goto_start()
function Operation:goto_mine()
function Operation:add_plugin(plugin)
function Operation:append(next_operation)

virtual function Operation:run_impl()
virtual function Operation:goto_start_impl()
virtual function Operation:goto_mine_impl()
virtual function Operation:size()






virtual function Operation.Plugin:init()
virtual function Operation.Plugin:pre_dig(calling_operation, orientation, block_id, block_metadata)
virtual function Operation.Plugin:post_dig(calling_operation, orientation, block_id, block_metadata)
virtual function Operation.Plugin:pre_move(calling_operation, orientation_move)
virtual function Operation.Plugin:post_move(calling_operation, orientation_moved)

]]--




loader.include("api/util/functional.lua")
loader.include("api/util/filter.lua")
loader.include("api/util/math/math.lua")
loader.include("api/util/math/vec.lua")
loader.include("api/mc/turtle/turtle.lua")
loader.include("api/util/datastructs/list.lua")
loader.include("api/mc/blocks.lua")




Operation = {}
Operation.__index = Operation

function Operation:add_plugin(plugin)
	if not self.plugins then self.plugins = ArrayList.new() end
	plugin.plugin_operation = self
	self.plugins:append(plugin)
	return self
end

function Operation:set_parent_operation(operation)
	self.parent_operation = operation
	return self
end

function Operation:do_plugins(calling_operation, from_parent, func_name, ...)
	assert(calling_operation, "No calling operation given!")
	if not self.plugins then self.plugins = ArrayList.new() end
	
	for plugin in self.plugins:it() do
		local func = plugin[func_name]
		if func and not (from_parent and plugin.not_as_parent) then
			func(plugin, calling_operation, unpack(arg)) -- oop call
		end
	end

	if self.parent_operation and func_name ~= "init" then self.parent_operation:do_plugins(calling_operation, true, func_name, unpack(arg)) end
end

function Operation:append(next_operation)
	if self.next_operation then
		self.next_operation:append(next_operation)
	else
		self.next_operation = next_operation
		next_operation:set_parent_operation(self)
	end
end

function Operation:dig(orientation)
	local success, data = Turtle.Rel.inspect(orientation)
	if success then
		self:do_plugins(self, false, "pre_dig", orientation, Blocks.get(data.name), data.metadata)
		turtle.select(1)
		Turtle.Rel.dig(orientation, true)
		self:do_plugins(self, false, "post_dig", orientation, Blocks.get(data.name), data.metadata)
	end
end

function Operation:move(length, orientation, f_pre, f_post)
	for i = 1, math.abs(length) do
		self:dig(if_(length > 0, orientation, Turtle.Rel.opposite(orientation)))
		self:do_plugins(self, false, "pre_move", orientation)
		if f_pre then f_pre() end
		Turtle.Rel.move(sign(length), orientation, true)
		if f_post then f_post() end
		self:do_plugins(self, false, "post_move", orientation)
	end
end

function Operation:run()
	self.abort = false
	self:do_plugins(self, false, "init")
	
	self:run_impl()
	
	if self.next_operation then
		self.next_operation:run()
	elseif self.goto_start_impl then
		self:goto_start(true)
	end
	
	return self
end

function Operation:goto_start(after_run)
	if not after_run then
		assert(not self.is_in_goto, "Cannot go to start without going to mine first!")
		self.is_in_goto = true
	end
	assert(self.goto_start_impl, "Operation is not supported!")
	self:goto_start_impl()
	if self.parent_operation then self.parent_operation:goto_start(after_run) end
end

function Operation:goto_mine()
	assert(self.is_in_goto, "Cannot go to mine without going to start first!")
	if self.parent_operation then self.parent_operation:goto_mine() end
	self:goto_mine_impl()
	self.is_in_goto = false
end

function Operation:isInGoto()
	return self.is_in_goto
end




loader.include("api/mc/turtle/operation/minedeposit.lua")
loader.include("api/mc/turtle/operation/minebranch_s.lua")
loader.include("api/mc/turtle/operation/minebox.lua")
loader.include("api/mc/turtle/operation/mineline.lua")
loader.include("api/mc/turtle/operation/offset.lua")



Operation.Plugin = {}



loader.include("api/mc/turtle/operationplugin/refuellava.lua")
loader.include("api/mc/turtle/operationplugin/evadeturtles.lua")
loader.include("api/mc/turtle/operationplugin/minesurroundingdeposits.lua")
loader.include("api/mc/turtle/operationplugin/dropexcessblocks.lua")
loader.include("api/mc/turtle/operationplugin/unloadatwaypoint.lua")
loader.include("api/mc/turtle/operationplugin/placesapling.lua")