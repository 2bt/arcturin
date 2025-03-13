Solid = Object:new {
    alive = true
}
function Solid:update()
end
function Solid:hit(power)
end
function Solid:draw()
    G.setColor(1, 1, 1, 0.5)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end



local CRATE_COLOR1 = { 0.25, 0.48, 0.19 }
local CRATE_COLOR2 = { 0.12, 0.28, 0.17 }
Crate = Solid:new()
function Crate:init(x, y)
    self.box = Box(x, y, TILE_SIZE, TILE_SIZE)
    self.hp  = 2
end
function Crate:hit(power)
    self.hp = self.hp - power
    if self.hp <= 0 then
        self.alive = false
        for i = 1, 20 do
            World:add_particle(CrateParticle(
                self.box:center_x() + love.math.random(-4, 4),
                self.box:center_y() + love.math.random(-4, 4)))
        end
    end
end
function Crate:draw()

    local q = self.hp > 1 and 1 or 3
    G.setColor(unpack(CRATE_COLOR1))
    G.rectangle("fill", self.box.x,     self.box.y,     4, 4, q)
    G.rectangle("fill", self.box.x + 4, self.box.y + 4, 4, 4, q)
    G.setColor(unpack(CRATE_COLOR2))
    G.rectangle("fill", self.box.x + 4, self.box.y,     4, 4, q)
    G.rectangle("fill", self.box.x,     self.box.y + 4, 4, 4, q)
end


CrateParticle = Particle:new()
function CrateParticle:init(x, y)
    self.box   = Box(x-1, y-1, 2, 2)
    self.vx    = love.math.random() * 3 - 1.5
    self.vy    = love.math.random() * 3 - 2
    self.ttl   = 10 + love.math.random(20)
    self.color = love.math.random(1, 2) == 1 and CRATE_COLOR1 or CRATE_COLOR2
end
function CrateParticle:sub_update()

    self.vx = self.vx * 0.95
    self.vy = self.vy * 0.95
    self.vy = clamp(self.vy + GRAVITY, -MAX_VY, MAX_VY)
    if World:move_x(self.box, self.vx) then
        self.vx = self.vx * -1
        self.vy = self.vy * 0.8
    end
    if World:move_y(self.box, self.vy) then
        self.vy = self.vy * -love.math.random()
        self.vx = self.vx * 0.8
    end
end
function CrateParticle:draw()
    local r = math.min(1, self.ttl / 5)
    G.setColor(unpack(self.color))
    G.circle("fill", self.box:center_x(), self.box:center_y() + (1 - r), r)
end
