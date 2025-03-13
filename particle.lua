Particle = Object:new({
    alive = true,
    ttl   = nil,
    tick  = 0,
})
function Particle:update()
    if self.ttl then
        self.ttl = self.ttl - 1
        if self.ttl < 0 then
            self.alive = false
            return
        end
    end
    self.tick = self.tick + 1
    if self.sub_update then self:sub_update() end
end


FlashParticle = Particle:new({
    colors = {
        { 1,   1,   1,   0.9 },
        { 1,   0.8, 0.7, 0.9 },
        { 1,   0.5, 0.2, 0.7 },
        { 0.7, 0.5, 0.2, 0.5 },
        { 0.7, 0.2, 0,   0.3 },
    }
})
function FlashParticle:init(x, y, r)
    self.r = r or 5
    self.x = x
    self.y = y
    self.ttl = #self.colors
end
function FlashParticle:draw()
    G.setColor(unpack(self.colors[self.tick]))
    G.circle("fill", self.x, self.y, self.r)
end


SparkParticle = Particle:new()
function SparkParticle:init(x, y)
    self.box = Box(x-1, y-1, 2, 2)
    self.vx  = randf(-3, 3)
    self.vy  = randf(-3, 3)
    self.ttl = love.math.random(3, 7)
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


local Dust = Particle:new()
function Dust:init(x, y)
    local a = randf(0, 2 * math.pi)
    self.x = x + math.sin(a) * randf(0, 4)
    self.y = y + math.cos(a) * randf(0, 4)
    a = randf(0, 2 * math.pi)

    local v = randf(0.2, 1.5)
    self.vx  = math.sin(a) * v
    self.vy  = math.cos(a) * v
    self.ttl = love.math.random(10, 30)
    self.r   = randf(4, 6)
    self.r_fade = randf(0.9, 0.96)
end
function Dust:sub_update()
    self.r  = self.r * self.r_fade
    self.vx = self.vx * 0.9
    self.vy = self.vy * 0.9
    self.x  = self.x + self.vx
    self.y  = self.y + self.vy
end
function Dust:draw()
    local a = math.min(0.7, self.ttl / 10)
    G.setColor(0.4, 0.4, 0.4, a)
    G.circle("fill", self.x, self.y, self.r)
end

function make_explosion(x, y)
    for i = 1, 20 do
        World:add_particle(Dust(x, y))
    end
    World:add_particle(FlashParticle(x, y, 10))
end