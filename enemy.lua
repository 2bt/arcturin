Enemy = Object:new({
    alive  = true,
    active = false,
    hp     = 5,
    inactive_count = 0
})
function Enemy:activate()
end
function Enemy:update()

    -- activate and deactivate
    if not self.active then
        if not self.box:overlaps(World.active_area) then return end
        self.active = true
        self:activate()
    else
        if self.box:overlaps(World.active_area) then
            self.inactive_count = 0
        else
            self.inactive_count = self.inactive_count + 1
            if self.inactive_count > 20 then
                self.inactive_count = 0
                self.active = false
                return
            end
        end
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
    self.box  = Box.make_above(x, y, 16, 14)
    self.hp   = 7
    self.tick = 0
    self.dir  = 1
end
function UfoEnemy:activate()
    self.dir = self.box:center_x() > World.camera:center_x() and -1 or 1
end
function UfoEnemy:sub_update()
    self.tick = self.tick + 1

    local vx = self.dir * 1
    local t = self.tick * 0.12
    local vy = math.cos(t) * 1.5
    if t % (2 * math.pi) > math.pi then vy = -vy end

    if World:move_x(self.box, vx) then
        self.dir = -self.dir
    end
    World:move_y(self.box, vy)

end
function UfoEnemy:draw()
    G.setColor(1, 0, 0)
    G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h, 2)
end