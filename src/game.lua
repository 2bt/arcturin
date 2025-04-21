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

FONT_SMALL  = G.newFont("assets/monofonto rg.otf", 3, "normal", 6)
FONT_NORMAL = G.newFont("assets/monofonto rg.otf", 5, "normal", 6)
FONT_BIG    = G.newFont("assets/monofonto rg.otf", 15, "normal", 6)


require("helper")
require("box")
require("input")
require("mesh_builder")
require("model")
require("animation_manager")
require("tween")

require("enemy_bullet")
require("enemy")
require("particle")
require("solid")
require("map")
require("meshgen")
require("hero_bullet")
require("hero")
require("collectable")
require("title")
require("world")


local BLEND_SPEED = 0.025
-- DEBUG
-- local BLEND_SPEED = 0.5


Game = {
    inputs = {
        Keyboard,
        -- Keyboard2, -- DEBUG
    },
    next_scene    = Title,
    current_scene = nil,
    blend         = 1,
}
function Game:init()
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
function Game:change_scene(scene)
    if self.next_scene then return end
    self.next_scene = scene
end
function Game:update()
    for _, input in ipairs(self.inputs) do input:update() end

    -- state transition
    if self.next_scene then
        if self.blend == 1 then
            if self.current_scene then self.current_scene:leave() end
            self.next_scene:enter()
            self.current_scene = self.next_scene
            self.next_scene = nil
        end
        if self.blend < 1 then
            self.blend = math.min(self.blend + BLEND_SPEED, 1)
        end
    elseif self.blend > 0 then
        self.blend = math.max(self.blend - BLEND_SPEED, 0)
    end

    self.current_scene:update()
end

function Game:draw()
    G.clear(0, 0, 0)

    self.current_scene:draw()

    G.setColor(0, 0, 0, self.blend)
    G.rectangle("fill", 0, 0, W, H)
end
