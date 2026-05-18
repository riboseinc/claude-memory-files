---
schema-version: 1
name: github-content-via-file
description: Use --body-file / -F for non-trivial gh or git content; never heredoc/inline (shell quoting on backticks/multiline is the failure mode).
type: instruction
scope: universal
target: instructions/github-content-via-file.md
autoload: true
tags: [github, pr, cli]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# GitHub content: write to a file, not inline

Any non-trivial GitHub content — commit messages longer than a sentence, PR descriptions, issue bodies, issue/PR comments — must be written to a temporary file first and passed to `gh` via `-F file` (or `git commit -F file`), **never** inline as `gh ... -b "..."` / `git commit -m "..."` / heredoc.

**Why:** heredocs and inline strings repeatedly trip on shell quoting — backticks, `$(...)`, embedded quotes, multi-line content, code fences with backticks, and narration with non-ASCII all cause silent corruption or outright command failure. The fallback (rewriting to a file after the failure) wastes a turn and sometimes garbles content that already shipped.

**How to apply:**
- One-line trivial commit message: `-m "fix typo"` is fine.
- Anything multi-line, anything with backticks/code fences, anything with embedded quotes, any PR/issue body: write the content to e.g. `/tmp/gh-body.md`, then `gh pr create --body-file /tmp/gh-body.md` or `git commit -F /tmp/commit-msg.txt`.
- The `Co-Authored-By` trailer counts as multi-line — use `-F`.
- Clean up the temp file after the gh/git call succeeds.
- Applies to all repos and projects.
