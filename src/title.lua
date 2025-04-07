
Turtle = Object:new()
function Turtle:init(x, y)
    self.data = {}
    return self:add_vertex(x, y)
end
function Turtle:add_vertex(x, y)
    self.x = x
    self.y = y
    table.append(self.data, self.x, self.y)
    return self
end
function Turtle:mv(x, y)
    return self:add_vertex(self.x + x, self.y + y)
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
        self:add_vertex(
            cx + math.sin(a * 0.5 * math.pi) * r,
            cy - math.cos(a * 0.5 * math.pi) * r)
        a1 = a1 + da
    end
    if a1 ~= a2 then
        self:add_vertex(
            cx + math.sin(a2 * 0.5 * math.pi) * r,
            cy - math.cos(a2 * 0.5 * math.pi) * r)
    end
    return self
end



local title_shader = G.newShader([[
extern float time;
vec4 effect(vec4 c, Image t, vec2 uv, vec2 p) {
    vec3 c0 = vec3(0.75, 0.9, 1.0);
    vec3 c1 = vec3(0.51, 0.73, 0.81);
    vec3 c2 = vec3(0.05, 0.25, 0.5);
    vec3 c3 = vec3(0.05, 0.08, 0.1);
    vec3 o = mix(c1, c2, smoothstep(-30.0, 30.0, uv.y));
    o = mix(o, c3, smoothstep(30.0, 80.0, uv.y));
    o = mix(o, c0, smoothstep(-30.0, -80.0, uv.y));
    float sweep = (uv.x + uv.y * 0.55) - mod(time * 2.5, 1400.0) + 700.0;
    float shine = smoothstep(0.0, 1.0, 1.0 - abs(sweep * 0.015));
    o += vec3(shine);
    return vec4(o, 1.0);
}]])
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
                local l = 15
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

    local x = -70
    local y = -35
    local t = Turtle()
    -- A
    local q = 80/145
    t:init(x - 85, y + 60 + 40):mv(80, -145):mv(-12, 45):mv(-50*q, 50)
    local d = 30 * (1-q)
    local xx = t.x
    local yy = t.y
    for i = 4, 50-4, 4 do
        t:add_vertex(xx - i * mix(q, 1, i/90), yy + i)
    end

    poly(t.data)
    local q = 22.07
    t:init(x - 5, y - 45):down(105):left(12):up(20):left(q):up(10):right(q):up(30)
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



local tick = 0

Title = {}
function Title:init()
    tick = 0
end
function Title:update()
    tick = tick + 1
    title_shader:send("time", tick)

    for _, input in ipairs(Game.inputs) do
        if input.state.a or input.state.start then
            Game:change_state(World)
        end
    end
end


local function print_centered(text, x, y)
    local font = G.getFont()
    local width = font:getWidth(text)
    G.print(text, x - width/2, y)
end


function Title:draw()
    G.clear(0, 0, 0)

    G.push()
    G.translate(W/2, 75)
    G.scale(0.8)
    G.setColor(1, 1, 1)
    G.draw(title_shadow_mesh)
    G.setShader(title_shader)
    G.draw(title_mesh)
    G.setShader()
    G.pop()


    G.setColor(0.6, 0.6, 0.5)
    G.setFont(FONT_NORMAL)
    print_centered("KEYBOARD CONTROLS", W/2, H/2 + 27)
    print_centered(
[[move        LEFT/RIGHT
duck        DOWN
jump        X
shoot       C
fullscreen  F
]], W/2, H/2 + 40)

end
