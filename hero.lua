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
    G.setColor(0.9, 1, 1, 0.7)
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
local AIM_MESH
do
    local v = {}
    for x = -5, 5, 0.5 do
        local y1 = math.cos(x * 0.14) * 22 - 18
        local y2 = math.min(y1, -1)
        table.insert(v, { x, y1, 0, 0, 1, 1, 0.9, 1 })
        table.insert(v, { x, y2, 0, 0, 1, 1, 0.9, 0 })
    end
    AIM_MESH = G.newMesh(v, "strip", "static")
end
function AimShot:draw()
    G.setColor(1, 1, 1)
    G.push()
    G.translate(self.box:get_center())
    G.rotate(-self.a)
    G.draw(AIM_MESH)
    -- G.polygon("fill",
    --      0,  0,
    --     -5, -2,
    --      0,  3,
    --      5, -2)
    G.pop()
    -- G.setColor(1, 1, 1, 0.2)
    -- G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end



local HeroExplosion = Particle:new({
    ttl = 40
})
function HeroExplosion:init(x, y)
    self.x = x
    self.y = y
end
function HeroExplosion:sub_update(x, y)
    local c = self.tick % 20
    if c == 1 then
        make_explosion(self.x + randf(-10, 0), self.y + randf(-13, 0))
    elseif c == 6 then
        make_explosion(self.x + randf(0, 10), self.y + randf(-13, 0))
    elseif c == 11 then
        make_explosion(self.x + randf(-10, 0), self.y + randf(0, 13))
    elseif c == 16 then
        make_explosion(self.x + randf(0, 10), self.y + randf(0, 13))
    end
end



MAX_HP = 12

local MAX_SPEED    = 1.25
local ACCEL_GROUND = 0.5
local ACCEL_AIR    = 0.25
local JUMP_HEIGHT  = 5
local ENEMY_DAMAGE = 3


local MODEL_SCALE = 0.05
local BODY_POLY   = 4
local ANIM_IDLE   = 1
local ANIM_RUN    = 2
local ANIM_HUNKER = 3
local ANIM_AIM    = 4
local ANIM_JUMP   = 5


local STATE_NORMAL = 0 -- idle, run
local STATE_HUNKER = 1
local STATE_AIM    = 2
local STATE_IN_AIR = 3
local STATE_DEAD   = 4
local STATE_SPAWN  = 5


local HERO_MODEL = Model("assets/hero.model")

Hero = Object:new({
    prev_jump          = true,
    prev_shoot         = true,
    aim                = 0.5,
    aim_counter        = 0,
    hunk_counter       = 0,
    jump_control       = false,
    shoot_counter      = 0,
    invincible_counter = 0,
    spawn_counter      = 0,
    dead_counter       = 0,
    vy                 = 0,
    vx                 = 0,
    dir                = 1,
    hp                 = MAX_HP,
    lives              = 2,
})
local AIM_OFFSET
do
    -- precalculate aim offsets
    local ox = {}
    local oy = {}
    local a = AnimationManager(HERO_MODEL)
    a:play(ANIM_AIM, 0)
    for i = 0, 1, 1/16 do
        a:seek(i)
        a:update()
        local x, y = unpack(a.gt[18])
        ox[i] = x * MODEL_SCALE
        oy[i] = y * MODEL_SCALE
        ox[i] = math.floor(ox[i] * 2 + 0.5) / 2
        oy[i] = math.floor(oy[i] * 2 + 0.5) / 2
    end
    AIM_OFFSET = { x = ox, y = oy }
end
function Hero:init(input, index, x, y)
    self.input = input
    self.index = index
    input.hero = self
    self.box = Box.make_above(x, y, 11, 23)
    self.respawn_x = self.box.x
    self.respawn_y = self.box.y
    self.anim_manager = AnimationManager(HERO_MODEL)
    self:set_state(STATE_SPAWN)
    self.anim_manager:update()
end

function Hero:is_gameover()
    return self.lives == 0 and self.state == STATE_DEAD and self.dead_counter == 0
end
function Hero:set_state(state)

    if self.state == STATE_HUNKER then
        -- get up
        self.box.y = self.box.y - 6.5
        self.box.h = self.box.h + 6.5
    end

    self.state = state

    if state == STATE_SPAWN then
        self.spawn_counter = 60
        self.anim_manager:play(ANIM_IDLE, 0)
        self.anim_manager:update()

    elseif state == STATE_DEAD then
        self.dead_counter = 120

    elseif state == STATE_IN_AIR then
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


function Hero:hit(damage)
    self.hp = math.max(0, self.hp - ENEMY_DAMAGE)
    self.invincible_counter = 90 -- 1.5 seconds

    if self.hp == 0 then
        World:add_particle(HeroExplosion(self.box:get_center()))
        self:set_state(STATE_DEAD)
    end
end


function Hero:update()
    local input = self.input.state
    local jump  = input.a
    local shoot = input.b


    -- dead
    if self.state == STATE_DEAD then
        if self.dead_counter > 0 then
            self.dead_counter = self.dead_counter - 1
            if self.dead_counter == 0 and self.lives > 0 then
                -- respawn
                self.lives = self.lives - 1
                self.hp = MAX_HP
                self.vx = 0
                self.vy = 0
                self.box.x = self.respawn_x
                self.box.y = self.respawn_y
                self.invincible_counter = 90
                self:set_state(STATE_SPAWN)
            end
        end
        return
    end



    local function stay_inside_camera_view()
        if self.box.x < World.camera.x then
            self.box.x = World.camera.x
        end
        if self.box:right() > World.camera:right() then
            self.box.x = World.camera:right() - self.box.w
        end
    end


    if self.state == STATE_SPAWN then
        self.spawn_counter = self.spawn_counter - 1
        if self.spawn_counter > 0 then

            -- particles
            local o = math.min(0, (1 - self.spawn_counter / 40) * -25)
            local y = self.box:bottom() + o
            for _ = 1, 4 do
                local x = self.box.x + randf(-2, self.box.w + 2)
                local y = y + randf(-0.5, 0.5)
                local r = randf(0.5, 2)
                World:add_particle(FlashParticle(x, y, r))
            end

            return
        end
        self:set_state(STATE_NORMAL)
    end

    if self.state == STATE_NORMAL then

        -- update respawn position
        local y = self.box:bottom() + 1
        if  World.map:tile_at_world_pos(self.box.x,       y) > 0
        and World.map:tile_at_world_pos(self.box:right(), y) > 0
        then
            self.respawn_x = self.box.x
            self.respawn_y = self.box.y
        end

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

        stay_inside_camera_view()

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

        stay_inside_camera_view()

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
            local muzzle_x = self.box:center_x() + AIM_OFFSET.x[self.aim] * self.dir
            local muzzle_y = self.box:bottom()   + AIM_OFFSET.y[self.aim]
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
        self.solid_ground = nil
        -- move vertically
        -- gravity
        self.vy = self.vy + GRAVITY
        local falling_fast = self.vy > 4.8
        local vy = clamp(self.vy, -MAX_VY, MAX_VY)
        local in_air = true
        local s = World:move_y(self.box, vy)
        if s then
            if vy > 0 then
                in_air = false
                self.solid_ground = s
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

        -- particles
        for _ = 1, 4 do
            local x = self.box.x + randf(-2, self.box.w + 2)
            local y = self.box.y + randf(-3, self.box.h + 1)
            local r = randf(0.5, 1.5)
            World:add_particle(FlashParticle(x, y, r))
        end

    else

        -- enemy collision
        for _, e in ipairs(World.enemies) do
            if self.box:overlaps(e.box) then

                local x, y = self.box:intersection(e.box):get_center()
                World:add_particle(FlashParticle(x, y, 10))

                self:hit(ENEMY_DAMAGE)

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
    self.anim_manager:update()
end


local HERO_SPAWN_SHADER = G.newShader([[
varying vec2 pos;

#ifdef VERTEX

uniform mat4 transform;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    pos = (transform * vertex_position).xy;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL

uniform float spawn;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    color.a = pos.y < spawn ? 0.0 : 1.0;
    return color;
}
#endif

]])


function Hero:draw()

    -- G.setColor(1, 1, 1, 0.2)
    -- G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)

    if self.state == STATE_DEAD then return end

    -- blink
    if self.invincible_counter % 4 > 2 then return end

    -- give each player a unique body color
    HERO_MODEL.polys[BODY_POLY].color = ({ 11, 4, 6, 15 })[self.index] or 11
    HERO_MODEL.polys[BODY_POLY].shade = ({ 0.7, 0.5, 0.7, 0.7 })[self.index] or 0.7

    G.push()
    G.translate(self.box:center_x(), self.box:bottom())

    G.scale(self.dir, 1)
    G.scale(MODEL_SCALE)

    if self.state == STATE_SPAWN then
        local t = Transform:clone()
        t:translate(-World.camera.x, -World.camera.y)
        t:translate(self.box:center_x(), self.box:bottom())
        HERO_SPAWN_SHADER:send("transform", { t:inverse():getMatrix() })
        local o = math.min(0, (1 - self.spawn_counter / 40) * -25)
        HERO_SPAWN_SHADER:send("spawn", o)
        G.setShader(HERO_SPAWN_SHADER)
    end

    HERO_MODEL:draw(self.anim_manager.gt)
    G.setShader()
    G.pop()

end

