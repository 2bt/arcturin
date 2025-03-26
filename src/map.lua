local json = require("dkjson")

TILE_SIZE = 8

TILE_TYPE_EMPTY   = 0
TILE_TYPE_ROCK    = 1
TILE_TYPE_STONE   = 2
TILE_TYPE_COMB    = 9
TILE_TYPE_BRIDGE  = 10



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
    if c < 0 or c >= self.w then return TILE_TYPE_EMPTY end
    if r < 0 or r >= self.h then return TILE_TYPE_EMPTY end
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
function Map:init(file_name)
    self.file_name          = file_name
    self.tick               = 0
    self.bridge_offsets     = {}
    self.new_bridge_offsets = {}

    local raw = love.filesystem.read(file_name)
    local data = json.decode(raw)
    self.w = data.width
    self.h = data.height
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

local MAX_BRIDGE_OFFSET = 2


function Map:collision(box, overlap_func, amount)
    local c1 = math.floor(box.x / TILE_SIZE)
    local c2 = math.floor(box:right() / TILE_SIZE)
    local r1 = math.floor(box.y / TILE_SIZE)
    local r2 = math.floor(box:bottom() / TILE_SIZE)

    local b = Box(0, 0, TILE_SIZE, TILE_SIZE)
    local overlap = 0

    local EPSILON = 0.0001

    for c = c1, c2 do
        for r = r1, r2 do
            local t = self.main:get(c, r)

            if t == TILE_TYPE_BRIDGE then

                -- jump through
                -- HACK: let small boxes fall through
                if box.w > 6 and overlap_func == Box.overlap_y and amount > 0 then

                    self:update_bridge_offsets(box:center_x(), box:bottom())

                    b.x = c * TILE_SIZE
                    b.y = r * TILE_SIZE + MAX_BRIDGE_OFFSET
                    local o = overlap_func(box, b)
                    if 0 > o and o >= -amount - EPSILON and math.abs(o) > math.abs(overlap) then
                    -- if 0 > o and math.abs(o) > math.abs(overlap) then
                        -- print(string.format("%.2f %.2f", o, amount), o >= -amount)
                        overlap = o
                    end
                end

            elseif t ~= TILE_TYPE_EMPTY then
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

function Map:update_bridge_offsets(x, y)
    local c = math.floor(x / TILE_SIZE)
    local r = math.floor(y / TILE_SIZE)
    local i = c + r * self.w + 1
    if self.main.data[i] ~= TILE_TYPE_BRIDGE then return end

    local yy = r * TILE_SIZE
    for cc = c - 3, c + 3, 0.5 do
        local xx = cc * TILE_SIZE + 2
        local dx = clamp(math.abs(xx - x) - 5, 0, 7) / 7 * MAX_BRIDGE_OFFSET
        local dy = clamp(y - yy, 0, MAX_BRIDGE_OFFSET)
        local j = cc + r * self.w + 1
        self.new_bridge_offsets[j] = math.max(self.new_bridge_offsets[j] or 0, dy - dx)
    end
end

function Map:update()
    self.tick = self.tick + 1


    local prev_bridge_offsets = self.bridge_offsets
    self.bridge_offsets = self.new_bridge_offsets
    self.new_bridge_offsets = {}


    -- for _, h in ipairs(World.heroes) do
    --     if h:has_weight() then
    --         self:update_bridge_offsets(h.box:center_x(), h.box:bottom())
    --     end
    -- end
    -- for _, e in ipairs(World.enemies) do
    --     if e.active and e.alive then
    --         self:update_bridge_offsets(e.box:center_x(), e.box:bottom())
    --     end
    -- end


    -- gradually move elements up
    for i, po in pairs(prev_bridge_offsets) do
        local o = self.bridge_offsets[i] or 0
        if po > o then
            self.bridge_offsets[i] = math.max(o, po - 0.2)
        end
    end

end


function Map:draw(layer)

    if layer == "background" then
        self.background:draw()


        local box = World.camera
        local x1 = math.floor(box.x / TILE_SIZE)
        local x2 = math.floor(box:right() / TILE_SIZE)
        local y1 = math.floor(box.y / TILE_SIZE)
        local y2 = math.floor(box:bottom() / TILE_SIZE)

        G.setColor(0.4, 0.4, 0.4, 0.5)
        for x = x1, x2 do
            for y = y1, y2 do
                local i = x + y * self.w + 1
                if self.main.data[i] == TILE_TYPE_BRIDGE then
                    for j = 0, 1 do
                        local bo = self.bridge_offsets[i + j * 0.5] or 0
                        -- G.rectangle("fill", x * 8 + j * 4, y * 8 + bo, 4, 4)
                        G.push()
                        G.translate(x * 8 + j * 4 + 2, y * 8 + 2 + bo)
                        G.setColor(0.3, 0.29, 0.25)
                        G.circle("fill", 0, 0, 2.25, 6)
                        G.setColor(0.2, 0.18, 0.18)
                        G.circle("fill", 0, 0, 1, 6)
                        G.pop()
                    end
                end
            end
        end


    elseif layer == "main" then

        self.main:draw()


    end
end