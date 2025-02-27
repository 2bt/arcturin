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
function Crate:update()
end
function Crate:draw()

    local q = 3 - self.hp
    G.setColor(0.19, 0.27, 0.07)
    G.rectangle("fill", self.box.x,     self.box.y,     4, 4, q)
    G.rectangle("fill", self.box.x + 4, self.box.y + 4, 4, 4, q)
    G.setColor(0.2, 0.3, 0.15)
    G.rectangle("fill", self.box.x + 4, self.box.y,     4, 4, q)
    G.rectangle("fill", self.box.x,     self.box.y + 4, 4, 4, q)
end

