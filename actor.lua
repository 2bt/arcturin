GRAVITY = 0.2

Actor = Object:new {
    alive = true,
}
function Actor:update()
end
function Actor:draw(camera)
    G.setColor(1, 1, 1, 0.5)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end


-- Crate = Actor:new()
-- function Crate:init(x, y)
--     self.box = Box.make_above(x, y, 16, 16)
--     self.vy  = 0
-- end
-- function Crate:update()
--     self.vy = self.vy + GRAVITY
--     local vy = clamp(self.vy, -3, 3)
--     self.next_y = self.box.y + vy
-- end
-- function Crate:on_collision(axis, dist, other)
--     if other == nil
--     or getmetatable(other) == Crate and other.box.y > self.box.y
--     then
--         if axis == "y" then
--             self.box.y = self.box.y + dist
--             self.next_y = self.box.y
--             self.vy = 0
--         end
--     end

-- end
-- function Crate:draw(camera)
--     G.setColor(0.6, 0.5, 0.2, 0.5)
--     G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h)
-- end

