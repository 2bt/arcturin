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
function Input:is_just_pressed(...)
    for _, k in ipairs({...}) do
        if self.state[k] and not self.prev_state[k] then return true end
    end
    return false
end


Joystick = Input:new({
    button_name_a = "[A]",
})
function Joystick:init(j)
    self.name = j:getName():gsub(" gamepad$", "")
    self.joy  = j
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


Keyboard = Input:new({
    name          = "Keyboard",
    button_name_a = "[X]",
})
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


Keyboard2 = Input:new({
    name          = "Keyboard 2",
    button_name_a = "[G]",
})
function Keyboard2:update()
    self:set_state({
        left  = love.keyboard.isDown("j"),
        right = love.keyboard.isDown("l"),
        up    = love.keyboard.isDown("i"),
        down  = love.keyboard.isDown("k"),
        a     = love.keyboard.isDown("g"),
        b     = love.keyboard.isDown("h"),
        start = love.keyboard.isDown("t"),
        back  = love.keyboard.isDown("y"),
    })
end
