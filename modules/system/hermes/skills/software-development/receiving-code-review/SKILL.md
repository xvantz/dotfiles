---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

**NEVER:**
- "You're absolutely right!" (explicit AGENTS.md violation)
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
your human partner: "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From your human partner
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

**your human partner's rule:** "External feedback - be skeptical, but check carefully"

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**your human partner's rule:** "You and reviewer both report to me. If we don't need this feature, don't add it."

## Named-Artifact Objections ("why does this helper exist?")

When a reviewer names one helper as opaque over-engineering, do not defend it and do not delete it
reflexively. Triage that artifact in three buckets and answer each in the reply:

1. **Repo precedent** - grep the repo for the same primitive before calling it exotic:
   `grep -rn --include="*.ts" "<primitive>" apps packages | grep -v node_modules`. Two existing
   precedents turn the objection into a style preference, and the paths settle it.
2. **Mechanism** - state what it protects and from whom, with numbers. A limit on concurrent async
   work throttles **in-flight I/O against an upstream service**, never CPU: one unit of work = N
   outbound calls, so a limit of K caps in-flight calls at K×N. Answering "what concurrency on one
   node?" means naming the protected resource (the gRPC service, the DB) - cores do not enter an
   `await` loop.
3. **Dead semantics** - read the ACTUAL call site, not only the helper. Fail-fast flags, result-order
   guarantees and error propagation only earn their lines when the callback can throw or the caller
   reads results positionally; if the callback catches internally and returns a sentinel, those paths
   are unreachable, so concede and swap in the simplest form (chunked `Promise.all`) rather than
   defending the util.

Before conceding a non-obvious choice, find the constraint that forces it: a session-scoped lock
instead of a transaction-scoped one is usually forced by something else in the design (your own open
transaction would hold a resource the rest of the design reads). Name that constraint - if it
disappears, the artifact goes with it, and that is the simplification to offer.

When the feedback is "start over", check whether a parallel implementation of the same feature already
exists (another branch or MR) and compare **value semantics before code size**: a narrower definition
of the stored value is legitimately smaller, so the size gap is scope, not quality. Present the choice
(adopt the other implementation / fix in place / agree a spec first) instead of deciding silently.

## When Clarified Requirements Land Mid-Review

A review that stalled on "what does the requirement actually mean" usually resumes with answers. Treat
those answers as new evidence and re-run the comparison instead of re-arguing the old points:

1. **Re-check every candidate implementation against the clarified acceptance criterion, in code.** An
   answer like "the value must match what the UI shows" or "this feeds customer messaging" decides
   between two branches by itself: one that copies raw storage fields cannot satisfy it, one that
   recomputes through the same function the UI calls can.
2. **Verify the mechanism before costing a requested field.** A field can be semantically undefined
   under the current rules (a "progress to the next" counter when granting is all-or-nothing) or have
   no source at all. Grep the entity, the config DTO and the write path first; the deliverable is then
   a question back to the requester, not a guess at cost.
3. **Turn unmeasurable wording into numbers before writing code.** "Hard sync", "100%", "realtime"
   cannot be verified as written; restate as "the value equals what the product's own function returns
   at recompute time" plus a per-source lag budget, or the same objection returns at every review.
4. **Re-open the compromises you had marked accepted.** A laggy source, a record that can be missing
   entirely, or a failure deferred to a nightly job all become blocking once sync is mandatory — name
   them as work, not as caveats buried in a spec.

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve your human partner if architectural

**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"

## Acknowledging Correct Feedback

When feedback IS correct:
```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
```

**Why no thanks:** Actions speak. Just fix it. The code itself shows you heard the feedback.

**If you catch yourself about to write "Thanks":** DELETE IT. State the fix instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

State the correction factually and move on.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State limitation, ask for direction |

## Real Examples

**Performative Agreement (Bad):**
```
Reviewer: "Remove legacy code"
❌ "You're absolutely right! Let me remove that..."
```

**Technical Verification (Good):**
```
Reviewer: "Remove legacy code"
✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**YAGNI (Good):**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

**Unclear Item (Good):**
```
your human partner: "Fix items 1-6"
You understand 1,2,3,6. Unclear on 4,5.
✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
```

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

No performative agreement. Technical rigor always.
