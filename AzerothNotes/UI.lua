local _, NS = ...
local U, D = {}, NS.Data
NS.UI = U
local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local function Plain(s) return (tostring(s or ""):gsub("|", "||")) end
local function Label(parent, text, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    label:SetText(text)
    return label
end
local function Button(parent, text, width, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(text)
    button:SetScript("OnClick", click)
    return button
end
local function Input(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetSize(width, 24)
    box:SetMaxLetters(160)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return box
end
local function Scroll(parent, name)
    return CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
end

function U:Note()
    return self.selected and NS.App.db.notes[self.selected]
end

function U:Status(text)
    if self.status then self.status:SetText(text) end
end

function U:Flush()
    local note = self:Note()
    if not note or not self.frame or self.loading or note.deleted then return end
    local oldTitle = note.title
    local ok, err = D.Update(NS.App.db, note, "title", self.title:GetText(), time(), NS.App:Author())
    if not ok then self:Status(err); self.title:SetText(note.title) end
    if ok and note.title ~= oldTitle then self:Status("Page renamed. Update any [[links]] that used its old title.") end
    D.Update(NS.App.db, note, "tags", D.Tags(self.tags:GetText()), time(), NS.App:Author())
end

function U:SaveGeometry()
    local f = self.frame
    if not f then return end
    local point, _, relative, x, y = f:GetPoint(1)
    local ui = NS.App.db.ui
    ui.point, ui.relative, ui.x, ui.y = point, relative, x, y
    ui.width, ui.height = f:GetWidth(), f:GetHeight()
end

function U:QueueList()
    if self.listPending then return end
    self.listPending = true
    C_Timer.After(0.25, function()
        self.listPending = nil
        if self.frame and self.frame:IsShown() then self:RefreshList() end
    end)
end

function U:RefreshList()
    if not self.frame then return end
    local list = D.List(NS.App.db, self.search:GetText(), self.trash)
    self.rows = self.rows or {}
    local width = math.max(140, self.listScroll:GetWidth() - 4)
    self.listChild:SetWidth(width)
    for index, note in ipairs(list) do
        local row = self.rows[index]
        if not row then
            row = CreateFrame("Button", nil, self.listChild)
            row:SetHeight(44)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            row.selected = row:CreateTexture(nil, "BACKGROUND")
            row.selected:SetAllPoints()
            row.selected:SetColorTexture(0.65, 0.48, 0.16, 0.25)
            row.title = Label(row, "", "GameFontNormal")
            row.title:SetPoint("TOPLEFT", 8, -7)
            row.title:SetPoint("TOPRIGHT", -8, -7)
            row.title:SetJustifyH("LEFT")
            row.tags = Label(row, "", "GameFontDisableSmall")
            row.tags:SetPoint("TOPLEFT", 8, -25)
            row.tags:SetPoint("TOPRIGHT", -8, -25)
            row.tags:SetJustifyH("LEFT")
            row:SetScript("OnClick", function(button) U:Select(button.noteID, true) end)
            self.rows[index] = row
        end
        row.noteID = note.id
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 45)
        row:SetWidth(width)
        row.title:SetText(Plain(note.title))
        local tags = #note.tags > 0 and ("#" .. table.concat(note.tags, "  #")) or "Untagged"
        row.tags:SetText(Plain(tags))
        row.selected:SetShown(self.selected == note.id)
        row:Show()
    end
    for index = #list + 1, #self.rows do self.rows[index]:Hide() end
    self.listChild:SetHeight(math.max(1, #list * 45))
    self.count:SetText((self.trash and "Trash" or "Notes") .. "  ·  " .. #list)
    self.emptyList:SetShown(#list == 0)
    self.emptyList:SetText(self.trash and "Trash is empty." or "No matching notes.")
end

function U:Select(id, remember)
    self:Flush()
    if remember and self.selected and self.selected ~= id then
        self.history = self.history or {}
        self.history[#self.history + 1] = self.selected
    end
    self.selected = id
    NS.App.db.ui.selected = id
    self:ShowNote()
end

function U:ShowNote()
    local note = self:Note()
    self.loading = true
    self.title:SetText(note and note.title or "")
    self.tags:SetText(note and table.concat(note.tags, ", ") or "")
    self.editor:SetText(note and note.body or "")
    self.loading = nil
    self.editor:ClearFocus()
    self.title:ClearFocus()
    self.tags:ClearFocus()
    self:ResizeEditor()
    self.editScroll:SetVerticalScroll(0)
    self.readScroll:SetVerticalScroll(0)
    self:RefreshMode()
    self:RefreshList()
    self:Status(note and (note.deleted and "In Trash. Restore this page to edit it." or "Changes reach disk on /reload or logout.") or "Choose a page, or begin a new note.")
end

function U:Render()
    local note = self:Note()
    local width = math.max(80, self.readScroll:GetWidth() - 16)
    self.reader:SetWidth(width)
    self.reader:SetText(NS.Markdown.Render(note and note.body or ""))
    self.reader:SetHeight(math.max(self.readScroll:GetHeight(), self.reader:GetContentHeight() + 30))
end

function U:ResizeEditor()
    if not self.frame then return end
    local width = math.max(80, self.editScroll:GetWidth() - 12)
    self.editor:SetWidth(width)
    self.measure:SetWidth(width)
    self.measure:SetText(Plain(self.editor:GetText()) .. "\n ")
    self.editor:SetHeight(math.max(self.editScroll:GetHeight(), self.measure:GetStringHeight() + 36))
end

function U:RefreshMode()
    local note = self:Note()
    local exists = note ~= nil
    local editable = exists and not note.deleted
    local read = self.reading or not editable
    self.title:SetEnabled(editable)
    self.tags:SetEnabled(editable)
    self.editScroll:SetShown(exists and not read)
    self.readScroll:SetShown(exists and read)
    self.emptyPage:SetShown(not exists)
    self.mode:SetText(read and "Edit" or "Read")
    self.mode:SetEnabled(editable)
    self.remove:SetEnabled(exists)
    self.remove:SetText(note and note.deleted and "Restore" or "Trash")
    self.back:SetEnabled(self.history and #self.history > 0)
    self.parchment:SetShown(read)
    self.editorBackground:SetShown(not read)
    if read then self:Render() end
end

function U:New(title)
    self:Flush()
    self.trash = false
    self.trashButton:SetText("Trash")
    self.search:SetText("")
    local note = D.Create(NS.App.db, title or "Untitled note", "", time(), NS.App:Author())
    self.reading = false
    NS.App.db.ui.reading = false
    self:Select(note.id, true)
    self.title:SetFocus()
    self.title:HighlightText()
end

function U:OpenLink(target)
    local note = D.Find(NS.App.db, target)
    if note then
        self.trash = false
        self.trashButton:SetText("Trash")
        self:Select(note.id, true)
    else
        StaticPopup_Show("AZEROTHNOTES_CREATE_LINK", Plain(target), nil, target)
    end
end

StaticPopupDialogs.AZEROTHNOTES_CREATE_LINK = {
    text = 'Create a page named "%s"?', button1 = "Create", button2 = CANCEL,
    OnAccept = function(_, target) U:New(target) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

function U:Layout()
    local collapsed = NS.App.db.ui.collapsed
    self.sidebar:SetShown(not collapsed)
    self.page:ClearAllPoints()
    self.page:SetPoint("TOPLEFT", self.frame, "TOPLEFT", collapsed and 18 or 250, -106)
    self.page:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -32, 53)
    self.title:ClearAllPoints()
    self.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", collapsed and 24 or 256, -72)
    self.title:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -40, -72)
    self.tags:ClearAllPoints()
    self.tags:SetPoint("BOTTOMLEFT", self.page, "BOTTOMLEFT", 44, -30)
    self.tags:SetPoint("BOTTOMRIGHT", self.page, "BOTTOMRIGHT", -4, -30)
    if not self.layoutPending then
        self.layoutPending = true
        C_Timer.After(0, function()
            self.layoutPending = nil
            self:ResizeEditor()
            if self.reading or (self:Note() and self:Note().deleted) then self:Render() end
            self:RefreshList()
        end)
    end
end

function U:Build()
    local db = NS.App.db
    local ok, frame = pcall(CreateFrame, "Frame", "AzerothNotesFrame", UIParent, "PortraitFrameTemplate")
    if not ok then frame = CreateFrame("Frame", "AzerothNotesFrame", UIParent, "BasicFrameTemplateWithInset") end
    self.frame = frame
    frame:Hide()
    if frame.SetTitle then frame:SetTitle("Azeroth Notes")
    elseif frame.TitleText then frame.TitleText:SetText("Azeroth Notes") end
    if frame.SetPortraitToAsset then frame:SetPortraitToAsset(ICON) end
    frame:SetSize(math.max(680, db.ui.width or 900), math.max(430, db.ui.height or 600))
    frame:SetPoint(db.ui.point or "CENTER", UIParent, db.ui.relative or "CENTER", db.ui.x or 0, db.ui.y or 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing(); U:SaveGeometry() end)
    frame:SetScript("OnHide", function() U:Flush(); U:SaveGeometry() end)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(680, 430, 1500, 1100) else frame:SetMinResize(680, 430) end
    tinsert(UISpecialFrames, "AzerothNotesFrame")
    if not frame.CloseButton then
        frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.CloseButton:SetPoint("TOPRIGHT", -3, -3)
    end
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)

    self.back = Button(frame, "Back", 55, function()
        local id = table.remove(U.history or {})
        if id then U:Select(id, false) end
    end)
    self.back:SetPoint("TOPLEFT", 72, -38)
    local fold = Button(frame, "Notes", 65, function()
        db.ui.collapsed = not db.ui.collapsed; U:Layout()
    end)
    fold:SetPoint("LEFT", self.back, "RIGHT", 4, 0)
    local new = Button(frame, "New", 60, function() U:New() end)
    new:SetPoint("LEFT", fold, "RIGHT", 4, 0)
    self.trashButton = Button(frame, "Trash", 65, function()
        U:Flush(); U.trash = not U.trash
        U.trashButton:SetText(U.trash and "All notes" or "Trash")
        U:Select(nil, true)
    end)
    self.trashButton:SetPoint("LEFT", new, "RIGHT", 4, 0)
    self.remove = Button(frame, "Trash", 75, function()
        U:Flush()
        local note = U:Note()
        if not note then return end
        local restoring = note.deleted
        D.SetDeleted(db, note, not restoring, time())
        if restoring then
            U.trash = false; U.trashButton:SetText("Trash"); U:ShowNote()
        else U:Select(nil, false) end
    end)
    self.remove:SetPoint("TOPRIGHT", -34, -38)
    self.mode = Button(frame, "Edit", 65, function()
        U:Flush(); U.reading = not U.reading; db.ui.reading = U.reading
        U.editor:ClearFocus(); U:RefreshMode()
    end)
    self.mode:SetPoint("RIGHT", self.remove, "LEFT", -4, 0)

    self.sidebar = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    self.sidebar:SetPoint("TOPLEFT", 16, -71)
    self.sidebar:SetPoint("BOTTOMLEFT", 16, 53)
    self.sidebar:SetWidth(220)
    self.search = Input(self.sidebar, 185)
    self.search:SetPoint("TOPLEFT", 12, -10)
    self.search:SetMaxLetters(200)
    local searchHint = Label(self.sidebar, "Search notes or #tag", "GameFontDisableSmall")
    searchHint:SetPoint("TOPLEFT", 12, -37)
    self.search:SetScript("OnTextChanged", function() U:RefreshList() end)
    self.listScroll = Scroll(self.sidebar, "AzerothNotesListScroll")
    self.listScroll:SetPoint("TOPLEFT", 4, -59)
    self.listScroll:SetPoint("BOTTOMRIGHT", -27, 26)
    self.listChild = CreateFrame("Frame", nil, self.listScroll)
    self.listChild:SetSize(180, 1)
    self.listScroll:SetScrollChild(self.listChild)
    self.count = Label(self.sidebar, "")
    self.count:SetPoint("BOTTOMLEFT", 10, 8)
    self.emptyList = Label(self.sidebar, "No matching notes.", "GameFontDisableSmall")
    self.emptyList:SetPoint("TOPLEFT", 12, -75)

    self.title = Input(frame, 400)
    self.title:SetFontObject("GameFontHighlightLarge")
    self.title:SetScript("OnEditFocusLost", function() U:Flush(); U:QueueList() end)
    self.page = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    self.parchment = self.page:CreateTexture(nil, "ARTWORK")
    self.parchment:SetPoint("TOPLEFT", 2, -2)
    self.parchment:SetPoint("BOTTOMRIGHT", -2, 2)
    self.parchment:SetTexture("Interface\\QuestFrame\\QuestBG")
    self.parchment:SetVertexColor(0.94, 0.89, 0.75)
    self.editorBackground = self.page:CreateTexture(nil, "ARTWORK")
    self.editorBackground:SetPoint("TOPLEFT", 2, -2)
    self.editorBackground:SetPoint("BOTTOMRIGHT", -2, 2)
    self.editorBackground:SetColorTexture(0.075, 0.065, 0.05, 1)

    self.editScroll = Scroll(self.page, "AzerothNotesEditScroll")
    self.editScroll:SetPoint("TOPLEFT", 14, -14)
    self.editScroll:SetPoint("BOTTOMRIGHT", -30, 14)
    self.editor = CreateFrame("EditBox", nil, self.editScroll)
    self.editor:SetMultiLine(true)
    self.editor:SetAutoFocus(false)
    self.editor:SetMaxLetters(100000)
    self.editor:SetFont("Fonts\\ARIALN.TTF", 16, "")
    self.editor:SetTextColor(0.92, 0.87, 0.75)
    self.editor:SetSpacing(4)
    self.editor:SetTextInsets(2, 2, 2, 2)
    self.editor:SetSize(400, 400)
    self.editScroll:SetScrollChild(self.editor)
    self.measure = frame:CreateFontString(nil, "OVERLAY")
    self.measure:SetFont("Fonts\\ARIALN.TTF", 16, "")
    self.measure:SetSpacing(4)
    self.measure:Hide()
    self.editor:SetScript("OnTextChanged", function(box, user)
        if U.loading or not user then return end
        local note = U:Note()
        if note and not note.deleted then
            D.Update(db, note, "body", box:GetText(), time(), NS.App:Author())
            U:ResizeEditor(); U:QueueList()
        end
    end)
    self.editor:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local scroll = U.editScroll:GetVerticalScroll()
        y = -y
        local visible = U.editScroll:GetHeight()
        if y < scroll then U.editScroll:SetVerticalScroll(math.max(0, y))
        elseif y + height > scroll + visible then U.editScroll:SetVerticalScroll(y + height - visible) end
    end)
    self.editor:SetScript("OnEscapePressed", function(box) box:ClearFocus(); frame:Hide() end)
    self.editor:SetScript("OnKeyDown", function(box, key)
        if key == "S" and IsControlKeyDown() then U:Flush(); box:ClearFocus() end
    end)

    self.readScroll = Scroll(self.page, "AzerothNotesReadScroll")
    self.readScroll:SetPoint("TOPLEFT", 18, -18)
    self.readScroll:SetPoint("BOTTOMRIGHT", -30, 18)
    self.reader = CreateFrame("SimpleHTML", nil, self.readScroll)
    self.reader:SetSize(400, 400)
    for _, tag in ipairs({ "p", "h1", "h2", "h3" }) do
        local size = ({ p = 16, h1 = 25, h2 = 21, h3 = 18 })[tag]
        self.reader:SetFont(tag, "Fonts\\FRIZQT__.TTF", size, "")
        self.reader:SetTextColor(tag, 0.22, 0.16, 0.10)
        self.reader:SetSpacing(tag, 5)
        self.reader:SetShadowOffset(tag, 0, 0)
    end
    self.reader:SetHyperlinksEnabled(true)
    self.reader:SetScript("OnHyperlinkClick", function(_, link)
        local hex = link:match("^note:(%x+)$")
        local title = hex and NS.Markdown.Unhex(hex)
        if title then U:OpenLink(title) end
    end)
    self.reader:SetScript("OnHyperlinkEnter", function(_, link)
        local hex = link:match("^note:(%x+)$")
        local title = hex and NS.Markdown.Unhex(hex)
        if not title then return end
        GameTooltip:SetOwner(U.reader, "ANCHOR_CURSOR")
        GameTooltip:SetText(Plain(title))
        GameTooltip:AddLine(D.Find(db, title) and "Open this page" or "Create this page", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    self.reader:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
    self.readScroll:SetScrollChild(self.reader)
    self.emptyPage = Label(self.page, "Your next adventure begins on a blank page.", "GameFontNormalLarge")
    self.emptyPage:SetPoint("CENTER")
    self.emptyPage:SetWidth(300)
    self.tags = Input(frame, 300)
    self.tags:SetMaxLetters(500)
    self.tags:SetScript("OnEditFocusLost", function() U:Flush(); U:QueueList() end)
    local tagsLabel = Label(frame, "Tags:")
    tagsLabel:SetPoint("BOTTOMLEFT", self.page, "BOTTOMLEFT", 0, -24)

    self.status = Label(frame, "", "GameFontDisableSmall")
    self.status:SetPoint("BOTTOMLEFT", 24, 14)
    self.status:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -180, 14)
    self.status:SetJustifyH("LEFT")
    local minimap = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    minimap:SetSize(24, 24)
    minimap:SetPoint("BOTTOMRIGHT", -129, 9)
    minimap:SetChecked(db.ui.minimap == true)
    local minimapLabel = Label(minimap, "Minimap book")
    minimapLabel:SetPoint("LEFT", minimap, "RIGHT", 0, 0)
    minimap:SetScript("OnClick", function(box)
        db.ui.minimap = box:GetChecked() and true or false
        U:SetupMinimap()
    end)
    self.minimapCheck = minimap
    local resize = CreateFrame("Button", nil, frame)
    resize:SetSize(18, 18)
    resize:SetPoint("BOTTOMRIGHT", -3, 3)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end end)
    resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); U:SaveGeometry() end)
    frame:SetScript("OnSizeChanged", function() U:Layout() end)
    self:Layout()
    self.selected = db.ui.selected
    self.reading = db.ui.reading ~= false
    self:ShowNote()
end

function U:Toggle()
    if not self.frame then self:Build() end
    if self.frame:IsShown() then self.frame:Hide()
    else self.frame:Show(); self:RefreshList(); self:RefreshMode() end
end

function U:SetupMinimap()
    local db = NS.App.db
    local function Position()
        local radians = math.rad(db.ui.minimapAngle)
        local radius = math.max(Minimap:GetWidth(), Minimap:GetHeight()) / 2 + 8
        U.minimap:ClearAllPoints()
        U.minimap:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
    end
    if not self.minimap then
        local button = CreateFrame("Button", "AzerothNotesMinimapButton", Minimap)
        self.minimap = button
        button:SetSize(32, 32)
        button:SetFrameStrata("MEDIUM")
        button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
        button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        local icon = button:CreateTexture(nil, "BACKGROUND")
        icon:SetTexture(ICON)
        icon:SetSize(20, 20)
        icon:SetPoint("CENTER")
        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        border:SetSize(54, 54)
        border:SetPoint("TOPLEFT")
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(_, mouse)
            if mouse == "RightButton" then
                db.ui.minimap = false; U:SetupMinimap()
            else NS.App:Toggle() end
        end)
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", function(b)
            b:SetScript("OnUpdate", function()
                local x, y = GetCursorPosition()
                local scale = Minimap:GetEffectiveScale()
                local cx, cy = Minimap:GetCenter()
                db.ui.minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
                Position()
            end)
        end)
        button:SetScript("OnDragStop", function(b) b:SetScript("OnUpdate", nil) end)
        button:SetScript("OnEnter", function(b)
            GameTooltip:SetOwner(b, "ANCHOR_LEFT")
            GameTooltip:SetText("Azeroth Notes")
            GameTooltip:AddLine("Click to open your journal. Drag to move.", 1, 0.82, 0)
            GameTooltip:AddLine("Right-click to hide. /anotes minimap restores it.", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    Position()
    self.minimap:SetShown(db.ui.minimap == true)
    if self.minimapCheck then self.minimapCheck:SetChecked(db.ui.minimap == true) end
end
