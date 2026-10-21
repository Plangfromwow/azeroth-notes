local _, NS = ...
local E = {}
NS.Editor = E

function E.Continuation(before, cursor, after)
    if after ~= before:sub(1, cursor) .. "\n" .. before:sub(cursor + 1) then return end
    local left = before:sub(1, cursor)
    local first = left:match(".*\n()") or 1
    local line = left:sub(first)
    local tail = before:sub(cursor + 1):match("^[^\n]*") or ""
    local indent, bullet, gap, checked, taskGap, content = line:match("^([ \t]*)([-+*])([ \t]+)%[([ xX])%]([ \t]*)(.*)$")
    local prefix
    if bullet then
        prefix = indent .. bullet .. gap .. "[ ]" .. (taskGap ~= "" and taskGap or " ")
    else
        indent, bullet, gap, content = line:match("^([ \t]*)([-+*])([ \t]+)(.*)$")
        if bullet then
            prefix = indent .. bullet .. gap
        else
            local number, delimiter
            indent, number, delimiter, gap, content = line:match("^([ \t]*)(%d+)([.)])([ \t]+)(.*)$")
            if number and #number <= 9 then prefix = indent .. tostring(tonumber(number) + 1) .. delimiter .. gap end
        end
    end
    if not prefix then return end
    if content:match("^%s*$") and tail:match("^%s*$") then
        return first - 1, cursor, "", first
    end
    return cursor + 1, cursor + 1, prefix, cursor + 1 + #prefix
end

function E.KeyDown(box, key)
    box.anEnter = nil
    if (key == "ENTER" or key == "NUMPADENTER") and not IsShiftKeyDown()
        and not IsControlKeyDown() and not IsAltKeyDown() then
        box.anEnter = { text = box:GetText(), cursor = box:GetCursorPosition() }
    end
end

function E.Changed(box, user)
    local pending = box.anEnter
    box.anEnter = nil
    if not user or not pending or box.anContinuing then return end
    local first, last, insertion, cursor = E.Continuation(pending.text, pending.cursor, box:GetText())
    if not first then return end
    local limit = box:GetMaxLetters()
    if limit > 0 and #box:GetText() - (last - first) + #insertion > limit then return end
    -- Native insertion preserves the edit box's undo history; SetText would replace the whole buffer.
    box.anContinuing = true
    box:HighlightText(first, last)
    box:Insert(insertion)
    box:SetCursorPosition(cursor)
    box.anContinuing = nil
end
