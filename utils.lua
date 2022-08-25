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
    return (newWidth/currentWidth ), (newHeight/currentHeight)
end

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

function smoothstep(x) 
    return ((x) * (x) * (3 - 2 * (x)))
end

local uid = 0
function getUID()
    uid = uid + 1
    return uid
end