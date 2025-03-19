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
local function get_distances(map)
    local rows = map.h
    local cols = map.w
    local INF = rows*rows + cols*cols

    local dist = {}
    for i = 1, rows do
        dist[i] = {}
        for j = 1, cols do
            if map:tile_at(j - 1, i - 1) == 0 then
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
    local output = {}  -- final result
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
            output[#output + 1] = (dx*dx + f[v[hullIndex]])^0.5
        end
    end
    return output
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

local noise = love.math.noise


local function voronoi(map, dist, x, y)
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
            x * 8 + mix(-3, 11, noise(x * f, y * f, 1.234)),
            y * 8 + mix(-3, 11, noise(x * f, y * f, 4.567)),
        }
    end

    local c = point(x, y)
    local distance = dist[x + y * map.w + 1] or 0

    for oy = -1, 1 do
        for ox = -1, 1 do
            if ox ~= 0 or oy ~= 0 then

                -- keep outer wall more regular
                if map:tile_at(x + ox, y + oy) ~= 1 then
                    local p = {
                        x * 8 + 4 + 4 * ox,
                        y * 8 + 4 + 4 * oy,
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
                    local ratio = mix(0.1, 0.9, q)

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


function plant(b, x, y)


    local DY = 1.7
    local DP = 0.27
    local XX = 6

    local q = randf(0, math.pi * 2)
    for j = 1, 3 do
        q = q + math.pi * 2 / 3 + randf(-0.4, 0.4)

        local p = q
        local yy = y
        for i = love.math.random(10, 40), 1, -1 do

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



function generate_map_meshes(map)
    love.math.setRandomSeed(1337)

    local meshes = {}

    -- plants
    local b = MeshBuilder()
    for y = 0, map.h - 1 do
        for x = 0, map.w - 1 do
            if  map:tile_at(x-1, y+1) == 1
            and map:tile_at(x-1, y)   == 0
            and map:tile_at(x-1, y-1) == 0
            and map:tile_at(x,   y+1) == 1
            and map:tile_at(x,   y)   == 0
            and map:tile_at(x,   y-1) == 0
            and map:tile_at(x+1, y+1) == 1
            and map:tile_at(x+1, y)   == 0
            and map:tile_at(x+1, y-1) == 0
            and randf(0, 20) < 1
            then
                map.tile_data[x + map.w * y + 2] = -1
                plant(b, x * 8 + 4, y * 8 + 8)
            end
        end
    end
    table.insert(meshes, b:build())



    -- background
    local b = MeshBuilder()
    b:color(0.03, 0.03, 0.03)
    local function add_point(p, c, r)
        local q1 = map:tile_at(c-1, r-1) == 1
        local q2 = map:tile_at(c,   r-1) == 1
        local q3 = map:tile_at(c-1, r)   == 1
        local q4 = map:tile_at(c,   r)   == 1
        local x = c * 8
        local y = r * 8
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
        p[#p+1] = x + mix(-1, 1, noise(x*0.57, y*0.57, 0.0))
        p[#p+1] = y + mix(-1, 1, noise(x*0.57, y*0.57, 13.69))
    end

    for r = 0, map.h - 1 do
        for c = 0, map.w - 1 do
            if map:tile_at(c, r) == 1 then
                local p = {}
                add_point(p, c,   r)
                add_point(p, c+1, r)
                add_point(p, c+1, r+1)
                add_point(p, c,   r+1)
                b:polygon(p)
            end
        end
    end


    -- stones
    local dist = get_distances(map)
    for y = 0, map.h - 1 do
        for x = 0, map.w - 1 do
            if map:tile_at(x, y) == 1 then
                local d = dist[x + y * map.w + 1]
                local r = randf(0.9, d)
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


                    local poly = voronoi(map, dist, x, y)
                    if #poly > 6 then b:polygon(poly) end
                end

            end
        end
    end
    table.insert(meshes, b:build())


    return meshes
end
