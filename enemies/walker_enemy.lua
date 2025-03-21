
local ANIM_IDLE = 1
local ANIM_WALK = 2
local ANIM_JUMP = 3

local STATE_WALK  = 1
local STATE_WAIT  = 2
local STATE_JUMP  = 3

local MODEL = Model("assets/walker.model")

WalkerEnemy = Enemy:new()
function WalkerEnemy:init(x, y)
    self.box          = Box.make_above(x, y, 14, 14)
    self.hp           = 7
    self.vy           = 0
    self.wait_count   = 0
    self.state        = STATE_WALK
    self.anim_manager = AnimationManager(MODEL)
end
function WalkerEnemy:sub_update()

    if self.state == STATE_WALK then
        local vx = self.dir * 1.1
        if World:move_x(self.box, vx) then
            self.state      = STATE_WAIT
            self.wait_count = 10
        end
        self.anim_manager:play(ANIM_WALK)

    elseif self.state == STATE_JUMP then

        local vx = self.dir * 1.1
        World:move_x(self.box, vx)
        self.anim_manager:play(ANIM_JUMP)

    elseif self.state == STATE_WAIT then
        self.wait_count = self.wait_count - 1
        if self.wait_count <= 0 then
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
        end
        self.vy = 0
    else
        self.state = STATE_JUMP
    end


    self.anim_manager:update()
end
function WalkerEnemy:draw()
    -- G.setColor(unpack(COLORS[8]))
    -- G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h)

    G.push()
    G.translate(self.box:center_x(), self.box:bottom())
    G.scale(self.dir, 1)
    G.scale(0.06)
    MODEL:draw(self.anim_manager.gt)
    G.pop()

end
