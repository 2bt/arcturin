Solid = Object:new {
    alive = true
}
function Solid:update()
end
function Solid:get_hp()
    return math.huge
end
function Solid:take_hit(power)
end
function Solid:draw()
    G.setColor(1, 1, 1, 0.5)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end
