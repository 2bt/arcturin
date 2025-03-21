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


local CRATE_COLOR1 = { 0.4,  0.23, 0.17 }
local CRATE_COLOR2 = { 0.4,  0.31, 0.2 }
local CRATE_MESHES = {}
do
    local b = MeshBuilder()
    b:polygon({0,160,40,160,40,130,60,110,140,80,160,80,160,0,120,0,120,30,100,50,20,80,0,80})
    table.insert(CRATE_MESHES, b:build())
    local b = MeshBuilder()
    b:polygon({0,0,40,0,40,30,60,50,140,80,160,80,160,160,120,160,120,130,100,110,20,80,0,80})
    table.insert(CRATE_MESHES, b:build())
end
Crate = Solid:new()
function Crate:init(x, y)
    self.box = Box(x, y, TILE_SIZE, TILE_SIZE)
    self.hp  = 2
end
function Crate:hit(power)
    self.hp = self.hp - power
    if self.hp <= 0 then
        self.alive = false
        for i = 1, 10 do
            World:add_particle(CrateParticle(
                self.box:center_x() + randf(-4, 4),
                self.box:center_y() + randf(-4, 4)))
        end
    end
end
function Crate:draw()
    local q = (self.box.x + self.box.y) / 8 % 2
    if q == 0 then
        G.setColor(0.19, 0.15, 0.11)
        G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h, 3)
        G.setColor(unpack(CRATE_COLOR1))
        G.draw(CRATE_MESHES[1], self.box.x, self.box.y,  0, 1/20)
    else
        G.setColor(0.15, 0.13, 0.11)
        G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h, 3)
        G.setColor(unpack(CRATE_COLOR2))
        G.draw(CRATE_MESHES[2], self.box.x, self.box.y, 0, 1/20)
    end
end


CrateParticle = Particle:new()
function CrateParticle:init(x, y)
    self.r     = randf(0.5, 1.3)
    self.box   = Box(x - self.r, y - self.r, self.r, self.r)
    self.vx    = randf(-1.5, 1.5)
    self.vy    = randf(-2.0, 1.0)
    self.ttl   = random(10, 40)
    self.color = random(1, 2) == 1 and CRATE_COLOR1 or CRATE_COLOR2
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
        self.vy = self.vy * -randf(0, 0.7)
        self.vx = self.vx * 0.8
    end
end
function CrateParticle:draw()
    local r = math.min(self.r, self.ttl / 5)
    G.setColor(unpack(self.color))
    G.circle("fill", self.box:center_x(), self.box:center_y() + (1 - r), r)
end
