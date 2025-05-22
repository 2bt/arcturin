local MODEL = Model("assets/models/fly.model")


local STATE_WAIT   = 1
local STATE_ATTACK = 2


FlyEnemy = Enemy:new()
function FlyEnemy:init(x, y)
    self.box          = Box.make_above(x, y, 10, 12)
    self.hp           = 5
    self.vx           = 0
    self.vy           = 0
    self.counter           = 0
    self.collision_counter = 0
    self.anim_manager = AnimationManager(MODEL)
    self.wx = self.box:center_x()
    self.wy = self.box:center_y()
end

function FlyEnemy:activate()
    self:set_state(STATE_WAIT)
end

function FlyEnemy:take_hit(power)
    Enemy.take_hit(self, power)
    if self.state == STATE_WAIT then
        local h, d = World:get_nearest_hero(self.box:get_center())
        if h then
            self.hero = h
            self:set_state(STATE_ATTACK)
        end
    end
end

function FlyEnemy:set_state(state)
    if state == STATE_WAIT then
        self.tx = self.wx + randf(-10, 10)
        self.ty = self.wy + randf(-10, 10)
        self.counter = random(10, 30)
    elseif state == STATE_ATTACK then
        self.tx = self.hero.box:center_x() + randf(-7, 7)
        self.ty = self.hero.box:center_y() + randf(-7, 7)
        self.counter = random(5, 20)
    end
    self.state = state
end

function FlyEnemy:sub_update()

    if self.state == STATE_WAIT then

        local SPEED = 0.9
        local dx = clamp(self.tx - self.box:center_x(), -SPEED, SPEED)
        local dy = clamp(self.ty - self.box:center_y(), -SPEED, SPEED)
        self.vx = mix(self.vx, dx, 0.01)
        self.vy = mix(self.vy, dy, 0.01)

        local sx = World:move_x(self.box, self.vx)
        local sy = World:move_y(self.box, self.vy)
        if sx then
            self.counter = 0
            self.wx = self.box:center_x() - math.sign(self.vx) * 20
            self.vx = 0
        end
        if sy then
            self.counter = 0
            self.wy = self.box:center_y() - math.sign(self.vy) * 20
            self.vy = 0
        end

        if self.counter > 0 then
            self.counter = self.counter - 1
        else
            local close_bullet = false
            local x, y = self.box:get_center()
            for _, b in ipairs(World.hero_bullets) do
                if distance(x, y, b.box:get_center()) < 40 then
                    close_bullet = true
                    break
                end
            end

            local h, d = World:get_nearest_hero(self.box:get_center())
            if h and (d < 50 or close_bullet) then
                self.hero = h
                self:set_state(STATE_ATTACK)
            else
                self:set_state(STATE_WAIT)
            end
        end

    elseif self.state == STATE_ATTACK then

        if self.counter > 0 then
            self.counter = self.counter - 1
        else
            local h, d = World:get_nearest_hero(self.box:get_center())
            if h and d < 100 then
                self.hero = h
                self:set_state(STATE_ATTACK)
            else
                self:set_state(STATE_WAIT)
            end
        end

        local SPEED = 2.0
        local dx = clamp(self.tx - self.box:center_x(), -SPEED, SPEED)
        local dy = clamp(self.ty - self.box:center_y(), -SPEED, SPEED)
        self.vx = mix(self.vx, dx, 0.03)
        self.vy = mix(self.vy, dy, 0.03)

        local sx = World:move_x(self.box, self.vx)
        local sy = World:move_y(self.box, self.vy)
        if sx then self.vx = 0 end
        if sy then self.vy = 0 end
        if sx or sy then
            self.collision_counter = self.collision_counter + 1
            if self.collision_counter > 20 then
                self:set_state(STATE_WAIT)
            end
        else
            self.collision_counter = 0
        end

    end

    self.anim_manager:update()
end
function FlyEnemy:sub_draw()
    G.push()
    G.translate(self.box:get_center())
    G.scale(0.03)
    G.rotate(clamp(self.vx * 0.5, -1.5, 1.5))
    self.anim_manager:draw()
    G.pop()
end
