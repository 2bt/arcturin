Scene = Object:new()
function Scene:enter() end
function Scene:leave() end
function Scene:update() end
function Scene:draw() end


LevelLoader = Scene:new({
    levels = {
        -- "assets/test-map.json",
        "assets/level-1.json",
        "assets/level-2.json",
    },
})
function LevelLoader:init(heroes)
    self.level_number = 1
    self.state        = "blend"
    self.heroes       = heroes
end
function LevelLoader:leave()
    self.level_number = self.level_number + 1
    self.state        = "blend"
end
function LevelLoader:update()
    if self.state == "blend" then
        if Game.blend == 0 then
            self.state = "load"
        end
    elseif self.state == "load" then
        self.state = "ready"
        local map  = Map(self.levels[self.level_number])
        World:init(self.heroes, map)
    elseif self.state == "ready" then
        for _, input in ipairs(Title.player_inputs) do
            if input:is_just_pressed("a", "start") then
                Game:change_scene(World)
            end
        end
    end

end
function LevelLoader:draw()
    G.setColor(0.6, 0.6, 0.5)
    G.setFont(FONT_NORMAL)

    G.printf(string.format("Level %d", self.level_number), 0, H/2 - 10, W, "center")
    if self.state == "load" then
        G.printf(string.format("Loading...", self.state), 0, H/2 + 10, W, "center")
    elseif self.state == "ready" then
        G.printf(string.format("Ready", self.state), 0, H/2 + 10, W, "center")
    end
end




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



local TITLE_SHADER = G.newShader([[
uniform float time;
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
local TITLE_MESH
local TITLE_SHADOW_MESH
do
    local b1 = MeshBuilder()
    local b2 = MeshBuilder()

    -- shadow colors
    local c1 = { 0.1, 0.2, 0.25, 1 }
    local c2 = { 0, 0, 0, 0 }
    local len = 15


    local function poly(p)
        b1:polygon(p)

        -- shadow
        local x1 = p[#p-1]
        local y1 = p[#p]
        for i = 1, #p, 2 do
            local x2 = p[i]
            local y2 = p[i + 1]
            if x2 < x1 then
                local v1 = { x1, y1,       0, 0, unpack(c1) }
                local v2 = { x1, y1 + len, 0, 0, unpack(c2) }
                local v3 = { x2, y2 + len, 0, 0, unpack(c2) }
                local v4 = { x2, y2,       0, 0, unpack(c1) }
                table.append(b2.v, v1, v2, v3, v1, v3, v4)
            end
            x1, y1 = x2, y2
        end
    end

    local x = -75
    local y = -35
    local t = Turtle()
    -- A
    local q = 80/145
    t:init(x - 85, y + 60 + 40):mv(80, -145):mv(-12, 45)
    t:mv(-30*q, 30):right(20):down(10):left(20+10*q)
    local d = 30 * (1-q)
    local xx = t.x
    local yy = t.y
    for i = 4, 50-4, 4 do
        t:add_vertex(xx - i * mix(q, 1, i/90), yy + i)
    end
    poly(t.data)
    t:init(x - 5, y - 45):down(105):left(12):up(60)
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

    TITLE_MESH = b1:build()
    TITLE_SHADOW_MESH = b2:build()
end


local FLARE_SHADER = G.newShader([[
uniform float time;
vec4 effect(vec4 c, Image t, vec2 uv, vec2 p) {
    uv.x += sin(time * 0.0027) * 0.1;
    float o = 0.1 / (abs(uv.y) + 0.09 + uv.x * uv.x);
    o -= 0.1;
    //if (o <= 0.0) return vec4(1.0);
    return vec4(vec3(1.2, 1.1, 1.0) * o, 1.0);
}
]])
local FLARE_MESH
do
    local s = 50
    FLARE_MESH = G.newMesh({
        { -s, -s, -1, -1 },
        {  s, -s,  1, -1 },
        {  s,  s,  1,  1 },
        { -s,  s, -1,  1 },
    })
end


Title = Scene:new()
function Title:init()
    self.tick          = 0
    self.state         = "title"
    self.player_inputs = {}
end
Title:init()

function Title:start_game()

    -- init heroes
    local heroes = {}
    for i, input in ipairs(self.player_inputs) do
        heroes[i] = Hero(input, i)
    end

    LevelLoader:init(heroes)
    Game:change_scene(LevelLoader)
end
function Title:update()
    self.tick = self.tick + 1

    if self.state == "title" then
        for _, input in ipairs(Game.inputs) do
            if input:is_just_pressed("a", "start") then
                -- add input to player inputs
                self.player_inputs = { input, [input] = true }
                if #Game.inputs == 1 then
                    -- start game
                    self:start_game()
                else
                    -- enter lobby
                    self.state = "lobby"
                end
                break
            end
        end
    elseif self.state == "lobby" then

        -- check for disconnecting inputs
        local i = 1
        while i <= #self.player_inputs do
            local input = self.player_inputs[i]
            if not input.joy or input.joy:isConnected() then
                i = i + 1
            else
                table.remove(self.player_inputs, i)
                if #self.player_inputs == 0 then
                    self.state = "title"
                end
            end
        end

        for _, input in ipairs(Game.inputs) do

            if input:is_just_pressed("a", "start") then
                if self.player_inputs[input] then
                    -- start game
                    self:start_game()
                else
                    -- add player
                    table.insert(self.player_inputs, input)
                    self.player_inputs[input] = true
                end
            end

            if self.player_inputs[input] and input:is_just_pressed("b") then
                -- remove player
                for i, pi in ipairs(self.player_inputs) do
                    if pi == input then
                        table.remove(self.player_inputs, i)
                        self.player_inputs[input] = nil
                        if #self.player_inputs == 0 then
                            self.state = "title"
                        end
                        break
                    end
                end
            end

        end

    end
end

function Title:draw()
    TITLE_SHADER:send("time", self.tick)
    FLARE_SHADER:send("time", self.tick)

    -- title
    G.setColor(1, 1, 1)
    G.draw(TITLE_SHADOW_MESH, W/2, 60, 0, 0.6)
    G.setShader(TITLE_SHADER)
    G.draw(TITLE_MESH, W/2, 60, 0, 0.6)
    G.setShader()

    -- flare
    G.setBlendMode("add")
    G.setShader(FLARE_SHADER)
    G.draw(FLARE_MESH, 94.8, 43, 2.075)
    G.setShader()
    G.setBlendMode("alpha")

    -- text
    G.setColor(0.6, 0.6, 0.5)
    G.setFont(FONT_NORMAL)
    local LINE_HEIGHT = FONT_NORMAL:getHeight()
    local CHAR_WIDTH  = FONT_NORMAL:getWidth(" ")
    local y = H/2 + 20

    if self.state == "title" then


        G.printf("Keyboard Controls", 0, y, W, "center")
        y = y + LINE_HEIGHT * 2

        G.print([[Move        [LEFT]/[RIGHT]
Duck        [DOWN]
Jump        [X]
Shoot       [C]
Fullscreen  [F] ]], W/2 - 13 * CHAR_WIDTH, y)

        G.printf("[Keyboard:X]/[A] Start", FONT_SMALL, W/2-100, H-10, 200, "right")


    elseif self.state == "lobby" then
        -- G.line(W/2, H/2 + 20, W/2, H - 10)
        local x = W/2 - 52

        for i, input in ipairs(self.player_inputs) do
            local txt = string.format("Player %d (%s)", i, input.name)
            local pad = string.rep(".", 30 - #txt)
            G.print(string.format("%s %s Press %s to start", txt, pad, input.button_name_a),
                    W/2 - CHAR_WIDTH * 25, y)
            y = y + LINE_HEIGHT
        end

        if #self.player_inputs < #Game.inputs then
            G.print(string.rep("-", 50), W/2 - CHAR_WIDTH * 25, y)

            y = y + LINE_HEIGHT
            for _, input in ipairs(Game.inputs) do
                if not self.player_inputs[input] then

                    local txt = input.name
                    local pad = string.rep(".", 30 - #txt)
                    G.print(string.format("%s %s Press %s to join", txt, pad, input.button_name_a),
                            W/2 - CHAR_WIDTH * 25, y)
                    y = y + LINE_HEIGHT
                end
            end
        end

        G.printf("[Keyboard:C]/[B] Leave", FONT_SMALL, W/2-100, H-10, 200, "left")
        G.printf("[Keyboard:X]/[A] Join/Start", FONT_SMALL, W/2-100, H-10, 200, "right")

    end

end
