
-- c64 colors
COLORS = {
    { 0, 0, 0 },
    { 1, 1, 1 },
    { 0.41, 0.22, 0.17 },
    { 0.44, 0.64, 0.7 },
    { 0.44, 0.24, 0.53 },
    { 0.35, 0.55, 0.26 },
    { 0.21, 0.16, 0.47 },
    { 0.72, 0.78, 0.44 },
    { 0.44, 0.31, 0.15 },
    { 0.26, 0.22, 0 },
    { 0.6, 0.4, 0.35 },
    { 0.27, 0.27, 0.27 },
    { 0.42, 0.42, 0.42 },
    { 0.6, 0.82, 0.52 },
    { 0.42, 0.37, 0.71 },
    { 0.58, 0.58, 0.58 },
}


Game = {
    inputs = { Keyboard() },
    state  = "title",
}

function Game:init()
    World:init()
end

function Game:add_joystick(j)
    table.insert(self.inputs, Joystick(j))
end
function Game:remove_joystick(j)
    for i, input in ipairs(self.inputs) do
        if input.joy == j then
            table.remove(self.inputs, i)
            return
        end
    end
end
function Game:change_state(state)
    self.next_state = state
end
function Game:update()

    for _, input in ipairs(self.inputs) do
        input:update()
        if not input.hero and not (input.start or input.a) then
            World:add_hero(input)
        end
    end

    if self.next_state then
        self.state = self.next_state
        self.next_state = nil
    end


    if self.state == "title" then
        Title:update()
    elseif self.state == "playing" then
        World:update()
    end

end

function Game:draw()
    G.clear(0, 0, 0)

    if self.state == "title" then
        Title:draw()
    elseif self.state == "playing" then
        World:draw()
    end

    -- for i, input in ipairs(self.inputs) do
    --     G.print(("%d %d"):format(input.state.dx, input.state.dy), 10, i * 20)
    -- end

end
