local F = 5
function love.conf(t)
    t.window.title     = "Ladus"
    t.window.width     = 320 * F
    t.window.height    = 180 * F
    t.window.resizable = true
    t.window.msaa      = 4

    -- XXX
    t.window.display   = 2
end
