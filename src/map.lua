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


local Layer = Object:new()
function Layer:init(w, h, data)
    self.w         = w
    self.h         = h
    self.data      = data
    -- set during mesh generation
    self.mesh      = nil
    self.distances = nil
end
function Layer:get_cr(i)
    return (i - 1) % self.w, math.floor((i - 1) / self.w)
end
function Layer:get(c, r)
    if c < 0 or c >= self.w then return 1 end
    if r < 0 or r >= self.h then return 1 end
    return self.data[r * self.w + c + 1]
end
function Layer:get_tile_at_world_pos(x, y)
    return self:get(math.floor(x / TILE_SIZE), math.floor(y / TILE_SIZE))
end
function Layer:draw()
    G.setColor(1, 1, 1)
    G.draw(self.mesh)
end


Map = Object:new()
function Map:init(name)

    local raw = love.filesystem.read(name)
    local data = json.decode(raw)

    self.tick       = 0
    self.w          = data.width
    self.h          = data.height
    -- layers
    self.main       = nil
    self.background = nil


    for _, l in ipairs(data.layers) do

        if l.name == "objects" then
            for _, o in ipairs(l.objects) do
                local x = o.x + o.width / 2
                local y = o.y + o.height
                if o.name == "hero" then
                    self.hero_x = x
                    self.hero_y = y
                elseif ENEMY_MAP[o.name] then
                    World:add_enemy(ENEMY_MAP[o.name](x, y))
                else
                    error(string.format("unknown object [%s]", o.name))
                end
            end
        else
            if self.w ~= l.width or self.h ~= l.height then
                error("layer size mismatch")
            end
            self[l.name] = Layer(l.width, l.height, l.data)
        end
    end

    -- convert comb tiles to comb solids
    for i, t in ipairs(self.main.data) do
        if t == TILE_TYPE_COMB then
            self.main.data[i] = TILE_TYPE_EMPTY
            local c, r = self.main:get_cr(i)
            World:add_solid(CombSolid(c * TILE_SIZE, r * TILE_SIZE))
        end
    end

    self:generate_meshes()
end


function Map:collision(box, axis)
    local c1 = math.floor(box.x / TILE_SIZE)
    local c2 = math.floor(box:right() / TILE_SIZE)
    local r1 = math.floor(box.y / TILE_SIZE)
    local r2 = math.floor(box:bottom() / TILE_SIZE)

    local b = Box(0, 0, TILE_SIZE, TILE_SIZE)
    local overlap_func = axis == "x" and Box.overlap_x or Box.overlap_y
    local overlap = 0

    for c = c1, c2 do
        for r = r1, r2 do
            local t = self.main:get(c, r)
            if t > 0 then
                b.x = c * TILE_SIZE
                b.y = r * TILE_SIZE
                local o = overlap_func(box, b)
                if math.abs(o) > math.abs(overlap) then
                    overlap = o
                end
            end
        end
    end

    return overlap
end

function Map:update()
    self.tick = self.tick + 1
end

-- function Map:draw()
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
-- end
