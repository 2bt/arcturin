local G = love.graphics

Entity = Object:new {
	alive = true,
}

function Entity:on_collision(axis, dist, entity)
end
function Entity:update()
end
function Entity:draw(camera)
	G.setColor(1, 1, 1)
	G.rectangle("line", self.rect.x, self.rect.y, self.rect.w, self.rect.h)
end


Hero = Entity:new()
function Hero:init(x, y)
	self.rect = {
		x = x,
		y = y,
		w = 12,
		h = 24,
	}
end
