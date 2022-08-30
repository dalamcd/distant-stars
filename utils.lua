---@diagnostic disable: lowercase-global

function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

function clamp(val, lower, upper)
    assert(val and lower and upper, "one of val, upper, lower not supplied")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

function fstr(str, precision)
    precision = precision or 2
    return string.format('%.' .. precision .. 'f', str)
end

function concatTables(t1, t2)
    nt = {}
    n = 0
    for _,v in ipairs(t1) do n=n+1; nt[n]=v end
    for _,v in ipairs(t2) do n=n+1; nt[n]=v end
    return nt
end

function convertQuadToScale(sprite, newWidth, newHeight)
    local _, _, currentWidth, currentHeight = sprite:getViewport()
    return (newWidth/currentWidth), (newHeight/currentHeight)
end

-- from lua-users.org wiki
function wrap(str, limit, indent, indent1)
    indent = indent or ""
    indent1 = indent1 or indent
    limit = limit or 72
    local here = 1-#indent1
    local function check(sp, st, word, fi)
       if fi - here > limit then
          here = st - #indent
          return "\n"..indent..word
       end
    end
    return indent1..str:gsub("(%s+)()(%S+)()", check)
 end

function tableValues(t)
    local rt = {}
    for k, v in pairs(t) do
        table.insert(rt, v)
    end
    return unpack(rt)
end

function fmtValues(...)
    local fmtStr = ""
    local arg = {...}
    for _, v in ipairs(arg) do
        if type(v) == "string" then
            fmtStr = fmtStr .. "c" .. v:len()
        elseif type(v) == "number" then
            fmtStr = fmtStr .. "n"
        elseif type(v) == "table" then
            fmtStr = fmtStr .. fmtValues(tableValues(v))
        end
    end
    return fmtStr
end

-- I think this is not a great implementation of this alogorithm
function midpointCircle(centerX, centerY, radius)
    local points = {}
    for y=-radius, radius do
        for x=-radius, radius do
            if x*x+y*y <= radius*radius + radius then
                table.insert(points, {x=centerX+x, y=centerY+y})
            end
        end
    end
    return points
end

-- Need to look into how this works 
function smoothstep(x)
    return ((x) * (x) * (3 - 2 * (x)))
end

local uid = 0
function getUID()
    uid = uid + 1
    return uid
end