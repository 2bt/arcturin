Enemy = Object:new({
    alive  = true,
    active = false,
})


UfoEnemy = Enemy:new()
function UfoEnemy:init(x, y)
    self.box = Box.make_above(x, y, 16, 14)
end
function UfoEnemy:update()

end
function UfoEnemy:draw()
    G.setColor(1, 0, 0)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h, 2)
end