Object = {}
function Object:new(o)
    o = o or {}
    setmetatable(o, self)
    local m = getmetatable(self)
    self.__index = self
    self.__call = m.__call
    self.super = m.__index and m.__index.init
    return o
end
setmetatable(Object, { __call = function(self, ...)
    local o = self:new()
    if o.init then o:init(...) end
    return o
end })


bool = { [true] = 1, [false] = 0 }

function clamp(v, min, max)
    return math.max(min, math.min(max, v))
end

function length(dx, dy)
    return (dx * dx + dy * dy) ^ 0.5
end

function distance(ax, ay, bx, by)
    return length(bx - ax, by - ay)
end


function randf(min, max)
    return min + random() * (max - min)
end

function mix(a, b, x)
    local y = 1 - x
    if type(a) == "number" then
        return a * y + b * x
    end
    local c = {}
    for i = 1, #a do c[i] = a[i] * y + b[i] * x end
    return c
end

function math.sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end

function table.clear(t)
    for k in pairs (t) do t [k] = nil end
end
function table.tostring(t)
    local buf = {}
    local function w(o, s, p)
        p = p or s
        local t = type(o)
        if t == "table" then
            buf[#buf + 1] = p .. "{"
            if not next(o)
            or (o[1] and type(o[1]) == "number") then
                for i, a in ipairs(o) do
                    if i > 1 then buf[#buf+1] = "," end
                    w(a, "")
                end
                buf[#buf + 1] = "}"
            else
                buf[#buf+1] = "\n"
                if o[1] then
                    for i, a in ipairs(o) do
                        w(a, s .. " ")
                        buf[#buf+1] = ",\n"
                    end
                else
                    -- sort keys for cleaner diffs
                    local keys = {}
                    for k in pairs(o) do table.insert(keys, k) end
                    table.sort(keys)
                    for _, k in ipairs(keys) do
                        buf[#buf+1] = s .. " " .. k .. "="
                        w(o[k], s .. " ", "")
                        buf[#buf+1] = ",\n"
                    end
                end
                if buf[#buf] == ","
                or buf[#buf] == "\n"
                or buf[#buf] == ",\n" then buf[#buf] = nil end
                buf[#buf+1] = "\n" .. s .. "}"
            end
        elseif t == "string" then
            buf[#buf+1] = p .. ("%q"):format(o)
        elseif t == "number" then
            buf[#buf+1] = p .. ("%g"):format(o)
        else
            buf[#buf+1] = p .. tostring(o)
        end
    end
    w(t, "")
    return table.concat(buf)
end
function table.append(t, ...)
    for _, a in ipairs({ ... }) do t[#t+1] = a end
end