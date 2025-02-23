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

function Box:right()
    return self.x + self.w
end
function Box:bottom()
    return self.y + self.h
end
function Box:center_x()
    return self.x + self.w / 2
end
function Box:center_y()
    return self.y + self.h / 2
end


function Box:overlaps(other)
    return self.x < other.x + other.w and self:right() > other.x and
           self.y < other.y + other.h and self:bottom() > other.y
end

function Box:overlap_x(other)
    if not self:overlaps(other) then return 0 end
    local d1 = other:right() - self.x
    local d2 = other.x - self:right()
    return math.abs(d1) < math.abs(d2) and d1 or d2
end
function Box:overlap_y(other)
    if not self:overlaps(other) then return 0 end
    local d1 = other:bottom() - self.y
    local d2 = other.y - self:bottom()
    return math.abs(d1) < math.abs(d2) and d1 or d2
end