local G = love.graphics

local GRAVITY      = 0.2
local MAX_SPEED    = 1.25
local ACCEL_GROUND = 0.5
local ACCEL_AIR    = 0.15



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
    self.box = Box.make_above(x, y, 16, 16)
    self.vy  = 0
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

-- Hero.model = Model("assets/turri.model")
-- Hero.model.scale = 0.08
-- local ANIM_IDLE  = 2
-- local ANIM_RUN   = 1
-- local ANIM_JUMP  = 3
-- local ANIM_AIM   = 5

Hero.model = Model("assets/ladus.model")
Hero.model.scale = 0.05
local ANIM_IDLE  = 1
local ANIM_RUN   = 2
local ANIM_AIM   = 3
local ANIM_JUMP  = 4

function Hero:init(input, x, y)
    self.box          = Box.make_above(x, y, 12, 22)
    self.vy           = 0
    self.vx           = 0
    self.dir          = 1
    self.in_air       = true
    self.is_aiming    = false
    self.jump_control = false

    self.aim = 0 -- aim angle goes from 0 to 1
    self:set_anim(ANIM_IDLE)

    self.input = input
    input.hero = self

end

function Hero:set_anim(a)
    local anim = self.model.anims[a]
    if self.anim == anim then
        return
    end
    self.anim = anim
    self.anim_frame = anim.start
end
function Hero:update_anim()

    local anim = self.anim
    self.anim_frame = self.anim_frame + anim.speed
    if self.anim_frame > anim.stop then
        if anim.loop then
            self.anim_frame = self.anim_frame - anim.stop + anim.start
        else
            self.anim_frame = anim.stop
        end
    end

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
    local jump  = input.a
    local shoot = input.b



    -- aiming
    if not self.in_air and self.vx == 0 then
        if not shoot then
            self.is_aiming = false
        else
            if not self.is_aiming then
                self.is_aiming = true
                self.aim = 0.5
            end


            self.aim = self.aim - self.dir * input.dx * 0.02
            if self.aim > 1.0 then
                self.aim = 2 - self.aim
                self.dir = -self.dir
            elseif self.aim < 0.0 then
                self.aim = -self.aim
                self.dir = -self.dir
            end

            self:set_anim(ANIM_AIM)
            self.anim_frame = mix(self.anim.start, self.anim.stop, self.aim)
        end
    end
    if not self.is_aiming then

        -- turn
        if input.dx ~= 0 then self.dir = input.dx end

        -- moving

        local acc = self.in_air and ACCEL_AIR or ACCEL_GROUND
        self.vx = clamp(input.dx * MAX_SPEED, self.vx - acc, self.vx + acc)

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
            self:set_anim(ANIM_JUMP)
        else
            if self.vx == 0 then
                self:set_anim(ANIM_IDLE)
            else
                self:set_anim(ANIM_RUN)
            end
        end
        self.old_jump = jump

    end

    -- gravity
    self.vy = self.vy + GRAVITY
    local vy = clamp(self.vy, -3, 3)
    self.in_air = true

    self.next_x = self.box.x + self.vx
    self.next_y = self.box.y + vy

--  p.x = p.x + p.vx
--  update_player_box(p)
--  local cx = self:collision(p.box, "x")
--  if cx ~= 0 then
--      p.x = p.x + cx
--      p.vx = 0
--  end


--  update_player_box(p)
--  local cy = self:collision(p.box, "y", not fall_though and vy)
--  if cy ~= 0 then
--      p.y = p.y + cy
--      p.vy = 0
--      if cy < 0 then
--          p.in_air = false
--      end
--  end

    self:update_anim()
end

function Hero:draw(camera)
    G.setColor(1, 1, 1, 0.1)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)




    -- render model
    G.push()
    G.translate(self.box.x + self.box.w / 2, self.box.y + self.box.h)
    G.scale(self.dir, 1)
    G.scale(self.model.scale)

    local lt = self.model:get_local_transform(self.anim_frame)
    self.model:draw(lt)


    G.pop()
end

