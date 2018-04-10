local G = love.graphics
GRAVITY = 0.2

Entity = Object:new {
	alive = true,
}

function Entity:on_collision(axis, dist, entity)
end
function Entity:update()
end
function Entity:draw(camera)
	G.setColor(1, 1, 1, 0.5)
	G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end


Crate = Entity:new()
function Crate:init(x, y)
	self.box   = { w = 16, h = 16 }
	self.box.x = x - self.box.w / 2
	self.box.y = y - self.box.h
	self.vy    = 0
end
function Crate:update()
    self.vy = self.vy + GRAVITY
    local vy = clamp(self.vy, -3, 3)
	self.next_y = self.box.y + vy
end
function Crate:on_collision(axis, dist, entity)
	if entity == nil
	or getmetatable(entity) == Crate and entity.box.y > self.box.y
	then
		if axis == "y" then
			self.box.y = self.box.y + dist
			self.next_y = self.box.y
			self.vy = 0
		end
	end

end
function Crate:draw(camera)
	G.setColor(0.6, 0.5, 0.2, 0.5)
	G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h)
end




Hero = Entity:new()
function Hero:init(input, x, y)
	self.box   = { w = 12, h = 20 }
	self.box.x = x - self.box.w / 2
	self.box.y = y - self.box.h
	self.vy    = 0

	self.vx           = 0
	self.dir          = 1
	self.in_air       = true
	self.jump_control = false

	self.input = input
	input.hero = self
end
function Hero:on_collision(axis, dist, entity)
	if entity == nil
	or getmetatable(entity) == Crate
	then
		if axis == "x" then
			self.box.x = self.box.x + dist
			self.next_x = self.box.x
			self.vx = 0
		elseif axis == "y" then
			self.box.y = self.box.y + dist
			self.next_y = self.box.y
			self.vy = 0
			if dist < 0 then
				self.in_air = false
			end
		end
	end
end
function Hero:update()
	local input = self.input.state
	local jump = input.a

	-- turn
    if input.dx ~= 0 then self.dir = input.dx end

	-- running
	local acc = self.in_air and 0.1 or 0.5
	self.vx = clamp(input.dx * 1.25, self.vx - acc, self.vx + acc)

	-- jumping
	local fall_though = false
	if not self.in_air and jump and not self.old_jump then
		if input.dy > 0 then
			fall_though = true
		else
			self.vy           = -4
			self.jump_control = true
			self.in_air       = true
		end
	end
    if self.in_air then
        if self.jump_control then
            if not jump and self.vy < -1 then
                self.vy = -1
                self.jump_control = false
            end
            if self.vy > -1 then self.jump_control = false end
        end
    end
	self.old_jump = jump


    -- gravity
    self.vy = self.vy + GRAVITY
    local vy = clamp(self.vy, -3, 3)
    self.in_air = true

	self.next_x = self.box.x + self.vx
	self.next_y = self.box.y + vy

--	p.x = p.x + p.vx
--	update_player_box(p)
--	local cx = self:collision(p.box, "x")
--	if cx ~= 0 then
--		p.x = p.x + cx
--		p.vx = 0
--	end


--	update_player_box(p)
--	local cy = self:collision(p.box, "y", not fall_though and vy)
--	if cy ~= 0 then
--		p.y = p.y + cy
--		p.vy = 0
--		if cy < 0 then
--			p.in_air = false
--		end
--	end

end
