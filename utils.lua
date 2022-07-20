function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end
  
function clamp(val, lower, upper)
    assert(val and lower and upper, "one of val, upper, lower not supplied")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
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

local uid = 0
function getUID()
    uid = uid + 1
    return uid
end