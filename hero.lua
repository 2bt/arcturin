MAX_VY = 3

local MAX_SPEED    = 1.25
local ACCEL_GROUND = 0.5
local ACCEL_AIR    = 0.15
local JUMP_HEIGHT  = 5

local MODEL_SCALE = 0.05
local ANIM_IDLE   = 1
local ANIM_RUN    = 2
local ANIM_AIM    = 3
local ANIM_JUMP   = 4


local HeroBullet = Actor:new()
function HeroBullet:init(x, y, dir)
    self.box    = Box(x - 5, y - 2, 10, 4)
    self.dir    = dir
    self.hit    = false
    self.energy = 5
end
function HeroBullet:update()
    if self.hit then
        self.alive = false
        return
    end

    -- check if still on screen
    if not self.box:overlaps(World.camera) then
        self.alive = false
        return
    end

    local s = World:move_x(self, self.dir * 5)
    if s then

        local e = self.energy
        if s.shield then e = math.min(e, s.shield) end
        s:hit(e)

        self.energy = self.energy - e
        if self.energy <= 0 then
            self.hit = true
        end
    end
end
function HeroBullet:draw()
    G.setColor(0.9, 1, 1, 0.8)
    G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h, 1)
end



local AIM_SHOT_SIZE = 5
local AimShot = Actor:new()
function AimShot:init(x, y, a)
    self.box = Box(x - AIM_SHOT_SIZE/2, y - AIM_SHOT_SIZE/2, AIM_SHOT_SIZE, AIM_SHOT_SIZE)
    self.a   = a
    self.ttl = 15
    self.hit = false
end
function AimShot:update()
    if self.hit then
        self.alive = false
        return
    end
    -- check if still on screen
    if not self.box:overlaps(World.camera) then
        self.alive = false
        return
    end

    self.ttl = self.ttl - 1
    if self.ttl < 0 then
        self.alive = false
        return
    end

    local dx = math.sin(self.a) * 4
    local dy = math.cos(self.a) * 4

    local x = self.box.x + dx
    local y = self.box.y + dy

    local s = World:move_x(self, dx)
    local t = World:move_y(self, dy)
    s = s or t

    self.box.x = x
    self.box.y = y

    if s then
        s:hit(1)
        self.hit = true
    end

end
function AimShot:draw()
    G.setColor(1, 1, 0.9, 0.8)
    G.push()
    G.translate(self.box:get_center())
    G.rotate(-self.a)
    G.polygon("fill", 0, 0, -5, -2, 0, 3, 5, -2)
    G.pop()
end


Hero = Actor:new({
    model = Model("assets/ladus.model"),
})
function Hero:init(input, x, y)
    self.box          = Box.make_above(x, y, 12, 22)
    self.vy           = 0
    self.vx           = 0
    self.dir          = 1

    self.is_aiming    = false
    self.aim_counter  = 0

    self.in_air       = true
    self.jump_control = false

    self.prev_jump     = false
    self.prev_shoot    = false
    self.shoot_counter = 0

    self.muzzle_x      = 0
    self.muzzle_y      = 0


    self.anim_manager = AnimationManager(self.model)
    self.anim_manager:play(ANIM_IDLE)

    self.input = input
    input.hero = self

end

function Hero:update_muzzle_pos()
    local x, y = unpack(self.gt[18])
    self.muzzle_x = self.box:center_x() + x * MODEL_SCALE * self.dir
    self.muzzle_y = self.box:bottom()   + y * MODEL_SCALE
end


function Hero:update()
    local input = self.input.state
    local jump  = input.a
    local shoot = input.b


    -- aiming
    if not self.in_air and self.vx == 0 and shoot then
        if not self.is_aiming then
            self.aim_counter = self.aim_counter + 1
            if self.aim_counter > 20 then
                -- start aiming
                self.is_aiming = true
                self.aim       = 0.5 -- neutral position
            end
        end
    else
        self.is_aiming   = false
        self.aim_counter = 0
    end



    if not self.is_aiming then

        -- turn
        if input.dx ~= 0 then self.dir = input.dx end

        -- moving
        local acc = self.in_air and ACCEL_AIR or ACCEL_GROUND
        self.vx = clamp(input.dx * MAX_SPEED, self.vx - acc, self.vx + acc)
        World:move_x(self, self.vx)

        -- jumping
        local fall_though = false
        if not self.in_air and jump and not self.prev_jump then
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
    end


    -- gravity
    self.vy = self.vy + GRAVITY
    local vy = clamp(self.vy, -MAX_VY, MAX_VY)

    self.in_air = true
    if World:move_y(self, vy) then
        if vy > 0 then
            self.in_air = false
        end
        self.vy = 0
    end


    if self.is_aiming then
        -- aiming
        if self.shoot_counter > 0 then
            self.shoot_counter = self.shoot_counter - 1
        else
            self.shoot_counter = 2

            -- self.aim = self.aim - self.dir * input.dx * 0.02
            self.aim = self.aim - self.dir * input.dx * (1/16)
            if self.aim > 1.0 then
                self.aim = 2 - self.aim
                self.dir = -self.dir
            elseif self.aim < 0.0 then
                self.aim = -self.aim
                self.dir = -self.dir
            end

            -- update animation
            self.anim_manager:play(ANIM_AIM)
            self.anim_manager:seek(self.aim)
            local lt = self.anim_manager:update()
            self.gt = self.model:get_global_transform(lt)

            self:update_muzzle_pos()

            -- make new aim shot
            local a = self.dir * self.aim * math.pi
            World:add_actor(AimShot(self.muzzle_x, self.muzzle_y, a))
        end

    else

        local lt = self.anim_manager:update()
        self.gt = self.model:get_global_transform(lt)

        if shoot and not self.prev_shoot then
            self:update_muzzle_pos()
            World:add_actor(HeroBullet(self.muzzle_x, self.muzzle_y, self.dir))
        end
    end

    self.prev_jump  = jump
    self.prev_shoot = shoot

end

function Hero:draw()
    -- G.setColor(1, 1, 1, 0.1)
    -- G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)


    G.push()
    G.translate(self.box:center_x(), self.box:bottom())
    G.scale(self.dir, 1)
    G.scale(MODEL_SCALE)
    self.model:draw(self.gt)
    G.pop()


end

