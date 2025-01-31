local G = love.graphics

require("helper")
require("input")
require("map")
require("entity")
require("world")
require("game")


W = 320
H = 180
love.mouse.setVisible(false)
G.setFont(G.newFont(14))
G.setBackgroundColor(0.2, 0.2, 0.2)

game:init()


function love.update()
    game:update()
end


function love.draw()
    local w = G.getWidth()
    local h = G.getHeight()
    if w / h < W / H then
        local f = w / W * H
        G.setScissor(0, (h - f) * 0.5, w, f)
        G.translate(0, (h - f) * 0.5)
        G.scale(w / W, w / W)
    else
        local f = h / H * W
        G.setScissor((w - f) * 0.5, 0, f, h)
        G.translate((w - f) * 0.5, 0)
        G.scale(h / H, h / H)
    end

    game:draw()
    G.setScissor()
end



function love.keypressed(k)
    if k == "p" then
        local screenshot = love.graphics.newScreenshot()
        screenshot:encode('png', os.time() .. '.png')
    elseif k == "escape" then
        love.event.quit()
    end
end


function love.joystickadded(j)
    game:add_joystick(j)
end
function love.joystickremoved(j)
    game:remove_joystick(j)
end
