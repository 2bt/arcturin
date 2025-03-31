local MODE_PLAY = 0
local MODE_SEEK = 1

AnimationManager = Object:new()
function AnimationManager:init(model)
    self.model       = model
    self.blend       = 0
    self.blend_speed = 0
    self.a1          = model.anims[1]
    self.a1_frame    = self.a1.start
    self.a1_mode     = MODE_PLAY
    self.a2          = nil
    self.a2_frame    = 0
end

function AnimationManager:play(anim_index, blend_speed)
    blend_speed = blend_speed or 0.3

    self.a1_mode = MODE_PLAY
    local a = self.model.anims[anim_index]
    if a == self.a1 then
        return
    end

    self.blend_speed = blend_speed
    if self.a1 and self.blend_speed > 0 then
        self.a2       = self.a1
        self.a2_frame = self.a1_frame
        self.blend    = 1
    else
        self.a2       = nil
        self.a2_frame = 0
        self.blend    = 0
    end

    self.a1       = a
    self.a1_frame = a.start
end

function AnimationManager:seek(pos, speed)
    speed = speed or 0
    if speed == 0 then
        self.a1_mode  = MODE_PLAY
        self.a1_frame = mix(self.a1.start, self.a1.stop, pos)
    else
        self.a1_mode       = MODE_SEEK
        self.a1_seek_speed = speed
        self.a1_seek_frame = mix(self.a1.start, self.a1.stop, pos)
    end
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

    if self.a1_mode == MODE_PLAY then
        self.a1_frame = update_frame(self.a1, self.a1_frame)
    else
        self.a1_frame = clamp(self.a1_seek_frame,
                              self.a1_frame - self.a1_seek_speed,
                              self.a1_frame + self.a1_seek_speed)
    end

    self.lt = self.model:get_local_transform(self.a1_frame)

    if self.a2 then
        self.a2_frame = update_frame(self.a2, self.a2_frame)
        local lt2 = self.model:get_local_transform(self.a2_frame)

        self.blend = math.max(0, self.blend - self.blend_speed)
        lerp_transform(self.lt, lt2, self.blend)
    end

    self.gt = self.model:get_global_transform(self.lt)
end
function AnimationManager:draw()
    if not self.gt then return end
    self.model:draw(self.gt)
end
