local NS = {}
assert(loadfile("AzerothNotes/Markdown.lua"))("AzerothNotes", NS)
local M = NS.Markdown
for _, source in ipairs({ "- [ ] item", "+ [x] item", "  * [X] café 世界", "- [ ]", "\t- [ ]  spaced" }) do
    local task = assert(M.Task(source))
    local changed = assert(M.ToggleTask(source, task.position))
    assert(#changed == #source)
    local again = assert(M.ToggleTask(changed, task.position))
    assert(again == source or (source:find("[X]", 1, true) and again == source:gsub("%[X%]", "[x]")))
end
local source = "# Title\n\n- [ ] same\n- [ ] same"
local second = assert(source:find("- [ ] same", 20, true))
local position = second + assert(M.Task(source:sub(second))).position - 1
assert(M.ToggleTask(source, position) == "# Title\n\n- [ ] same\n- [x] same")
assert(not M.ToggleTask(source, 1))
assert(not M.ToggleTask("plain [ ] text", 8))
assert(not M.Task("`- [ ] code`"))
print("Tasks: precise marker edits, repeated items, uppercase state, Unicode and invalid targets passed.")
