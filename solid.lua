Solid = Object:new {
    alive = true
}
function Solid:update()
end
function Solid:hit(amount)
end
function Solid:draw()
    G.setColor(1, 1, 1, 0.5)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end


Crate = Solid:new()
function Crate:init(x, y)
    self.box    = Box(x, y, TILE_SIZE, TILE_SIZE)
    self.shield = 2
end
function Crate:hit(amount)
    self.shield = self.shield - amount
    if self.shield <= 0 then
        self.alive = false

        -- TODO: explode
        for i = 1, 10 do
            World:add_actor(CrateParticle(
                self.box:center_x() + love.math.random(-4, 4),
                self.box:center_y() + love.math.random(-4, 4)))
        end
    end
end
function Crate:update()

end
function Crate:draw()

    local q = 3 - self.shield
    G.setColor(0.19, 0.27, 0.07)
    G.rectangle("fill", self.box.x,     self.box.y,     4, 4, q)
    G.rectangle("fill", self.box.x + 4, self.box.y + 4, 4, 4, q)
    G.setColor(0.2, 0.3, 0.1)
    G.rectangle("fill", self.box.x + 4, self.box.y,     4, 4, q)
    G.rectangle("fill", self.box.x,     self.box.y + 4, 4, 4, q)
end

