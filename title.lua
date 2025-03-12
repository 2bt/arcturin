
Turtle = Object:new()
function Turtle:init(x, y)
    self.x = x
    self.y = y
    self.data = { x, y }
    return self
end
function Turtle:add_vertex()
    table.append(self.data, self.x, self.y)
end
function Turtle:mv(x, y)
    self.x = self.x + x
    self.y = self.y + y
    self:add_vertex()
    return self
end
function Turtle:right(v) return self:mv( v,  0) end
function Turtle:left(v)  return self:mv(-v,  0) end
function Turtle:down(v)  return self:mv( 0,  v) end
function Turtle:up(v)    return self:mv( 0, -v) end
function Turtle:arc(a1, a2, r)
    local da = (a1 < a2 and 1 or -1) / 8
    local cx = self.x - math.sin(a1 * 0.5 * math.pi) * r
    local cy = self.y + math.cos(a1 * 0.5 * math.pi) * r
    for a = a1 + da, a2, da do
        self.x = cx + math.sin(a * 0.5 * math.pi) * r
        self.y = cy - math.cos(a * 0.5 * math.pi) * r
        self:add_vertex()
        a1 = a1 + da
    end
    if a1 ~= a2 then
        print(a1, a2)
        self.x = cx + math.sin(a2 * 0.5 * math.pi) * r
        self.y = cy - math.cos(a2 * 0.5 * math.pi) * r
        self:add_vertex()
    end
    return self
end


local time = 0
local title_shader = G.newShader([[
extern float time;
vec4 effect(vec4 c, Image t, vec2 uv, vec2 p) {

    float v = sin(time * 0.02 - uv.x / 200.0) * 0.5 + 0.5;

    vec3 c1 = vec3(0.5, 0.5, 0.6);
    vec3 c2 = vec3(0.2, 0.3, 0.5);
    vec3 c3 = vec3(0.1, 0.1, 0.3);

    vec3 o = mix(c1, c2, smoothstep(0.0, 10.0, uv.y));
    o = mix(o, mix(c1, c2, 0.5), v * 0.8);


    return vec4(o, 1.0);
}
]])
local title_mesh
local title_shadow_mesh
do
    local b1 = MeshBuilder()
    local b2 = MeshBuilder()

    local function poly(p)
        b1:polygon(p)

        -- shadow
        local x1 = p[#p-1]
        local y1 = p[#p]
        for i = 1, #p, 2 do
            local x2 = p[i]
            local y2 = p[i + 1]
            if x2 < x1 then
                local l = 20
                local c1 = { 0.2, 0.2, 0.25 }
                local c2 = { 0,   0,   0    }
                local v1 = { x1, y1,     0, 0, unpack(c1) }
                local v2 = { x1, y1 + l, 0, 0, unpack(c2) }
                local v3 = { x2, y2 + l, 0, 0, unpack(c2) }
                local v4 = { x2, y2,     0, 0, unpack(c1) }
                table.append(b2.v, v1, v2, v3, v1, v3, v4)
            end
            x1, y1 = x2, y2
        end
    end

    local x = -80
    local y = -30
    local t = Turtle()

    -- A
    t:init(x - 5, y - 50):mv(-10, 50):mv(-30, 70):mv(-23, 30)
    poly(t.data)
    local q = 17
    t:init(x - 5, y - 50):down(110):left(10):up(20):left(q):up(10):right(q):up(30)
    poly(t.data)

    -- R
    t:init(x, y):right(10):arc(0, 2, 20):up(10):arc(2, 0, 10):down(50):left(10)
    poly(t.data)
    t:init(x + 20, y + 60):up(10):arc(1, 0, 10):up(10):arc(0, 1, 20):down(10)
    poly(t.data)

    -- C
    t:init(x + 65, y + 60):left(10):arc(2, 3, 20):up(20):arc(3, 4, 20):right(10):down(10):left(10):arc(0, -1, 10):down(20):arc(3, 2, 10):right(10)
    poly(t.data)

    -- T
    t:init(x + 70, y):right(30):down(10):left(10):down(50):left(10):up(50):left(10)
    poly(t.data)

    -- U
    t:init(x + 105, y):right(10):down(45):arc(3, 1, 5):up(45):right(10):down(45):arc(1, 3, 15)
    poly(t.data)

    -- R
    t:init(x + 140, y):right(10):arc(0, 2, 20):up(10):arc(2, 0, 10):down(50):left(10)
    poly(t.data)
    t:init(x + 160, y + 60):up(10):arc(1, 0, 10):up(10):arc(0, 1, 20):down(10)
    poly(t.data)

    -- I
    t:init(x + 175, y):right(10):down(60):left(10)
    poly(t.data)

    -- N
    t:init(x + 190, y):right(10):mv(10, 30):up(30):right(10):down(60):left(10):mv(-10, -30):down(30):left(10)
    poly(t.data)


    for _, v in ipairs(b1.v) do
        v[3] = v[1]
        v[4] = v[2]
    end

    title_mesh = b1:build()
    title_shadow_mesh = b2:build()

end




Title = {}
function Title:update()
    time = time + 1
    title_shader:send("time", time)

    for _, input in ipairs(Game.inputs) do
        if input.state.a or input.state.start then
            Game:change_state("playing")
        end
    end
end



function Title:draw()
    G.clear(0, 0, 0)
    G.push()
    G.translate(W/2, 70)
    G.scale(0.8)

    G.setColor(1, 1, 1)
    G.draw(title_shadow_mesh)

    G.setShader(title_shader)
    -- G.setColor(0.2, 0.3, 0.5)
    G.draw(title_mesh)
    G.setShader()


    G.pop()

end
