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
    local hero = self.heroes[#self.heroes]

    local cx, cy = self.camera:get_center()
    local x, y = hero.box:get_center()
    local pad_x = W / 8
    local pad_y = H / 8
    cx = clamp(cx, x - pad_x, x + pad_x)
    cy = clamp(cy, y - pad_y, y + pad_y)

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
