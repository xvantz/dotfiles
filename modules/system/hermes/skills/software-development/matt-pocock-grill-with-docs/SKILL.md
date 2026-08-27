---
name: matt-pocock-grill-with-docs
description: "Grilling session that builds project domain model, sharpens terminology and updates CONTEXT.md and ADRs inline. Based on Matt Pocock's approach."
version: 1.0.0
author: Matt Pocock (adapted for Hermes)
license: MIT
metadata:
  hermes:
    tags: [grilling, domain-modeling, architecture, adr, context]
    related_skills: [matt-pocock-codebase-design, matt-pocock-improve-codebase-architecture]
---

---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
disable-model-invocation: true
---

Load skills via skill_view(name): "grilling" and "domain-modeling" (from the corresponding matt-pocock directories).

For Hermes Agent: use skill_view(name="matt-pocock-grill-with-docs-grilling") and skill_view(name="matt-pocock-grill-with-docs-domain-modeling") to load the referenced sub-skills.
