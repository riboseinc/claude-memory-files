---
schema-version: 1
name: memory-autoload-default
description: When user says "remember", save to ~/.claude/memory/ + inline operational rule into ~/.claude/instructions/ file @-included from CLAUDE.md.
type: instruction
scope: universal
target: instructions/memory-autoload-default.md
autoload: true
tags: [memory, conventions]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Memory persistence: autoload by default

When the user asks me to "remember", "save to memory", or otherwise persist a preference, fact, or rule for future sessions, the default is **global autoload**: write the memory file to `~/.claude/memory/` *and* wire it so the operational rule reaches every future session automatically without re-asking. Surfacing an irrelevant rule costs nothing meaningful; missing a rule the user has explicitly asked to be remembered costs them re-correcting me.

## The autoload wiring

After writing a memory file at `~/.claude/memory/<type>_<topic>.md`:

1. **Inline the operational rule** into a topically-appropriate `~/.claude/instructions/*.md` file that is already `@`-included from `~/.claude/CLAUDE.md`. Inlining is what makes the rule actually present in context every session — a path-only reference does not load the content.
2. If no existing instruction file is a topical fit, **create a new one** at `~/.claude/instructions/<topic>.md` and add a `@instructions/<topic>.md` line to `~/.claude/CLAUDE.md` under the appropriate thematic group (or open a new group block with an HTML-comment header).
3. **Update the global index** at `~/.claude/memory/MEMORY.md` with a one-line pointer.

The memory file stays as the **fuller record** (rationale, sourced quotes, incident history, the full corpus of substitutions). The instruction file holds the **operational gist** that needs to be in context each session — the rule itself, the actual substitutions, the actual default. Short rules can be inlined entirely; long reference data (glossaries, corpora) can be left in the memory file with a forcing-function pointer from the instruction file.

## Structural reasons that override the default

The autoload-by-default applies unless one of these holds — name the reason explicitly when overriding so the user can challenge the call:

- **The fact is genuinely project-specific** — e.g. "in repo X, the layout convention is Y", or an in-progress migration's state. Use the project-scoped auto-memory at `~/.claude/projects/<project-key>/memory/` instead; that system has its own MEMORY.md and auto-loads only when working in that project.
- **The content is large reference material** (a glossary, a corpus, a long lookup table) that would bloat every session's context. Keep it in `~/.claude/memory/` as a file but reference rather than inline, with a forcing-function paragraph in the instruction telling me when to consult.
- **The information is short-lived** — current task state, today's branch, an in-progress investigation. That belongs in tasks/plan files, not memory.
- **Secrets, credentials, personal data** — never in memory of any flavour.

When in doubt, default to global autoload.

## Confirmation to the user

After saving, briefly state: where the memory file lives, which instruction file picked up the operational rule (or that a new one was created and `@`-included from CLAUDE.md), and that the rule now autoloads. This gives the user the artefact to verify or revise without having to ask.
