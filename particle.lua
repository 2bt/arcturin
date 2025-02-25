CrateParticle = Object:new({ alive = true })
function CrateParticle:init(x, y)
    self.box = Box(x-1, y-1, 2, 2)
    self.vx = love.math.random() * 3 - 1.5
    self.vy = love.math.random() * 3 - 2
    self.ttl = 5 + love.math.random(20)
    self.taint = love.math.random(1, 2)
end
function CrateParticle:update()
    self.ttl = self.ttl - 1
    if self.ttl <= 0 then
        self.alive = false
        return
    end
    self.vy = clamp(self.vy + GRAVITY, -MAX_VY, MAX_VY)
    if World:move_x(self.box, self.vx) then
        self.vx = self.vx * -1
    end
    if World:move_y(self.box, self.vy) then
        self.vy = self.vy * -love.math.random()
    end
end
function CrateParticle:draw()
    local a = math.min(1, self.ttl / 3)
    if self.taint == 1 then
        G.setColor(0.19, 0.27, 0.07, a)
    else
        G.setColor(0.2, 0.3, 0.1, a)
    end
    G.circle("fill", self.box:center_x(), self.box:center_y(), 1)
end
