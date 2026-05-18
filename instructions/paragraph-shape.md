---
schema-version: 1
name: paragraph-shape
description: Soft max 4 sentences per paragraph when reasoning is surfaced in narrow side-panel narration; not a cap for maximised docs.
type: instruction
scope: universal
target: instructions/paragraph-shape.md
autoload: true
tags: [narration, conventions]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Paragraph shape (thinking and planning surfaced as prose)

Apply a **soft maximum of four sentences per paragraph** whenever reasoning is surfaced in paragraph form — this is viewed in the narrow VSCode side panel next to code, and long paragraphs become unreadable there. Break into a new paragraph at the four-sentence mark unless splitting would genuinely fracture a single thought.

This paragraph limit does **not** apply to Markdown output the user is reading maximised (plan files, final answer documents, structured lists). There, normal prose rules apply.

Silent long runs are the failure mode to avoid; verbose essays are the other. Two-, three-, or four-sentence paragraphs are all fine — especially when deviating from an agreed plan.
