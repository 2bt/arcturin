local json = require("dkjson")

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
                    local x = o.x + o.width / 2
                    local y = o.y + o.height
                    if o.name == "hero" then
                        self.hero_x = x
                        self.hero_y = y
                    elseif o.name == "ufo" then
                        World:add_enemy(UfoEnemy(x, y))
                    end

                end
            end
        elseif layer.type == "tilelayer" then
            self.tile_data = layer.data
        end

    end

    local i = 1
    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            if self.tile_data[i] == 2 then
                self.tile_data[i] = 0
                World:add_solid(Crate(x * TILE_SIZE, y * TILE_SIZE))
            end
            i = i + 1
        end
    end

    self:gen_mesh()
end


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



local noise = love.math.noise
function Map:gen_mesh()



    local mm = MeshMaker()

    local function noise_x(x, y)
        return x * 8 + mix(-2, 2, noise(x*1.03, y*1.03, 0.0))
    end
    local function noise_y(x, y)
        return y * 8 + mix(-2, 2, noise(x*1.03, y*1.03, 3.0))
    end


    mm:color(0.15, 0.12, 0.18)
    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            if self:tile_at(x, y) == 1 then
                mm:rectangle(x * 8, y * 8, 8, 8)
            end
        end
    end


    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            if self:tile_at(x, y) == 1 then
                mm:color(0.2, 0.2, 0.3)
                mm:polygon({
                    noise_x(x,   y  ), noise_y(x,   y  ),
                    noise_x(x+1, y  ), noise_y(x+1, y  ),
                    noise_x(x+1, y+1), noise_y(x+1, y+1),
                    noise_x(x,   y+1), noise_y(x,   y+1),
                })
                if love.math.random(7) == 1 then
                    local q = randf(0.2, 0.35)
                    mm:color(q, q * 0.7, 0.2)
                    mm:rectangle(x * 8 + randf(0, 2),
                                 y * 8 + randf(0, 2),
                                 6, 6)
                end
            end
        end
    end

    self.mesh = mm:make_mesh()
end

function Map:tile_at(x, y)
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
function Map:draw()
    -- local cam = World.camera
    -- local x1 = math.floor(cam.x / TILE_SIZE)
    -- local x2 = math.floor(cam:right() / TILE_SIZE)
    -- local y1 = math.floor(cam.y / TILE_SIZE)
    -- local y2 = math.floor(cam:bottom() / TILE_SIZE)
    -- G.setColor(0.1, 0.1, 0.2)
    -- for x = x1, x2 do
    --     for y = y1, y2 do
    --         local t = self:tile_at(x, y)
    --         if t == 1 then
    --             G.rectangle("fill",
    --                 x * TILE_SIZE,
    --                 y * TILE_SIZE,
    --                 TILE_SIZE,
    --                 TILE_SIZE)
    --         end
    --     end
    -- end

    G.setColor(1, 1, 1)
    G.draw(self.mesh)
end
