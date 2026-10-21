local NS = {}
assert(loadfile("AzerothNotes/Data.lua"))("AzerothNotes", NS)
assert(loadfile("AzerothNotes/UnitNotes.lua"))("AzerothNotes", NS)
local N = NS.UnitNotes
assert(not N.Install())
local unitName = "Forest Spider"
_G.UnitNameUnmodified = function(unit) assert(unit == "target"); return unitName end
_G.NameUtil = { GetFullNameWithoutRealm = function(name, surname)
    return surname and name .. " " .. surname or name
end }
assert(N.Name({ name = "Eacam", surname = "Brennan" }) == "Eacam Brennan")
assert(N.Name({ unit = "target" }) == "Forest Spider")
assert(N.Name({}) == nil)
assert(N.Tag("Eacam Brennan") == "eacam-brennan")
assert(N.Tag("Forest Spider") == "forest-spider")
assert(N.Tag("世界 Dragon") == "世界-dragon")
local secret = {}
_G.issecretvalue = function(value) return value == secret end
assert(N.Name({ name = secret }) == nil)
local callbacks, registrations, timers = {}, 0, {}
_G.Menu = { ModifyMenu = function(tag, callback)
    assert(not callbacks[tag]); callbacks[tag] = callback; registrations = registrations + 1
end }
_G.C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
assert(N.Install())
local count = registrations
assert(N.Install() and registrations == count)
assert(callbacks.MENU_UNIT_TARGET and callbacks.MENU_UNIT_PLAYER and callbacks.MENU_UNIT_RAID_TARGET_ICON)
local captured
local root = {
    CreateDivider = function() end,
    CreateButton = function(_, label, callback) assert(label == "Add note"); captured = callback end,
}
callbacks.MENU_UNIT_TARGET(nil, root, {unit = "target"})
assert(captured)
unitName = "Different Target"
local created
N.CreateNote = function(name) created = name end
captured(); assert(not created)
timers[1]()
assert(created == "Forest Spider")
captured = nil
callbacks.MENU_UNIT_TARGET(nil, root, {})
assert(not captured)
callbacks.MENU_UNIT_PLAYER(nil, root, { name = "Eacam", surname = "Brennan" })
captured(); timers[2]()
assert(created == "Eacam Brennan")
print("Unit menus: full names, unit lookup, safe tags, delayed callbacks, target changes and duplicate registration passed.")
