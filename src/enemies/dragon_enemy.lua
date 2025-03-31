
local ANIM_FIRE = 1
local ANIM_SLEEP = 2

local STATE_NORMAL = 1
local STATE_SLEEP  = 2
local STATE_DYING  = 3

local MODEL_HEAD = Model("assets/models/dragon-head.model")
local MODEL_BODY = Model("assets/models/dragon-body.model")
local EYE_POLY = nil
do
    for _, p in ipairs(MODEL_HEAD.polys) do
        if p.color == 6 then
            EYE_POLY = p
            break
        end
    end
end


DragonEnemy = Enemy:new()
function DragonEnemy:init(x, y)
    self.box         = Box.make_above(x, y, 50, 60)
    self.state       = STATE_SLEEP
    self.die_counter = 0
    self.hp          = 60

    self.vx = 0
    self.vy = 0

    self.segments = {
        Box.make_above(x, y, 12, 10),
        Box.make_above(x, y, 12, 12),
        Box.make_above(x, y, 12, 12),
        Box.make_above(x, y, 12, 12),
        Box.make_above(x, y, 12, 12),
        Box.make_above(x, y, 12, 12),
        Box.make_above(x, y, 16, 14),
    }
    self.head = self.segments[7]

    self.sleep_x   = self.head:center_x()
    self.sleep_y   = self.head:center_y()
    self.tx        = self.sleep_x
    self.ty        = self.sleep_y
    self.distance  = 0
    self.collision = false

    self.head_anim = AnimationManager(MODEL_HEAD)
    self.body_anim = AnimationManager(MODEL_BODY)
    self.head_anim:play(ANIM_SLEEP)
end


function DragonEnemy:sub_update()

    if self.state == STATE_DYING then
        if self.die_counter == 0 then
            self.die_counter = 7
            local s = table.remove(self.segments)
            make_explosion(s:get_center())
            if #self.segments == 0 then
                self.alive = false
                return
            end
        else
            self.die_counter = self.die_counter - 1
        end
        return

    elseif self.state == STATE_SLEEP then
        self.head_anim:play(ANIM_SLEEP)
        self.tx = self.sleep_x
        self.ty = self.sleep_y
        local FRICTION = self.distance > 3 and 0.93 or 0.8
        self.vx = self.vx * FRICTION
        self.vy = self.vy * FRICTION

        -- wake up if hero comes too close
        local h, d = World:get_nearest_hero(self.tx, self.ty)
        if h and d < 30 then
            self.state = STATE_NORMAL
        end



    elseif self.state == STATE_NORMAL then
        self.head_anim:play(ANIM_FIRE)

        if self.collision or self.distance < 5 then
            local h = World:get_nearest_hero(self.head:get_center())
            if h then
                -- turn around
                self.dir = h.box:center_x() < self.sleep_x and -1 or 1
                -- new target
                self.tx = self.sleep_x + self.dir * 10 + randf(-20, 20)
                self.ty = randf(self.box.y, self.box:bottom() - 20)
            else
                self.state = STATE_SLEEP
            end
        end
    end

    local MAX_ACCEL = 0.06
    local x, y = self.head:get_center()
    self.vx = self.vx + clamp(self.tx - x, -MAX_ACCEL, MAX_ACCEL)
    self.vy = self.vy + clamp(self.ty - y, -MAX_ACCEL, MAX_ACCEL)
    self.vx = self.vx * 0.97
    self.vy = self.vy * 0.97

    self.collision = false
    if World:move_x(self.head, self.vx) then
        self.vx = 0
        self.collision = true
    end
    if World:move_y(self.head, self.vy) then
        self.vy = 0
        self.collision = true
    end
    local x, y = self.head:get_center()
    self.distance = distance(self.tx, self.ty, x, y)

    -- update segments
    local rx, ry = self.segments[1]:get_center()
    local hx, hy = self.head:get_center()

    -- move head a bit forward
    -- this looks better and lets bullets hit the head more easily
    hx = hx - self.dir * 3
    local dx = hx - rx

    for i = 2, 6 do
        local m = (i - 1) / 6
        local x
        if dx > 0 then
            x = rx + clamp(dx - (1-m) * 25, 0, mix(0, dx, m))
        else
            x = rx + clamp(dx + (1-m) * 25, mix(0, dx, m), 0)
        end
        local x2 = mix(rx, hx, m^1.5)
        x = mix(x, x2, 0.5)

        local y = mix(ry, hy, m)
        self.segments[i]:set_center(x, y)
    end

    self.head_anim:update()
    self.body_anim:update()
end
function DragonEnemy:die()
    self.state = STATE_DYING
    make_explosion(self.box:get_center())
end

function DragonEnemy:deactivate()
    -- go to sleep
    if self.state == STATE_NORMAL or (self.state == STATE_SLEEP and self.distance > 0.5) then
        self.active = true
        self.state  = STATE_SLEEP
    end
end


function DragonEnemy:hero_collision(hero)
    if self.state == STATE_DYING then
        return nil, nil
    end
    for _, s in ipairs(self.segments) do
        if s:overlaps(hero.box) then
            -- wake up
            if self.state == STATE_SLEEP then
                self.state = STATE_NORMAL
            end
            return s:intersection(hero.box):get_center()
        end
    end
    return nil, nil
end
function DragonEnemy:bullet_collision(bullet)
    if self.state == STATE_DYING then
        return nil, nil
    end
    -- for i = 7, 1, -1 do
    for i = 7, 7, -1 do -- only head
        local s = self.segments[i]
        if s:overlaps(bullet.box) then
            -- wake up
            if self.state == STATE_SLEEP then
                self.state = STATE_NORMAL
            end
            if s == self.head then
                self.vx = bullet.vx > 0 and 1 or -1
                self:take_hit(bullet.power)
            end
            local b = s:intersection(bullet.box)
            return b:intersect_center_ray(-bullet.vx, -bullet.vy)
        end
    end
    return nil, nil
end


function DragonEnemy:sub_draw()

    if self.state == STATE_SLEEP then
        EYE_POLY.color = 16
        EYE_POLY.shade = 0.4
    else
        EYE_POLY.color = 6
        EYE_POLY.shade = 1.2
    end

    for i, s in ipairs(self.segments) do
        G.push()
        G.translate(s:get_center())
        if s == self.head then
            G.scale(-self.dir, 1)
            G.scale(0.052)
            self.head_anim:draw()
        else
            G.translate((-1)^i * 0.5, 0)
            G.scale(0.065)
            self.body_anim:draw()
        end
        G.pop()
    end

    -- G.setColor(1, 0, 0, 0.2)
    -- for i, s in ipairs(self.segments) do
    --     G.rectangle("line", s.x, s.y, s.w, s.h)
    -- end
    -- G.circle("fill", self.tx, self.ty, 4)
end
