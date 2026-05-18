---
description: List available memory files from the riboseinc/claude-memory-files catalogue with optional filters
argument-hint: [--tag <tag>] [--scope universal|team|personal-share] [--team <name>] [--installed]
allowed-tools: Bash, WebFetch
---

List the catalogue of memory files available from riboseinc/claude-memory-files, with optional filters.

## What the user typed

`$ARGUMENTS`

## Process

1. **Fetch the catalogue index.** Use WebFetch or curl to read:
   `https://raw.githubusercontent.com/riboseinc/claude-memory-files/main/_meta/index.json`

2. **Apply filters from `$ARGUMENTS`** (any combination):
   - `--tag <tag>`: only entries whose `tags` array includes `<tag>`.
   - `--scope universal|team|personal-share`: only entries matching the scope.
   - `--team <name>`: only entries with `team: <name>`.
   - `--installed`: only entries currently in the user's
     `~/.claude/.memory-files-manifest.json`.
   - `--include-deprecated`: also include the `deprecated` array from the index
     (default: deprecated entries are hidden).
   - No arguments: show everything not deprecated.

3. **Render the matching entries** as a table or a tight bulleted list, one
   row/line per entry. Show:
   - `name` (slug)
   - `type`
   - `scope` (plus `team:` qualifier if present)
   - `description` (first 100 chars)
   - whether `--installed` is in the local manifest

4. **Group by category** for readability when listing more than ~10 entries:
   instructions, memory, settings-fragments, project-claude-md, rules.

5. **Suggest next actions** at the bottom of the listing:
   - `/install-memory-file <slug>` to install one.
   - `/remove-memory-file <slug>` to uninstall.
   - `/submit-memory-file <local-path>` to propose a new file.

## Examples

- `/list-memory-files` — show all non-deprecated entries.
- `/list-memory-files --scope team --team metanorma` — team:metanorma rules only.
- `/list-memory-files --tag github` — entries tagged `github`.
- `/list-memory-files --installed` — what's currently on this machine.
