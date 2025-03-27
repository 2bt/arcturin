
local ANIM_FIRE = 1
local ANIM_IDLE = 2

-- local STATE_WALK  = 1
-- local STATE_WAIT  = 2
-- local STATE_JUMP  = 3

local MODEL_HEAD = Model("assets/models/dragon-head.model")
local MODEL_BODY = Model("assets/models/dragon-body.model")

DragonEnemy = Enemy:new()
function DragonEnemy:init(x, y)
    self.box       = Box.make_above(x, y, 80, 80)
    self.hp        = 60
    self.head_anim = AnimationManager(MODEL_HEAD)
    self.body_anim = AnimationManager(MODEL_BODY)


    self.segments = {}
    for i = 0, 5 do
        table.append(self.segments, {
            box = Box.make_centered(x, y - i * 10 - 5, 12, 12),
        })
    end

    self.head = {
        box = Box.make_centered(x, y - 6 * 10 - 5, 16, 14),
    }
    table.append(self.segments, self.head)


end
function DragonEnemy:sub_update()


    self.head_anim:update()
    self.body_anim:update()
end

function DragonEnemy:hero_collision(hero)
    for _, s in ipairs(self.segments) do
        if s.box:overlaps(hero.box) then
            return s.box:intersection(hero.box):get_center()
        end
    end
    return nil, nil
end
function DragonEnemy:bullet_collision(bullet)

    for i = 7, 1, -1 do
        local s = self.segments[i]
        if s.box:overlaps(bullet.box) then
            if s == self.head then
                self:take_hit(bullet.power)
            end
            local b = s.box:intersection(bullet.box)
            return b:intersect_center_ray(-bullet.vx, -bullet.vy)
        end
    end
    return nil, nil
end


function DragonEnemy:sub_draw()

    for i, s in ipairs(self.segments) do

        G.push()
        G.translate(s.box:get_center())
        G.scale(-self.dir, 1)

        if s == self.head then
            G.scale(0.054)
            self.head_anim:draw()
        else
            G.scale(0.064)
            self.body_anim:draw()
        end
        G.pop()
    end


    -- for i, s in ipairs(self.segments) do
    --     G.setColor(1, 0, 0, 0.2)
    --     G.rectangle("fill", s.box.x, s.box.y, s.box.w, s.box.h)
    -- end

end
