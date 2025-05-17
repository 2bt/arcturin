Particle = Object:new({
    alive = true,
    ttl   = nil,
    tick  = 0,
})
function Particle:draw()
end
function Particle:sub_update()
end
function Particle:update()
    if self.ttl then
        self.ttl = self.ttl - 1
        if self.ttl < 0 then
            self.alive = false
            return
        end
    end
    self.tick = self.tick + 1
    self:sub_update()
end


TWINKLE_MESH = G.newMesh({
    {  0,  0, 0, 0, 1, 1, 1, 0.8 },
    { -1, -1, 0, 0, 1, 1, 1, 0.2 },
    {  0, -3, 0, 0, 1, 1, 0, 0.2 },
    {  1, -1, 0, 0, 1, 1, 1, 0.2 },
    {  3,  0, 0, 0, 1, 1, 0, 0.2 },
    {  1,  1, 0, 0, 1, 1, 1, 0.2 },
    {  0,  3, 0, 0, 1, 1, 0, 0.2 },
    { -1,  1, 0, 0, 1, 1, 1, 0.2 },
    { -3,  0, 0, 0, 1, 1, 0, 0.2 },
    { -1, -1, 0, 0, 1, 1, 1, 0.2 },
})
TwinkleParticle = Particle:new()
function TwinkleParticle:init(x, y, delay)
    self.x = x
    self.y = y
    self.size = Tween(0)
    if delay and delay > 0 then self.size:tween(0, delay) end
    self.size:tween(0.75, 2):tween(0, 8):kill_when_done(self)
end
function TwinkleParticle:sub_update()
    self.size:update()
end
function TwinkleParticle:draw()
    G.setColor(1, 1, 1)
    G.draw(TWINKLE_MESH, self.x, self.y, 0, self.size.value)
end




FlashParticle = Particle:new({
    R = { 1, 1.1, 0.8, 0.6, 0.3}
})
function FlashParticle:init(x, y, r)
    self.r = r or 5
    self.x = x
    self.y = y
    self.ttl = #self.R
end
function FlashParticle:sub_update()
    self.r = self.r * 0.8
end
function FlashParticle:draw()
    local c1 = { 1,   1,   0.6, 0.7 }
    local c2 = { 1,   0.5, 0.2, 0.6 }
    G.setColor(unpack(self.tick == 1 and c1 or c2))
    G.circle("fill", self.x, self.y, self.r * self.R[self.tick])
end


SparkParticle = Particle:new()
function SparkParticle:init(x, y)
    self.box = Box(x-1, y-1, 2, 2)
    self.vx  = randf(-3, 3)
    self.vy  = randf(-3, 3)
    self.ttl = random(3, 7)
end
function SparkParticle:sub_update()
    self.vx = self.vx * 0.97
    self.vy = self.vy * 0.97
    self.vy = clamp(self.vy + GRAVITY, -MAX_VY, MAX_VY)
    if World:move_x(self.box, self.vx) then
        self.vx = self.vx * -1
    end
    if World:move_y(self.box, self.vy) then
        self.vy = self.vy * -1
    end
end
function SparkParticle:draw()
    local r = math.min(1, self.ttl / 5)
    G.setColor(1, 1, 1, 0.5)
    G.push()
    G.translate(self.box:get_center())
    G.rotate(math.atan2(self.vx, -self.vy))
    G.ellipse("fill", 0, 0, r, length(self.vx, self.vy))
    G.pop()
end




local DustParticle = Particle:new()
function DustParticle:init(x, y, a)
    self.x = x + randf(-3, 3)
    self.y = y + randf(-3, 3)

    a = a + randf(-0.1, 0.1)
    local v = randf(0.4, 1.1)
    self.vx = math.sin(a) * v
    self.vy = math.cos(a) * v

    self.r = Tween(0):tween(randf(4, 6), randf(1, 15))
    self.r:set_ease(Tween.EASE_OUT):set_trans(Tween.TRANS_QUAD):tween(0, randf(15, 25)):kill_when_done(self)

end
function DustParticle:sub_update()
    self.r:update()
    self.vx = self.vx * 0.93
    self.vy = self.vy * 0.93
    self.x  = self.x + self.vx
    self.y  = self.y + self.vy
end
function DustParticle:draw()
    G.setColor(0.35, 0.35, 0.35, 0.6)
    G.circle("fill", self.x, self.y, self.r.value)
end




local DebrisParticle = Particle:new({
    POLYS = {
        { -1, -1, 1, -0.8, 0.2, 1, -0.8, 1 },
        { -0.7, -1, 1, -0.8, 0, 1 },
    }

})
function DebrisParticle:init(x, y)
    self.r = randf(0.5, 2)
    x = x - self.r + randf(-5, 5)
    y = y - self.r + randf(-5, 5)
    self.box = Box(x, y, self.r, self.r)
    self.vx  = randf(-2.5, 2.5)
    self.vy  = randf(-4.5, 1)
    self.a   = randf(0, 2 * math.pi)
    self.va  = randf(-0.5, 0.5)

    self.poly = DebrisParticle.POLYS[random(1, #DebrisParticle.POLYS)]

    self.ttl = random(70, 100)
end
function DebrisParticle:sub_update()

    self.vx = self.vx * 0.99
    self.vy = self.vy * 0.99
    self.a = self.a + self.va

    self.vy = self.vy + GRAVITY

    if World:move_x(self.box, self.vx) then
        self.ttl = math.max(0, self.ttl - 20)
        self.vx  = self.vx * -randf(0, 1)
        self.va  = randf(-0.5, 0.5)
    end

    local vy = clamp(self.vy, -MAX_VY, MAX_VY)
    if World:move_y(self.box, vy) then
        self.ttl = math.max(0, self.ttl - 20)
        self.vy   = self.vy * -randf(0, 1)
        self.va  = randf(-0.5, 0.5)
    end
end
function DebrisParticle:draw()
    G.setColor(0.4, 0.4, 0.4, math.min(1, self.ttl / 10))

    G.push()
    G.translate(self.box:get_center())
    G.rotate(self.a)
    G.scale(self.r)

    G.polygon("fill", self.poly)

    G.pop()
end


function make_explosion(x, y)
    for i = 1, 7 do
        World:add_particle(DebrisParticle(x, y))
    end
    local N = 20
    for i = 1, N do
        World:add_particle(DustParticle(x, y, i * 2 * math.pi / N))
    end
    World:add_particle(FlashParticle(x, y, 10))

    World.shaker:shake()
end

function make_sparks(x, y)
    for _ = 1, 5 do
        World:add_particle(SparkParticle(x, y))
    end
end


