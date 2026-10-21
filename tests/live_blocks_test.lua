local NS = {}
assert(loadfile("AzerothNotes/LivePreview.lua"))("AzerothNotes", NS)
local L = NS.LivePreview
for _, source in ipairs({ "", "\n", "\n\n", "# Heading\n\nA café\ncontinued\n- list\n> quote\n", "  \nlast", "first\r\n\r\nsecond" }) do
    local blocks = L.Blocks(source)
    assert(#blocks > 0)
    for _, block in ipairs(blocks) do
        assert(source:sub(block.first, block.last) == block.text)
        assert(L.Replace(source, block, block.text) == source)
        local changed = L.Replace(source, block, "a\n\nb")
        assert(changed == source:sub(1, block.first - 1) .. "a\n\nb" .. source:sub(block.last + 1))
    end
end
local source = "# Heading\n\nfirst line\nsecond line\n\n- one\n- two"
local blocks = L.Blocks(source)
assert(#blocks == 6)
assert(blocks[3].text == "first line\nsecond line")
assert(blocks[5].text == "- one" and blocks[6].text == "- two")
assert(L.Replace("", L.Blocks("")[1], "new") == "new")
local trailing = L.Blocks("one\n\n")
assert(trailing[#trailing].first == 6 and trailing[#trailing].text == "")
print("Live blocks: exact source spans, blank lines, multiline paragraphs, Unicode, and edits passed.")
