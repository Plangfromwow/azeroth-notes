local _, NS = ...
local F, D = {}, NS.Data
NS.Folders = F
local UNFILED = "_unfiled"
local function Plain(text) return (tostring(text or ""):gsub("|", "||")) end

function F.Create(owner)
    local self = setmetatable({owner = owner, headers = {}}, {__index = F})
    local button = CreateFrame("Button", nil, owner.sidebar, "UIPanelButtonTemplate")
    button:SetSize(92, 22)
    button:SetPoint("BOTTOMRIGHT", -7, 2)
    button:SetText("New folder")
    button:SetScript("OnClick", function() self:Prompt() end)
    self.newButton = button
    owner.count:SetWidth(65)
    owner.count:SetJustifyH("LEFT")
    owner.count:SetWordWrap(false)
    StaticPopupDialogs.AZEROTHNOTES_REMOVE_FOLDER = {
        text = 'Remove folder "%s"? Its notes will move to Unfiled.',
        button1 = "Remove folder", button2 = CANCEL,
        OnAccept = function(_, id)
            owner:Flush()
            D.RemoveFolder(NS.App.db, id, time())
            owner:RefreshList()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    return self
end

function F:Prompt(folderID, noteID)
    self.owner:Flush()
    if not self.dialog then
        local dialog = CreateFrame("Frame", "AzerothNotesFolderDialog", self.owner.frame, "BasicFrameTemplateWithInset")
        self.dialog = dialog
        dialog:SetSize(340, 154)
        dialog:SetPoint("CENTER", self.owner.frame, "CENTER", 0, 0)
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetClampedToScreen(true)
        self.caption = dialog.TitleText or dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if not dialog.TitleText then self.caption:SetPoint("TOP", 0, -8) end
        self.entry = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        self.entry:SetSize(290, 24)
        self.entry:SetPoint("TOPLEFT", 24, -42)
        self.entry:SetAutoFocus(false)
        self.entry:SetMaxLetters(80)
        self.error = dialog:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
        self.error:SetPoint("TOPLEFT", 20, -76)
        self.error:SetWidth(300)
        local save = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        self.saveButton = save
        save:SetSize(100, 24)
        save:SetPoint("BOTTOMRIGHT", -20, 15)
        save:SetText("Save")
        save:SetScript("OnClick", function() self:SavePrompt() end)
        local cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        cancel:SetSize(100, 24)
        cancel:SetPoint("RIGHT", save, "LEFT", -8, 0)
        cancel:SetText(CANCEL)
        cancel:SetScript("OnClick", function() dialog:Hide() end)
        self.entry:SetScript("OnEnterPressed", function() self:SavePrompt() end)
        self.entry:SetScript("OnEscapePressed", function() dialog:Hide() end)
        dialog:SetScript("OnHide", function() self.entry:ClearFocus() end)
        tinsert(UISpecialFrames, "AzerothNotesFolderDialog")
    end
    self.promptFolderID, self.promptNoteID = folderID, noteID
    local folder = folderID and NS.App.db.folders[folderID]
    self.caption:SetText(folder and "Rename folder" or "New folder")
    self.entry:SetText(folder and folder.name or "")
    self.error:SetText("")
    self.dialog:Show()
    self.entry:SetFocus()
    self.entry:HighlightText()
end

function F:SavePrompt()
    local db = NS.App.db
    local folder, err
    if self.promptFolderID then
        folder, err = D.RenameFolder(db, self.promptFolderID, self.entry:GetText(), time())
    else folder, err = D.CreateFolder(db, self.entry:GetText(), time()) end
    if not folder then self.error:SetText(err); return end
    db.ui.folderCollapsed[folder.id] = nil
    if self.promptNoteID then self:Move(self.promptNoteID, folder.id) end
    self.dialog:Hide()
    self.owner:RefreshList()
end

function F:Move(noteID, folderID)
    self.owner:Flush()
    local ok, err = D.MoveNote(NS.App.db, NS.App.db.notes[noteID], folderID, time(), NS.App:Author())
    if ok then
        NS.App.db.ui.folderCollapsed[folderID or UNFILED] = nil
        local folder = folderID and NS.App.db.folders[folderID]
        self.owner:Status("Note moved to " .. Plain(folder and folder.name or "Unfiled") .. ".")
    else self.owner:Status(err) end
    self.owner:RefreshList()
end

function F:NoteMenu(row)
    local id = row.noteID
    local note = NS.App.db.notes[id]
    if not note or note.deleted then return end
    self.owner:Flush()
    MenuUtil.CreateContextMenu(row, function(_, root)
        root:CreateTitle("Move to folder")
        root:CreateRadio("Unfiled", function() return note.folderID == nil end, function() self:Move(id) end)
        for _, folder in ipairs(D.FolderList(NS.App.db)) do
            local folderID = folder.id
            root:CreateRadio(Plain(folder.name), function() return note.folderID == folderID end,
                function() self:Move(id, folderID) end)
        end
        root:CreateDivider()
        root:CreateButton("New folder...", function() self:Prompt(nil, id) end)
    end)
end

function F:FolderMenu(header)
    if header.key == UNFILED then return end
    local folder = NS.App.db.folders[header.key]
    if not folder then return end
    local id = folder.id
    MenuUtil.CreateContextMenu(header, function(_, root)
        root:CreateTitle(Plain(folder.name))
        root:CreateButton("Rename folder", function() self:Prompt(id) end)
        root:CreateButton("Remove folder (keep notes)", function()
            StaticPopup_Show("AZEROTHNOTES_REMOVE_FOLDER", Plain(folder.name), nil, id)
        end)
    end)
end

function F:BeginDrag(noteID)
    local note = NS.App.db.notes[noteID]
    if self.owner.trash or not note or note.deleted then return end
    self.owner:Flush()
    self.draggedID = noteID
    self.owner:Status("Drag onto a folder, then release to move this note.")
end

function F:EndDrag(row)
    local id = self.draggedID
    self.draggedID = nil
    if not id then return end
    row.suppressClick = true
    C_Timer.After(0, function() row.suppressClick = nil end)
    for key, header in pairs(self.headers) do
        if header:IsShown() and MouseIsOver(header) then
            self:Move(id, key ~= UNFILED and key or nil)
            return
        end
    end
    self.owner:Status("Move cancelled. Drop onto a folder heading to move a note.")
    self.owner:RefreshList()
end

function F:Arrange(notes, query, trash, width)
    for _, header in pairs(self.headers) do header:Hide() end
    self.newButton:SetEnabled(not trash)
    local visible, offsets, y = {}, {}, 0
    local function Add(note, indent)
        visible[#visible + 1] = note
        offsets[#offsets + 1] = {x = indent, y = y}
        y = y + 45
    end
    if trash then
        for _, note in ipairs(notes) do Add(note, 0) end
        return visible, offsets, y
    end
    local db, groups = NS.App.db, {{id = UNFILED, name = "Unfiled"}}
    for _, folder in ipairs(D.FolderList(db)) do groups[#groups + 1] = folder end
    local searching = D.Trim(query) ~= ""
    for _, group in ipairs(groups) do
        local members = {}
        for _, note in ipairs(notes) do
            if (note.folderID or UNFILED) == group.id then members[#members + 1] = note end
        end
        if not searching or #members > 0 then
            local header = self.headers[group.id]
            if not header then
                header = CreateFrame("Button", nil, self.owner.listChild)
                self.headers[group.id] = header
                header.key = group.id
                header:SetHeight(26)
                header:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                header.label = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                header.label:SetPoint("LEFT", 5, 0)
                header.label:SetPoint("RIGHT", -4, 0)
                header.label:SetJustifyH("LEFT")
                header.label:SetWordWrap(false)
                header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                header:SetScript("OnClick", function(button, mouse)
                    if mouse == "RightButton" then self:FolderMenu(button); return end
                    db.ui.folderCollapsed[button.key] = not db.ui.folderCollapsed[button.key]
                    self.owner:RefreshList()
                end)
            end
            local collapsed = not searching and db.ui.folderCollapsed[group.id]
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", 0, -y)
            header:SetWidth(width)
            header.label:SetText((collapsed and "+ " or "- ") .. Plain(group.name) .. " (" .. #members .. ")")
            header:Show()
            y = y + 27
            if not collapsed then for _, note in ipairs(members) do Add(note, 12) end end
        end
    end
    return visible, offsets, y
end
