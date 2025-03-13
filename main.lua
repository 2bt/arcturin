G = love.graphics
W = 320
H = 180

require("helper")
require("box")
require("input")
require("model")
require("animation_manager")
require("tween")

require("particle")
require("solid")
require("hero")
require("enemy")
require("map")
require("world")
require("title")
require("game")

function love.load()
    G.setFont(G.newFont(14))
    G.setBackgroundColor(0.2, 0.2, 0.2)
    love.mouse.setVisible(false)
    Game:init()
end

function love.update()
    Game:update()
end


function love.draw()
    local w = G.getWidth()
    local h = G.getHeight()
    if w / h < W / H then
        local f = w / W * H
        G.setScissor(0, (h - f) * 0.5, w, f)
        G.translate(0, (h - f) * 0.5)
        G.scale(w / W)
    else
        local f = h / H * W
        G.setScissor((w - f) * 0.5, 0, f, h)
        G.translate((w - f) * 0.5, 0)
        G.scale(h / H)
    end

    Game:draw()
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
    Game:add_joystick(j)
end
function love.joystickremoved(j)
    Game:remove_joystick(j)
end
