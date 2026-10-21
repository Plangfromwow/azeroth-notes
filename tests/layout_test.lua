local NS = {}
assert(loadfile("AzerothNotes/Layout.lua"))("AzerothNotes", NS)
for _, screen in ipairs({ {1920,1080}, {3840,2160}, {1280,720}, {800,600}, {600,400}, {3440,1440}, {800,1200} }) do
    for _, prefs in ipairs({ {}, {widthFraction = 5, heightFraction = 3}, {widthFraction = 0.1, heightFraction = 0.1} }) do
        local w, h, scale, maxW, maxH = NS.Layout.Fit(screen[1], screen[2], prefs)
        assert(w >= 680 and h >= 430)
        assert(w <= maxW + 0.01 and h <= maxH + 0.01)
        assert(w * scale <= screen[1] * 0.92 + 0.01)
        assert(h * scale <= screen[2] * 0.90 + 0.01)
        local sidebar, fontSize = NS.Layout.Content(w)
        assert(sidebar >= 180 and sidebar <= 240)
        assert(w - sidebar - 62 >= 400)
        assert(fontSize >= 14)
    end
end
local w, h = NS.Layout.Fit(1920, 1080, {widthFraction = 0.7, heightFraction = 0.7})
assert(math.abs(w / 1920 - 0.7) < 0.001)
assert(math.abs(h / 1080 - 0.7) < 0.001)
print("Layout: viewport fit, small screens, UI scale, saved proportions, and readable column widths passed.")
