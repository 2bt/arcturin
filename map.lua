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
function Map:collision(box, axis, vel_y)
    vel_y = vel_y or 0

    local x1 = math.floor(box.x / TILE_SIZE)
    local x2 = math.floor((box.x + box.w) / TILE_SIZE)
    local y1 = math.floor(box.y / TILE_SIZE)
    local y2 = math.floor((box.y + box.h) / TILE_SIZE)

    local b = { w = TILE_SIZE, h = TILE_SIZE }
    local d = 0

    for x = x1, x2 do
        for y = y1, y2 do
            local t = self:tile_at(x, y)
            if t > 0
            then
                b.x = x * TILE_SIZE
                b.y = y * TILE_SIZE
                local e = collision(box, b, axis)

                if t == 1 then
                    if math.abs(e) > math.abs(d) then d = e end
                elseif t == 9 then
                    if axis == "y" and vel_y > 0 and e < 0 and -e <= vel_y + 0.001 then d = e end
                end
            end
        end
    end

    return d
end
function Map:draw(box)

    local x1 = math.floor(box.x / TILE_SIZE)
    local x2 = math.floor((box.x + box.w) / TILE_SIZE)
    local y1 = math.floor(box.y / TILE_SIZE)
    local y2 = math.floor((box.y + box.h) / TILE_SIZE)

    G.setColor(0.5, 0.2, 0.2)
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
