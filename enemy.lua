Enemy = Object:new({
    alive  = true,
    active = false,
    hp     = 5,
})
function Enemy:update()
    if not self.active then
        if not self.box:overlaps(World.active_area) then
            return
        end
        self.active = true
    end

    self:sub_update()
end
function Enemy:hit(power)
    self.hp = self.hp - power
    if self.hp <= 0 then
        self.alive = false
    end
end

UfoEnemy = Enemy:new()
function UfoEnemy:init(x, y)
    self.box = Box.make_above(x, y, 16, 14)
    self.hp  = 10
end
function UfoEnemy:sub_update()

end
function UfoEnemy:draw()
    G.setColor(1, 0, 0)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h, 2)
end