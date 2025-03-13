
Tween = Object:new({
    TRANS_LINEAR = function(x) return x end,
    TRANS_SINE   = function(x) return 1 - math.cos(x * math.pi * 0.5) end,
    TRANS_QUAD   = function(x) return x^2 end,
    TRANS_POW    = function(p)
        return function(x) return x^p end
    end,

    EASE_IN     = 0,
    EASE_OUT    = 1,
    EASE_IN_OUT = 2,
})
function Tween:init(start_value)
    self.start_value = start_value
    self.value       = start_value
    self.frame       = 0
    self.data        = {}

    self.ease  = Tween.EASE_IN_OUT
    self.trans = Tween.TRANS_LINEAR
end
function Tween:set_ease(ease)
    self.ease = ease
    return self
end
function Tween:set_trans(trans)
    self.trans = trans
    return self
end
function Tween:tween(final_value, frames)
    table.insert(self.data, {
        final_value = final_value,
        frames      = frames,
        ease        = self.ease,
        trans       = self.trans,
    })
    return self
end
function Tween:is_done()
    return #self.data == 0
end
function Tween:update()
    local d = self.data[1]
    if not d then return self.value end
    self.frame = self.frame + 1

    local x = self.frame / d.frames

    if d.ease == Tween.EASE_IN then
        x = d.trans(x)
    elseif d.ease == Tween.EASE_OUT then
        x = 1 - d.trans(1 - x)
    elseif d.ease == Tween.EASE_IN_OUT then
        x = x < 0.5 and d.trans(x * 2) * 0.5 or 1 - d.trans(2 - x * 2) * 0.5
    end

    self.value = mix(self.start_value, d.final_value, x)

    if self.frame >= d.frames then
        -- self.frame = self.frame - d.frames
        self.frame = 0
        self.start_value = d.final_value
        table.remove(self.data, 1)
    end
    return self.value
end