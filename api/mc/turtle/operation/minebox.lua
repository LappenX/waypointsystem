loader.include("api/mc/turtle/operation.lua")

Operation.MineBox = {}
Operation.MineBox.__index = Operation.MineBox
setmetatable(Operation.MineBox, {__index = Operation})

function Operation.MineBox.new(width, height, length)
	local result = {}
	setmetatable(result, Operation.MineBox)
	assert(width ~= 0 and length ~= 0 and height ~= 0, "Invalid box dimensions!")
	
	result.name = "box"
	result.width = width
	result.height = height
	result.length = length
	
	return result
end

function Operation.MineBox:run_impl()
	-- helper function
	local function dig_layer(height)
		assert(math.abs(height) <= 3 and height ~= 0, "Invalid layer height!")

		-- box behind turtle
		if self.length < 0 then Turtle.Rel.rotate_by(2) self.rel_rotation = self.rel_rotation + 2 end
		
		local right = (self.width > 0) == (self.length > 0) -- first turn
		
		local dig_helper = function(rotate, dig_front, move, rel_location_updater)
			if self.abort then return end
			if height >= 2 or height == -3 then self:dig(ORIENTATION_UP) end
			if height == 3 or height <= -2 then
				self:dig(ORIENTATION_DOWN)
				self:dig(ORIENTATION_UP) -- repeat up for falling blocks
			end
			
			if rotate then Turtle.Rel.rotate_by(if_(right, 1, -1)) self.rel_rotation = self.rel_rotation + if_(right, 1, -1) end 
			if dig_front then
				self:dig(ORIENTATION_FRONT)
				if height >= 2 or height == -3 then self:dig(ORIENTATION_UP) end -- repeat up for falling blocks
			end
			if move then self:move(1, ORIENTATION_FRONT, rel_location_updater) end
		end
		
		for x = 1, math.abs(self.width) do
			-- dig row
			for z = 1, math.abs(self.length) - 1 do
				self.rel_rotation = mod_(self.rel_rotation, 4)
				assert(self.rel_rotation == 0 or self.rel_rotation == 2, "Invalid rel_rotation: " .. tostring(self.rel_rotation))
				dig_helper(false, true, true, function() self.rel_location = self.rel_location:add_to(2, if_(self.rel_rotation == 0, 1, -1)) end)
				if self.abort then break end
			end
			
			if x < math.abs(self.width) then
				-- move to next row
				self.rel_rotation = mod_(self.rel_rotation, 4)
				dig_helper(true, true, true, function() self.rel_location = self.rel_location:add_to(0, if_(self.rel_rotation == 1, 1, -1)) end)
				Turtle.Rel.rotate_by(if_(right, 1, -1))
				self.rel_rotation = self.rel_rotation + if_(right, 1, -1)
			else
				-- dig last blocks
				dig_helper(false, false, false)
			end

			right = not right
			if self.abort then break end
		end
		
		if self.length < 0 and not self.abort then Turtle.Rel.rotate_by(2) self.rel_rotation = self.rel_rotation + 2 end
	end
	
	local neg_width = self.width < 0
	self.current_y = 0
	self.layer = 0
	self.rel_location = Vec.new(0, 0, 0)
	self.rel_rotation = 0
	while self.layer * 3 < math.abs(self.height) and not self.abort do
		local layer_height = math.min(3, math.abs(self.height) - self.layer * 3)
		local target_y = (self.layer * 3 + select_(layer_height - 1, 0, 0, 1)) * sign(self.height)
		layer_height = layer_height * sign(self.height)
		
		-- move to layer
		self:move(target_y - self.current_y, ORIENTATION_UP, function() self.rel_location = self.rel_location:add_to(1, sign(self.height)) end)
		self.current_y = target_y

		-- dig layer
		dig_layer(layer_height)
		self.layer = self.layer + 1
		
		if self.abort then break end

		Turtle.Rel.rotate_by(2)
		self.rel_rotation = self.rel_rotation + 2
		if mod_(self.width, 2) == 0 then
			self.width = -self.width
		end
	end
	
	if neg_width then
		self.width = -math.abs(self.width)
	else
		self.width = math.abs(self.width)
	end
end

function Operation.MineBox:goto_start_impl()
	Turtle.Rel.rotate_by(-self.rel_rotation)
	self:move(self.rel_location:get(0), ORIENTATION_LEFT)
	self:move(self.rel_location:get(2), ORIENTATION_BACK)
	self:move(self.rel_location:get(1), ORIENTATION_DOWN)
end

function Operation.MineBox:goto_mine_impl()
	self:move(self.rel_location:get(1), ORIENTATION_UP)
	self:move(self.rel_location:get(2), ORIENTATION_FRONT)
	self:move(self.rel_location:get(0), ORIENTATION_RIGHT)
	Turtle.Rel.rotate_by(self.rel_rotation)
end

function Operation.MineBox:size()
	return Vec.new(self.width, self.height, self.length)
end