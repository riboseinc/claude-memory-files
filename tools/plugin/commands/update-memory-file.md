---
description: Update an installed memory file by re-fetching upstream and applying the decision matrix (hash drift, version bump, local-edit detection)
argument-hint: <slug> [--force] [--upstream] [--ref <sha>]
allowed-tools: Bash, WebFetch
---

Update an already-installed memory file from the riboseinc/claude-memory-files catalogue. Drift is detected by hash; the decision matrix (per [issue #2](https://github.com/riboseinc/claude-memory-files/issues/2)) decides overwrite vs abort.

## What the user typed

`$ARGUMENTS`

## Process

1. **Validate input.** If `$ARGUMENTS` is empty, show usage and stop. Usage:
   `/update-memory-file <slug> [--force] [--upstream] [--ref <sha>]`.

2. **Check the manifest** at `~/.claude/.memory-files-manifest.json` for the slug. If missing, tell the user nothing is installed under that name.

3. **Show the user what the update will do** before running. Quote from the manifest entry:
   - The currently installed version + installed-hash prefix.
   - Note that `--update` will fetch upstream, compare hashes, and either overwrite or abort.

4. **Run the updater.** Use the Bash tool:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/riboseinc/claude-memory-files/main/tools/install.sh \
     | bash -s -- --update [user options from $ARGUMENTS] <slug>
   ```

5. **Interpret the result.** Three common outcomes:
   - `already up to date` — nothing to do, exit 0.
   - `Updated <slug> → <version>` — successful overwrite; report the new version and the hash diff.
   - `update aborted — local copy has been hand-edited` — the user has hand-edited the installed file. Ask whether to:
     (a) keep local edits (do nothing further); or
     (b) overwrite local edits by re-running with `--force` (offer to do this for them).
   - `--update is a no-op for forked entries` (personal-share): ask whether the user wants `--upstream` overwrite (which discards their local customisation).

## Decision matrix reference

The current install.sh `--update` flow implements the matrix as follows (per the
[plan](https://github.com/riboseinc/claude-memory-files/issues/2)):

| Local edited? | Bump category | Action |
|---|---|---|
| no | any | silent overwrite; manifest history appended |
| yes | any | abort; `--force` overrides |
| n/a | none (hashes differ, versions match) | abort as anomalous; `--force` overrides |
| forked | any | no-op; `--upstream` overrides |

Interactive UX nuance per bump (patch silent vs minor prompt-with-diff vs major
require-ack) is handled by the slash command, not the installer — the
installer is non-interactive and decides bluntly on overwrite vs abort. The
slash command can surface the bump category to the user before invoking.

## Examples

- `/update-memory-file github-pr-title-issue-link` — standard update.
- `/update-memory-file github-pr-title-issue-link --force` — overwrite local edits.
- `/update-memory-file user-maintained-gems --upstream` — overwrite personal-share fork.
