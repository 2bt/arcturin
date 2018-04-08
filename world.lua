local G = love.graphics

World = Object:new()
function World:init()
	self.map    = Map("assets/map.json")
	self.heroes = {}
end
function World:update()

end
function World:draw()
	local rect = {
		x = 120,
		y = 72,
		w = W,
		h = H
	}
	G.translate(-rect.x, -rect.y)


	self.map:draw(rect)
end
