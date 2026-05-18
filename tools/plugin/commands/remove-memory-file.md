---
description: Uninstall a memory file installed from the riboseinc/claude-memory-files catalogue
argument-hint: <slug>
allowed-tools: Bash
---

Uninstall a memory file by its slug from `~/.claude/`.

## What the user typed

`$ARGUMENTS`

## Process

1. **Validate input.** If `$ARGUMENTS` is empty, show usage and stop. Usage:
   `/remove-memory-file <slug>`.

2. **Check the manifest.** Read `~/.claude/.memory-files-manifest.json` and
   confirm the slug is installed. If not, tell the user there's nothing to
   uninstall under that slug.

3. **Show what will be removed** before acting:
   - For `instruction`: the file at `~/.claude/instructions/<slug>.md` and the
     `@`-include from `~/.claude/CLAUDE.md`.
   - For `memory-*`, `path-rule`: just the file.
   - For `settings-fragment`: the manifest-recorded entries will be subtracted
     from `~/.claude/settings.json`; hand-added entries will be preserved.
     A backup of `settings.json` will be created first.
   - For `project-claude-md`: the project's `CLAUDE.md` is left intact (it may
     have been hand-edited); only the manifest entry is removed. The user can
     delete the file manually if they want.

4. **Confirm with the user** before running the uninstaller.

5. **Run the uninstaller.** Use the Bash tool:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/riboseinc/claude-memory-files/main/tools/uninstall.sh \
     | bash -s -- <slug>
   ```

6. **Report the result.** Quote the uninstall.sh output and confirm clean state
   (manifest entry gone, file removed if applicable, backup path if a
   settings-fragment was un-merged).
