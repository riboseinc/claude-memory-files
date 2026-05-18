---
schema-version: 1
name: github-claude-attribution
description: Append the robot footer to substantive GitHub bodies (issues, PRs, narrative comments). Same footer the gh pr create harness injects.
type: instruction
scope: universal
target: instructions/github-claude-attribution.md
autoload: true
tags: [github, attribution, claude-code, pr]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Claude attribution on GitHub content I author

Append the PR-style robot footer to **narrative GitHub bodies I author** — issue bodies, PR bodies, long issue/PR comments (anything more than a single short sentence). Use the same footer the system already injects on `gh pr create`:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Format: blank line, then the footer line, then nothing.

**Where to apply.**

- `gh issue create --body-file ...` — yes
- `gh pr create --body-file ...` — yes (already auto-applied by the `gh pr create` default; keep consistent if drafting the body manually)
- `gh issue comment ...` and `gh pr review --body-file ...` when the comment is a substantive narrative (root-cause diagnosis, decision rationale, summary of work, multi-paragraph explanation) — yes
- Short acknowledgement / status comments (one sentence, "landed in `<sha>`", "yes confirmed", etc.) — no
- Commit messages — no (the `Co-Authored-By` trailer already covers these via the built-in commit-commands convention; do not duplicate)
- Non-GitHub channels (team chat, email, in-chat prose) — no

**Why this form.** The robot-emoji-plus-link footer is the convention the Claude Code harness already injects on PR creation, so adopting it for issue and comment bodies aligns the whole GitHub surface on one visual signal. The `Co-Authored-By` trailer stays the convention for commits because it integrates with GitHub's commit-author rendering; the two are different channels, both used.

**When in doubt.** If a comment runs to more than ~2 sentences or spans multiple paragraphs, treat it as narrative and apply the footer. The footer is one line — over-applying it is cheap; the cost the user objects to is *inconsistency*, not presence.
