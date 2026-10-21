local NS = {}
assert(loadfile("AzerothNotes/Editor.lua"))("AzerothNotes", NS)
local E = NS.Editor
local function Enter(before, cursor, expected, expectedCursor)
    cursor = cursor or #before
    local after = before:sub(1, cursor) .. "\n" .. before:sub(cursor + 1)
    local first, last, insertion, position = E.Continuation(before, cursor, after)
    if first then after = after:sub(1, first) .. insertion .. after:sub(last + 1) end
    assert(after == expected, string.format("%q instead of %q", after, expected))
    if expectedCursor then assert(position == expectedCursor) end
end
Enter("- Apples", nil, "- Apples\n- ")
Enter("* Apples", nil, "* Apples\n* ")
Enter("+ Apples", nil, "+ Apples\n+ ")
Enter("  - Nested", nil, "  - Nested\n  - ")
Enter("9. Ninth", nil, "9. Ninth\n10. ")
Enter("2) Second", nil, "2) Second\n3) ")
Enter("- [x] Finished", nil, "- [x] Finished\n- [ ] ")
Enter("- [ ] Pending", nil, "- [ ] Pending\n- [ ] ")
Enter("- ", nil, "\n", 1)
Enter("paragraph\n- ", nil, "paragraph\n\n", 11)
Enter("  - [ ] ", nil, "\n")
Enter("1. ", nil, "\n")
Enter("- Apples and pears", 8, "- Apples\n-  and pears")
Enter("- café 世界", nil, "- café 世界\n- ")
Enter("A normal paragraph", nil, "A normal paragraph\n")
Enter("# Heading", nil, "# Heading\n")
assert(not E.Continuation("- text", 6, "- text\n- pasted\ntext"))
assert(not E.Continuation("- selection", 4, "- se\ntion"))
print("Editor: bullets, numbering, checklists, indent, empty-item exit, cursor splits, Unicode and paste passed.")
