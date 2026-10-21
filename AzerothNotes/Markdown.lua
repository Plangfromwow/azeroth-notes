local _, NS = ...
NS.Markdown = {}
local M = NS.Markdown

local function Escape(s)
    return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        :gsub('"', "&quot;"):gsub("|", "||"))
end

local function Hex(s)
    return (s:gsub(".", function(c) return string.format("%02x", c:byte()) end))
end

function M.Unhex(s)
    if #s % 2 ~= 0 or s:find("[^%x]") then return nil end
    return (s:gsub("%x%x", function(pair) return string.char(tonumber(pair, 16)) end))
end

local function Inline(text)
    local out, pos = {}, 1
    while pos <= #text do
        local rest = text:sub(pos)
        local target = rest:match("^%[%[([^%]\n]+)%]%]")
        local code = rest:match("^`([^`\n]+)`")
        local bold = rest:match("^%*%*([^*\n]+)%*%*")
        local italic = rest:match("^%*([^*\n]+)%*")
        if target then
            out[#out + 1] = '<a href="note:' .. Hex(target) .. '">|cff315d83' .. Escape(target) .. '|r</a>'
            pos = pos + #target + 4
        elseif code then
            out[#out + 1] = "|cff72523b" .. Escape(code) .. "|r"
            pos = pos + #code + 2
        elseif bold then
            out[#out + 1] = "|cff8c4519" .. Escape(bold) .. "|r"
            pos = pos + #bold + 4
        elseif italic then
            out[#out + 1] = "|cff6d634d" .. Escape(italic) .. "|r"
            pos = pos + #italic + 2
        else
            local stop = pos + 1
            while stop <= #text and not text:sub(stop, stop):find("[%[`*]") do stop = stop + 1 end
            out[#out + 1] = Escape(text:sub(pos, stop - 1))
            pos = stop
        end
    end
    return table.concat(out)
end

function M.Render(source)
    source = tostring(source or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    local out, paragraph = {}, {}
    local function Flush()
        if #paragraph > 0 then
            out[#out + 1] = "<p>" .. Inline(table.concat(paragraph, " ")) .. "</p>"
            paragraph = {}
        end
    end
    for line in (source .. "\n"):gmatch("(.-)\n") do
        local hashes, heading = line:match("^(#+)%s+(.+)$")
        local task, taskText = line:match("^%s*[-*]%s+%[([ xX])%]%s*(.*)$")
        local bullet = line:match("^%s*[-*+]%s+(.+)$")
        local number, numbered = line:match("^%s*(%d+)[.)]%s+(.+)$")
        local quote = line:match("^>%s?(.*)$")
        if line:match("^%s*$") then
            Flush()
        elseif hashes and #hashes <= 3 then
            Flush()
            out[#out + 1] = "<h" .. #hashes .. ">" .. Inline(heading) .. "</h" .. #hashes .. ">"
        elseif task then
            Flush()
            out[#out + 1] = "<p>" .. (task:lower() == "x" and "[x] " or "[ ] ") .. Inline(taskText) .. "</p>"
        elseif bullet or numbered or quote then
            Flush()
            local prefix = bullet and "• " or (number and (number .. ". ") or "› ")
            out[#out + 1] = "<p>" .. prefix .. Inline(bullet or numbered or quote) .. "</p>"
        else
            paragraph[#paragraph + 1] = line
        end
    end
    Flush()
    return "<html><body>" .. table.concat(out) .. "</body></html>"
end
