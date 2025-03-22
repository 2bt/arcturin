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

FONT_SMALL = G.newFont("assets/monofonto rg.otf", 5, "normal", 6)
FONT_BIG   = G.newFont("assets/monofonto rg.otf", 9, "normal", 6)


require("helper")
require("box")
require("input")
require("model")
require("animation_manager")
require("tween")
require("meshgen")

require("particle")
require("solid")
require("hero")
require("enemy")
require("map")
require("world")
require("title")



local inputs = {
    Keyboard(),
    -- Keyboard2(), -- DEBUG
}
local state      = "title"
local next_state = nil
local blend      = 0

local BLEND_SPEED = 0.1

Game = {
    inputs = inputs
}
function Game:init()

end
function Game:add_joystick(j)
    table.insert(inputs, Joystick(j))
end
function Game:remove_joystick(j)
    for i, input in ipairs(inputs) do
        if input.joy == j then
            table.remove(inputs, i)
            return
        end
    end
end
function Game:change_state(state)
    if next_state then return end
    next_state = state
end
function Game:update()

    for _, input in ipairs(inputs) do
        input:update()
    end

    -- state transition
    if next_state then
        if blend < 1 then
            blend = math.min(blend + BLEND_SPEED, 1)
            if blend == 1 then
                state = next_state
                next_state = nil
                if state == "playing" then
                    World:init()
                end
            end
        end
    elseif blend > 0 then
        blend = math.max(blend - BLEND_SPEED, 0)
    end


    if state == "title" then
        Title:update()
    elseif state == "playing" then
        World:update()
    end


end

function Game:draw()
    G.clear(0, 0, 0)

    if state == "title" then
        Title:draw()
    elseif state == "playing" then
        World:draw()
    end


    G.setColor(0, 0, 0, blend)
    G.rectangle("fill", 0, 0, W, H)
end
