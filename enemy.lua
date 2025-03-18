Enemy = Object:new({
    alive  = true,
    active = false,
    dir    = 1,
    hp     = 5,
    inactive_count = 0
})
function Enemy:activate()
    self.dir = self.box:center_x() > World.camera:center_x() and -1 or 1
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
        make_explosion(self.box:get_center())
    end
end


require("enemies.ufo_enemy")
require("enemies.walker_enemy")