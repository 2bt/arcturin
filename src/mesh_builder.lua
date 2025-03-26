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