local G = love.graphics

World = Object:new()
function World:init()

    self.map = Map("assets/map.json")
    self.entities = {}

--  self.new_entities = {}
--  self.active_entities = {}
--  self.heroes = {}

    table.insert(self.entities, Crate(232, 210))
    table.insert(self.entities, Crate(240, 180))


    self.cam = Box(0, 0, W, H)

end
function World:add_hero(input)

    self.hero = Hero(input, self.map.hero_x, self.map.hero_y)

    self.cam:set_center(self.hero.box:get_center())

    table.insert(self.entities, self.hero)

end
function World:update()

    -- update / delete entities
    local j = 1
    for i, e in ipairs(self.entities) do
        e:update()
        if e.alive then
            self.entities[j] = e
            j = j + 1
        end
    end
    for i = j, #self.entities do
        self.entities[i] = nil
    end


    -- horizontal collision
    for i, e in ipairs(self.entities) do
        if e.alive then
            if e.next_x and e.next_x ~= e.box.x then
                e.box.x = e.next_x
                local dx = self.map:collision(e.box, "x")
                if dx ~= 0 then
                    e:on_collision("x", dx, nil)
                end
            end
        end
    end
    for i, e in ipairs(self.entities) do
        if e.alive then
            for j = i + 1, #self.entities do
                local f = self.entities[j]
                if f.alive then
                    local dx = collision(e.box, f.box, "x")
                    if dx ~= 0 then
                        e:on_collision("x", dx, f)
                        f:on_collision("x", -dx, e)
                    end
                end
            end
        end
    end


    -- vertical collision
    for i, e in ipairs(self.entities) do
        if e.alive then
            if e.next_y and e.next_y ~= e.box.y then
                e.box.y = e.next_y
                local dy = self.map:collision(e.box, "y")
                if dy ~= 0 then
                    e:on_collision("y", dy, nil)
                end
            end
        end
    end
    for i, e in ipairs(self.entities) do
        if e.alive then
            for j = i + 1, #self.entities do
                local f = self.entities[j]
                if f.alive then
                    local dy = collision(e.box, f.box, "y")
                    if dy ~= 0 then
                        e:on_collision("y", dy, f)
                        f:on_collision("y", -dy, e)
                    end
                end
            end
        end
    end

    -- append new entities

    -- update camera

    local cx, cy = self.cam:get_center()
    local x, y = self.hero.box:get_center()
    local pad_x = W / 8
    local pad_y = H / 8
    cx = clamp(cx, x - pad_x, x + pad_x)
    cy = clamp(cy, y - pad_y, y + pad_y)
    self.cam:set_center(cx, cy)

end
function World:draw()
    G.translate(-self.cam.x, -self.cam.y)


    self.map:draw(self.cam)

    for _, e in ipairs(self.entities) do
        if e.alive then
            e:draw(self.cam)
        end
    end
end
