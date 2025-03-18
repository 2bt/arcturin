
local MODEL = Model("assets/ufo.model")

UfoEnemy = Enemy:new()
function UfoEnemy:init(x, y)
    self.box  = Box.make_above(x, y, 20, 10)
    self.hp   = 7
    self.anim_manager = AnimationManager(MODEL)
    self.step_counter = 0
    self.phase = 0
end
function UfoEnemy:sub_update()

    self.phase = self.phase + 0.12
    if self.phase > math.pi then
        self.phase = self.phase - math.pi
        self.step_counter = self.step_counter + 1
        if self.step_counter >= 5 then
            self.step_counter = 0
            self.dir = -self.dir
        end
    end

    local vy = math.cos(self.phase) * 1.5

    World:move_y(self.box, vy)

    local vx = self.dir * 1
    if World:move_x(self.box, vx) then
        self.dir = -self.dir
        self.step_counter = 0
    end


    local lt = self.anim_manager:update()
    self.gt = MODEL:get_global_transform(lt)
end
function UfoEnemy:draw()

    G.push()
    G.translate(self.box:get_center())
    G.scale(0.05)
    MODEL:draw(self.gt)
    G.pop()

    -- G.setColor(1, 0, 0, 0.4)
    -- G.rectangle("fill", self.box.x, self.box.y, self.box.w, self.box.h, 3)
end
