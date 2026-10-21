# Azeroth Notes

A standalone Markdown journal for **WoW Forever**, interface 16001. Version 0.1.1
is the first playable prototype. It uses Blizzard's native portrait frame, buttons,
inputs and scrollbars, with a parchment reading page and a quiet source editor.

## Open the journal

- `/anotes` toggles the window.
- `/anotes minimap` shows or hides the minimap book, visible by default.
- Bind **Azeroth Notes: Open / close journal** in the game's keybinding settings.
- Escape closes the journal. Drag the frame to move it; drag its lower-right corner
  to resize. Position, size and reading mode persist.

The window fits the current viewport and responds to resolution/UI-scale changes.
Manual sizes are remembered as screen proportions. Narrower windows use a smaller
sidebar and reading font; very small viewports also scale the frame to keep all
controls on screen. Screen changes recenter the journal. The reading page samples
the opaque area of Blizzard's quest parchment so the background fills the pane.

## Write and read

Choose **New**, enter a title, and write Markdown. Commit a title or tags by pressing
Enter or leaving the field. **Read** shows the formatted page; **Edit** returns to
the source. **Notes** collapses or restores the left-hand list.

Supported in this build:

- `#`, `##`, `###` headings, paragraphs and blank lines.
- Bullet and numbered lists, and `- [ ]` / `- [x]` task markers.
- `> Quotes` and inline backtick code.
- `**bold**` and `*italic*` use distinct ink colors in this initial renderer; they
  do not switch the font's weight or slant.
- `[[Note Title]]` opens a note. A missing target offers to create it. **Back**
  returns to the previous selection.

Lists are one level deep and checkboxes are edited in the source. Tables, fenced
code blocks, nested formatting, URL rendering, images, and link aliases are not
implemented. Unsupported text remains literal. A rename preserves the note's ID
but does not automatically rewrite links that use its former title.

Enter comma-separated tags below a page. Search titles and bodies using words;
add `#tag` to filter by an assigned tag. Multiple terms must all match. Notes are
shared account-wide across characters in this Forever installation.

The page's **Trash** action moves a note to recoverable trash. The top toolbar's
**Trash** button browses those pages; select one and choose **Restore**. There is
no permanent deletion or automatic trash cleanup in this version.

## Storage

WoW stores `AzerothNotesDB` in the account's `WTF/Account/.../SavedVariables`
directory. Edits update memory immediately; `/reload` or normal logout writes them
to disk. A client crash can lose edits since the last disk save. Use a normal
logout before backing up your SavedVariables.

No companion app, external folder sync, or Obsidian connection exists yet.
[PROJECT_DESIGN.md](PROJECT_DESIGN.md) describes those future phases.

## Install and test

Copy the **AzerothNotes** directory into the Forever beta client's
`Interface/AddOns` directory. Do not copy the surrounding project folder. Enable
Azeroth Notes in the AddOns list and use `/anotes`. If a newly installed addon is
not detected after `/reload`, restart the game client.

1. Open the welcome note and switch between Read and Edit.
2. Create two pages, use a `[[link]]` between them, then try Back.
3. Create a missing linked page. Try renaming to an existing title.
4. Add tags, search a body word, and filter with `#tag`.
5. Trash a page, browse Trash, and restore it.
6. Collapse the list, resize the window, and try a long note.
7. Toggle the minimap book, drag it, and right-click it to hide it.
8. `/reload` and confirm the notes, tags, window, and icon preferences persist.
9. Try another character and confirm the shared notebook appears.

For a useful error report, enable `/console scriptErrors 1`, reproduce the problem,
and record the first Lua error and what you clicked. Real-client appearance and
API behavior require in-game testing; the automated checks cover the data model,
Markdown conversion, and UI control flow with a simulated client.

## Development

Run `python tests/run.py` with Python and `lupa` installed. The test runner uses
LuaJIT's Lua 5.1 runtime. It does not launch WoW or perform visual verification.
