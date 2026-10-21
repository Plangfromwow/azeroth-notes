# Azeroth Notes

A standalone Markdown journal for **WoW Forever**, interface 16001. Version 0.3.3
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

Choose **New**, enter a title, and click the page to start writing. Commit a title
or tags by pressing Enter or leaving the field. **Notes** collapses or restores
the left-hand list.

### Live Preview

Live Preview is the default for new notebooks and new pages. Click a paragraph,
heading, or list item to reveal and edit its Markdown. Surrounding blocks stay
rendered. Click away or press Escape to render the edited block again. Enter adds
normal line breaks; paragraphs added inside an active block become separate blocks
when it renders. Press Enter twice to leave a blank line and begin another
paragraph, including at the end of the page. No separate paragraph button is needed.

In both Live and Source modes, Enter continues `-`, `*`, and `+` lists, increments
`1.` / `1)` numbering, and creates an unchecked next item for Markdown checklists.
List indentation is preserved. Enter on an empty item ends the list. Shift-Enter
inserts a plain line break without adding a marker. Pasting multiple lines leaves
them as pasted. The existing one-level list rendering limitation still applies.

Tab moves to the next block; Shift-Tab moves to the previous block. Ctrl-S finishes
editing the current block (WoW still writes to disk only on reload/logout).
Ctrl-click `[[note links]]` to follow them in Live Preview; a normal click edits
their paragraph. The first click places the cursor at the end of a block; click
within the exposed source to position it more precisely. Native undo is limited
to the current block's editing session; this is not a complete Obsidian editor.

**Source** opens the whole-note Markdown editor, and its **Read** button opens the
read-only page. **Live** returns to Live Preview. All three modes share the same
note content. The current mode is remembered between sessions. The existing
Markdown subset and colored emphasis limitation below apply in every preview.

Supported in this build:

- `#`, `##`, `###` headings, paragraphs and blank lines.
- Bullet and numbered lists, and `- [ ]` / `- [x]` task markers.
- `> Quotes` and inline backtick code.
- `**bold**` and `*italic*` use distinct ink colors in this initial renderer; they
  do not switch the font's weight or slant.
- `[[Note Title]]` opens a note. A missing target offers to create it. **Back**
  returns to the previous selection.

Task items render as native Blizzard checkboxes in Live and Read modes. Click to
check or uncheck; Source mode reflects the change as `[x]` or `[ ]`. Clicking the
task text in Live still edits its Markdown, while the checkbox toggles without
opening the editor. Tasks in Trash cannot be changed. Long task labels wrap beside
their checkbox.

Lists are one level deep. Tables, fenced
code blocks, nested formatting, URL rendering, images, and link aliases are not
implemented. Unsupported text remains literal. A rename preserves the note's ID
but does not automatically rewrite links that use its former title.

Enter space-separated tags below a page: `quest forest-spider helpful-player`.
Tags update the note list and search as you type; `druid quest` creates two tags,
displayed as `druid · quest` below the title.
Commas and optional hash signs are also accepted and normalized when committed.
Tags display without hash signs; use hyphens to keep a multiword tag together.
Search by typing ordinary words. An exact tag name filters to notes with that tag;
other words search titles, bodies, and tags. This means `quest` shows notes tagged
`quest`, rather than every page that mentions a quest. Multiple terms must all match. Notes are
shared account-wide across characters in this Forever installation.

The page's **Trash** action moves a note to recoverable trash. The top toolbar's
**Trash** button browses those pages; select one and choose **Restore**. There is
no permanent deletion or automatic trash cleanup in this version.

## Notes about players and creatures

Right-click a native player, target, focus, party, raid, pet, or boss unit frame
and choose **Add note**. The journal opens a new page titled with that unit's name,
tags it automatically, and focuses the Live editor so you can start writing.
Forever player surnames are included in the title.

Name tags use lowercase and hyphens in place of spaces: `Forest Spider` becomes
`forest-spider`, and `Eacam Brennan` becomes `eacam-brennan`. Search that tag to
find all your pages about the unit. Each click creates a new note; existing pages
remain intact, with numbered titles when needed. Names are captured when the menu
opens, so changing your target before clicking does not change the note's subject.

The entry uses Forever's native menu extension API. Custom unit-frame addons need
to use those same unit menus to inherit it. Unavailable or restricted names are
skipped. This feature does not add tooltip notes or a permanent unit-frame icon.

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

1. Open a note, click and edit a block in Live, then switch Source → Read → Live.
2. Create two pages, use a `[[link]]` between them, then try Back.
3. Create a missing linked page. Try renaming to an existing title.
4. Add space-separated tags, search a body word, and find a note using a tag without a hash sign.
5. Trash a page, browse Trash, and restore it.
6. Collapse the list, resize the window, and try a long note.
7. Toggle the minimap book, drag it, and right-click it to hide it.
8. `/reload` and confirm the notes, tags, window, and icon preferences persist.
9. Try another character and confirm the shared notebook appears.
10. In Live, change a heading's length, then edit a later paragraph. Insert blank
    lines, use Tab/Shift-Tab, and switch notes while editing. Verify surrounding
    source text remains intact in Source mode.

For a useful error report, enable `/console scriptErrors 1`, reproduce the problem,
and record the first Lua error and what you clicked. Real-client appearance and
API behavior require in-game testing; the automated checks cover the data model,
Markdown conversion, and UI control flow with a simulated client.

## Development

Run `python tests/run.py` with Python and `lupa` installed. The test runner uses
LuaJIT's Lua 5.1 runtime. It does not launch WoW or perform visual verification.
