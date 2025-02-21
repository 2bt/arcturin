AnimationManager = Object:new()
function AnimationManager:init(model)
    self.model       = model
    self.blend       = 0
    self.blend_speed = 0
    self.a1          = model.anims[1]
    self.a1_frame    = self.a1.start
    self.a2          = nil
    self.a2_frame    = 0
end

function AnimationManager:play(anim_index, blend_time)
    blend_time = blend_time or 3

    local a = self.model.anims[anim_index]
    if a == self.a1 then
        return
    end

    if blend_time > 0 then
        self.a2          = self.a1
        self.a2_frame    = self.a1_frame
        self.blend       = 1
        self.blend_speed = 1 / blend_time
    else
        self.a2          = nil
        self.a2_frame    = 0
        self.blend       = 0
        self.blend_speed = 0
    end

    self.a1       = a
    self.a1_frame = a.start
end

function AnimationManager:seek(p)
    self.a1_frame = mix(self.a1.start, self.a1.stop, p)
end

local function update_frame(a, f)
    f = f + a.speed
    if f > a.stop then
        if a.loop then
            f = f - a.stop + a.start
        else
            f = a.stop
        end
    end
    return f
end

local function lerp_transform(t1, t2, l)
    for i, t in ipairs(t1) do
        local x1, y1, a1 = unpack(t)
        local x2, y2, a2 = unpack(t2[i])
        t[1] = mix(x1, x2, l)
        t[2] = mix(y1, y2, l)
        t[3] = mix(a1, a2, l)
    end
end


function AnimationManager:update()

    self.blend = math.max(0, self.blend - self.blend_speed)
    self.a1_frame = update_frame(self.a1, self.a1_frame)

    self.lt = self.model:get_local_transform(self.a1_frame)

    if self.a2 then
        self.a2_frame = update_frame(self.a2, self.a2_frame)
        local lt2 = self.model:get_local_transform(self.a2_frame)

        lerp_transform(self.lt, lt2, self.blend)
    end

end
