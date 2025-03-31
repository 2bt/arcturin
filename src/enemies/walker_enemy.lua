
local ANIM_IDLE = 1
local ANIM_WALK = 2
local ANIM_JUMP = 3

local STATE_WALK  = 1
local STATE_WAIT  = 2
local STATE_JUMP  = 3

local MODEL = Model("assets/models/walker.model")

WalkerEnemy = Enemy:new()
function WalkerEnemy:init(x, y)
    self.box          = Box.make_above(x, y, 14, 14)
    self.hp           = 7
    self.vy           = 0
    self.wait_counter = 0
    self.jump_counter = 0
    self.state        = STATE_WALK
    self.anim_manager = AnimationManager(MODEL)
end
function WalkerEnemy:sub_update()

    if self.state == STATE_WALK then
        local vx = self.dir * 1.1
        if World:move_x(self.box, vx) then
            self.state        = STATE_WAIT
            self.wait_counter = 10
        end
        -- jumping
        if self.jump_counter > 0 then
            self.jump_counter = self.jump_counter - 1
        else

            -- jump over cliff
            local x = self.box:center_x() + self.dir * 6
            local t = World.map.main:get_tile_at_world_pos(x, self.box:bottom() + 1)
            if t == TILE_TYPE_EMPTY then
                if random(1, 4) < 4 then
                    self.vy = random(1, 5) == 1 and -3.5 or -2.5
                else
                    self.jump_counter = 20
                end
            end

            -- jump up single tile
            local x = self.box:center_x() + self.dir * 10
            local t1 = World.map.main:get_tile_at_world_pos(x, self.box:bottom() - 1)
            local t2 = World.map.main:get_tile_at_world_pos(x, self.box:bottom() - 1 - TILE_SIZE)
            local t3 = World.map.main:get_tile_at_world_pos(x, self.box:bottom() - 1 - TILE_SIZE * 2)
            if t1 ~= TILE_TYPE_EMPTY and t1 ~= TILE_TYPE_BRIDGE
            and t2 == TILE_TYPE_EMPTY and t3 == TILE_TYPE_EMPTY then
                if random(1, 3) == 1 then
                    self.vy = random(1, 3) == 1 and -3.5 or -2.5
                else
                    self.jump_counter = 20
                end
            end
        end
        self.anim_manager:play(ANIM_WALK)

    elseif self.state == STATE_JUMP then

        local vx = self.dir * 1.1
        World:move_x(self.box, vx)
        self.anim_manager:play(ANIM_JUMP)

    elseif self.state == STATE_WAIT then
        self.wait_counter = self.wait_counter - 1
        if self.wait_counter <= 0 then
            self.state = STATE_WALK
            self.dir   = -self.dir
        end
        self.anim_manager:play(ANIM_IDLE)
    end

    self.vy = self.vy + GRAVITY
    local vy = clamp(self.vy, -MAX_VY, MAX_VY)
    if World:move_y(self.box, vy) then
        if self.vy > 0 and self.state == STATE_JUMP then
            self.state = STATE_WALK
            self.jump_counter = 20
        end
        self.vy = 0
    else
        self.state = STATE_JUMP
    end


    self.anim_manager:update()
end
function WalkerEnemy:sub_draw()
    G.push()
    G.translate(self.box:center_x(), self.box:bottom())
    G.scale(self.dir, 1)
    G.scale(0.06)
    self.anim_manager:draw()
    G.pop()
end
