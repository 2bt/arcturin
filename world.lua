GRAVITY = 0.2
MAX_VY  = 3




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
    for i = j, #t do
        t[i] = nil
    end
end
local function draw_all(t)
    for _, e in ipairs(t) do e:draw() end
end
local function draw_alive_and_with_box(t)
    for _, e in ipairs(t) do
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

    -- loading the map will fill up actors and solids
    self.map = Map("assets/map.json")

    -- add heroes
    for _, input in ipairs(Game.inputs) do
        local index = #self.heroes + 1
        local hero  = Hero(input, index, self.map.hero_x - (index - 1) * 16, self.map.hero_y)
        self.heroes[index] = hero
    end

    -- init camera
    local hero_box
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
    self.camera:set_center(hero_box:get_center())

end


function World:add_solid(solid)         table.insert(self.solids, solid)         end
function World:add_hero_bullet(bullet)  table.insert(self.hero_bullets, bullet)  end
function World:add_enemy(enemy)         table.insert(self.enemies, enemy)        end
function World:add_enemy_bullet(bullet) table.insert(self.enemy_bullets, bullet) end
function World:add_particle(particle)   table.insert(self.particles, particle)   end


-- movement
local DUMMY_SOLID = Solid:new()
function World:move_x(box, amount)
    box.x = box.x + amount

    local solid   = nil
    local overlap = self.map:collision(box, "x")
    if overlap ~= 0 then
        solid = DUMMY_SOLID
    end

    local overlap_area = 0
    for _, s in ipairs(self.active_solids) do
        local o = box:overlap_x(s.box)
        if o ~= 0 then
            if math.abs(o) > math.abs(overlap) then
                overlap = o
                solid   = s
            elseif math.abs(o) >= math.abs(overlap) then
                local oa = math.abs(o * box:overlap_y(s.box))
                if oa > overlap_area then
                    overlap = o
                    solid   = s
                end
            end
        end
    end

    box.x = box.x + overlap
    return solid
end
function World:move_y(box, amount)
    box.y = box.y + amount

    local solid   = nil
    local overlap = self.map:collision(box, "y")
    if overlap ~= 0 then
        solid = DUMMY_SOLID
    end

    local overlap_area = 0
    for _, s in ipairs(self.active_solids) do
        local o = box:overlap_y(s.box)
        if o ~= 0 then
            if math.abs(o) > math.abs(overlap) then
                overlap = o
                solid   = s
            elseif math.abs(o) >= math.abs(overlap) then
                local oa = math.abs(o * box:overlap_x(s.box))
                if oa > overlap_area then
                    overlap = o
                    solid   = s
                end
            end
        end
    end

    box.y = box.y + overlap
    return solid
end

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


    local nx = hx
    local ny = hy
    local PAD_X = W / 10
    local PAD_Y = H / 10
    if hero_box.w <= PAD_X * 2 then
        nx = clamp(ox, hero_box:right() - PAD_X, hero_box.x + PAD_X)
    end
    if hero_box.h <= PAD_Y * 2 then
        ny = clamp(oy, hero_box:bottom() - PAD_Y, hero_box.y + PAD_Y)
    end

    -- stay inside of map
    nx = clamp(nx, W/2 + TILE_SIZE/2, self.map.w * TILE_SIZE - W/2 - TILE_SIZE/2)
    ny = clamp(ny, H/2 + TILE_SIZE/2, self.map.h * TILE_SIZE - H/2 - TILE_SIZE/2)
    hx = clamp(hx, W/2 + TILE_SIZE/2, self.map.w * TILE_SIZE - W/2 - TILE_SIZE/2)
    hy = clamp(hy, H/2 + TILE_SIZE/2, self.map.h * TILE_SIZE - H/2 - TILE_SIZE/2)

    -- fast scroll to new position
    nx = mix(ox, nx, 0.1)
    ny = mix(oy, ny, 0.1)

    -- slowly scroll to center of heroes
    nx = mix(nx, hx, 0.008)
    ny = mix(ny, hy, 0.01)

    self.camera:set_center(nx, ny)

    -- for activating enemies
    self.active_area:set_center(self.camera:get_center())
end


function World:update()

    update_alive(self.solids)

    -- get all active solids for speedier collision
    local active_solids_area = Box(0, 0, W + TILE_SIZE * 4, H + TILE_SIZE * 4)
    active_solids_area:set_center(self.camera:get_center())
    self.active_solids = {}
    for _, s in ipairs(self.solids) do
        if s.box:overlaps(active_solids_area) then
            table.append(self.active_solids, s)
        end
    end


    update_all(self.heroes)
    self:update_camera()

    update_alive(self.enemies)
    update_alive(self.hero_bullets)
    update_alive(self.enemy_bullets)
    update_alive(self.particles)


    local gameover = true
    for _, h in ipairs(self.heroes) do
        if not h:is_gameover() then
            gameover = false
            break
        end
    end
    if gameover then
        Game:change_state("title")
    end
end

function World:draw()
    G.push()

    draw_background()

    G.translate(-self.camera.x, -self.camera.y)

    self.map:draw(1)
    draw_alive_and_with_box(self.solids)
    draw_alive_and_with_box(self.hero_bullets)
    draw_alive_and_with_box(self.enemy_bullets)
    draw_all(self.heroes)
    draw_alive_and_with_box(self.enemies)
    self.map:draw(2)
    draw_all(self.particles)

    G.pop()

    -- HUD
    for i, h in ipairs(self.heroes) do
        local y = 4 + (i-1) * 6

        G.setColor(0.8, 0.8, 0.8, 0.8)
        G.setFont(FONT_NORMAL)
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


end
