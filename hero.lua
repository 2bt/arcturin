local MAX_SPEED    = 1.25
local ACCEL_GROUND = 0.5
local ACCEL_AIR    = 0.15
local JUMP_HEIGHT  = 5



Hero = Actor:new()

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

    self.anim_manager = AnimationManager(self.model)
    self.anim_manager:play(ANIM_IDLE)

    self.input = input
    input.hero = self

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

            -- start aiming
            if not self.is_aiming then
                self.is_aiming = true
                self.aim = 0.5 -- neutral position
            end

            self.aim = self.aim - self.dir * input.dx * 0.02
            if self.aim > 1.0 then
                self.aim = 2 - self.aim
                self.dir = -self.dir
            elseif self.aim < 0.0 then
                self.aim = -self.aim
                self.dir = -self.dir
            end

            self.anim_manager:play(ANIM_AIM)
            self.anim_manager:seek(self.aim)
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
                self.vy           = -JUMP_HEIGHT
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
            self.anim_manager:play(ANIM_JUMP)
        else
            if self.vx == 0 then
                self.anim_manager:play(ANIM_IDLE)
            else
                self.anim_manager:play(ANIM_RUN)
            end
        end
        self.old_jump = jump

    end


    World:move_x(self, self.vx)

    -- gravity
    self.vy = self.vy + GRAVITY
    local vy = clamp(self.vy, -3, 3)

    self.in_air = true
    if World:move_y(self, vy) then
        if vy > 0 then
            self.in_air = false
        end
        self.vy = 0
    end


    self.anim_manager:update()
end

function Hero:draw(camera)
    -- G.setColor(1, 1, 1, 0.1)
    -- G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)


    G.push()
    G.translate(self.box.x + self.box.w / 2, self.box.y + self.box.h)
    G.scale(self.dir, 1)
    G.scale(self.model.scale)

    self.model:draw(self.anim_manager.lt)

    G.pop()
end

