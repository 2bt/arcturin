GRAVITY   = 0.2
TILE_SIZE = 8



World = {}
function World:init()
    self.actors = {}
    self.solids = {}
    self.hero   = nil
    self.camera = Box(0, 0, W, H)

    -- loading the map will fill up actors and solids
    self.map = Map("assets/map.json")
end

function World:add_solid(solid)
    table.insert(self.solids, solid)
end

function World:add_actor(actor)
    table.insert(self.actors, actor)
end

function World:add_hero(input)
    self.hero = Hero(input, self.map.hero_x, self.map.hero_y)
    self:add_actor(self.hero)

    self.camera:set_center(self.hero.box:get_center())
end

local dummy_solid = Solid:new()

function World:move_x(actor, amount)
    actor.box.x = actor.box.x + amount

    local solid   = nil
    local overlap = self.map:collision(actor.box, "x")
    if overlap ~= 0 then
        solid = dummy_solid
    end

    local overlap_area = 0
    for _, s in ipairs(self.solids) do
        local o = actor.box:overlap_x(s.box)
        if o ~= 0 then
            if math.abs(o) > math.abs(overlap) then
                overlap = o
                solid   = s
            elseif math.abs(o) >= math.abs(overlap) then
                local oa = math.abs(o * actor.box:overlap_y(s.box))
                if oa > overlap_area then
                    overlap = o
                    solid   = s
                end
            end
        end
    end

    actor.box.x = actor.box.x + overlap
    return solid
end

function World:move_y(actor, amount)
    actor.box.y = actor.box.y + amount

    local solid   = nil
    local overlap = self.map:collision(actor.box, "y")
    if overlap ~= 0 then
        solid = dummy_solid
    end

    local overlap_area = 0
    for _, s in ipairs(self.solids) do
        local o = actor.box:overlap_y(s.box)
        if o ~= 0 then
            if math.abs(o) > math.abs(overlap) then
                overlap = o
                solid   = s
            elseif math.abs(o) >= math.abs(overlap) then
                local oa = math.abs(o * actor.box:overlap_x(s.box))
                if oa > overlap_area then
                    overlap = o
                    solid   = s
                end
            end
        end
    end

    actor.box.y = actor.box.y + overlap
    return solid
end


function World:update()

    -- update / delete actors
    local j = 1
    for i, e in ipairs(self.actors) do
        e:update()
        if e.alive then
            self.actors[j] = e
            j = j + 1
        end
    end
    for i = j, #self.actors do
        self.actors[i] = nil
    end


    -- update / delete solids
    local j = 1
    for i, e in ipairs(self.solids) do
        e:update()
        if e.alive then
            self.solids[j] = e
            j = j + 1
        end
    end
    for i = j, #self.solids do
        self.solids[i] = nil
    end


    -- update camera
    local cx, cy = self.camera:get_center()
    local x, y = self.hero.box:get_center()
    local pad_x = W / 8
    local pad_y = H / 8
    cx = clamp(cx, x - pad_x, x + pad_x)
    cy = clamp(cy, y - pad_y, y + pad_y)
    self.camera:set_center(cx, cy)

end
function World:draw()
    G.translate(-self.camera.x, -self.camera.y)

    self.map:draw()

    for _, s in ipairs(self.solids) do
        if s.alive then
            s:draw()
        end
    end

    for _, a in ipairs(self.actors) do
        if a.alive then
            a:draw()
        end
    end


end
