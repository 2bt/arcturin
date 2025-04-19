FLASH_SHADER = G.newShader([[
uniform float flash;
vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
    return vec4(mix(col.rgb, vec3(1.0, 1.0, 1.0), flash * 0.5), col.a);
}]])


Enemy = Object:new({
    alive  = true,
    active = false,
    flash  = 0,
    tick   = 0,
    dir    = 1,
    hp     = 5,
    inactive_count = 0
})
function Enemy:activate()
    self.dir = self.box:center_x() > World.camera:center_x() and -1 or 1
end
function Enemy:deactivate()
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
            if self.inactive_count > 10 then
                self.inactive_count = 0
                self.active = false
                self:deactivate()
                if not self.active then return end
            end
        end
    end

    self.tick = self.tick + 1
    self.flash = math.max(0, self.flash - 0.4)
    self:sub_update()


    if self.box.y > World.map.h * TILE_SIZE then
        self:die()
    end
end
function Enemy:draw()
    FLASH_SHADER:send("flash", self.flash)
    G.setShader(FLASH_SHADER)
    self:sub_draw()
    G.setShader()

    -- G.setColor(1, 0, 0, 0.4)
    -- G.rectangle("line", self.box.x, self.box.y, self.box.w, self.box.h)
end

function Enemy:take_hit(power)
    self.flash = 1
    self.hp    = self.hp - power
    if self.hp <= 0 then
        self:die()
    end
end
function Enemy:die()
    if not self.alive then return end
    make_explosion(self.box:get_center())
    self.alive = false
end


function Enemy:hero_collision(hero)
    if self.box:overlaps(hero.box) then
        return self.box:intersection(hero.box):get_center()
    end
    return nil, nil
end
function Enemy:bullet_collision(bullet)
    if self.box:overlaps(bullet.box) then
        self:take_hit(bullet.power)
        local b = self.box:intersection(bullet.box)
        return b:intersect_center_ray(-bullet.vx, -bullet.vy)
    end
    return nil, nil
end




require("enemies.ufo_enemy")
require("enemies.fly_enemy")
require("enemies.walker_enemy")
require("enemies.dragon_enemy")
require("enemies.cannon_enemy")
