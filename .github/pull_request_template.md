## Summary

<!-- One or two sentences. Link to the design issue (#1 for v1 foundational; #2 for update regulation) if applicable. -->

## What does this PR add or change?

<!-- For new files: which category, scope, and worked example does it follow?
     For changes to existing files: what bumps version (patch/minor/major) and why? -->

## Validator passes

- [ ] `node _meta/validate.mjs` exits 0 locally (once validator lands in PR 2).
- [ ] If this PR touches `_meta/build-codeowners.mjs` output, `.github/CODEOWNERS` is regenerated and committed.

## Frontmatter checks (for new content files)

- [ ] `name` matches filename (minus `.md`).
- [ ] `scope` declared correctly (`universal` / `team` / `personal-share`).
- [ ] `owners:` declared (or defaults to `[author.github]`).
- [ ] For `scope: personal-share`: `owners == [author.github]` (validator-enforced).
- [ ] `description` ≤ 140 chars.
- [ ] Body ≤ 200 lines.
- [ ] No personal credentials in body or frontmatter.
- [ ] No non-Ribose project names in shared content (redact to "non-Ribose activity").

## Related

<!-- Link to design issue: https://github.com/riboseinc/claude-memory-files/issues/1 (v1)
     or https://github.com/riboseinc/claude-memory-files/issues/2 (update regulation) -->
