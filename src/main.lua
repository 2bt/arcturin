G = love.graphics
random = love.math.random
Transform = love.math.newTransform()

W = 320
H = 180

require("game")

function love.load()
    G.setFont(G.newFont(14))
    G.setBackgroundColor(0.2, 0.2, 0.2)
    Game:init()
end

local FIXED_DT = 1/60
local time_left = 0
function love.update(dt)
    local fps = love.timer.getFPS()
    if fps >= 59 and fps <= 61 then
        Game:update()
    else
        -- fixed timestep
        time_left = math.min(time_left + dt, FIXED_DT * 2)
        while time_left >= FIXED_DT do
            time_left = time_left - FIXED_DT
            Game:update()
        end
    end
end
function love.draw()
    Transform:reset()

    local w = G.getWidth()
    local h = G.getHeight()
    if w / h < W / H then
        local f = w / W * H
        G.setScissor(0, (h - f) * 0.5, w, f)
        Transform:translate(0, (h - f) * 0.5)
        Transform:scale(w / W)
    else
        local f = h / H * W
        G.setScissor((w - f) * 0.5, 0, f, h)
        Transform:translate((w - f) * 0.5, 0)
        Transform:scale(h / H)
    end

    G.replaceTransform(Transform)
    Game:draw()
    G.setScissor()
end
function love.keypressed(k)
    -- if k == "p" then
    --     G.captureScreenshot(os.time() .. ".png")
    -- elseif k == "escape" then
    --     love.event.quit()
    -- end
end
function love.joystickadded(j)
    Game:add_joystick(j)
end
function love.joystickremoved(j)
    Game:remove_joystick(j)
end

