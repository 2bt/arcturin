local BACKGROUND_SHADER = G.newShader([[
float gradient_noise(in vec2 uv) {
    return fract(52.9829189 * fract(dot(uv, vec2(0.06711056, 0.00583715))));
}
vec4 effect(vec4 c, Image t, vec2 uv, vec2 p) {
    return c + gradient_noise(p) * (1.0 / 255.0) - (0.5 / 255.0);
}
]])
local BACKGROUND_MESH
do
    local c1 = { 0.18,  0.22, 0.35 }
    local c2 = { 0.1,   0.18, 0.18 }
    BACKGROUND_MESH = G.newMesh({
        { 0, 0, 0, 0, unpack(c1) },
        { W, 0, 0, 0, unpack(c1) },
        { W, H, 0, 0, unpack(c2) },
        { 0, H, 0, 0, unpack(c2) },
    })
end
local function draw_background()
    G.setColor(1, 1, 1)
    G.setShader(BACKGROUND_SHADER)
    G.draw(BACKGROUND_MESH)
    G.setShader()
end



-- helper functions for updating and drawing
local function update_all(t)
    for _, e in ipairs(t) do e:update() end
end
local function update_alive(t)
    -- update / delete actors
    local j = 1
    for i, e in ipairs(t) do
        if e.alive then e:update() end
        if e.alive then
            t[j] = e
            j = j + 1
        end
    end
    for i = j, #t do t[i] = nil end
end
local function draw_all(t)
    for _, e in ipairs(t) do e:draw() end
end
local function draw_alive_and_with_box(t)
    for _, e in ipairs(t) do
        -- if e.alive then e:draw() end
        if e.alive and e.box:overlaps(World.active_area) then e:draw() end
    end
end



World = {}
function World:init()
    self.solids        = {}
    self.active_solids = {}
    self.heroes        = {}
    self.hero_bullets  = {}
    self.enemies       = {}
    self.enemy_bullets = {}
    self.particles     = {}


    local ACTIVE_AREA_PADDING = TILE_SIZE
    self.active_area = Box(0, 0, W + ACTIVE_AREA_PADDING * 2, H + ACTIVE_AREA_PADDING * 2)

    -- XXX: loading the map will fill up actors and solids
    self.map = Map("assets/map.json")
    -- self.map = Map("assets/test-map.json")

    -- add heroes
    for _, input in ipairs(Game.inputs) do
        local index = #self.heroes + 1
        local hero  = Hero(input, index, self.map.hero_x - (index - 1) * 16, self.map.hero_y)
        self.heroes[index] = hero
    end

    -- init camera
    local hero_box
    local ox = 0
    for i, h in ipairs(self.heroes) do
        local hx = h.box:center_x()
        local hy = h.box:bottom() - 12
        if i == 1 then
            hero_box = Box(hx, hy, 0, 0)
        else
            hero_box:grow_to_fit(hx, hy)
        end
    end
    self.camera = Box(0, 0, W, H)
    self.camera:set_center(hero_box:center_x() + ox, hero_box:center_y())

end


function World:add_solid(solid)         table.insert(self.solids, solid)         end
function World:add_hero_bullet(bullet)  table.insert(self.hero_bullets, bullet)  end
function World:add_enemy(enemy)         table.insert(self.enemies, enemy)        end
function World:add_enemy_bullet(bullet) table.insert(self.enemy_bullets, bullet) end
function World:add_particle(particle)   table.insert(self.particles, particle)   end


function World:get_nearest_hero(x, y)
    local hero = nil
    local dist = math.huge
    for _, h in ipairs(self.heroes) do
        if h:is_targetable() then
            local hx, hy = h.box:get_center()
            local d = distance(x, y, hx, hy)
            if d < dist then
                hero = h
                dist = d
            end
        end
    end
    return hero, dist
end


-- movement
function World:move(box, axis, amount)
    local overlap_func, overlap_func2
    if axis == "x" then
        overlap_func = Box.overlap_x
        overlap_func2 = Box.overlap_y
        box.x = box.x + amount
    else
        overlap_func = Box.overlap_y
        overlap_func2 = Box.overlap_x
        box.y = box.y + amount
    end

    local overlap, solid = self.map:collision(box, overlap_func, amount)

    local overlap_area = 0
    for _, s in ipairs(self.active_solids) do
        local o = overlap_func(box, s.box)
        if o ~= 0 then
            if math.abs(o) > math.abs(overlap) then
                overlap = o
                solid   = s
            elseif math.abs(o) >= math.abs(overlap) then
                local oa = math.abs(o * overlap_func2(box, s.box))
                if oa > overlap_area then
                    overlap = o
                    solid   = s
                end
            end
        end
    end

    if axis == "x" then
        box.x = box.x + overlap
    else
        box.y = box.y + overlap
    end
    return solid

end
function World:move_x(box, amount) return self:move(box, "x", amount) end
function World:move_y(box, amount) return self:move(box, "y", amount) end


function World:update_camera()
    local ox, oy = self.camera:get_center()

    local hero_box
    for i, h in ipairs(self.heroes) do
        if not h:is_gameover() then
            local hx = h.box:center_x()
            local hy = h.box:bottom() - 12
            if hy > oy then
                hy = oy + (hy - oy) * 0.9
            end
            if not hero_box then
                hero_box = Box(hx, hy, 0, 0)
            else
                hero_box:grow_to_fit(hx, hy)
            end
        end
    end
    if not hero_box then return end
    local hx, hy = hero_box:get_center()
    hx = clamp(hx, W/2 + TILE_SIZE/2, self.map.w * TILE_SIZE - W/2 - TILE_SIZE/2)
    hy = clamp(hy, H/2 + TILE_SIZE/2, self.map.h * TILE_SIZE - H/2 - TILE_SIZE/2)

    local min_border_x = math.min(hero_box.x - self.camera.x, self.camera:right() - hero_box:right())
    local min_border_y = math.min(hero_box.y - self.camera.y, self.camera:bottom() - hero_box:bottom())

    local px = (min_border_x - 50) / 10
    local py = (min_border_y - 50) / 10
    local mx = 0.2 * 0.7^px
    local my = 0.2 * 0.7^py

    hx = mix(ox, hx, mx)
    hy = mix(oy, hy, my)
    local dx = hx - ox
    local dy = hy - oy
    local l = length(dx, dy)
    local MAX_L = 7
    if l > MAX_L then
        dx = dx / l * MAX_L
        dy = dy / l * MAX_L
    end
    self.camera:set_center(ox + dx, oy + dy)

    -- for activating enemies
    self.active_area:set_center(self.camera:get_center())
end



local TimeTracker = Object:new()
function TimeTracker:init()
    self.checkpoint_map     = {}
    self.checkpoints        = {}
    self.current_checkpoint = nil
end
function TimeTracker:checkpoint(name)
    local t = love.timer.getTime()
    self:stop(t)
    local c = self.checkpoint_map[name]
    if not c then
        c = {
            name = name,
        }
        table.insert(self.checkpoints, c)
        self.checkpoint_map[name] = c
    end
    c.t1 = t
    self.current_checkpoint = c
end
function TimeTracker:stop(t)
    if self.current_checkpoint then
        local c = self.current_checkpoint
        self.current_checkpoint = nil
        c.t2 = t or love.timer.getTime()
        c.time = c.t2 - c.t1
    end
end
function TimeTracker:draw()
    for i, c in ipairs(self.checkpoints) do
        G.setColor(1, 1, 1, 0.5)
        G.print(string.format("%-20s %3d", c.name, c.time * 10000), 4, 30 + (i-1) * 6)
        G.rectangle("fill", 80, 31 + (i - 1) * 6, c.time * 1000, 4)
    end
end
local TT = TimeTracker()




function World:update()

    TT:checkpoint("update solids")
    update_alive(self.solids)


    -- get all active solids for speedier collision
    local active_solids_area = Box(0, 0, W + TILE_SIZE * 5, H + TILE_SIZE * 5)
    active_solids_area:set_center(self.camera:get_center())
    self.active_solids = {}
    for _, s in ipairs(self.solids) do
        if s.box:overlaps(active_solids_area) then
            table.append(self.active_solids, s)
        end
    end

    TT:checkpoint("update heroes")
    update_all(self.heroes)

    TT:checkpoint("update camera")
    self:update_camera()

    TT:checkpoint("update enemies")
    update_alive(self.enemies)

    TT:checkpoint("update hero bullets")
    update_alive(self.hero_bullets)

    TT:checkpoint("update enemy bullets")
    update_alive(self.enemy_bullets)

    TT:checkpoint("update particles")
    update_alive(self.particles)

    TT:checkpoint("update map")
    self.map:update()
    TT:stop()


    local gameover = true
    for _, h in ipairs(self.heroes) do
        if not h:is_gameover() then
            gameover = false
            break
        end
    end
    if gameover then
        Game:change_state(Title)
    end
end

function World:draw()
    G.push()

    TT:checkpoint("draw map bg")
    draw_background()

    G.translate(-self.camera.x, -self.camera.y)

    self.map:draw("background")

    TT:checkpoint("draw solids")
    draw_alive_and_with_box(self.solids)
    TT:checkpoint("draw heroes")
    draw_all(self.heroes)
    TT:checkpoint("draw enemies")
    draw_alive_and_with_box(self.enemies)
    TT:checkpoint("draw hero bullets")
    draw_alive_and_with_box(self.hero_bullets)
    TT:checkpoint("draw enemy bullets")
    draw_alive_and_with_box(self.enemy_bullets)

    TT:checkpoint("draw map main")
    self.map:draw("main")

    TT:checkpoint("draw particles")
    draw_all(self.particles)

    G.pop()



    TT:checkpoint("draw hud")

    -- HUD
    G.setFont(FONT_NORMAL)
    G.setColor(0.8, 0.8, 0.8, 0.8)
    G.print(string.format("%3d ENEMIES LEFT", #self.enemies), W - 52, 3.5)

    for i, h in ipairs(self.heroes) do
        local y = 4 + (i-1) * 6

        G.setColor(0.8, 0.8, 0.8, 0.8)
        G.print(string.format("%02d", h.lives), 4, y - 1.2)

        for j = 1, MAX_HP do
            local x = 13 + (j - 1) * 4

            G.setColor(0.5, 0.5, 0.5, 0.5)
            G.rectangle("fill", x, y, 3.5, 3.5)
            if j <= h.hp then
                G.setColor(0.5, 0.8, 0.3, 0.5)
                G.rectangle("fill", x, y, 3.5, 3.5)
            end
        end
    end


    TT:stop()
    -- TT:draw()
end
