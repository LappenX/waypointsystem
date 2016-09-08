loader.include("api/mc/turtle/operation.lua")

Operation.MineBranchS = {}
Operation.MineBranchS.__index = Operation.MineBranchS
setmetatable(Operation.MineBranchS, {__index = Operation})

function Operation.MineBranchS.new(branch_length, branch_num, branch_separation, right)
	local result = {}
	setmetatable(result, Operation.MineBranchS)
	
	result.name = "branch_s"
	result.branch_length = branch_length
	result.branch_num = branch_num
	result.branch_separation = branch_separation
	result.right = right
	
	return result
end

function Operation.MineBranchS:run_impl()
	-- branching including deposits
	local branch_helper = function(length)
		self.way_along_branch = 0
		for i = 1, length do
			self:dig(ORIENTATION_FRONT)
			self:move(1, ORIENTATION_FRONT, function() self.way_along_branch = self.way_along_branch + 1 end)
			
			if self.abort then return end
		end
	end
	
	self.current_n = 0
	self.current_right = self.right
	while self.current_n < self.branch_num and not self.abort do
		self.current_n = self.current_n + 1
		
		-- Mine branch
		self.digging_main_branch = true
		branch_helper(self.branch_length)
		
		-- Goto next branch
		if self.current_n < self.branch_num then
			Turtle.Rel.rotate_by(if_(self.current_right, 1, -1))
			self.digging_main_branch = false
			branch_helper(self.branch_separation)
			Turtle.Rel.rotate_by(if_(self.current_right, 1, -1))
			
			self.current_right = not self.current_right
		end
	end
end

function Operation.MineBranchS:goto_start_impl()
	if self.digging_main_branch then
		-- digging main branch
		if self.current_n % 2 == 1 then
			-- way to opposite side
			Turtle.Rel.rotate_by(2)
			self:move(self.way_along_branch, ORIENTATION_FRONT)
		else
			-- way to correct side
			self:move(self.branch_length - self.way_along_branch, ORIENTATION_FRONT)
		end
	else
		-- digging separation branch
		if self.current_n % 2 == 1 then
			-- on opposite side
			Turtle.Rel.rotate_by(2)
			self:move(self.way_along_branch, ORIENTATION_FRONT)
			Turtle.Rel.rotate_by(if_(self.right, -1, 1))
			self:move(self.branch_length, ORIENTATION_FRONT)
		else
			-- on correct side
			Turtle.Rel.rotate_by(2)
			self:move(self.way_along_branch, ORIENTATION_FRONT)
			Turtle.Rel.rotate_by(if_(self.right, -1, 1))
		end
	end
	
	Turtle.Rel.rotate_by(if_(self.right, 1, -1))
	self:move((self.current_n - 1) * self.branch_separation, ORIENTATION_FRONT)
	Turtle.Rel.rotate_by(if_(self.right, 1, -1))
end

function Operation.MineBranchS:goto_mine_impl()
	Turtle.Rel.rotate_by(if_(self.right, 1, -1))
	self:move((self.current_n - 1) * self.branch_separation, ORIENTATION_FRONT)
	Turtle.Rel.rotate_by(if_(self.right, 1, -1))

	if self.digging_main_branch then
		-- digging main branch
		if self.current_n % 2 == 1 then
			-- way to opposite side
			Turtle.Rel.rotate_by(2)
			self:move(self.way_along_branch, ORIENTATION_FRONT)
		else
			-- way to correct side
			self:move(self.branch_length - self.way_along_branch, ORIENTATION_BACK)
		end
	else
		-- digging separation branch
		if self.current_n % 2 == 1 then
			-- on opposite side
			Turtle.Rel.rotate_by(2)
			self:move(self.branch_length, ORIENTATION_FRONT)
			Turtle.Rel.rotate_by(if_(self.right, 1, -1))
			self:move(self.way_along_branch, ORIENTATION_FRONT)
		else
			-- on correct side
			Turtle.Rel.rotate_by(if_(self.right, -1, 1))
			self:move(self.way_along_branch, ORIENTATION_FRONT)
		end
	end
end

function Operation.MineBranchS:size()
	return Vec.new(self.branch_num * self.branch_separation * if_(self.right, 1, -1), self.branch_separation, self.branch_length + self.branch_separation)
end