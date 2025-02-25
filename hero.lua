local MAX_SPEED    = 1.25
local ACCEL_GROUND = 0.5
local ACCEL_AIR    = 0.25

local JUMP_HEIGHT  = 5

local MODEL_SCALE = 0.05
local ANIM_IDLE   = 1
local ANIM_RUN    = 2
local ANIM_CROUCH = 3
local ANIM_AIM    = 4
local ANIM_JUMP   = 5


local HeroBullet = Object:new({
    alive = true,
    hit   = false,
    power = 1,
    vx    = 0,
    vy    = 0,
})
function HeroBullet:move_back()
    self.box.x = self.box.x - self.vx
    self.box.y = self.box.y - self.vy
end
function HeroBullet:update()
    -- check if still on screen
    if not self.box:overlaps(World.camera) then
        self.alive = false
        return
    end

    if self.hit then
        self.alive = false
        return
    end

    if self.ttl then
        self.ttl = self.ttl - 1
        if self.ttl < 0 then
            self.alive = false
            return
        end
    end

    local x = self.box.x + self.vx
    local y = self.box.y + self.vy

    local s = World:move_x(self.box, self.vx)
    local t = World:move_y(self.box, self.vy)
    s = s or t
    self.box.x = x
    self.box.y = y

    -- enemy collision
    for _, e in ipairs(World.enemies) do
        if self.box:overlaps(e.box) then
            e:hit(self.power)
            self.hit = true
        end
    end

    -- solid collision
    if s then
        local p = self.power
        if s.hp then p = math.min(p, s.hp) end
        s:hit(p)

        self.power = self.power - p
        if self.power <= 0 then
            self.hit = true
            return
        end
    end

end

local Laser = HeroBullet:new()
function Laser:init(x, y, dir)
    self.box   = Box.make_centered(x, y, 10, 4)
    self.vx    = dir * 5
    self.power = 5
    self:move_back()
end
function Laser:draw()
    G.setColor(0.9, 1, 1, 0.8)
    G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h, 1)
end



local AimShot = HeroBullet:new()
function AimShot:init(x, y, a)
    self.box = Box.make_centered(x, y, 5, 5)
    self.vx  = math.sin(a) * 4
    self.vy  = math.cos(a) * 4
    self.a   = a
    self.ttl = 16
    self:move_back()
end
function AimShot:draw()
    G.setColor(1, 1, 0.9, 0.8)
    G.push()
    G.translate(self.box:get_center())
    G.rotate(-self.a)
    G.polygon("fill", 0, 0, -5, -2, 0, 3, 5, -2)
    G.pop()
end


Hero = Object:new({
    alive = true,
    model = Model("assets/ladus.model"),
})
do
    -- precalculate aim offsets
    local ox = {}
    local oy = {}
    local a = AnimationManager(Hero.model)
    a:play(ANIM_AIM, 0)
    for i = 0, 1, 1/16 do
        a:seek(i, 0)
        local lt = a:update()
        local gt = a.model:get_global_transform(lt)
        local x, y = unpack(gt[18])
        ox[i] = x * MODEL_SCALE
        oy[i] = y * MODEL_SCALE
        ox[i] = math.floor(ox[i] * 2 + 0.5) / 2
        oy[i] = math.floor(oy[i] * 2 + 0.5) / 2
    end
    Hero.aim_offset = { x = ox, y = oy }
end



function Hero:init(input, x, y)
    self.box          = Box.make_above(x, y, 11, 23)
    self.vy           = 0
    self.vx           = 0
    self.dir          = 1

    self.is_crouching = false

    self.is_aiming    = false
    self.aim          = 0.5
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

function Hero:update()
    local input = self.input.state
    local jump  = input.a
    local shoot = input.b

    if self.prev_is_crouching then
        self.box.y = self.box.y - 6.5
        self.box.h = self.box.h + 6.5
    end
    local is_crouching = false

    -- aiming
    if not self.in_air and self.vx == 0 and shoot then
        if not self.is_aiming then
            self.aim_counter = self.aim_counter + 1
            if self.aim_counter > 20 then
                -- start aiming
                self.is_aiming = true
                self.aim       = 0.5 -- neutral position
                self.anim_manager:play(ANIM_AIM)
                self.anim_manager:seek(self.aim)
            end
        end
    else
        self.is_aiming   = false
        self.aim_counter = 0
        self.aim         = 0.5
    end


    if not self.is_aiming then

        -- turn
        if input.dx ~= 0 then self.dir = input.dx end

        -- moving
        local acc = self.in_air and ACCEL_AIR or ACCEL_GROUND
        self.vx = clamp(input.dx * MAX_SPEED, self.vx - acc, self.vx + acc)
        World:move_x(self.box, self.vx)

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
            if self.vx ~= 0 then
                self.anim_manager:play(ANIM_RUN)
            elseif input.down then
                is_crouching = true
                self.anim_manager:play(ANIM_CROUCH)
            else
                self.anim_manager:play(ANIM_IDLE)
            end
        end
    end


    -- gravity
    self.vy = self.vy + GRAVITY
    local vy = clamp(self.vy, -MAX_VY, MAX_VY)

    self.in_air = true
    if World:move_y(self.box, vy) then
        if vy > 0 then
            self.in_air = false
        end
        self.vy = 0
    end


    if self.is_aiming then

        if self.shoot_counter > 0 then
            self.shoot_counter = self.shoot_counter - 1
        else
            self.shoot_counter = 2

            local a = self.dir * self.aim * math.pi

            self.muzzle_x = self.box:center_x() + self.aim_offset.x[self.aim] * self.dir
            self.muzzle_y = self.box:bottom()   + self.aim_offset.y[self.aim]

            World:add_hero_bullet(AimShot(self.muzzle_x, self.muzzle_y, a))
        end

        if self.shoot_counter == 0 then

            self.aim = self.aim - self.dir * input.dx * (1/16)
            if self.aim > 1.0 then
                self.aim = 2 - self.aim
                self.dir = -self.dir
            elseif self.aim < 0.0 then
                self.aim = -self.aim
                self.dir = -self.dir
            end

        end

        self.anim_manager:play(ANIM_AIM)
        self.anim_manager:seek(self.aim, 0.3)

    else
        if shoot and not self.prev_shoot then
            self.muzzle_x = self.box:center_x() + self.aim_offset.x[self.aim] * self.dir
            self.muzzle_y = self.box:bottom()   + self.aim_offset.y[self.aim]
            if is_crouching then
                self.muzzle_y = self.muzzle_y + 6.5
            end
            World:add_hero_bullet(Laser(self.muzzle_x, self.muzzle_y, self.dir))
        end
    end

    local lt = self.anim_manager:update()
    self.gt = self.model:get_global_transform(lt)

    if is_crouching then
        self.box.y = self.box.y + 6.5
        self.box.h = self.box.h - 6.5
    end

    self.prev_jump  = jump
    self.prev_shoot = shoot
    self.prev_is_crouching = is_crouching
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

