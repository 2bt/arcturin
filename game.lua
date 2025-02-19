Game = {
    inputs = { Keyboard() },
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
function Game:update()

    for _, input in ipairs(self.inputs) do
        input:update()
        if not input.hero and not (input.start or input.a) then
            World:add_hero(input)
        end
    end

    World:update()

end
function Game:draw()
    G.clear(0, 0, 0)

--  G.setColor(255, 255, 255)
--  for i, input in ipairs(self.inputs) do
--      G.print(("%d %d"):format(input.state.dx, input.state.dy), 10, i * 20)
--  end


    World:draw()

end
