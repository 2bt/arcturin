Box = Object:new()
function Box:init(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
end
function Box.make_above(x, y, w, h)
    return Box(x - w / 2, y - h, w, h)
end

function Box:get_center()
    return self.x + self.w / 2, self.y + self.h / 2
end
function Box:set_center(x, y)
    self.x = x - self.w / 2
    self.y = y - self.h / 2
end