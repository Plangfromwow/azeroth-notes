local _, NS = ...
NS.Layout = {}
local L = NS.Layout

local function Clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function L.Fit(screenWidth, screenHeight, preferences)
    screenWidth, screenHeight = math.max(1, screenWidth), math.max(1, screenHeight)
    local scale = math.min(1, screenWidth * 0.92 / 680, screenHeight * 0.90 / 430)
    local maxWidth, maxHeight = screenWidth * 0.92 / scale, screenHeight * 0.90 / scale
    local preferredWidth = preferences.widthFraction and screenWidth * preferences.widthFraction / scale
        or math.min(1000, screenWidth * 0.80 / scale)
    local preferredHeight = preferences.heightFraction and screenHeight * preferences.heightFraction / scale
        or math.min(780, screenHeight * 0.82 / scale)
    local width = Clamp(preferredWidth, 680, maxWidth)
    local height = Clamp(preferredHeight, 430, maxHeight)
    return width, height, scale, maxWidth, maxHeight
end

function L.Content(width)
    return math.floor(Clamp(width * 0.24, 180, 240)), width < 760 and 14 or 15
end
