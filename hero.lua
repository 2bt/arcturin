local MAX_SPEED    = 1.25
local ACCEL_GROUND = 0.5
local ACCEL_AIR    = 0.25

local JUMP_HEIGHT  = 5

local MODEL_SCALE = 0.05
local ANIM_IDLE   = 1
local ANIM_RUN    = 2
local ANIM_HUNKER = 3
local ANIM_AIM    = 4
local ANIM_JUMP   = 5

local BODY_POLY   = 4



local HeroBullet = Object:new({
    alive = true,
    first_update = true,
    -- attributes
    power = 1,
    vx    = 0,
    vy    = 0,
})
function HeroBullet:move_back()
    self.box.x = self.box.x - self.vx
    self.box.y = self.box.y - self.vy
end
function HeroBullet:spark(nx, ny)
    self.alive = false
    local cx = self.box:center_x() + nx * self.box.w / 2
    local cy = self.box:center_y() + ny * self.box.h / 2
    World:add_particle(FlashParticle(cx, cy))
    for _ = 1, 5 do
        local x = cx + randf(-ny, ny) * 4
        local y = cy + randf(-nx, nx) * 4
        World:add_particle(SparkParticle(x, y))
    end
    -- DEBUG: for testing explosions
    -- make_explosion(self.box:get_center())
end
function HeroBullet:update()
    -- check if still on screen
    if not self.box:overlaps(World.camera) then
        self.alive = false
        return
    end
    if self.ttl then
        self.ttl = self.ttl - 1
        if self.ttl < 0 then
            self.alive = false
            local x = self.box:center_x() + self.vx * 0.5
            local y = self.box:center_y() + self.vy * 0.5
            for _ = 1, 5 do
                World:add_particle(SparkParticle(x, y))
            end
            return
        end
    end

    -- move bullet back in first update
    local steps = 1
    if self.first_update then
        self.first_update = false
        steps = 2
        self.box.x = self.box.x - self.vx * 2
        self.box.y = self.box.y - self.vy * 2
    end
    local sx, sy, s
    for _ = 1, steps do
        sx = World:move_x(self.box, self.vx)
        sy = World:move_y(self.box, self.vy)
        s = sx or sy
        if s then break end
    end

    local nx = 0
    local ny = 0
    if sx then
        nx = self.vx > 0 and 1 or -1
    elseif sy then
        ny = self.vy > 0 and 1 or -1
    end


    -- enemy collision
    for _, e in ipairs(World.enemies) do
        if self.box:overlaps(e.box) then
            e:hit(self.power)
            self:spark(0, 0)
            return
        end
    end

    -- solid collision
    if s then
        local p = self.power
        if s.hp then p = math.min(p, s.hp) end
        s:hit(p)

        self.power = self.power - p
        if self.power <= 0 then
            self:spark(nx, ny)
        end
    end
end

local Laser = HeroBullet:new()
function Laser:init(x, y, dir)
    self.box   = Box.make_centered(x, y, 10, 4)
    self.vx    = dir * 5
    self.power = 5
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
    model = Model("assets/hero.model"),
    prev_jump = true,
    prev_shoot = true,

})
do
    -- precalculate aim offsets
    local ox = {}
    local oy = {}
    local a = AnimationManager(Hero.model)
    a:play(ANIM_AIM, 0)
    for i = 0, 1, 1/16 do
        a:seek(i)
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

local STATE_NORMAL = 0 -- idle, run
local STATE_HUNKER = 1
local STATE_AIM    = 2
local STATE_IN_AIR = 3


function Hero:init(input, index, x, y)
    self.input = input
    self.index = index
    input.hero = self

    self.box = Box.make_above(x, y, 11, 23)
    self.vy  = 0
    self.vx  = 0
    self.dir = 1
    self.hp  = 12

    self.state              = STATE_NORMAL
    self.aim                = 0.5
    self.aim_counter        = 0
    self.hunk_counter       = 0
    self.jump_control       = false
    self.shoot_counter      = 0
    self.invincible_counter = 0

    self.anim_manager = AnimationManager(self.model)
end


function Hero:set_state(state)

    if self.state == STATE_HUNKER then
        -- get up
        self.box.y = self.box.y - 6.5
        self.box.h = self.box.h + 6.5
    end

    self.state = state

    if state == STATE_IN_AIR then
        self.anim_manager:play(ANIM_JUMP)

    elseif state == STATE_HUNKER then
        self.box.y = self.box.y + 6.5
        self.box.h = self.box.h - 6.5
        self.anim_manager:play(ANIM_HUNKER)

    elseif state == STATE_AIM then
        self.aim = 0.5 -- neutral position
        self.shoot_counter = 0
        self.anim_manager:play(ANIM_AIM)
        self.anim_manager:seek(self.aim)
    end


end

function Hero:update()
    local input = self.input.state
    local jump  = input.a
    local shoot = input.b



    if self.state == STATE_NORMAL then

        -- turn
        if input.dx ~= 0 then
            self.dir = input.dx
            self.anim_manager:play(ANIM_RUN)
        else
            self.anim_manager:play(ANIM_IDLE)
        end

        -- move
        local acc = ACCEL_GROUND
        self.vx = clamp(input.dx * MAX_SPEED, self.vx - acc, self.vx + acc)
        World:move_x(self.box, self.vx)

        -- jump
        if jump and not self.prev_jump then
            self.vy           = -JUMP_HEIGHT
            self.jump_control = true
        end

        -- start hunkering
        if input.dx == 0 and input.down then
            self:set_state(STATE_HUNKER)
        end

        -- start aiming
        if input.dx == 0 and shoot then
            self.aim_counter = self.aim_counter + 1
            if self.aim_counter > 20 then
                self:set_state(STATE_AIM)
            end
        else
            self.aim_counter = 0
        end


    elseif self.state == STATE_IN_AIR then

        -- turn
        if input.dx ~= 0 then self.dir = input.dx end

        -- move
        local acc = ACCEL_AIR
        self.vx = clamp(input.dx * MAX_SPEED, self.vx - acc, self.vx + acc)
        World:move_x(self.box, self.vx)

        if self.jump_control then
            if not jump and self.vy < -1 then
                self.vy = -1
                self.jump_control = false
            end
            if self.vy > -1 then self.jump_control = false end
        end

    elseif self.state == STATE_HUNKER then
        if self.hunk_counter > 0 then
            self.hunk_counter = self.hunk_counter - 1
            if input.dx ~= 0 then
                self.hunk_counter = 0
            end
        end

        -- turn
        if input.dx ~= 0 then self.dir = input.dx end
        self.anim_manager:play(ANIM_HUNKER)

        if not input.down and self.hunk_counter == 0 then
            self:set_state(STATE_NORMAL)
        end

    elseif self.state == STATE_AIM then

        -- stop aiming
        if not shoot then
            self:set_state(STATE_NORMAL)
        end

        if self.shoot_counter > 0 then
            self.shoot_counter = self.shoot_counter - 1
        else
            self.shoot_counter = 2
            local a = self.dir * self.aim * math.pi
            local muzzle_x = self.box:center_x() + self.aim_offset.x[self.aim] * self.dir
            local muzzle_y = self.box:bottom()   + self.aim_offset.y[self.aim]
            World:add_hero_bullet(AimShot(muzzle_x, muzzle_y, a))
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
    end


    do
        -- move vertically
        -- gravity
        self.vy = self.vy + GRAVITY
        local falling_fast = self.vy > 4.8
        local vy = clamp(self.vy, -MAX_VY, MAX_VY)
        local in_air = true
        if World:move_y(self.box, vy) then
            if vy > 0 then
                in_air = false
            end
            self.vy = 0
        end
        if self.state == STATE_IN_AIR and not in_air then
            -- bend knees to dampen landing
            if falling_fast and input.dx == 0 then
                self.hunk_counter = 5
                self:set_state(STATE_HUNKER)
            else
                self:set_state(STATE_NORMAL)
            end

        elseif self.state ~= STATE_IN_AIR and in_air then
            self:set_state(STATE_IN_AIR)
        end
    end

    -- shooting
    if shoot and not self.prev_shoot then
        local muzzle_x = self.box:center_x() + 10 * self.dir
        local muzzle_y = self.box.y          + 8.6
        World:add_hero_bullet(Laser(muzzle_x, muzzle_y, self.dir))
    end


    if self.invincible_counter > 0 then
        self.invincible_counter = self.invincible_counter - 1
    else

        -- enemy collision
        for _, e in ipairs(World.enemies) do
            if self.box:overlaps(e.box) then
                self.hp = math.max(0, self.hp - 1)
                self.invincible_counter = 60
                -- knockback
                self.vy = -2
                local dir = self.box:center_x() > e.box:center_x() and 1 or -1
                self.vx = dir * 3

            end
        end

    end


    self.prev_jump  = jump
    self.prev_shoot = shoot


    -- animation stuff
    local lt = self.anim_manager:update()
    self.gt = self.model:get_global_transform(lt)

end

function Hero:draw()
    -- G.setColor(1, 1, 1, 0.2)
    -- G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)

    if self.invincible_counter % 2 == 1 then return end

    -- give each player a unique body color
    self.model.polys[BODY_POLY].color = ({ 11, 6, 4, 15 })[self.index] or 11

    G.push()
    G.translate(self.box:center_x(), self.box:bottom())
    G.scale(self.dir, 1)
    G.scale(MODEL_SCALE)
    self.model:draw(self.gt)
    G.pop()

end

