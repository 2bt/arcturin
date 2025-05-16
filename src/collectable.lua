Collectable = Object:new({
    alive = true,
    tick  = 0,
})
function Collectable:update() end
function Collectable:draw()
    G.setColor(1, 1, 1, 0.4)
    G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h)
end
function Collectable:collect(hero)
   self.alive = false
   hero.hp = MAX_HP
end



local STATE_JUMP  = 1
local STATE_FLOAT = 2
PowerUp = Collectable:new()
function PowerUp:init(x, y)
    self.box     = Box.make_centered(x, y, 8, 8)
    self.vx      = randf(-1.8, 1.8)
    self.vy      = randf(-3.5, -2)
    self.ty      = y + randf(-10, 20)
    self.state   = STATE_JUMP
    self.counter = 0
    self.tick    = randf(0, 100)
end
function PowerUp:update()
    self.tick = self.tick + 1
    if self.state == STATE_JUMP then
        self.counter = self.counter + 1
        if self.counter > 40 then
            self.state = STATE_FLOAT
        end
        if self.box.y > self.ty and self.vy > 0 then
            self.state = STATE_FLOAT
        end

        if World:move_x(self.box, self.vx) then
            self.vx = -self.vx
        end
        self.vy = self.vy + GRAVITY
        local vy = clamp(self.vy, -MAX_VY, MAX_VY)
        if World:move_y(self.box, vy) then
            self.vy = -vy
        end
    elseif self.state == STATE_FLOAT then
        self.vx = self.vx * 0.7 + math.sin(self.tick * 0.11) * 0.02
        self.vy = clamp(self.vy, -2, 2)
        self.vy = mix(-0.05, self.vy, 0.7) + math.cos(self.tick * 0.13) * 0.02
        World:move_x(self.box, self.vx)
        World:move_y(self.box, self.vy - 0.02)
    end
end
function PowerUp:collect(_hero)
    self.alive = false
    local x, y = self.box:get_center()
    for i = 0, 10 do
        World:add_particle(TwinkleParticle(x + randf(-5, 5), y + randf(-5, 5), i))
        World:add_particle(TwinkleParticle(x + randf(-5, 5), y + randf(-5, 5), i))
    end
end


local HEALTH_MODEL = Model("assets/models/health.model")
HealthPowerUp = PowerUp:new()
function HealthPowerUp:draw()
    -- change color
    local color = mix(
        { 0.6, 0.3, 0.2, 1 },
        { 0.6, 0.4, 0.35, 0.7 },
        math.sin(self.tick * 0.2) * 0.5 + 0.5)
    local c = HEALTH_MODEL.polys[1].color
    c[1] = color[1]
    c[2] = color[2]
    c[3] = color[3]

    G.push()
    G.translate(self.box:get_center())
    G.scale(0.04)
    HEALTH_MODEL:draw()
    G.pop()
end
function HealthPowerUp:collect(hero)
    PowerUp.collect(self)
    hero.hp = math.min(hero.hp + 4, MAX_HP)
end