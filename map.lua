local json = require("dkjson")
local G = love.graphics
TILE_SIZE = 8


Map = Object:new()
function Map:init(name)

	local raw = love.filesystem.read(name)
	local data = json.decode(raw)

	self.w = data.width
	self.h = data.height

	for _, layer in ipairs(data.layers) do

		if layer.type == "objectgroup" then
			if layer.name == "objects" then
			end

		elseif layer.type == "tilelayer" then
			self.tile_data = layer.data
		end

	end

end
function Map:tile_at(x, y)
	return self.tile_data[y * self.w + x + 1] or 0
end
function Map:draw(rect)

	local x1 = math.floor(rect.x / TILE_SIZE)
	local x2 = math.floor((rect.x + rect.w) / TILE_SIZE)
	local y1 = math.floor(rect.y / TILE_SIZE)
	local y2 = math.floor((rect.y + rect.h) / TILE_SIZE)

	G.setColor(1, 0, 0)
	for x = x1, x2 do
		for y = y1, y2 do
			local t = self:tile_at(x, y)
			if t == 1 then
				G.rectangle("fill",
					x * TILE_SIZE,
					y * TILE_SIZE,
					TILE_SIZE,
					TILE_SIZE)
			end
		end
	end

end
