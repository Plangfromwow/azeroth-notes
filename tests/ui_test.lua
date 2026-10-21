local frames, timers = {}, {}
local focusedBox
local methods = {}
local function New(kind, name, parent, template)
    local f = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, shown = true,
        width = 400, height = 300, text = "", enabled = true, points = {} }, { __index = methods })
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
for _, method in ipairs({ "SetTextColor", "SetFontObject", "SetTexture", "SetVertexColor", "SetColorTexture",
    "SetAllPoints", "SetJustifyH", "SetFont", "SetShadowOffset", "SetHyperlinksEnabled", "SetSpacing",
    "SetAutoFocus", "SetMultiLine", "SetMaxLetters", "SetTextInsets", "SetFrameStrata", "SetFrameLevel",
    "SetClampedToScreen", "SetMovable", "EnableMouse", "RegisterForDrag", "SetResizable", "SetResizeBounds",
    "SetMinResize", "SetPortraitToAsset", "SetTitle", "SetNormalTexture", "SetHighlightTexture", "SetPushedTexture",
    "RegisterForClicks", "RegisterEvent", "UnregisterEvent", "StartMoving", "StopMovingOrSizing", "StartSizing",
    "HighlightText", "SetOwner", "AddLine", "SetTexCoord", "SetWordWrap" }) do
    methods[method] = function() end
end
function methods:SetScript(key, handler) self.scripts[key] = handler end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(scale) self.scale = scale end
function methods:GetScale() return self.scale or 1 end
function methods:SetParent(parent) self.parent = parent end
function methods:SetCursorPosition(position) self.cursor = position end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:GetPoint() return unpack(self.points[1] or { "CENTER", UIParent, "CENTER", 0, 0 }) end
function methods:ClearAllPoints() self.points = {} end
function methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function methods:Show() self.shown = true end
function methods:Hide()
    local changed = self.shown
    self.shown = false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetText(text)
    self.text = text or ""
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
end
function methods:GetText() return self.text end
function methods:SetFocus()
    if focusedBox and focusedBox ~= self then focusedBox:ClearFocus() end
    focusedBox, self.focus = self, true
end
function methods:ClearFocus()
    local focused = self.focus
    self.focus = false
    if focusedBox == self then focusedBox = nil end
    if focused and self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked end
function methods:SetScrollChild(child) self.child = child end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetContentHeight() return math.max(20, #self.text / math.max(1, self.width / 8) * 20) end
function methods:GetStringHeight() return self:GetContentHeight() end
function methods:CreateFontString() return New("FontString", nil, self) end
function methods:CreateTexture() return New("Texture", nil, self) end
function methods:GetFrameLevel() return 1 end
function methods:GetEffectiveScale() return 1 end
function methods:GetCenter() return 500, 500 end
function methods:Click() assert(self.enabled); self.scripts.OnClick(self, "LeftButton") end
function methods:Type(text)
    self.text = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, true) end
end
_G.CreateFrame = New
_G.UIParent = New("Frame", "UIParent")
UIParent:SetSize(1920, 1080)
_G.Minimap = New("Frame", "Minimap")
_G.GameTooltip = New("Frame", "GameTooltip")
_G.UISpecialFrames = {}
_G.StaticPopupDialogs = {}
_G.SlashCmdList = {}
_G.CANCEL = "Cancel"
_G.tinsert = table.insert
_G.time = function() return 100 end
_G.UnitName = function() return "Adventurer" end
_G.GetRealmName = function() return "Forever" end
_G.IsControlKeyDown = function() return false end
_G.IsShiftKeyDown = function() return false end
_G.C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local popup
_G.StaticPopup_Show = function(which, text, _, data) popup = { which = which, data = data } end
local function Tick()
    local pending = timers; timers = {}
    for _, callback in ipairs(pending) do callback() end
end
local function Load()
    local NS = {}
    for _, file in ipairs({ "Data", "Markdown", "Layout", "LivePreview", "UI", "Core" }) do
        assert(loadfile("AzerothNotes/" .. file .. ".lua"))("AzerothNotes", NS)
    end
    local loader = frames[#frames]
    loader.scripts.OnEvent(loader, "ADDON_LOADED", "AzerothNotes")
    return NS, loader
end
local NS, loader = Load()
local U, A = NS.UI, NS.App
assert(A.db and U.minimap and U.minimap:IsShown())
A:Toggle(); Tick()
assert(U.frame:IsShown() and U.live.scroll:IsShown() and not U.editScroll:IsShown())
assert(U.live.rows[1].html:GetText():find("<h1>", 1, true))
UIParent:SetSize(800, 600)
loader.scripts.OnEvent(loader, "DISPLAY_SIZE_CHANGED"); Tick()
assert(U.frame:GetWidth() * U.frame:GetScale() <= 800 * 0.92 + 0.01)
assert(U.frame:GetHeight() * U.frame:GetScale() <= 600 * 0.90 + 0.01)
UIParent:SetSize(1920, 1080)
loader.scripts.OnEvent(loader, "UI_SCALE_CHANGED"); Tick()
local welcomeID = U.selected
U:New("A place"); Tick()
U:SetView("source")
local firstID = U.selected
U.title:ClearFocus()
U.editor:Type("# My discovery\n\nA **quiet** forest. [[Second page]]")
U.tags:SetFocus(); U.tags:Type("forest, travel"); U.tags:ClearFocus(); Tick()
assert(A.db.notes[firstID].body:find("forest", 1, true))
assert(A.db.notes[firstID].tags[1] == "forest")
U:SetView("live")
assert(U.live.scroll:IsShown() and not U.editScroll:IsShown())
U.live.rows[3]:Click()
assert(U.live.active == 3 and U.live.editor:GetText():find("**quiet**", 1, true))
assert(not U.live.rows[3].html:IsShown() and U.live.rows[1].html:IsShown())
U.live.editor:Type("A **quiet** forest. [[Second page]]\n\nA fresh thought.")
assert(A.db.notes[firstID].body:find("A fresh thought.", 1, true))
U.live.rows[1]:Click()
U.live.editor:Type("# A much longer discovery heading")
local paragraphRow
for _, row in ipairs(U.live.rows) do
    if row:IsShown() and row.html:GetText():find("quiet", 1, true) then paragraphRow = row; break end
end
assert(paragraphRow)
paragraphRow:Click()
assert(U.live.editor:GetText():find("quiet", 1, true))
assert(A.db.notes[firstID].body:find("# A much longer discovery heading\n\nA **quiet**", 1, true))
U.live.editor:ClearFocus(); Tick()
assert(not U.live.active)
U.live:ActivateOffset(#A.db.notes[firstID].body)
U.live.editor:Type(U.live.editor:GetText() .. "\n\nFinal paragraph")
local editedBody = A.db.notes[firstID].body
assert(editedBody:sub(-15) == "Final paragraph")
U:SetView("source")
assert(U.editor:GetText() == editedBody and not U.live.active)
assert(U.live.blocks[#U.live.blocks].text == "Final paragraph")
U.mode:Click()
assert(U.readScroll:IsShown() and not U.editScroll:IsShown())
assert(U.reader:GetText():find('href="note:', 1, true))
U:OpenLink("Second page")
assert(popup.data == "Second page")
StaticPopupDialogs[popup.which].OnAccept(nil, popup.data); Tick()
local secondID = U.selected
assert(secondID ~= firstID and A.db.notes[secondID].title == "Second page")
U.live:ActivateOffset(1)
U.live.editor:Type("A second page's private words")
U.live.editor:ClearFocus()
U:Select(firstID, true); Tick()
assert(A.db.notes[firstID].body == editedBody)
assert(A.db.notes[secondID].body == "A second page's private words")
U:Select(secondID, false)
U.title:ClearFocus()
U.title:SetFocus(); U.title:Type("A place"); U.title:ClearFocus()
assert(A.db.notes[secondID].title == "Second page" and U.title:GetText() == "Second page")
U.back:Click()
assert(U.selected == secondID)
U:Select(firstID, false)
U.search:Type("#forest")
assert(U.rows[1].noteID == firstID and not U.rows[2]:IsShown())
U.remove:Click()
assert(A.db.notes[firstID].deleted and not U.selected)
U.trashButton:Click()
assert(U.trash and U.rows[1].noteID == firstID)
U.rows[1]:Click()
assert(U.remove:GetText() == "Restore" and not U.title.enabled)
U.remove:Click()
assert(not A.db.notes[firstID].deleted and U.selected == firstID)
SlashCmdList.AZEROTHNOTES("minimap")
assert(not U.minimap:IsShown() and not A.db.ui.minimap)
SlashCmdList.AZEROTHNOTES("minimap")
assert(U.minimap:IsShown() and A.db.ui.minimap)
U:Toggle()
assert(not U.frame:IsShown())
loader.scripts.OnEvent(loader, "PLAYER_LOGOUT")
local saved = AzerothNotesDB
local reloaded = Load()
assert(reloaded.App.db == saved and #NS.Data.List(saved, "") == 3)
assert(saved.notes[firstID].tags[1] == "forest" and saved.notes[secondID].title == "Second page")
assert(reloaded.UI.minimap:IsShown())
assert(saved.notes[welcomeID])
print("UI flow: loading, editor/reader, link creation, history, tags, search, trash, icon and reload passed.")
