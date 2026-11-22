---
name: matt-pocock-improve-codebase-architecture
description: "Архитектурный обзор: shallow-модули, deep-рефакторинг, HTML-отчёт + grilling. Use for architecture review, refactor, разбери архитектуру, мелкие модули."
version: 1.1.0
author: Matt Pocock (adapted for Hermes)
license: MIT
metadata:
  hermes:
    tags: [architecture, codebase-analysis, deepening, visual-report]
    related_skills: [matt-pocock-codebase-design, matt-pocock-grill-with-docs]
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**: refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

**This is a survey, not a rescue.** It hands over candidates; it does not untangle a muddy codebase. Say that out loud when reporting, so nobody expects the report to fix anything by itself.

**Decline on a codebase with no modules yet.** A landing page, a CLI script, a fresh scaffold has no shallow modules to find and no change history to weight by - the run returns generic "extract a module" advice and burns tokens. Refuse and explain why instead of producing an empty report.

This command is _informed_ by the project's domain model and built on a shared design vocabulary:

- Load skill_view(name="matt-pocock-codebase-design") for the architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use these terms exactly in every suggestion, and don't drift into "component," "service," "API," or "boundary."
- The domain language in `GLOSSARY.md` (older repos still call it `CONTEXT.md` - accept either) gives names to good seams; ADRs in `docs/adr/` record decisions this command should not re-litigate.

## Process

### 1. Explore

**Scope before you scan: YAGNI.** Deepening a module pays off by making future changes to it easier, so put extra weight on the parts of the codebase that have recently changed. Decide *where* to look before you look:

- If the user named a direction (a module, a subsystem, a pain point), take it, and skip the inference below.
- Otherwise, walk back a good stretch of the commit history (`git log --oneline`) to find the codebase's hot spots, the files and areas that keep coming up, and let those paths pull your attention first. If the changes are scattered with no clear hot spot, widen the net.

Read the project's domain glossary (`GLOSSARY.md`) and any ADRs in the area you're touching first. If neither exists, say so and build a starter glossary with `skill_view(name="matt-pocock-grill-with-docs", file_path="domain-modeling.md")` before scanning - without domain names the report degrades into generic advice that is indistinguishable from re-reading `git log`.

Then spawn a sub-agent with `delegate_task` and a **fresh context window** - its own goal plus the file paths to start from, not a fork of this conversation. Don't follow rigid heuristics; explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow**, with an interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates as an HTML report

Write a self-contained HTML file to the scratch directory (`$TMPDIR`, i.e. `/data/.hermes/cache/scratch`) so nothing lands in the repo: `architecture-review-<timestamp>.html`, one fresh file per run.

**Delivery on this setup:** the agent runs headless in a container and talks over Telegram, so there is neither a desktop nor a `file://` route. The attached Chrome runs on the *host* (the container is host-network), so it cannot see container paths: `file:///data/.hermes/...` answers `ERR_FILE_NOT_FOUND` while the CDP port stays reachable. Serve the file over HTTP and let Chrome fetch it:

```bash
cd /data/.hermes/cache/scratch && exec python3 -m http.server 8799 --bind 127.0.0.1   # terminal(background=true)
```

Open `http://127.0.0.1:8799/<file>.html` with `browser_exec`, wait ~4-5s for the Tailwind and Mermaid CDNs, and assert the render before capturing - `document.querySelectorAll('pre.mermaid svg').length` must equal the number of diagrams; zero means Mermaid never painted. Then `capture_screenshot(path=..., full=True)` and send the PNG with a `MEDIA:` line plus the absolute path. Two traps: `Page.captureScreenshot` with a hand-built `clip` blows the harness's 5s IPC budget and times out, and `Emulation.setDeviceMetricsOverride` alone lays the page out at the new width but crops the image to the real window, so a full-width report arrives with its right edge cut. Kill the server afterwards (the pid from `terminal(background=true)`, never `pkill -f`) and confirm the port answers `000`. Look at the screenshot before sending: an unstyled page or an empty `<pre class="mermaid">` reaches the user broken, which is worse than a plain-text list of candidates.

The report uses **Tailwind via CDN** for layout and styling, and **Mermaid via CDN** for diagrams where a graph/flow/sequence reliably communicates the structure. Mix Mermaid with hand-crafted CSS/SVG visuals: use Mermaid when relationships are graph-shaped (call graphs, dependencies, sequences), and hand-built divs/SVG when you want something more editorial (mass diagrams, cross-sections, collapse animations). Each candidate gets a **before/after visualisation**. Be visual.

For each candidate, render a card with:

- **Files**: which files/modules are involved
- **Problem**: why the current architecture is causing friction
- **Solution**: plain English description of what would change
- **Benefits**: explained in terms of locality and leverage, and how tests would improve
- **Before / After diagram**: side-by-side, custom-drawn, illustrating the shallowness and the deepening
- **Recommendation strength**: one of `Strong`, `Worth exploring`, `Speculative`, rendered as a badge

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Use GLOSSARY.md vocabulary for the domain, and the `/codebase-design` vocabulary for the architecture.** If `GLOSSARY.md` defines "Order," talk about "the Order intake module," not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting the ADR. Mark it clearly in the card (e.g. a warning callout: _"contradicts ADR-0007, but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

See [HTML-REPORT.md](HTML-REPORT.md) for the full HTML scaffold, diagram patterns, and styling guidance.

Do NOT propose interfaces yet. After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, load `skill_view(name="matt-pocock-grill-with-docs", file_path="grilling.md")` and walk the decision tree with them: constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize; load `skill_view(name="matt-pocock-grill-with-docs", file_path="domain-modeling.md")` to keep the domain model current as you go:

- **Naming a deepened module after a concept not in `GLOSSARY.md`?** Add the term to `GLOSSARY.md`. Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term during the conversation?** Update `GLOSSARY.md` right there.
- **User rejects the candidate with a load-bearing reason?** Offer an ADR, framed as: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Only offer when the reason would actually be needed by a future explorer to avoid re-suggesting the same thing; skip ephemeral reasons ("not worth it right now") and self-evident ones.
- **Want to explore alternative interfaces for the deepened module?** Load skill_view(name="matt-pocock-codebase-design") and use its design-it-twice parallel sub-agent pattern.
