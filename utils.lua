function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end
  
function clamp(val, lower, upper)
    assert(val and lower and upper, "one of val, upper, lower not supplied")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end