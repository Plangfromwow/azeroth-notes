local _, NS = ...
local L = {}
NS.LivePreview = L

function L.Blocks(source)
    local blocks, paragraph = {}, nil
    local function Flush()
        if paragraph then
            paragraph.text = source:sub(paragraph.first, paragraph.last)
            blocks[#blocks + 1] = paragraph
            paragraph = nil
        end
    end
    local first = 1
    repeat
        local newline = source:find("\n", first, true)
        local last = newline and newline - 1 or #source
        local text = source:sub(first, last)
        local blank = text:match("^%s*$") ~= nil
        local special = text:match("^#+%s") or text:match("^%s*[-*+]%s")
            or text:match("^%s*%d+[.)]%s") or text:match("^>")
        if blank or special then
            Flush()
            blocks[#blocks + 1] = { first = first, last = last, text = text, blank = blank }
        else
            if not paragraph then paragraph = { first = first } end
            paragraph.last = last
        end
        if not newline then break end
        first = newline + 1
    until false
    Flush()
    return blocks
end

function L.Replace(source, block, text)
    return source:sub(1, block.first - 1) .. text .. source:sub(block.last + 1)
end

function L.Create(owner)
    local self = setmetatable({ owner = owner, rows = {}, generation = 0 }, { __index = L })
    local scroll = CreateFrame("ScrollFrame", "AzerothNotesLiveScroll", owner.page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 22, -20)
    scroll:SetPoint("BOTTOMRIGHT", -34, 20)
    self.scroll = scroll
    self.content = CreateFrame("Frame", nil, scroll)
    self.content:SetSize(400, 1)
    scroll:SetScrollChild(self.content)
    local editor = CreateFrame("EditBox", nil, self.content)
    self.editor = editor
    editor:SetMultiLine(true)
    editor:SetAutoFocus(false)
    editor:SetMaxLetters(100000)
    editor:SetSpacing(4)
    editor:SetTextInsets(4, 4, 4, 4)
    editor:SetTextColor(0.22, 0.16, 0.10)
    editor:Hide()
    self.measure = self.content:CreateFontString(nil, "OVERLAY")
    self.measure:SetSpacing(4)
    self.measure:Hide()
    editor:SetScript("OnTextChanged", function(box, user)
        NS.Editor.Changed(box, user)
        if user and self.active and not self.settingText then self:Save(); self:Layout() end
    end)
    editor:SetScript("OnEditFocusLost", function()
        if self.finishing or not self.active then return end
        local generation = self.generation
        C_Timer.After(0, function()
            if self.active and self.generation == generation then self:Finish(true) end
        end)
    end)
    editor:SetScript("OnEscapePressed", function() self:Finish(true) end)
    editor:SetScript("OnTabPressed", function()
        if not self.active then return end
        local index = self.active + (IsShiftKeyDown() and -1 or 1)
        local block = self.blocks[index]
        if block then self:ActivateOffset(self:UpdatedOffset(block.first))
        else self:Finish(true) end
    end)
    editor:SetScript("OnKeyDown", function(box, key)
        NS.Editor.KeyDown(box, key)
        if key == "S" and IsControlKeyDown() then self:Finish(true) end
    end)
    editor:SetScript("OnCursorChanged", function(_, _, y, _, height)
        if not self.active then return end
        local top = (self.rows[self.active].offset or 0) - y
        local current = scroll:GetVerticalScroll()
        if top < current then scroll:SetVerticalScroll(math.max(0, top))
        elseif top + height > current + scroll:GetHeight() then
            scroll:SetVerticalScroll(top + height - scroll:GetHeight())
        end
    end)
    return self
end

function L:Save()
    local note = self.owner:Note()
    if not self.active or not note or note.deleted or note.id ~= self.noteID then return end
    local body = L.Replace(self.snapshot, self.blocks[self.active], self.editor:GetText())
    if #body > 100000 then
        self.settingText = true
        self.editor:SetText(self.lastText)
        self.settingText = nil
        self.owner:Status("This note has reached the 100,000-byte editing limit.")
        return
    end
    NS.Data.Update(NS.App.db, note, "body", body, time(), NS.App:Author())
    self.lastText = self.editor:GetText()
    self.owner:QueueList()
end

function L:UpdatedOffset(offset)
    if self.active then
        local block = self.blocks[self.active]
        if offset > block.last then offset = offset + #self.editor:GetText() - #block.text end
    end
    return offset
end

function L:Finish(rebuild)
    if not self.active then return end
    self:Save()
    self.active = nil
    self.generation = self.generation + 1
    self.finishing = true
    self.editor:ClearFocus()
    self.editor:Hide()
    self.finishing = nil
    if rebuild then self:Show(self.owner:Note()) end
end

function L:ActivateOffset(offset)
    if self.readOnly then return end
    self:Finish(false)
    self.owner.title:ClearFocus()
    self.owner.tags:ClearFocus()
    self.owner.editor:ClearFocus()
    local note = self.owner:Note()
    if not note or note.deleted then return end
    self:Show(note)
    local index = #self.blocks
    for i, block in ipairs(self.blocks) do
        if offset <= math.max(block.first, block.last) then index = i; break end
    end
    self.active = index
    self.generation = self.generation + 1
    local block = self.blocks[index]
    self.snapshot = note.body
    self.lastText = block.text
    self.editor:SetMaxLetters(math.max(1, 100000 - (#note.body - #block.text)))
    self.settingText = true
    self.editor:SetText(block.text)
    self.settingText = nil
    self.editor:SetParent(self.rows[index])
    self.editor:ClearAllPoints()
    self.editor:SetPoint("TOPLEFT", 0, 0)
    self.editor:Show()
    self:Layout()
    self.editor:SetFocus()
    self.editor:SetCursorPosition(#block.text)
    self.owner:Status("Live Preview · Tab: next block · Shift-Tab: previous · Escape: render · Ctrl-click: follow link")
end

function L:ToggleTask(position)
    local offset = self:UpdatedOffset(position)
    self:Finish(false)
    local note = self.owner:Note()
    if not note or note.deleted then return end
    local body = NS.Markdown.ToggleTask(note.body, offset)
    if not body then self:Show(note, self.readOnly); return end
    local scroll = self.scroll:GetVerticalScroll()
    NS.Data.Update(NS.App.db, note, "body", body, time(), NS.App:Author())
    self.owner:QueueList()
    self:Show(note, self.readOnly)
    self.scroll:SetVerticalScroll(scroll)
end

function L:Show(note, readOnly)
    self.readOnly = readOnly == true
    if self.active then self:Layout(); return end
    self.noteID = note and note.id
    self.blocks = L.Blocks(note and note.body or "")
    for index, block in ipairs(self.blocks) do
        local row = self.rows[index]
        if not row then
            row = CreateFrame("Button", nil, self.content)
            self.rows[index] = row
            row.highlight = row:CreateTexture(nil, "BACKGROUND")
            row.highlight:SetAllPoints()
            row.highlight:SetColorTexture(0.38, 0.26, 0.08, 0.10)
            row.html = CreateFrame("SimpleHTML", nil, row)
            row.html:SetPoint("TOPLEFT", 4, -4)
            row.html:SetHyperlinksEnabled(true)
            row.html:EnableMouse(true)
            local function Edit()
                if self.readOnly or IsControlKeyDown() then return end
                self:ActivateOffset(self:UpdatedOffset(row.first))
            end
            row:SetScript("OnClick", Edit)
            row.html:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then Edit() end end)
            row.html:SetScript("OnHyperlinkClick", function(_, link)
                if not self.readOnly and not IsControlKeyDown() then return end
                local hex = link:match("^note:(%x+)$")
                local title = hex and NS.Markdown.Unhex(hex)
                if title then self.owner:OpenLink(title) end
            end)
            row.html:SetScript("OnHyperlinkEnter", function()
                GameTooltip:SetOwner(row.html, "ANCHOR_CURSOR")
                GameTooltip:SetText(self.readOnly and "Click to follow this note link" or "Ctrl-click to follow this note link")
                GameTooltip:Show()
            end)
            row.html:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
            row.checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            row.checkbox:SetSize(24, 24)
            row.checkbox:SetPoint("TOPLEFT", 0, -1)
            row.checkbox:SetScript("OnClick", function()
                if row.taskOffset then self:ToggleTask(row.taskOffset) end
            end)
        end
        row.first = block.first
        local task = NS.Markdown.Task(block.text)
        row.task = task
        row.taskOffset = task and (block.first + task.position - 1)
        row.checkbox:SetChecked(task and task.checked or false)
        row.checkbox:SetEnabled(note ~= nil and not note.deleted)
        row.placeholder = note and note.body == "" and index == 1
        row.html:SetText(NS.Markdown.Render(row.placeholder and "*Click here to begin writing…*" or (task and task.text or block.text)))
        row:Show()
    end
    for i = #self.blocks + 1, #self.rows do self.rows[i]:Hide() end
    self:Layout()
end

function L:Layout()
    if not self.blocks then return end
    local width, y = math.max(80, self.scroll:GetWidth() - 16), 0
    local fontSize = self.owner.fontSize or 15
    self.content:SetWidth(width)
    self.editor:SetFont("Fonts\\ARIALN.TTF", fontSize, "")
    self.measure:SetFont("Fonts\\ARIALN.TTF", fontSize, "")
    for i, block in ipairs(self.blocks) do
        local row = self.rows[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetWidth(width)
        row.offset = y
        local height
        if i == self.active then
            self.editor:SetWidth(width)
            self.measure:SetWidth(width - 8)
            self.measure:SetText((self.editor:GetText():gsub("|", "||")) .. "\n ")
            height = math.max(28, self.measure:GetStringHeight() + 12)
            self.editor:SetHeight(height)
        else
            local inset = row.task and 28 or 4
            row.html:ClearAllPoints()
            row.html:SetPoint("TOPLEFT", inset, -4)
            row.html:SetWidth(width - inset - 4)
            for _, tag in ipairs({ "p", "h1", "h2", "h3" }) do
                local extra = ({ p = 0, h1 = 8, h2 = 5, h3 = 2 })[tag]
                row.html:SetFont(tag, "Fonts\\FRIZQT__.TTF", fontSize + extra, "")
                row.html:SetTextColor(tag, 0.22, 0.16, 0.10)
                row.html:SetSpacing(tag, 4)
                row.html:SetShadowOffset(tag, 0, 0)
            end
            height = block.blank and not row.placeholder and 16 or math.max(24, row.html:GetContentHeight() + 8)
            row.html:SetHeight(height)
        end
        row.html:SetShown(i ~= self.active)
        row.checkbox:SetShown(row.task ~= nil and i ~= self.active)
        row.highlight:SetShown(i == self.active)
        row:SetHeight(height)
        y = y + height
    end
    self.content:SetHeight(math.max(self.scroll:GetHeight(), y + 24))
end
