local G = love.graphics

World = Object:new()
function World:init()
	self.map    = Map("assets/map.json")

	self.entities = {}
--	self.new_entities = {}
--	self.active_entities = {}
--	self.heroes = {}


	table.insert(self.entities, Hero(150, 100))

	self.camera = {
		x = 120,
		y = 72,
		w = W,
		h = H
	}

end
function World:update()

	-- update / delete entities
	local j = 1
	for i, e in ipairs(self.entities) do
		e:update()
		if e.alive then
			self.entities[j] = e
			j = j + 1
		end
	end
	for i = j, #self.entities do
		self.entities[i] = nil
	end


	-- horizintal collision

	-- vertical collision

	-- append new entities

	-- update camera

end
function World:draw()
	G.translate(-self.camera.x, -self.camera.y)


	self.map:draw(self.camera)

	for _, e in ipairs(self.entities) do
		if e.alive then
			e:draw(self.camera)
		end
	end
end
