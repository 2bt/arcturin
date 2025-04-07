local HeroBullet = Object:new({
    alive = true,
    first_update = true,
    -- attributes
    power = 1,
    vx    = 0,
    vy    = 0,
})
function HeroBullet:update()
    -- check if still on screen
    if not self.box:overlaps(World.camera) then
        self.alive = false
        return
    end
    if self.ttl then
        self.ttl = self.ttl - 1
        if self.ttl < 0 then
            self.alive = false
            local x = self.box:center_x() + self.vx * 0.5
            local y = self.box:center_y() + self.vy * 0.5
            for _ = 1, 5 do
                World:add_particle(SparkParticle(x, y))
            end
            return
        end
    end

    -- move bullet back in first update
    local steps = 2
    if self.first_update then
        self.first_update = false
        steps = 4
        self.box.x = self.box.x - self.vx * 2
        self.box.y = self.box.y - self.vy * 2
    end
    local s
    for _ = 1, steps do
        local sx = World:move_x(self.box, self.vx / 2)
        local sy = World:move_y(self.box, self.vy / 2)
        s = sx or sy
        if s then break end
    end

    -- enemy collision
    for _, e in ipairs(World.enemies) do
        if e.active then
            local x, y = e:bullet_collision(self)
            if x then
                self.alive = false
                World:add_particle(FlashParticle(x, y))
                make_sparks(x, y)
                return
            end
        end
    end


    -- solid collision
    if s then
        local p = math.min(self.power, s:get_hp())
        s:take_hit(p)
        self.power = self.power - p
        if self.power <= 0 then
            self.alive = false
            local x, y = self.box:intersect_center_ray(self.vx, self.vy)
            World:add_particle(FlashParticle(x, y))
            local l = 2 / length(self.vx, self.vy)
            make_sparks(x - self.vx*l, y - self.vy*l) -- move away from the wall
        end
    end
end


HeroLaser = HeroBullet:new()
function HeroLaser:init(x, y, dir)
    self.box   = Box.make_centered(x, y, 10, 4)
    self.vx    = dir * 5
    self.power = 5
end
function HeroLaser:draw()
    G.setColor(0.9, 1, 1, 0.7)
    G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h, 1)
end


HeroAimShot = HeroBullet:new()
function HeroAimShot:init(x, y, a)
    self.box = Box.make_centered(x, y, 5, 5)
    self.vx  = math.sin(a) * 4
    self.vy  = math.cos(a) * 4
    self.a   = a
    self.ttl = 16
end
local AIM_MESH
do
    local v = {}
    for x = -5, 5, 0.5 do
        local y1 = math.cos(x * 0.14) * 22 - 18
        local y2 = math.min(y1, -1)
        table.insert(v, { x, y1, 0, 0, 1, 1, 0.9, 1 })
        table.insert(v, { x, y2, 0, 0, 1, 1, 0.9, 0 })
    end
    AIM_MESH = G.newMesh(v, "strip", "static")
end
function HeroAimShot:draw()
    G.setColor(1, 1, 1)
    G.draw(AIM_MESH, self.box:center_x(), self.box:center_y(), -self.a)
    -- G.setColor(1, 0, 1)
    -- G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h)
end
