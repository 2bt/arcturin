local MODEL = Model("assets/models/fly.model")


local STATE_WAIT   = 1
local STATE_ATTACK = 2


FlyEnemy = Enemy:new()
function FlyEnemy:init(x, y)
    self.box               = Box.make_above(x, y, 10, 12)
    self.hp                = 5
    self.vx                = 0
    self.vy                = 0
    self.counter           = 0
    self.collision_counter = 0
    self.anger_counter     = 0
    self.anim_manager      = AnimationManager(MODEL)
    self.wx                = self.box:center_x()
    self.wy                = self.box:center_y()
end

function FlyEnemy:activate()
    self:set_state(STATE_WAIT)
end

function FlyEnemy:take_hit(power)
    Enemy.take_hit(self, power)
    if self.state == STATE_WAIT then
        self:set_state(STATE_ATTACK)
    end
end
function FlyEnemy:on_explosion(x, y)
    if self.state == STATE_WAIT and distance(self.tx, self.ty, x, y) < 50 then
        self:set_state(STATE_ATTACK)
    end
end

function FlyEnemy:set_state(state)
    self.state   = state
    self.counter = 0
    if state == STATE_ATTACK then
        self.anger_counter = 100
    end
end


function FlyEnemy:sub_update()

    if self.state == STATE_WAIT then

        if self.counter > 0 then
            self.counter = self.counter - 1
        else
            local h, d = World:get_nearest_hero(self.box:get_center())
            if h and d < 50 then
                self:set_state(STATE_ATTACK)
            else
                self.tx      = self.wx + randf(-10, 10)
                self.ty      = self.wy + randf(-10, 10)
                self.counter = random(10, 30)
            end
        end

        local SPEED = 0.9
        local dx = clamp(self.tx - self.box:center_x(), -SPEED, SPEED)
        local dy = clamp(self.ty - self.box:center_y(), -SPEED, SPEED)
        self.vx  = mix(self.vx, dx, 0.01)
        self.vy  = mix(self.vy, dy, 0.01)

        local sx = World:move_x(self.box, self.vx)
        local sy = World:move_y(self.box, self.vy)
        if sx then
            self.counter = 0
            self.wx      = self.box:center_x() - math.sign(self.vx) * 20
            self.vx      = 0
        end
        if sy then
            self.counter = 0
            self.wy      = self.box:center_y() - math.sign(self.vy) * 20
            self.vy      = 0
        end


    elseif self.state == STATE_ATTACK then
        if self.anger_counter > 0 then
            self.anger_counter = self.anger_counter - 1
        end
        if self.counter > 0 then
            self.counter = self.counter - 1
        else
            local h, d = World:get_nearest_hero(self.box:get_center())
            if h and (d < 100 or self.anger_counter > 0) then
                self.tx      = h.box:center_x() + randf(-7, 7)
                self.ty      = h.box:center_y() + randf(-7, 7)
                self.counter = random(5, 20)
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
