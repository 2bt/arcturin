Input = Object:new {
    state      = {},
    prev_state = {},
}
function Input:set_state(s)
    self.prev_state = self.state
    self.state = s
    s.dx = bool[s.right] - bool[s.left]
    s.dy = bool[s.down] - bool[s.up]
end
function Input:was_pressed(key)
    return self.state[key] and not self.prev_state[key]
end


Joystick = Input:new()
function Joystick:init(j)
    self.joy = j
end
function Joystick:update()
    local x, y = self.joy:getAxes()
    x = x or 0
    y = y or 0
    self:set_state({
        left  = self.joy:isGamepadDown("dpleft") or x < -0.1,
        right = self.joy:isGamepadDown("dpright") or x >  0.1,
        up    = self.joy:isGamepadDown("dpup") or y < -0.1,
        down  = self.joy:isGamepadDown("dpdown") or y >  0.1,
        a     = self.joy:isGamepadDown("a") or self.joy:isDown(1),
        b     = self.joy:isGamepadDown("b") or self.joy:isDown(2),
        start = self.joy:isGamepadDown("start"),
        back  = self.joy:isGamepadDown("back"),
    })
end


Keyboard = Input:new()
function Keyboard:init()
end
function Keyboard:update()
    self:set_state({
        left  = love.keyboard.isDown("left"),
        right = love.keyboard.isDown("right"),
        up    = love.keyboard.isDown("up"),
        down  = love.keyboard.isDown("down"),
        a     = love.keyboard.isDown("x"),
        b     = love.keyboard.isDown("c"),
        start = love.keyboard.isDown("return"),
        back  = love.keyboard.isDown("escape"),
    })
end
