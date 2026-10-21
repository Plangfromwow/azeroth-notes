# Azeroth Notes: Project Design

Status: Phase 1 prototype implemented as version 0.4.0. The companion remains planned.

Named, one-level folders now support drag-and-drop, right-click moves, rename,
and removal without deleting notes. Search spans all folders. Notes retain stable
IDs across moves; folder assignments and collapsed state are saved in WoW.

The first build uses a Blizzard portrait frame and native controls, a parchment
reading page, and a dark Markdown source editor. See README.md for installation,
implemented features, rendering limitations, and in-game test steps. Bold and
italic currently render with ink colors rather than font weight or slant. Automated
checks cover syntax, packaging references, data behavior, and simulated UI flows;
the installed Forever build still requires real-client visual testing.

Working name: Azeroth Notes. This name can change before the first release.

## Purpose

A quiet, personal notebook for World of Warcraft: Forever. Capture discoveries,
quest clues, people, places, and plans without leaving the game or covering the UI
with trackers. Write notes in Markdown and read them as formatted journal pages.

The long-term goal is to keep those same notes as ordinary Markdown files outside
the game, optionally in an Obsidian vault, through a separate desktop companion.
The addon must remain useful on its own when that companion is absent.

## Target and scope

- Target WoW Forever first, using the installed 1.60.1 / interface 16001 client as
  the initial development and testing environment.
- Validate against the actual Forever API. Retail compatibility is not an initial
  requirement, and Retail-only APIs must not become assumptions in shared code.
- Build a standalone addon. Spoken and other addons are optional neighbors, not
  dependencies.
- Begin with the notebook. The companion is a later project phase.
- No gameplay automation, AI generation, telemetry, accounts, or cloud service is
  required for the notebook.

## Experience and visual direction

The player opens one journal window through a configurable keybinding, a slash
command (`/anotes`), or a minimap book button, visible by default with an option to
hide it. Closing the journal leaves no persistent panel on screen.

Use restrained Blizzard-style framing, readable text, and warm parchment tones
where practical. Keep the page central and the controls compact. Avoid permanent
notifications, floating sticky notes, and automatic popups in the initial version.

The window contains a collapsible note list, a search field, and one selected note.
New, rename, delete, Edit/Read, and close are the essential controls. Support moving
and resizing the window and remember its position and size. Escape closes it.

Live Preview renders inactive blocks while the active block exposes its Markdown.
Full-note Source and read-only Read modes remain available. This preserves a quiet
single-page interface without a separate preview window.

## Initial player workflows

### Capture a discovery

1. Open the journal and create a note.
2. Enter a title and Markdown body.
3. Changes update the addon's in-memory note automatically while typing.
4. Switch to Read mode to see the formatting.
5. Close the journal and continue playing.
6. WoW persists the latest note state when the UI reloads or the player logs out.

Do not label in-memory autosave as a completed disk save. An abnormal client exit
can lose changes made since WoW last wrote SavedVariables.

### Find and connect notes

Search titles and bodies, filter by assigned tags, and click a note to open it.
Use `[[Note Title]]` to link to another note. Back navigation returns to the
previous note. An unresolved link offers to create the missing note rather than
silently opening the wrong page.

### Read with minimal distraction

Read mode hides editing controls that are not needed. The note list can collapse
so the page occupies most of the window. No journal content is pinned to the HUD
unless a later, explicit feature adds that option.

## Markdown support

Implement a documented subset rather than promise complete CommonMark or full
Obsidian feature parity. Preserve the original Markdown as the source of truth;
rendered UI content is derived and must never replace it.

Initial supported syntax:

- Headings: `#`, `##`, and `###`.
- Paragraphs and blank lines.
- Bold and italic text.
- Bullet and numbered lists, initially one level deep.
- Task markers: `- [ ]` and `- [x]`, initially edited in the source text.
- Blockquotes and inline code.
- Internal links: `[[Note Title]]`.

Tags are explicit note metadata in the first version. Inline `#tags`, link aliases,
backlinks, nested lists, fenced code blocks, and tables are later candidates.
Unsupported syntax should remain legible literal text instead of disappearing.

External Markdown links may display a label and offer a copyable URL. The addon
cannot directly open a browser or write to the system clipboard. Do not promise
embedded websites, arbitrary local images, HTML execution, or Obsidian plugins.

Treat note content as data. Escape WoW control sequences and generated rendering
markup so pasted content cannot unexpectedly alter the UI. Render only supported
links and formatting. Check layout with long notes, Unicode, and narrow windows.

## Note organization and data model

Start with one account-wide notebook shared by the player's characters. Each note
has a stable ID independent of its title, a title, a raw Markdown body, a tag list,
created and updated timestamps, and a revision counter. Record the character that
created or last edited it as optional metadata.

Track a schema version at the notebook level. Keep UI preferences separate from
note content. Title changes must not create a new note identity. Resolve links
through a title index; detect duplicate titles rather than picking one at random.
An initial rename should warn that title-based links may need updating. Automatic
link rewriting can be added with explicit tests later.

Use a small trash with restore rather than immediately destroying deleted notes.
Deletion records need IDs and revisions so future synchronization can distinguish
a deletion from a missing file. Define retention before adding automatic cleanup.

Future character-private notebooks and folders should fit this model without
changing existing IDs. Do not make them prerequisites for the first release.

## Persistence and WoW's boundaries

The addon stores its notebook through declared SavedVariables in WoW's `WTF`
directory. This is already separate from `Interface/AddOns`, but it is still inside
the game's data tree. It is not an external Markdown vault.

A normal addon cannot freely read or write arbitrary files, watch an external
folder, contact a local HTTP service, or launch a companion process. WoW writes
SavedVariables at reload/logout, not after each keystroke. The notebook can work
instantly in memory, but external synchronization has to respect those boundaries.

No filesystem redirects, client modifications, or memory access are required by
this design. Do not use a symbolic link to claim that SavedVariables is a Markdown
vault: it would still be a Lua serialization with the same save timing.

## Future desktop companion

The companion is a separate Windows application initially. It can run beside the
game, watch for completed SavedVariables writes, and export notes into a chosen
folder. The user may select a dedicated subfolder in an existing Obsidian vault.
Only manage notes explicitly belonging to this notebook; never scan or rewrite an
entire personal vault by default.

Each exported note is a readable `.md` file with YAML frontmatter containing its
stable ID, title, tags, revision, and timestamps. Define and document the exact
frontmatter schema before building the companion. File names should be readable,
Windows-safe, collision-resistant, and independent of synchronization identity.
The body retains the Markdown written in-game.

### Outbound: WoW to Markdown

1. The player writes notes in-game.
2. `/reload` or logout causes WoW to write SavedVariables.
3. The companion waits until the write is complete and reads a stable snapshot.
4. It safely parses the known data format, compares revisions and content hashes,
   and updates only the managed Markdown notes that changed.
5. It uses atomic writes and keeps recoverable backups of replaced content.

The companion may export while WoW is running after a completed save. It must not
execute SavedVariables as arbitrary Lua or mistake a partial write for a deletion.
Initial setup must bind explicitly to the Forever installation and correct WoW
account, not select a Retail folder automatically.

### Inbound: Markdown to WoW

External edits cannot appear instantly in the running addon. For the first
companion release, prepare imports only while the game is closed and apply them
at the next game launch. Use a dedicated, predeclared addon import-data file
containing a versioned snapshot; the addon merges that snapshot into its notebook.
Do not edit active SavedVariables under a running client.

Track the last applied import ID so an unchanged snapshot is not reapplied on
every login. The bridge is an implementation proposal to validate on Forever
before promising any faster import workflow. Manual copy/paste can cover imports
before the companion exists.

### Conflicts and deletion

Maintain a last-synchronized baseline per note. If both the in-game note and the
Markdown note changed since that baseline, preserve both and ask which to keep,
or create an explicitly labeled conflict copy. Do not use timestamps alone for
silent last-write-wins replacement.

Renames, duplicate titles, deleted files, restored notes, simultaneous edits, and
notes moved between folders all need deliberate behavior. Begin with an export-only
companion before enabling two-way synchronization. Never treat an inaccessible
vault or a temporarily absent drive as a request to delete the notebook.

### Companion status

Show whether WoW is running, the selected vault, last successful export/import,
and pending conflicts. Explain that pending in-game edits require reload/logout
before they can be exported. Keep routine operation quiet; surface errors that
need attention. No network access is needed for local vault synchronization.

## Implementation phases

### Phase 1: Standalone Forever notebook

Build the addon skeleton, SavedVariables schema, a single journal window,
create/rename/edit/read/search, metadata tags, internal links and back navigation,
trash/restore, keybinding, slash command, and an optional minimap button.
Implement the documented Markdown subset and remember window preferences.

### Phase 2: In-game usability

Improve rendering, keyboard navigation, link handling, and large-notebook behavior
based on real play. Consider backlinks, note pinning within the list, and an
explicit action to insert the current location. Add features only where they help
capture or find notes without adding persistent UI.

### Phase 3: Companion export

Build safe SavedVariables parsing, account selection, Markdown/frontmatter export,
change detection, atomic writes, backups, and visible sync status. Verify that
Obsidian can read and edit exported notes as ordinary files.

### Phase 4: Two-way synchronization

Implement the import bridge, baselines, revisions, deletion records, and conflict
resolution. Test interruption and recovery before enabling automatic imports.

## Validation and completion criteria for Phase 1

- Install and load in the actual WoW Forever client without Lua errors.
- Open and close using `/anotes`, the keybinding, and the optional minimap button.
- Start with a minimap book icon and no open journal window. Allow hiding the icon.
- Create, rename, edit, search, tag, trash, and restore notes.
- Verify every documented Markdown feature in Read mode; unsupported input remains
  visible and harmless.
- Follow internal links, create an unresolved target, and navigate back.
- Retain notes and preferences after `/reload`, logout/login, and a normal restart.
- Confirm that moving/resizing and long content do not break the layout.
- Test shared notes on another character and an existing-data schema migration.
- Use focused automated checks for parsing, persistence migrations, and link
  resolution, plus real in-game checks for rendering and input behavior.

The companion is not required to declare Phase 1 complete. External Markdown
storage must be described as a future feature until that bridge is implemented.

## Next development step

Test the installed Phase 1 prototype in Forever and fix client-specific errors and
layout issues. Keep the Markdown source and persistence model stable while
iterating on the in-game presentation. Do not implement the companion or expand
the HUD during the first build.
