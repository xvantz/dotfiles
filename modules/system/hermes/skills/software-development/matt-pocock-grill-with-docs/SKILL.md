---
name: matt-pocock-grill-with-docs
description: "Use when stress-testing a plan or a design: relentless interview that writes GLOSSARY.md and ADRs as it goes."
version: 1.1.0
author: Matt Pocock (adapted for Hermes)
license: MIT
metadata:
  hermes:
    tags: [grilling, domain-modeling, architecture, adr, glossary]
    related_skills: [matt-pocock-codebase-design, matt-pocock-improve-codebase-architecture]
---

# Grill With Docs

Relentless interview that sharpens a plan or design and writes the artefacts it produces: the project glossary and the decisions that must not be re-litigated.

Both halves live as supporting files, not as separate skills:

- `skill_view(name="matt-pocock-grill-with-docs", file_path="grilling.md")` - the interview primitive: design tree, frontier rounds, numbered questions each with your recommended answer.
- `skill_view(name="matt-pocock-grill-with-docs", file_path="domain-modeling.md")` - the glossary and ADR discipline: challenge terms, invent edge cases, write decisions down the moment they crystallise.

`skill_view(name="grilling")` and `skill_view(name="domain-modeling")` fail: this pool has no skills under those names. Always pass `file_path`.

## Flow

1. Load `grilling.md` and start the first frontier round. Never ask a question whose answer you could look up yourself - dispatch a sub-agent for facts instead.
2. Load `domain-modeling.md` once terms start moving. Write `GLOSSARY.md` (older repos: `CONTEXT.md`) and `docs/adr/NNNN-*.md` inline, not at the end.
3. Stop when the frontier is empty and the user confirms shared understanding. Do not act on the design before that.
