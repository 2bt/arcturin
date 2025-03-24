local json = require("dkjson")

TILE_SIZE = 8

TILE_TYPE_EMPTY = 0
TILE_TYPE_ROCK  = 1
TILE_TYPE_COMB  = 2
TILE_TYPE_STONE = 3



local ENEMY_MAP = {
    ["ufo"]    = UfoEnemy,
    ["walker"] = WalkerEnemy,
}

Map = Object:new()
function Map:init(name)

    local raw = love.filesystem.read(name)
    local data = json.decode(raw)

    for _, layer in ipairs(data.layers) do

        if layer.type == "objectgroup" then
            if layer.name == "objects" then
                for _, o in ipairs(layer.objects) do
                    local x = o.x + o.width / 2
                    local y = o.y + o.height
                    if o.name == "hero" then
                        self.hero_x = x
                        self.hero_y = y
                    elseif ENEMY_MAP[o.name] then
                        World:add_enemy(ENEMY_MAP[o.name](x, y))
                    else
                        error("unknown object")
                    end
                end
            end
        elseif layer.type == "tilelayer" then
            self.tile_data = layer.data
            self.w         = layer.width
            self.h         = layer.height
        end
    end


    -- convert comb tiles to comb solids
    local i = 1
    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            if self.tile_data[i] == TILE_TYPE_COMB then
                self.tile_data[i] = TILE_TYPE_EMPTY
                World:add_solid(CombSolid(x * TILE_SIZE, y * TILE_SIZE))
            end
            i = i + 1
        end
    end

    self.meshes = generate_map_meshes(self)
end
function Map:tile_at(x, y)
    if x < 0 or x >= self.w then return 1 end
    if y < 0 or y >= self.h then return 1 end
    return self.tile_data[y * self.w + x + 1]
end

function Map:tile_at_world_pos(x, y)
    x = math.floor(x / TILE_SIZE)
    y = math.floor(y / TILE_SIZE)
    if x < 0 or x >= self.w then return 1 end
    if y < 0 or y >= self.h then return 1 end
    return self.tile_data[y * self.w + x + 1]
end


function Map:collision(box, axis)
    local x1 = math.floor(box.x / TILE_SIZE)
    local x2 = math.floor(box:right() / TILE_SIZE)
    local y1 = math.floor(box.y / TILE_SIZE)
    local y2 = math.floor(box:bottom() / TILE_SIZE)

    local b = Box(0, 0, TILE_SIZE, TILE_SIZE)
    local overlap_func = axis == "x" and Box.overlap_x or Box.overlap_y
    local overlap = 0

    for x = x1, x2 do
        for y = y1, y2 do
            local t = self:tile_at(x, y)
            if t > 0 then
                b.x = x * TILE_SIZE
                b.y = y * TILE_SIZE
                local o = overlap_func(box, b)
                if math.abs(o) > math.abs(overlap) then
                    overlap = o
                end
            end
        end
    end

    return overlap
end
function Map:draw(layer)
    G.setColor(1, 1, 1)


    G.draw(self.meshes[layer])

    -- local box = World.camera
    -- local x1 = math.floor(box.x / TILE_SIZE)
    -- local x2 = math.floor(box:right() / TILE_SIZE)
    -- local y1 = math.floor(box.y / TILE_SIZE)
    -- local y2 = math.floor(box:bottom() / TILE_SIZE)
    -- G.setFont(FONT_SMALL)
    -- for x = x1, x2 do
    --     for y = y1, y2 do
    --         local i = x + y * self.w + 1
    --         G.print(string.format("%.1f", self.distances[i]), x * 8 + 2, y * 8 + 2)
    --     end
    -- end

end
