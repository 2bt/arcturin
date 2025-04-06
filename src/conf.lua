local F = 4
function love.conf(t)
    t.window.title     = "Arcturin"
    t.window.width     = 320 * F
    t.window.height    = 180 * F
    t.window.resizable = true
    t.window.msaa      = 4
    t.window.highdpi   = true
    -- XXX
    -- t.window.display   = 2
end
