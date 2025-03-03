FlashParticle = Object:new({
    alive = true,
    colors = {
        { 1, 1, 1, 0.7 },
        { 0.7, 0.5, 0.2, 0.5 },
        { 0.7, 0.2, 0, 0.3 },
    }
})
function FlashParticle:init(x, y)
    self.box = Box.make_centered(x, y, 10, 10)
    self.ttl = #self.colors
end
function FlashParticle:update()
    self.ttl = self.ttl - 1
    if self.ttl < 0 then
        self.alive = false
        return
    end
end
function FlashParticle:draw()
    G.setColor(unpack(self.colors[#self.colors - self.ttl]))
    G.circle("fill", self.box:center_x(), self.box:center_y(), self.box.w / 2)
end


SparkParticle = Object:new({ alive = true })
function SparkParticle:init(x, y)
    self.box = Box(x-1, y-1, 2, 2)
    self.vx  = randf(-3, 3)
    self.vy  = randf(-3, 3)
    self.ttl = 3 + love.math.random(4)
end
function SparkParticle:update()
    self.ttl = self.ttl - 1
    if self.ttl < 0 then
        self.alive = false
        return
    end
    self.vx = self.vx * 0.97
    self.vy = self.vy * 0.97
    self.vy = clamp(self.vy + GRAVITY, -MAX_VY, MAX_VY)
    if World:move_x(self.box, self.vx) then
        self.vx = self.vx * -1
    end
    if World:move_y(self.box, self.vy) then
        self.vy = self.vy * -1
    end
end
function SparkParticle:draw()
    local r = math.min(1, self.ttl / 5)
    G.setColor(1, 1, 1, 0.5)
    G.push()
    G.translate(self.box:get_center())
    G.rotate(math.atan2(self.vx, -self.vy))
    G.ellipse("fill", 0, 0, r, length(self.vx, self.vy))
    G.pop()
end
