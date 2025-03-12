GRAVITY   = 0.2
MAX_VY    = 3
TILE_SIZE = 8


local ACTIVE_AREA_PADDING = 8

World = {}
function World:init()
    self.solids        = {}
    self.heroes        = {}
    self.hero_bullets  = {}
    self.enemies       = {}
    self.enemy_bullets = {}
    self.particles     = {}

    self.camera = Box(0, 0, W, H)
    self.active_area = Box(0, 0, W + ACTIVE_AREA_PADDING * 2, H + ACTIVE_AREA_PADDING * 2)

    -- loading the map will fill up actors and solids
    self.map = Map("assets/map.json")
end


function World:add_hero(input)
    local index = #self.heroes + 1
    local hero  = Hero(input, index, self.map.hero_x - (index - 1) * 16, self.map.hero_y)
    self.heroes[index] = hero

    self.camera:set_center(hero.box:get_center())
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
    for _, s in ipairs(self.solids) do
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
    for _, s in ipairs(self.solids) do
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

local function update_all(t)
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
    for _, e in ipairs(t) do
        if e.alive and e.box:overlaps(World.active_area) then e:draw() end
    end
end

function World:update_camera()

    local pad_x = W / 8
    local pad_y = H / 8
    local cx, cy = self.camera:get_center()

    local hero = self.heroes[#self.heroes]
    local hx = hero.box:center_x()
    local hy = hero.box:bottom() - 12


    cx = clamp(cx, hx - pad_x, hx + pad_x)
    cy = clamp(cy, hy - pad_y, hy + pad_y)

    -- don't go outside of map
    cx = clamp(cx, W/2 + TILE_SIZE/2, self.map.w * TILE_SIZE - W/2 - TILE_SIZE/2)
    cy = clamp(cy, H/2 + TILE_SIZE/2, self.map.h * TILE_SIZE - H/2 - TILE_SIZE/2)


    self.camera:set_center(cx, cy)

    -- for activating enemies
    self.active_area.x = self.camera.x - ACTIVE_AREA_PADDING
    self.active_area.y = self.camera.y - ACTIVE_AREA_PADDING
end
function World:update()

    update_all(self.solids)
    for _, h in ipairs(self.heroes) do h:update() end
    self:update_camera()

    update_all(self.enemies)
    update_all(self.hero_bullets)
    update_all(self.enemy_bullets)
    update_all(self.particles)
end
function World:draw()
    G.push()

    -- background
    if not bg_mesh then
        local color1 = { 0.1,  0.18,  0.25 }
        local color2 = { 0.01, 0.08, 0.08 }
        bg_mesh = G.newMesh({
            { 0, 0, 0, 0, unpack(color1) },
            { W, 0, 0, 0, unpack(color1) },
            { W, H, 0, 0, unpack(color2) },
            { 0, H, 0, 0, unpack(color2) },
        })
        bg_shader = G.newShader([[
        float gradient_noise(in vec2 uv) {
            return fract(52.9829189 * fract(dot(uv, vec2(0.06711056, 0.00583715))));
        }
        vec4 effect(vec4 c, Image t, vec2 uv, vec2 p) {
            return c + gradient_noise(p) * (1.0 / 255.0) - (0.5 / 255.0);
        }
        ]])
    end
    G.setShader(bg_shader)
    G.setColor(1, 1, 1)
    G.draw(bg_mesh)
    G.setShader()

    G.translate(-self.camera.x, -self.camera.y)


    draw_all(self.solids)

    draw_all(self.hero_bullets)
    draw_all(self.enemy_bullets)

    draw_all(self.heroes)
    draw_all(self.enemies)

    self.map:draw()

    for _, e in ipairs(self.particles) do
        if e.alive then e:draw() end
    end

    G.pop()

    -- HUD
    for i, h in ipairs(self.heroes) do
        G.setColor(0.5, 0.5, 0.5, 0.5)
        G.rectangle("fill", 4, i * 8 - 4, 12 * 4, 4)
        G.setColor(0.5, 0.8, 0.3, 0.5)
        G.rectangle("fill", 4, i * 8 - 4, h.hp * 4, 4)
    end

end
