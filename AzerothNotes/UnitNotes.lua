local _, NS = ...
local N = {}
NS.UnitNotes = N

local function Readable(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "string" then return nil end
    value = NS.Data.Trim(value)
    return value ~= "" and value or nil
end

function N.Name(context)
    if type(context) ~= "table" then return nil end
    local name, surname = Readable(context.name), Readable(context.surname)
    local unit = Readable(context.unit)
    if not name and unit then
        local lookup = UnitNameUnmodified or UnitName
        local ok, first, second = pcall(lookup, unit)
        if ok then name, surname = Readable(first), Readable(second) end
    end
    if not name then return nil end
    if NameUtil and NameUtil.GetFullNameWithoutRealm then
        local ok, full = pcall(NameUtil.GetFullNameWithoutRealm, name, surname)
        if ok and Readable(full) then return Readable(full) end
    end
    return surname and (name .. " " .. surname) or name
end

function N.Tag(name)
    return (NS.Data.Trim(name):lower():gsub("^[#]+", ""):gsub("[%s,]+", "-"))
end

function N.CreateNote(name)
    local app, ui = NS.App, NS.UI
    if not app or not app.db or not Readable(name) then return end
    if not ui.frame then ui:Build() end
    ui.frame:Show()
    ui:New(name, { N.Tag(name) })
    ui.live:ActivateOffset(1)
end

function N.Install()
    if N.installed then return true end
    if not Menu or not Menu.ModifyMenu then return false end
    for _, which in ipairs({
        "SELF", "PLAYER", "ENEMY_PLAYER", "PARTY", "RAID_PLAYER", "RAID", "TARGET",
        "FOCUS", "BOSS", "RAID_TARGET_ICON", "PET", "OTHERPET", "VEHICLE", "ARENAENEMY",
    }) do
        Menu.ModifyMenu("MENU_UNIT_" .. which, function(_, root, context)
            local name = N.Name(context)
            if not name then return end
            root:CreateDivider()
            root:CreateButton("Add note", function()
                -- Unit tokens such as "target" may point elsewhere by the time the menu closes.
                C_Timer.After(0, function() N.CreateNote(name) end)
            end)
        end)
    end
    N.installed = true
    return true
end
