Bone = Object:new()
function Bone:init(i, keyframes)
    self.i         = i
    self.keyframes = keyframes
    self.kids      = {}
end
function Bone:add_kid(k)
    table.insert(self.kids, k)
    k.parent = self
end


Model = Object:new()
function Model:init(file_name)
    local str = io.open(file_name):read("*a")
    local data = loadstring("return " .. str)()
    self.anims = data.anims
    self.polys = data.polys
    self.bones = {}
    for i, d in ipairs(data.bones) do
        table.insert(self.bones, Bone(i, d.keyframes))
    end
    for i, d in ipairs(data.bones) do
        local b = self.bones[i]
        if d.parent then
            self.bones[d.parent]:add_kid(b)
        else
            self.root = b
        end
    end
    for _, p in ipairs(self.polys) do
        p.bone = self.bones[p.bone]
    end
    return true
end


function Model:get_local_transform(frame)
    local lt = {}
    for i, b in ipairs(self.bones) do
        local k1, k2
        for i, k in ipairs(b.keyframes) do
            if k[1] < frame then
                k1 = k
            end
            if k[1] >= frame then
                k2 = k
                break
            end
        end
        if k1 and k2 then
            local f1, x1, y1, a1 = unpack(k1)
            local f2, x2, y2, a2 = unpack(k2)
            local l = (frame - f1) / (f2 - f1)
            lt[i] = {
                mix(x1, x2, l),
                mix(y1, y2, l),
                mix(a1, a2, l),
            }
        else
            local _, x, y, a = unpack(k1 or k2)
            lt[i] = { x, y, a }
        end
    end
    return lt
end

function Model:get_global_transform(local_transform)
    local gt = {}
    local function f(b, p)
        local x, y, a = unpack(local_transform[b.i])
        local gx, gy, ga = unpack(p)
        local si = math.sin(ga)
        local co = math.cos(ga)
        local t = {
            gx + x * co - y * si,
            gy + y * co + x * si,
            ga + a,
        }
        gt[b.i] = t
        for _, k in ipairs(b.kids) do f(k, t) end
    end
    f(self.root, { 0, 0, 0 })
    return gt
end

-- drawing
local function draw_concav_poly(p)
    if #p < 6 then return end
    local status, err = pcall(function()
        local tris = love.math.triangulate(p)
        for _, t in ipairs(tris) do G.polygon("fill", t) end
    end)
    if not status then
        print(err)
    end
end

local COLORS = {
    { 0, 0, 0 },
    { 1, 1, 1 },
    { 0.41, 0.22, 0.17 },
    { 0.44, 0.64, 0.7 },
    { 0.44, 0.24, 0.53 },
    { 0.35, 0.55, 0.26 },
    { 0.21, 0.16, 0.47 },
    { 0.72, 0.78, 0.44 },
    { 0.44, 0.31, 0.15 },
    { 0.26, 0.22, 0 },
    { 0.6, 0.4, 0.35 },
    { 0.27, 0.27, 0.27 },
    { 0.42, 0.42, 0.42 },
    { 0.6, 0.82, 0.52 },
    { 0.42, 0.37, 0.71 },
    { 0.58, 0.58, 0.58 },
}
function Model:draw(global_transform)
    for i, p in ipairs(self.polys) do
        G.push()
        local x, y, a = unpack(global_transform[p.bone.i])
        G.translate(x, y)
        G.rotate(a)
        local c = COLORS[p.color]
        local s = p.shade
        G.setColor(c[1] * s, c[2] * s, c[3] * s)
        -- G.polygon("fill", p.data)
        draw_concav_poly(p.data)
        G.pop()
    end
end
