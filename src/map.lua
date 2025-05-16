local json = require("dkjson")

TILE_SIZE = 8

TILE_TYPE_EMPTY   = 0
TILE_TYPE_ROCK    = 1
TILE_TYPE_STONE   = 2
TILE_TYPE_BRIDGE  = 3
TILE_TYPE_COMB    = 9
TILE_TYPE_COMB2   = 10

local MAX_BRIDGE_OFFSET = 2

local ENEMY_MAP = {
    ["ufo"]    = UfoEnemy,
    ["fly"]    = FlyEnemy,
    ["walker"] = WalkerEnemy,
    ["dragon"] = DragonEnemy,
    ["cannon"] = CannonEnemy,
}


-- comb
local COMB_COLOR1 = { 0.4, 0.23, 0.17 }
local COMB_COLOR2 = { 0.4, 0.31, 0.2 }
local COMB_MESHES = {}
do
    local b = MeshBuilder()
    b:color(unpack(COMB_COLOR1))
    b:polygon({0,8,1.5,8,1.5,6.5,2.5,5.5,7,3.5,8,3.5,8,0,6.5,0,6.5,1.5,5.5,2.5,1,4.5,0,4.5})
    table.insert(COMB_MESHES, b:build())
    local b = MeshBuilder()
    b:color(unpack(COMB_COLOR2))
    b:polygon({0,0,1.5,0,1.5,1.5,2.5,2.5,7,4.5,8,4.5,8,8,6.5,8,6.5,6.5,5.5,5.5,1,3.5,0,3.5})
    table.insert(COMB_MESHES, b:build())
end
local CombParticle = Particle:new()
function CombParticle:init(x, y)
    self.r     = randf(0.5, 1.3)
    self.box   = Box(x - self.r, y - self.r, self.r, self.r)
    self.vx    = randf(-1.5, 1.5)
    self.vy    = randf(-2.0, 1.0)
    self.ttl   = random(10, 40)
    self.color = random(1, 2) == 1 and COMB_COLOR1 or COMB_COLOR2
end
function CombParticle:sub_update()

    self.vx = self.vx * 0.95
    self.vy = self.vy * 0.95
    self.vy = clamp(self.vy + GRAVITY, -MAX_VY, MAX_VY)
    if World:move_x(self.box, self.vx) then
        self.vx = self.vx * -1
        self.vy = self.vy * 0.8
    end
    if World:move_y(self.box, self.vy) then
        self.vy = self.vy * -randf(0, 0.7)
        self.vx = self.vx * 0.8
    end
end
function CombParticle:draw()
    local r = math.min(self.r, self.ttl / 5)
    G.setColor(unpack(self.color))
    G.circle("fill", self.box:center_x(), self.box:center_y() + (1 - r), r)
end
local MapSolid = Solid:new()
function MapSolid:get_hp()
    local t = World.map.main.data[self.index]
    if t == TILE_TYPE_COMB then return 2 end
    if t == TILE_TYPE_COMB2 then return 1 end
    return math.huge
end
function MapSolid:take_hit(power)
    local t = World.map.main.data[self.index]
    if t == TILE_TYPE_COMB or t == TILE_TYPE_COMB2 then
        local hp = self:get_hp() - power
        if hp > 0 then
            t = TILE_TYPE_COMB2
        else
            t = TILE_TYPE_EMPTY
            local c, r = World.map.main:get_cr(self.index)
            local x = c * TILE_SIZE
            local y = r * TILE_SIZE
            for i = 1, 10 do
                World:add_particle(CombParticle(
                    x + randf(1, 7),
                    y + randf(1, 7)))
            end
        end
        World.map.main.data[self.index] = t
    end
end



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

DEBUG_RAYS = {}

function Layer:raycast(x0, y0, x1, y1)
    local dx, dy = x1 - x0, y1 - y0
    if dx == 0 and dy == 0 then return nil end

    local stepX  = (dx >= 0) and 1 or -1
    local stepY  = (dy >= 0) and 1 or -1

    local mapX   = math.floor(x0 / TILE_SIZE)
    local mapY   = math.floor(y0 / TILE_SIZE)
    local endX   = math.floor(x1 / TILE_SIZE)
    local endY   = math.floor(y1 / TILE_SIZE)

    local invDx  = (dx ~= 0) and 1 / dx or math.huge
    local invDy  = (dy ~= 0) and 1 / dy or math.huge
    local deltaTX = math.abs(TILE_SIZE * invDx)
    local deltaTY = math.abs(TILE_SIZE * invDy)

    local tMaxX = (dx >= 0)
        and ((mapX + 1) * TILE_SIZE - x0) * invDx
        or  (x0 - mapX * TILE_SIZE) * -invDx

    local tMaxY = (dy >= 0)
        and ((mapY + 1) * TILE_SIZE - y0) * invDy
        or  (y0 - mapY * TILE_SIZE) * -invDy

    local tEnd = 1.0

    -- Immediate hit if we spawn inside a wall
    if self:get(mapX, mapY) ~= TILE_TYPE_EMPTY
       and self:get(mapX, mapY) ~= TILE_TYPE_BRIDGE then
        return x0, y0, mapX, mapY
    end

    while true do
        -- choose the next grid boundary we will cross
        local tNext, stepAxis = math.min(tMaxX, tMaxY),
                                (tMaxX <= tMaxY and "x" or "y")

        -- stop if the next boundary is *beyond* the end‑point
        if tNext > tEnd then return nil end

        -- advance to the neighbouring tile
        if stepAxis == "x" then
            mapX  = mapX + stepX
            tMaxX = tMaxX + deltaTX
        else
            mapY  = mapY + stepY
            tMaxY = tMaxY + deltaTY
        end

        -- wall test
        if self:get(mapX, mapY) ~= TILE_TYPE_EMPTY
           and self:get(mapX, mapY) ~= TILE_TYPE_BRIDGE then
            -- table.insert(DEBUG_RAYS, { x0, y0, x0 + dx * tNext, y0 + dy * tNext })
            return x0 + dx * tNext, y0 + dy * tNext, mapX, mapY
        end

        -- reached the destination tile with no hit
        if mapX == endX and mapY == endY then
            return nil
        end
    end
end



Map = Object:new()
function Map:init(file_name)
    self.file_name          = file_name
    self.bridge_offsets     = {}
    self.new_bridge_offsets = {}


    local raw = love.filesystem.read(file_name)
    local data = json.decode(raw)
    self.w = data.width
    self.h = data.height
    -- layers
    self.main       = nil
    self.background = nil

    self.enemies = {}
    self.exit    = nil

    for _, l in ipairs(data.layers) do


        if l.name == "stuff" then
            for _, o in ipairs(l.objects) do
                if o.name == "hero" then
                    self.hero_x = o.x + o.width / 2
                    self.hero_y = o.y + o.height
                elseif o.name == "exit" then
                    self.exit = Box(o.x, o.y, o.width, o.height)
                else
                    error(string.format("unknown object [%s]", o.name))
                end
            end

        elseif l.name == "enemies" then
            for _, o in ipairs(l.objects) do
                local e = ENEMY_MAP[o.name](
                    o.x + o.width / 2,
                    o.y + o.height,
                    self.main)
                table.insert(self.enemies, e)
            end
        else
            if self.w ~= l.width or self.h ~= l.height then
                error("layer size mismatch")
            end
            self[l.name] = Layer(l.width, l.height, l.data)
        end
    end

    self.background.index = 0
    self.main.index       = 1

    self:generate_meshes()
end



function Map:collision(box, overlap_func, amount)
    local c1 = math.floor(box.x / TILE_SIZE)
    local c2 = math.floor(box:right() / TILE_SIZE)
    local r1 = math.floor(box.y / TILE_SIZE)
    local r2 = math.floor(box:bottom() / TILE_SIZE)

    c1 = clamp(c1, 0, self.w-1)
    c2 = clamp(c2, 0, self.w-1)
    r1 = clamp(r1, 0, self.h-1)
    r2 = clamp(r2, 0, self.h-1)


    local b = Box(0, 0, TILE_SIZE, TILE_SIZE)
    local overlap = 0
    local index   = 0

    local EPSILON = 0.0001

    for c = c1, c2 do
        for r = r1, r2 do
            local i = c + r * self.w + 1
            local t = self.main.data[i]
            if t == TILE_TYPE_BRIDGE then

                -- jump through
                -- HACK: let small boxes fall through
                if box.w > 6 and overlap_func == Box.overlap_y and amount > 0 then

                    self:update_bridge_offsets(box:center_x(), box:bottom())

                    b.x = c * TILE_SIZE
                    b.y = r * TILE_SIZE + MAX_BRIDGE_OFFSET
                    local o = overlap_func(box, b)
                    if 0 > o and o >= -amount - EPSILON and math.abs(o) > math.abs(overlap) then
                        overlap = o
                        index   = i
                    end
                end

            elseif t ~= TILE_TYPE_EMPTY then
                b.x = c * TILE_SIZE
                b.y = r * TILE_SIZE
                local o = overlap_func(box, b)
                if math.abs(o) > math.abs(overlap) then
                    overlap = o
                    index   = i
                end
            end
        end
    end

    if index > 0 then
        MapSolid.index = index
        return overlap, MapSolid
    end
    return 0, nil
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

    -- bridge
    local prev_bridge_offsets = self.bridge_offsets
    self.bridge_offsets = self.new_bridge_offsets
    self.new_bridge_offsets = {}
    -- gradually move elements up
    for i, po in pairs(prev_bridge_offsets) do
        local o = self.bridge_offsets[i] or 0
        if po > o then
            self.bridge_offsets[i] = math.max(o, po - 0.3)
        end
    end

end


function Map:draw(layer)

    if layer == "background" then
        self.background:draw()

        local box = World.camera
        local c1 = math.floor(box.x / TILE_SIZE)
        local c2 = math.floor(box:right() / TILE_SIZE)
        local r1 = math.floor(box.y / TILE_SIZE)
        local r2 = math.floor(box:bottom() / TILE_SIZE)
        for c = c1, c2 do
            for r = r1, r2 do
                local i = c + r * self.w + 1
                local t = self.main.data[i]
                if t == TILE_TYPE_BRIDGE then
                    for j = 0, 1 do
                        local bo = self.bridge_offsets[i + j * 0.5] or 0
                        G.push()
                        G.translate(c * 8 + j * 4 + 2, r * 8 + 2 + bo)
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

        local box = World.camera
        local c1 = math.floor(box.x / TILE_SIZE)
        local c2 = math.floor(box:right() / TILE_SIZE)
        local r1 = math.floor(box.y / TILE_SIZE)
        local r2 = math.floor(box:bottom() / TILE_SIZE)
        for c = c1, c2 do
            for r = r1, r2 do
                local i = c + r * self.w + 1
                local t = self.main.data[i]

                if t == TILE_TYPE_COMB or t == TILE_TYPE_COMB2 then
                    local x = c * TILE_SIZE
                    local y = r * TILE_SIZE
                    local q = (c + r) % 2
                    if q == 0 then
                        G.setColor(0.19, 0.15, 0.11)
                        G.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE, 3)
                        G.setColor(1, 1, 1)
                        G.draw(COMB_MESHES[1], x, y)
                    else
                        G.setColor(0.15, 0.13, 0.11)
                        G.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE, 3)
                        G.setColor(1, 1, 1)
                        G.draw(COMB_MESHES[2], x, y)
                    end


                end


            end
        end

        -- DEBUG: render raycasts
        for _, r in ipairs(DEBUG_RAYS) do G.line(unpack(r)) end
        DEBUG_RAYS = {}
    end
end