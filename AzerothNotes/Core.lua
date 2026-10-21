local _, NS = ...
local A = { NS = NS }
_G.AzerothNotes = A
_G.BINDING_HEADER_AZEROTHNOTES = "Azeroth Notes"
_G.BINDING_NAME_AZEROTHNOTES_TOGGLE = "Open / close journal"

function A:Author()
    return (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Forever")
end

function A:Message(text)
    print("|cffd6b66eAzeroth Notes:|r " .. text)
end

function A:Toggle()
    if not self.db then self:Message(self.error or "The notebook is not ready."); return end
    self.NS.UI:Toggle()
end

local WELCOME = [=[# A journal for your travels

Welcome to **Azeroth Notes**. A quiet place for discoveries, clues, and stories.

## Begin a page

Choose New, give your note a title, and click a paragraph to write in Markdown.
Live Preview renders it when you click away. Source shows the full Markdown;
Read is available from Source. Ctrl-click a link in Live Preview to follow it.
The Notes button folds away the list when you want more room.

- Keep quest clues and the names of people you meet.
- Assign tags in the Tags field, separated by spaces. No hash signs needed.
- Search using words or tags to find a page again.
- Connect pages with [[A place worth remembering]].

## A few familiar marks

**Emphasis**, *a quieter thought*, and `inline code`.

> Every journey leaves something worth writing down.

- [ ] Find a place worth remembering
- [x] Begin your journal

## Keeping your pages

Edits are kept in memory as you type. WoW saves them to disk on /reload or logout.
Deleted notes stay in Trash until you restore them. Closing the journal leaves your screen clear.

This first build keeps notes in WoW. An external Markdown vault and desktop companion are planned.
]=]

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGOUT")
loader:RegisterEvent("DISPLAY_SIZE_CHANGED")
loader:RegisterEvent("UI_SCALE_CHANGED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and A.db) then
        if A.db and NS.UnitNotes.Install() then loader:UnregisterEvent("ADDON_LOADED") end
        return
    end
    if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        if A.db then
            C_Timer.After(0, function() NS.UI:FitToScreen(true) end)
        end
        return
    end
    if event == "PLAYER_LOGOUT" then
        if A.db and NS.UI.Flush then NS.UI:Flush() end
        return
    end
    if name ~= "AzerothNotes" then return end
    local db, err = NS.Data.Initialize(_G.AzerothNotesDB)
    if not db then A.error = err; A:Message(err); return end
    A.db, _G.AzerothNotesDB = db, db
    NS.App = A
    if not db.welcomed then
        local note = NS.Data.Create(db, "Welcome to Azeroth Notes", WELCOME, time(), A:Author())
        note.tags = { "journal" }
        db.ui.selected = note.id
        db.welcomed = true
    end
    NS.UI:SetupMinimap()
    if NS.UnitNotes.Install() then loader:UnregisterEvent("ADDON_LOADED") end
end)

SLASH_AZEROTHNOTES1 = "/anotes"
SlashCmdList.AZEROTHNOTES = function(message)
    message = NS.Data.Trim(message):lower()
    if message == "minimap" and A.db then
        A.db.ui.minimap = not A.db.ui.minimap
        NS.UI:SetupMinimap()
        A:Message(A.db.ui.minimap and "Minimap book shown." or "Minimap book hidden.")
    elseif message == "help" then
        A:Message("/anotes opens the journal. /anotes minimap toggles its book icon. Search words or tags to find notes.")
    else
        A:Toggle()
    end
end
