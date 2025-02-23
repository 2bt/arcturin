
Actor = Object:new {
    alive = true,
}
function Actor:update()
end
function Actor:draw()
    G.setColor(1, 1, 1, 0.5)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end
