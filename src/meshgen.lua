MeshBuilder = Object:new()
function MeshBuilder:init()
    self.v = {}
    self:color(1, 1, 1)
end
function MeshBuilder:color(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b
    self.a = a or 1
end
function MeshBuilder:polygon(data)
    local triangles = love.math.triangulate(data)
    for _, t in ipairs(triangles) do
        for i = 1, 5, 2 do
            self.v[#self.v + 1] = {
                t[i], t[i + 1],
                0, 0,
                self.r, self.g, self.b, self.a,
            }
        end
    end
end
function MeshBuilder:rectangle(x, y, w, h)
    self:polygon({
        x,   y,
        x+w, y,
        x+w, y+h,
        x,   y+h,
    })
end
function MeshBuilder:build()
    return G.newMesh(self.v, "triangles", "static")
end




-- Felzenszwalb & Huttenlocher algorithm
local function calc_layer_distances(layer)
    local rows = layer.h
    local cols = layer.w
    local INF = rows*rows + cols*cols

    local dist = {}
    for i = 1, rows do
        dist[i] = {}
        for j = 1, cols do
            if layer:get(j - 1, i - 1) == TILE_TYPE_EMPTY then
                dist[i][j] = 0
            else
                dist[i][j] = INF
            end
        end
    end

    -- First pass: vertical distance transform for each column
    for j = 1, cols do
        for i = 2, rows do
            local d = dist[i-1][j] + 1
            if d < dist[i][j] then
                dist[i][j] = d
            end
        end
        for i = rows-1, 1, -1 do
            local d = dist[i+1][j] + 1
            if d < dist[i][j] then
                dist[i][j] = d
            end
        end
    end

    -- Second pass: horizontal distance transform for each row (using parabola optimization)
    layer.distances = {}
    for i = 1, rows do
        local f = {}
        for j = 1, cols do
            local d = dist[i][j]
            f[j] = d * d
        end
        local function intersection(q, r)
            return (f[r] + r*r - f[q] - q*q) * 0.5 / (r - q)
        end

        -- Arrays for the "convex hull" of parabolas
        local v = {}   -- positions (column indices) of parabolas in the hull
        local z = {}   -- array of "breakpoints" (intersection positions on the x-axis between parabolas)
        local k = 1    -- current index of convex hull
        v[1] = 1
        z[1] = -INF    -- start with -infinite breakpoint
        z[2] =  INF    -- end with +infinite

        for q = 2, cols do
            local s = intersection(v[k], q)
            -- Remove the last parabola from the hull while the new one is better sooner
            while k > 1 and s <= z[k] do
                k = k - 1
                s = intersection(v[k], q)
            end
            k = k + 1
            v[k] = q
            z[k] = s
            z[k + 1] = INF
        end

        -- Compute the distance for each column j in this row using the hull
        local hullIndex = 1
        for j = 1, cols do
            -- Advance hull index while the next breakpoint is to the left of column j
            while z[hullIndex + 1] < j do
                hullIndex = hullIndex + 1
            end
            -- Compute squared distance using the parabola at v[hullIndex]
            local dx = j - v[hullIndex]
            table.insert(layer.distances, (dx*dx + f[v[hullIndex]])^0.5)
        end
    end
end


-- vector helper functions
local function dot(a, b)
    return a[1] * b[1] + a[2] * b[2]
end
local function add(a, b)
    return { a[1] + b[1], a[2] + b[2] }
end
local function sub(a, b)
    return { a[1] - b[1], a[2] - b[2] }
end
local function scale(v, f)
    return { v[1] * f, v[2] * f }
end
local function length(v)
    return (v[1]^2 + v[2]^2)^0.5
end
local function normalize(v)
    return scale(v, 1 / length(v))
end

local noise = love.math.noise

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = random(i)
        t[i], t[j] = t[j], t[i]
    end
end





local Turtle = Object:new()
function Turtle:init(x, y, a)
    self.x = x
    self.y = y
    self.a = a or 0
end
function Turtle:transform_point(x, y)
    local s = math.sin(self.a)
    local c = math.cos(self.a)
    return self.x + x * c + y * s, self.y + y * c - x * s
end
function Turtle:forward(v)
    self.x, self.y = self:transform_point(0, -v)
end
function Turtle:turn(a)
    self.a = self.a + a
end


local function plant(b, x, y)
    local DY = 1.7
    local DP = 0.27
    local XX = 6

    local q = randf(0, math.pi * 2)
    for j = 1, 3 do
        q = q + math.pi * 2 / 3 + randf(-0.4, 0.4)

        local p = q
        local yy = y
        for i = random(10, 40), 1, -1 do

            local m = (3 - j) / 2
            local color = mix({ 0.3, 0.6, 0.1 }, { 0.1, 0.3, 0.1 }, m)
            color = mix(color, { 0.1, 0.1, 0.1 }, 0.5)
            b:color(unpack(color))

            local xx = x + math.sin(p) * XX
            local x2 = x + math.sin(p + DP) * XX
            local a = math.atan2(x2 - xx, -DY)

            local t = Turtle(xx, yy, a)
            local s = math.min(3, i)
            local poly = {}
            table.append(poly, t:transform_point(-s, s * 0.5))
            table.append(poly, t:transform_point(0, -s * 0.5))
            table.append(poly, t:transform_point(s,  s * 0.5))
            table.append(poly, t:transform_point(0,  2))
            b:polygon(poly)
            p  = p + DP
            yy = yy - DY
        end
    end
end
local function generate_plants(layer, b)
    local i = 0
    while i < #layer.data do
        i = i + 1
        local x, y = layer:get_cr(i)
        if  layer:get(x-1, y+1) == TILE_TYPE_ROCK
        and layer:get(x+0, y+1) == TILE_TYPE_ROCK
        and layer:get(x+1, y+1) == TILE_TYPE_ROCK
        and layer:get(x-1, y+0) == TILE_TYPE_EMPTY
        and layer:get(x+0, y+0) == TILE_TYPE_EMPTY
        and layer:get(x+1, y+0) == TILE_TYPE_EMPTY
        and layer:get(x-1, y-1) == TILE_TYPE_EMPTY
        and layer:get(x+0, y-1) == TILE_TYPE_EMPTY
        and layer:get(x+1, y-1) == TILE_TYPE_EMPTY
        and randf(0, 20) < 1
        then
            plant(b, x * 8 + 4, y * 8 + 8)
            i = i + 1
        end
    end
end



local function clip_polygon(poly, mid, normal)
    local new_poly = {}
    local a = poly[#poly]
    for _, b in ipairs(poly) do
        local da = dot(sub(a, mid), normal)
        local db = dot(sub(b, mid), normal)
        local inside_a = da >= 0
        local inside_b = db >= 0
        if inside_a and inside_b then
            -- Both vertices are inside: keep next vertex.
            table.insert(new_poly, b)
        elseif inside_a and not inside_b then
            -- Edge exits the half-plane: compute intersection.
            local t = da / (da - db)
            local intersect = add(a, scale(sub(b, a), t))
            table.insert(new_poly, intersect)
        elseif not inside_a and inside_b then
            -- Edge enters the half-plane: compute intersection then keep next.
            local t = da / (da - db)
            local intersect = add(a, scale(sub(b, a), t))
            table.insert(new_poly, intersect)
            table.insert(new_poly, b)
        end
        a = b
    end
    return new_poly
end



local function voronoi(layer, x, y)

    local pad = 8
    local poly = {
        { x * 8 - pad,     y * 8 - pad },
        { x * 8 + 8 + pad, y * 8 - pad },
        { x * 8 + 8 + pad, y * 8 + 8 + pad },
        { x * 8 - pad,     y * 8 + 8 + pad },
    }

    local function point(x, y)
        local f = 9.321
        return {
            x * 8 + mix(-1, 9, noise(x * f, y * f, 1.234)),
            y * 8 + mix(-1, 9, noise(x * f, y * f, 4.567)),
        }
    end

    local c = point(x, y)
    local distance = layer.distances[x + y * layer.w + 1]


    for oy = -1, 1 do
        for ox = -1, 1 do
            if ox ~= 0 or oy ~= 0 then

                -- keep outer wall more regular
                if layer:get(x + ox, y + oy) ~= 1 then
                    local p = {
                        x * 8 + 4 + 4.5 * ox,
                        y * 8 + 4 + 4.5 * oy,
                    }
                    local n = {
                        -ox + randf(-0.2, 0.2),
                        -oy + randf(-0.2, 0.2),
                    }
                    poly = clip_polygon(poly, p, n)

                else
                    local qx = x + ox * 0.5
                    local qy = y + oy * 0.5
                    local q = noise(qx * 11.345, qy * 11.345)
                    local ratio = 0.5 + mix(-1, 1, q) * 0.4
                    if ox > 0 or (ox == 0 and oy > 0) then ratio = 1 - ratio end
                    local gap = 0.6
                    if distance > randf(0, 15) then
                        gap = gap * 2
                    end
                    local p  = point(x + ox, y + oy)
                    local pc = sub(c, p)
                    local n  = normalize(pc)
                    local m  = add(p, scale(n, length(pc) * ratio + gap))
                    poly = clip_polygon(poly, m, n)
                end
            end
        end
    end

    local data = {}
    for _, p in ipairs(poly) do
        table.append(data, p[1], p[2])
    end
    return data
end




local function generate_rocks(layer, b)

    -- background
    local color1 = { 0.1, 0.08, 0.05 }
    local color2 = { 0.03, 0.03, 0.03 }

    local function vertex(c, r)
        local q1 = layer:get(c-1, r-1) ~= TILE_TYPE_EMPTY
        local q2 = layer:get(c,   r-1) ~= TILE_TYPE_EMPTY
        local q3 = layer:get(c-1, r)   ~= TILE_TYPE_EMPTY
        local q4 = layer:get(c,   r)   ~= TILE_TYPE_EMPTY
        local q = bool[q1] + bool[q2] + bool[q3] + bool[q4]
        local x = c * 8
        local y = r * 8
        if q <= 2 then
            local pad = 0.25
            if q1 then
                x = x - pad
                y = y - pad
            end
            if q2 then
                x = x + pad
                y = y - pad
            end
            if q3 then
                x = x - pad
                y = y + pad
            end
            if q4 then
                x = x + pad
                y = y + pad
            end
            x = x + mix(-1.25, 1.25, noise(x*0.57, y*0.57, 0.0))
            y = y + mix(-1.25, 1.25, noise(x*0.57, y*0.57, 13.69))
        end

        return { x, y, 0, 0, unpack(q < 4 and color1 or color2) }
    end
    for i, t in ipairs(layer.data) do
        if t == TILE_TYPE_ROCK then
            local c, r = layer:get_cr(i)
            local v1 = vertex(c,   r)
            local v2 = vertex(c+1, r)
            local v3 = vertex(c+1, r+1)
            local v4 = vertex(c,   r+1)
            table.append(b.v, v1, v2, v3, v1, v3, v4)
        end
    end


    -- rocks
    for i, t in ipairs(layer.data) do
        if t == TILE_TYPE_ROCK then
            local d = layer.distances[i]
            local r = randf(0, d)
            local f = (r < 1 and 0.7
            or r < 3 and 0.4
            or r < 5 and 0.15
            or           0)

            if f > 0 then
                local r = randf(0, 10)
                local c = COLORS[r < 4 and 3 or 9]
                local g = 0.02
                local c = mix({ g, g, g }, c, f)
                b:color(unpack(c))
                local poly = voronoi(layer, layer:get_cr(i))
                if #poly >= 6 then b:polygon(poly) end
            end
        end
    end
end




local color1 = {0.6, 0.6, 0.47}
local color1 = mix({0, 0, 0}, color1, 0.6)
local color2 = mix({0, 0, 0}, {0.6, 0.4, 0.41}, 0.5)
local color2 = mix({0.2, 0.2, 0.2}, color2, 0.6)
local color3 = mix({0, 0, 0}, {0.5, 0.45, 0.4}, 0.2)

local function stone(b, box, dist)

    local color1 = color1
    local color2 = color2
    local color3 = color3

    if random(3) == 1 then
        local m = randf(0, 0.3)
        color1 = mix(color1, {0.2, 0.1, 0.1}, m)
        color2 = mix(color2, {0.2, 0.1, 0.1}, m)
        color3 = mix(color3, {0.2, 0.1, 0.1}, m)

    end

    local m = math.min(dist * 0.08, 0.5)
    local color1 = mix(color1, {0, 0.0, 0}, m)
    local color2 = mix(color2, {0, 0, 0}, m)
    local color3 = mix(color3, {0, 0, 0}, m)


    local x1 = box.x
    local y1 = box.y
    local x2 = box:right()
    local y2 = box:bottom()


    local inner = {
        x1 + randf(1,3), y1 + randf(1,3),
        x2 - randf(1,3), y1 + randf(1,3),
        x2 - randf(1,3), y2 - randf(1,3),
        x1 + randf(1,3), y2 - randf(1,3),
    }


    b:color(unpack(color1))
    b:polygon({
        x1, y1,
        x2, y1,
        inner[3], inner[4],
        inner[7], inner[8],
        x1, y2,
    })


    b:color(unpack(color3))
    b:polygon({
        x2, y1,
        x2, y2,
        x1, y2,
        inner[7], inner[8],
        inner[3], inner[4],
    })

    b:color(unpack(color2))
    b:polygon(inner)


    if random(3) == 1 then
        b:color(unpack(color1))
        b.a = 0.5
        b:polygon({
            x1, y1,
            randf(x1+2, x2-2), y1,
            x1, randf(y1+2, y2-2),
        })
    end

    if random(3) == 1 then
        b:color(unpack(color3))
        b.a = 0.5
        b:polygon({
            x2, randf(y1+2, y2-2),
            x2, y2,
            randf(x1+2, x2-2), y2,
        })
    end

end

local STONE_SIZES = {
    {3, 1}, {4, 2}, {2, 4}, {3, 3},
    {3, 2}, {2, 3}, {2, 2}, {3, 1}, {1, 3}, {2, 1}, {1, 2}, {1, 0}, {0, 0},
}
local STONE_SIZES2 = {
    {4, 2}, {3, 4}, {2, 4}, {4, 2},
    {3, 2}, {2, 3}, {2, 1}, {1, 2},
}

local function allocate_stone(r, c, layer, done)
    shuffle(STONE_SIZES)
    local sizes = random(3) == 1 and STONE_SIZES2 or STONE_SIZES
    local r2, c2
    for j = 1, #sizes do
        local size = sizes[j]
        c2 = math.min(layer.w - 1, c + size[1])
        r2 = math.min(layer.h - 1, r + size[2])

        local fits = true
        for x = c, math.min(layer.w - 1, c + size[1]) do
            for y = r, math.min(layer.h - 1, r + size[2]) do
                local i = y * layer.w + x + 1
                if layer.data[i] ~= TILE_TYPE_STONE or done[i] then
                    fits = false
                    break
                end
            end
            if not fits then break end
        end
        if fits then
            return r, r2, c, c2
        end
    end
    return r, r, c, c
end

local function generate_stones(layer, b)

    local done = {}
    for r = 0, layer.h - 1 do
        for c = 0, layer.w - 1 do
            if r % 2 == 0 then c = layer.w - c - 1 end
            local i = r * layer.w + c + 1
            if layer.data[i] == TILE_TYPE_STONE and not done[i] then

                local r1, r2, c1, c2 = allocate_stone(r, c, layer, done)

                local min_dist = 9e9
                for x = c1, c2 do
                    for y = r1, r2 do
                        local i = y * layer.w + x + 1
                        done[i] = true
                        min_dist = math.min(min_dist, layer.distances[i])
                    end
                end

                local x = c1 * TILE_SIZE
                local w = (c2 - c1 + 1) * TILE_SIZE
                local y = r1 * TILE_SIZE
                local h = (r2 - r1 + 1) * TILE_SIZE

                stone(b, Box(x, y, w, h), min_dist)

            end
        end
    end
end


function Map:generate_meshes()
    love.math.setRandomSeed(1337)

    calc_layer_distances(self.main)
    calc_layer_distances(self.background)

    -- background
    local b = MeshBuilder()

    generate_rocks(self.background, b)
    generate_stones(self.background, b)

    -- fade colors
    for _, v in ipairs(b.v) do
        local c = { v[5], v[6], v[7] }
        local m = (v[5] + v[6] + v[7]) / 3
        c = mix(c, {m * 0.8, m * 0.85, m}, 0.3)

        v[5], v[6], v[7] = unpack(mix(c, {0, 0, 0}, 0.4))
    end


    generate_plants(self.main, b)
    self.background.mesh = b:build()

    -- main
    local b = MeshBuilder()
    generate_rocks(self.main, b)
    generate_stones(self.main, b)
    self.main.mesh = b:build()

end
