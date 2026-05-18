---
description: Install a memory file from the riboseinc/claude-memory-files catalogue into ~/.claude/
argument-hint: <slug> [--project <dir>] [--ref <sha>]
allowed-tools: Bash, WebFetch
---

Install a memory file from the [riboseinc/claude-memory-files](https://github.com/riboseinc/claude-memory-files) catalogue into the user's `~/.claude/`.

## What the user typed

`$ARGUMENTS`

## Process

1. **Validate input.** If `$ARGUMENTS` is empty, show usage and stop. Usage:
   `/install-memory-file <slug> [--project <dir>] [--ref <sha>]`. The slug
   is the `name:` from the file's frontmatter (e.g. `github-pr-title-issue-link`).

2. **Look up the file in the catalogue.** Fetch the index:
   `https://raw.githubusercontent.com/riboseinc/claude-memory-files/main/_meta/index.json`
   and find the entry where `name == <slug>`. If none, fall back to treating
   `$ARGUMENTS` as a full path like `instructions/<slug>.md`.

3. **Show the user the entry's frontmatter** before installing. Highlight:
   - `description`
   - `type` and `scope` (and `team:` if present)
   - `owners`
   - `requires-companion` if any (warn if the companion isn't already installed)
   - `version`

4. **For `project-claude-md` type**: ensure `--project <dir>` is in the
   arguments. If not, ask the user which project directory to install into.

5. **Run the installer.** Use the Bash tool:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/riboseinc/claude-memory-files/main/tools/install.sh \
     | bash -s -- [user's options from $ARGUMENTS] <category>/<slug>.md
   ```

6. **Report the result.** Quote what the install.sh output said: where the
   file landed, the manifest path, and the `Remove:` hint. If the install
   failed (e.g. target already exists), surface the error and ask whether to
   retry with `--force`.

## Notes

- The installer always fetches the current contents of `main` (unless `--ref <sha>`
  is given). This means the slash command's behaviour stays in sync with the
  catalogue's latest installer logic.
- `hooks/` files are rejected by the installer with a pointer to `SAFETY.md`;
  this is intentional until v2 opens.
- Read [the catalogue's CONTRIBUTING.md](https://github.com/riboseinc/claude-memory-files/blob/main/CONTRIBUTING.md)
  for the scope rubric and how the install paths interact with `~/.claude/CLAUDE.md`.
