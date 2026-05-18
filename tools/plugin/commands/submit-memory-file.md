---
description: Propose a new memory file by scaffolding frontmatter, running the local validator, and opening a PR
argument-hint: <path-to-local-file.md> [--category instructions|memory|settings-fragments|project-claude-md|rules]
allowed-tools: Bash, Read, Write, Edit
---

Help the user contribute a new memory file to the riboseinc/claude-memory-files catalogue. Read their local file, draft frontmatter interactively if needed, run the validator, and open a PR.

## What the user typed

`$ARGUMENTS`

## Process

1. **Validate input.** If `$ARGUMENTS` is empty, show usage and stop. Usage:
   `/submit-memory-file <path-to-local-file.md> [--category <category>]`.

2. **Read the user's local file** at the given path. If the file already has
   frontmatter, parse it. If not, infer a reasonable starting frontmatter:
   - `name` from filename (kebab- or snake-case slug, no `.md`).
   - `type` from category (or ask if `--category` isn't given).
   - `scope` — ask the user: universal, team (with optional `team:` qualifier),
     or personal-share.
   - `description` — draft a 1-line summary ≤140 chars; let the user revise.
   - `author` — use the user's GitHub handle (look up via `gh api user --jq .login`).
   - `owners: [author.github]` — default to single owner; required to stay
     length 1 for `scope: personal-share`.
   - `tags` — suggest 1–5 from the controlled vocabulary in `_meta/tags.txt`
     (fetch it to confirm available tags).
   - `version: 1.0.0`.
   - `license: MIT`.
   - `schema-version: 1`.

3. **Walk through the frontmatter with the user**. Show the proposed block,
   ask for any edits, lock it in.

4. **Clone the catalogue repo into a sibling directory** (per the
   `sibling-clones` convention if installed):
   `gh repo clone riboseinc/claude-memory-files <sibling-dir>`.

5. **Create a feature branch** named `feat/<slug>` or
   `feat/seed-<category>-<slug>`.

6. **Drop the file** into the correct category subdirectory in the clone.

7. **Regenerate index and CODEOWNERS:**
   `node _meta/build-index.mjs && node _meta/build-codeowners.mjs`.

8. **Run the validator:** `node _meta/validate.mjs`. If it errors, surface the
   errors to the user and let them fix the frontmatter or body before continuing.

9. **Commit** (via `git commit -F <tmpfile>` per the `github-content-via-file`
   convention, with a `Co-Authored-By:` trailer).

10. **Push and open the PR** (via `gh pr create --assignee opoudjis --title "..."
    --body-file <tmpfile>`). PR title: `feat: add <slug>: https://github.com/riboseinc/claude-memory-files/issues/1`.
    PR body: one line referencing issue #1, plus the standard robot footer.

11. **Report the PR URL** back to the user.

## Notes

- For `scope: personal-share`, the validator enforces `owners == [author.github]`
  (length 1, exact match). The slash command must respect this when scaffolding
  the frontmatter.
- For `project-claude-md`, the body should be just the CLAUDE.md template
  content (frontmatter on install is stripped). Confirm the body is markdown
  and ≤200 lines.
- For `path-rule`, ask for the `paths:` glob list and validate each glob.
- For `settings-fragment`, the body must contain a `## fragment` heading followed
  by a fenced ```json block. Walk the user through it if missing.
