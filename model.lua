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
    self.polys = {}
    for _, p in ipairs(data.polys) do
        if love.math.isConvex(p.data) then
            table.insert(self.polys, p)
        else
            -- split up non-convex polygons
            local tris = love.math.triangulate(p.data)
            for _, t in ipairs(tris) do
                table.insert(self.polys, {
                    bone = p.bone,
                    color = p.color,
                    shade = p.shade,
                    data = t,
                })
            end
        end
    end
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

function Model:draw(global_transform)
    for i, p in ipairs(self.polys) do
        G.push()
        local x, y, a = unpack(global_transform[p.bone.i])
        G.translate(x, y)
        G.rotate(a)
        local c = COLORS[p.color]
        local s = p.shade
        G.setColor(c[1] * s, c[2] * s, c[3] * s)
        G.polygon("fill", p.data)
        G.pop()
    end
end
