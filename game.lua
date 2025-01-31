local G = love.graphics


game = {
    inputs = { Keyboard() },
}

function game:init()
    self.world = World()

end
function game:add_joystick(j)
    table.insert(self.inputs, Joystick(j))
end
function game:remove_joystick(j)
    for i, input in ipairs(self.inputs) do
        if input.joy == j then
            table.remove(self.inputs, i)
            return
        end
    end
end
function game:update()

    for _, input in ipairs(self.inputs) do
        input:update()
        if not input.hero and not (input.start or input.a) then
            self.world:add_hero(input)
        end
    end

    self.world:update()

end
function game:draw()
    G.clear(0, 0, 0)

--  G.setColor(255, 255, 255)
--  for i, input in ipairs(self.inputs) do
--      G.print(("%d %d"):format(input.state.dx, input.state.dy), 10, i * 20)
--  end


    self.world:draw()

end
