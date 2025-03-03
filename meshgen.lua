local MeshMaker = Object:new()
function MeshMaker:init()
    self.v = {}
end
function MeshMaker:color(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b
    self.a = a or 1
end
function MeshMaker:polygon(data)
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
function MeshMaker:rectangle(x, y, w, h)
    self:polygon({
        x,   y,
        x+w, y,
        x+w, y+h,
        x,   y+h,
    })
end
function MeshMaker:make_mesh()
    return G.newMesh(self.v, "triangles", "static")
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
    local poly = {
        { x * 8 -  4, y * 8 -  4 },
        { x * 8 + 12, y * 8 -  4 },
        { x * 8 + 12, y * 8 + 12 },
        { x * 8 -  4, y * 8 + 12 },
    }

    local function point(x, y)
        if map:tile_at(x, y) ~= 1 then
            return { x * 8 + 4, y * 8 + 4 }
        end
        local f = 9.321
        return {
            x * 8 + mix(-3, 11, noise(x * f, y * f, 1.234)),
            y * 8 + mix(-3, 11, noise(x * f, y * f, 4.567)),
        }
    end


    local c = point(x, y)

    local gap = 0.6
    local d = dist[x + y * map.w + 1] or 0
    if d > randf(1, 10) then
        gap = 1.2
    end

    for oy = -1, 1 do
        for ox = -1, 1 do
            if ox ~= 0 or oy ~= 0 then

                -- outer wall
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
                    local p = point(x + ox, y + oy)
                    local pc = sub(c, p)
                    local n = normalize(pc)
                    local m = add(p, scale(n, length(pc) * 0.5 + gap))
                    poly = clip_polygon(poly, m, n)
                end
            end
        end
    end

    local data = {}
    for _, p in ipairs(poly) do
        table.insert(data, p[1])
        table.insert(data, p[2])
    end
    return data
end


function generate_map_mesh(map)
    love.math.setRandomSeed(1337)
    local mm = MeshMaker()


    -- mm:color(0.15, 0.12, 0.18)
    -- for y = 0, self.h - 1 do
    --     for x = 0, self.w - 1 do
    --         if self:tile_at(x, y) == 1 then
    --             mm:rectangle(x * 8, y * 8, 8, 8)
    --         end
    --     end
    -- end
    -- mm:color(0.2, 0.2, 0.3)

    -- local function noise_x(x, y)
    --     return x * 8 + mix(-3, 3, noise(x*1.03, y*1.03, 0.0))
    -- end
    -- local function noise_y(x, y)
    --     return y * 8 + mix(-3, 3, noise(x*1.03, y*1.03, 3.0))
    -- end
    -- for y = 0, self.h - 1 do
    --     for x = 0, self.w - 1 do
    --         if self:tile_at(x, y) == 1 then
    --             local c = 0
    --             for yy = y-1, y+1 do
    --                 for xx = x-1, x+1 do
    --                     c = c + (self:tile_at(xx, yy) == 1 and 1 or 0)
    --                 end
    --             end
    --             if c < 9 then
    --                 mm:color(0.1, 0.1, 0.09)
    --             else
    --                 mm:color(0.06, 0.06, 0.02)
    --             end
    --             mm:polygon({
    --                 noise_x(x,   y  ), noise_y(x,   y  ),
    --                 noise_x(x+1, y  ), noise_y(x+1, y  ),
    --                 noise_x(x+1, y+1), noise_y(x+1, y+1),
    --                 noise_x(x,   y+1), noise_y(x,   y+1),
    --             })
    --         end
    --     end
    -- end

    local dist = get_distances(map)

    mm:color(0.4, 0.3, 0.2)
    for y = 0, map.h - 1 do
        for x = 0, map.w - 1 do

            if map:tile_at(x, y) == 1 then

                local d = dist[x + y * map.w + 1]
                local f = 1

                if d^-2 < randf(0, 1) then
                    f = 0.5
                end
                if d^-1 < randf(0, 0.4) then
                    f = 0.1
                end

                local q = randf(0.2, 0.25)
                mm:color(q * f, q * 0.8 * f, 0.2 * f)

                local p = voronoi(map, dist, x, y)
                mm:polygon(p)
            end
        end
    end

    return mm:make_mesh()
end
