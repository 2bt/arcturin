local json = require("dkjson")
local TILE_SIZE = 8

Map = Object:new()
function Map:init(name)

    local raw = love.filesystem.read(name)
    local data = json.decode(raw)

    self.w = data.width
    self.h = data.height

    for _, layer in ipairs(data.layers) do

        if layer.type == "objectgroup" then
            if layer.name == "objects" then
                for _, o in ipairs(layer.objects) do
                    if o.name == "hero" then
                        self.hero_x = o.x + o.width / 2
                        self.hero_y = o.y + o.height
                    end

                end
            end
        elseif layer.type == "tilelayer" then
            self.tile_data = layer.data
        end

    end

end
function Map:tile_at(x, y)
    if x < 0 or x >= self.w then return 1 end
    if y < 0 or y >= self.h then return 1 end
    return self.tile_data[y * self.w + x + 1]
end

function Map:collision(box, axis)
    local overlap_func = axis == "x" and Box.overlap_x or Box.overlap_y

    local x1 = math.floor(box.x / TILE_SIZE)
    local x2 = math.floor(box:right() / TILE_SIZE)
    local y1 = math.floor(box.y / TILE_SIZE)
    local y2 = math.floor(box:bottom() / TILE_SIZE)

    local b = Box(0, 0, TILE_SIZE, TILE_SIZE)
    local d = 0

    for x = x1, x2 do
        for y = y1, y2 do
            local t = self:tile_at(x, y)
            if t > 0 then
                b.x = x * TILE_SIZE
                b.y = y * TILE_SIZE
                local e = overlap_func(box, b)

                if t == 1 then
                    if math.abs(e) > math.abs(d) then d = e end
                end

            end
        end
    end

    return d
end
function Map:draw(box)

    local x1 = math.floor(box.x / TILE_SIZE)
    local x2 = math.floor(box:right() / TILE_SIZE)
    local y1 = math.floor(box.y / TILE_SIZE)
    local y2 = math.floor(box:bottom() / TILE_SIZE)

    G.setColor(0.2, 0.2, 0.3)
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

            -- if t == 9 then
            --     G.rectangle("fill",
            --         x * TILE_SIZE,
            --         y * TILE_SIZE,
            --         TILE_SIZE,
            --         TILE_SIZE / 4)
            -- end


        end
    end

end
