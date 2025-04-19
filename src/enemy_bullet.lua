local EnemyBullet = Object:new({
    alive = true,
    -- attributes
    power = 1,
    vx    = 0,
    vy    = 0,
    tick  = 0,
})
function EnemyBullet:update()
    -- check if still on screen
    if not self.box:overlaps(World.camera) then
        self.alive = false
        return
    end

    self.tick = self.tick + 1

    local sx = World:move_x(self.box, self.vx)
    local sy = World:move_y(self.box, self.vy)
    local s  = sx or sy

    -- solid collision
    if s then
        self.alive = false
        local x, y = self.box:intersect_center_ray(self.vx, self.vy)
        World:add_particle(FlashParticle(x, y))
    end

    -- hero collision
    for _, h in ipairs(World.heroes) do
        if h:is_targetable() then

            if self.box:overlaps(h.box) then
                self.alive = false
                h:take_hit(self.power, math.sign(self.vx))
                local b = self.box:intersection(h.box)
                local x, y = b:intersect_center_ray(-self.vx, -self.vy)
                World:add_particle(FlashParticle(x, y))
            end

        end
    end


end



local FIREBALL_MESH
do
    local p = { 0, 0 }
    local N = 12
    for i = 0, N do
        local a = i / N * 2 * math.pi
        local x = math.cos(a)
        local y = math.sin(a)
        local f = 7
        y = y * (0.4 + 0.2 * x)
        table.append(p, x * f, y * f)
    end
    local b = MeshBuilder()
    b:polygon(p)
    FIREBALL_MESH = b:build()
end

FireBall = EnemyBullet:new()
function FireBall:init(x, y, dir)
    self.box   = Box.make_centered(x, y, 7, 5)
    self.vx    = dir * 3
    self.power = 2
end
function FireBall:draw()
    G.setColor(mix({1, 0.4, 0.3, 0.7}, {1, 0.9, 0.3, 0.2}, math.sin(self.tick * 0.5) * 0.5 + 0.5))
    G.draw(FIREBALL_MESH, self.box:center_x(), self.box:center_y(), 0, math.sign(self.vx))
end



CannonBall = EnemyBullet:new()
function CannonBall:init(x, y, vx, vy)
    self.box = Box.make_centered(x, y, 3, 3)
    self.vx  = vx
    self.vy  = vy
end
function CannonBall:draw()
    G.setColor(mix({1, 0.3, 0.6, 0.7}, {1, 0.6, 0.9, 1}, math.sin(self.tick * 0.7) * 0.5 + 0.5))
    G.circle("fill", self.box:center_x(), self.box:center_y(), 3)
    -- G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h)
end