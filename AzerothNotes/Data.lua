local _, NS = ...
NS.Data = {}
local D = NS.Data
local VERSION = 2

local function Trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end
D.Trim = Trim

function D.Initialize(saved)
    if saved and type(saved) ~= "table" then return nil, "Notebook data is not a table." end
    local db = saved or {}
    local oldVersion = tonumber(db.schemaVersion) or 0
    if oldVersion > VERSION then
        return nil, "This notebook needs a newer version of Azeroth Notes. Your data was left untouched."
    end
    db.schemaVersion = VERSION
    db.notes = db.notes or {}
    if oldVersion < 2 then
        for _, note in pairs(db.notes) do
            local previous = note.tags or {}
            local tags = D.Tags(table.concat(previous, " "))
            if table.concat(previous, "\031") ~= table.concat(tags, "\031") then
                note.tags = tags
                note.revision = (note.revision or 1) + 1
            end
        end
    end
    db.ui = db.ui or {}
    if db.ui.minimap == nil then db.ui.minimap = true end
    db.nextID = db.nextID or 0
    if db.ui.minimapAngle == nil then db.ui.minimapAngle = 220 end
    return db
end

function D.Find(db, title)
    local wanted = Trim(title):lower()
    for _, note in pairs(db.notes) do
        if not note.deleted and note.title:lower() == wanted then return note end
    end
end

function D.UniqueTitle(db, base)
    base = Trim(base)
    if base == "" then base = "Untitled note" end
    local title, suffix = base, 2
    while D.Find(db, title) do
        title = base .. " (" .. suffix .. ")"
        suffix = suffix + 1
    end
    return title
end

function D.Tags(text)
    local tags, seen = {}, {}
    for tag in tostring(text or ""):gmatch("[^,%s#]+") do
        tag = tag:lower()
        if tag ~= "" and not seen[tag] then
            seen[tag] = true
            tags[#tags + 1] = tag
        end
    end
    table.sort(tags)
    return tags
end

function D.Create(db, title, body, now, author)
    db.nextID = db.nextID + 1
    local id = tostring(now) .. "-" .. tostring(db.nextID)
    while db.notes[id] do
        db.nextID = db.nextID + 1
        id = tostring(now) .. "-" .. tostring(db.nextID)
    end
    local note = {
        id = id, title = D.UniqueTitle(db, title), body = body or "", tags = {},
        createdAt = now, updatedAt = now, revision = 1, author = author,
    }
    db.notes[id] = note
    return note
end

function D.Update(db, note, field, value, now, author)
    if field == "title" then
        value = Trim(value)
        if value == "" then return false, "Give this note a title." end
        if #value > 160 then return false, "Keep titles under 160 bytes." end
        local other = D.Find(db, value)
        if other and other.id ~= note.id then return false, "Another note already uses that title." end
    elseif field ~= "body" and field ~= "tags" then
        return false, "Unknown note field."
    end
    if field == "tags" then
        if table.concat(note.tags, ",") == table.concat(value, ",") then return true end
    elseif note[field] == value then
        return true
    end
    note[field] = value
    note.updatedAt, note.lastAuthor = now, author
    note.revision = note.revision + 1
    return true
end

function D.SetDeleted(db, note, deleted, now)
    if not deleted then note.title = D.UniqueTitle(db, note.title) end
    note.deleted = deleted and true or nil
    note.deletedAt = deleted and now or nil
    note.updatedAt = now
    note.revision = note.revision + 1
end

function D.List(db, query, trash)
    local results = {}
    query = Trim(query):lower()
    local knownTags = {}
    for _, note in pairs(db.notes) do
        if (not not note.deleted) == (not not trash) then
            for _, tag in ipairs(note.tags) do knownTags[tag] = true end
        end
    end
    local words, tags = {}, {}
    for word in query:gmatch("%S+") do
        if word:sub(1, 1) == "#" then tags[#tags + 1] = word:sub(2)
        elseif knownTags[word] then tags[#tags + 1] = word
        else words[#words + 1] = word end
    end
    for _, note in pairs(db.notes) do
        if (not not note.deleted) == (not not trash) then
            local haystack = (note.title .. "\n" .. note.body .. "\n" .. table.concat(note.tags, " ")):lower()
            local matches = true
            for _, word in ipairs(words) do
                if not haystack:find(word, 1, true) then matches = false end
            end
            for _, wanted in ipairs(tags) do
                local found = false
                for _, tag in ipairs(note.tags) do if tag == wanted then found = true end end
                if not found then matches = false end
            end
            if matches then results[#results + 1] = note end
        end
    end
    table.sort(results, function(a, b)
        if a.updatedAt ~= b.updatedAt then return a.updatedAt > b.updatedAt end
        return a.id < b.id
    end)
    return results
end
