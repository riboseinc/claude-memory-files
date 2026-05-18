---
schema-version: 1
name: narrate-plan
description: Before each non-trivial tool call, state intent in one sentence; name the rejected alternative at decision points.
type: instruction
scope: universal
target: instructions/narrate-plan.md
autoload: true
tags: [narration, conventions]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Narrate plan as you execute

Before each non-trivial tool call, state the intent — one sentence is the default, and the bar to exceed that is high. Use more only when real ambiguity or a change from the agreed plan needs to be flagged; routine reads and edits get one sentence.

At decision points where you picked one approach over another, name the alternative you rejected and why — one short clause.

When a tool result changes your plan from what was agreed, say so explicitly before the next action. This is one of the cases where more than one sentence is warranted.
