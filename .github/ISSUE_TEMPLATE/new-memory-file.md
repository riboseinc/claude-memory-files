---
name: Propose a new memory file
about: Suggest a new memory, instruction, settings-fragment, project-claude-md, or path-rule
title: 'propose: <slug>'
labels: ['new-file']
assignees: []
---

## What's the file?

<!-- Brief description of the rule, convention, template, or data. -->

## Which category?

- [ ] `instructions/` — operational rule that always loads
- [ ] `memory/` — reference note or feedback
- [ ] `settings-fragments/` — JSON snippet for `settings.json`
- [ ] `project-claude-md/` — starter `CLAUDE.md` for a project type
- [ ] `rules/` — path-scoped rule with `paths:` frontmatter
- [ ] `hooks/` — **v2 only; will be deferred until v2 opens** (see [SAFETY.md](../SAFETY.md))

## What scope?

- [ ] `universal` — applies regardless of team
- [ ] `team` — team operating norm (specify `team:` qualifier if metanorma-specific etc.)
- [ ] `personal-share` — your data or behavioural preference, opt-in cherry-pick

## Is it ready to PR, or proposal-only?

- [ ] I'll open the PR myself
- [ ] I want feedback on the shape before drafting

## Worked example or local source

<!-- Optional: paste the body of the file (without frontmatter) here, or link to the file in your own ~/.claude/ if you have it locally. -->

## See also

- [SCHEMA.md](../../SCHEMA.md) for the frontmatter contract.
- [CONTRIBUTING.md](../../CONTRIBUTING.md) for the contribution flow.
- [issue #1](https://github.com/riboseinc/claude-memory-files/issues/1) for the foundational design.
