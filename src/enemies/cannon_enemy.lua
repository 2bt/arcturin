local MODEL = Model("assets/models/cannon.model")

local ANIM_IDLE  = 1
local ANIM_SHOOT = 2

local STATE_IDLE   = 1
local STATE_TARGET = 2
local STATE_SHOOT  = 3


local function delta_angle(a1, a2)
    local pi = math.pi
    return (a2 - a1 + pi) % (2 * pi) - pi
end



CannonEnemy = Enemy:new()
function CannonEnemy:init(x, y, walls)

    y = y - 8
    if walls:get_tile_at_world_pos(x, y + 10) > 0 then
        self.box = Box.make_centered(x, y - 2, 16, 16)
        self.ang = 0
    elseif walls:get_tile_at_world_pos(x, y - 10) > 0 then
        self.box = Box.make_centered(x, y + 2, 16, 16)
        self.ang = math.pi
    elseif walls:get_tile_at_world_pos(x - 10, y) > 0 then
        self.box = Box.make_centered(x + 2, y, 16, 16)
        self.ang = math.pi * 0.5
    else
        self.box = Box.make_centered(x - 2, y, 16, 16)
        self.ang = math.pi * -0.5
    end

    self.hp           = 7
    self.anim_manager = AnimationManager(MODEL)
    self.anim_manager:play(ANIM_IDLE)

    self.state      = STATE_IDLE
    self.counter    = 0
    self.target_ang = self.ang
    self.foot_ang   = self.ang
    self.ang        = self.ang + randf(-1, 1)
    self.turn_dir   = random(0, 1) == 0 and -1 or 1
end


function CannonEnemy:get_visible_hero()
    local x, y = self.box:get_center()
    local best_da = math.huge
    local best_ta
    local best_h
    for _, h in ipairs(World.heroes) do
        if h:is_targetable() then
            local hx, hy = h.box:get_center()
            if not World.map.main:raycast(x, y, hx, hy) then
                local dx = h.box:center_x() - x
                local dy = h.box:center_y() - y
                local ta = math.atan2(dx, -dy)
                local da = math.abs(delta_angle(self.ang, ta))
                if da < best_da then
                    best_da = da
                    best_ta = ta
                    best_h  = h
                end
            end
        end
    end
    return best_h, best_ta
end


function CannonEnemy:sub_update()

    if self.state == STATE_IDLE then

        local da = delta_angle(self.foot_ang, self.ang)
        if da > math.pi *  0.5 then self.turn_dir = -1 end
        if da < math.pi * -0.5 then self.turn_dir =  1 end
        self.ang = self.ang + self.turn_dir * 0.01


        self.counter = self.counter - 1
        if self.counter <= 0 then
            self.counter = random(20, 40)
            local h, ta = self:get_visible_hero()
            if h then
                self.state      = STATE_TARGET
                self.target_ang = ta
            end
        end
    elseif self.state == STATE_TARGET then
        local da = delta_angle(self.ang, self.target_ang)
        local SPEED = 0.02
        self.ang = self.ang + clamp(da, -SPEED, SPEED)
        if da == 0 then
            self.state   = STATE_IDLE
            self.counter = random(20, 40)
            local h, ta = self:get_visible_hero()
            if h then
                self.target_ang = ta
                if math.abs(delta_angle(self.ang, self.target_ang)) < 0.5 then
                    self.state   = STATE_SHOOT
                    self.counter = 0
                end
            end
        end
    elseif self.state == STATE_SHOOT then
        if self.counter == 10
        or self.counter == 20
        or self.counter == 30
        then
            local SPEED = 2.5
            local dx = math.sin(self.ang)
            local dy = -math.cos(self.ang)
            World:add_enemy_bullet(CannonBall(
                self.box:center_x() + dx * 11,
                self.box:center_y() + dy * 11,
                dx * SPEED,
                dy * SPEED))
            self.anim_manager:play(ANIM_SHOOT)
            self.anim_manager:seek(0)
        end
        self.counter = self.counter + 1
        if self.counter > 90 then
            self.state = STATE_TARGET
        end
    end


    self.anim_manager:update()
    self.anim_manager.lt[2][3] = self.ang
    self.anim_manager.lt[4][3] = self.foot_ang
    self.gt = MODEL:get_global_transform(self.anim_manager.lt)

end
function CannonEnemy:sub_draw()
    G.push()
    G.translate(self.box:center_x(), self.box:center_y())
    G.scale(0.1)
    MODEL:draw(self.gt)
    G.pop()

end
