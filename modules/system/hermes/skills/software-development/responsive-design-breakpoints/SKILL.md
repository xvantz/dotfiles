---
name: responsive-design-breakpoints
description: Explain breakpoints, container widths, Figma grids, and modern fluid layouts to clients and PMs. Map design artboards to Tailwind breakpoints, pick container widths, and answer "our widths don't match the template" questions. Use when a client/PM asks about screen sizes, grid templates, or responsive design.
---

# Responsive Design Breakpoints & Layout Specs

## When to use
- Client or PM asks about screen sizes, Figma grid templates, or "our widths vs framework widths"
- Deciding container width / breakpoints for a new frontend project
- Setting up Figma artboards or a design grid for a client
- Explaining why a layout has empty fields on wide monitors (4K etc.)

## Core mental model: artboards ≠ breakpoints
- **Artboard** (Figma): a canvas width where the designer draws (e.g. 1920, 1440, 1024, 768, 360). It's a *checkpoint*, not a style boundary.
- **Breakpoint**: a min-width threshold where the layout *changes*. It covers everything from that width up to infinity (2xl = "≥1536", NOT "exactly 1536").
- Layouts are fluid between breakpoints; artboards don't have to coincide with breakpoints. This is the #1 confusion for clients.

## Tailwind v4 default breakpoints (mobile-first)
| Prefix | Min width | CSS |
|---|---|---|
| (base) | < 640px | no prefix |
| sm | 640px | 40rem |
| md | 768px | 48rem |
| lg | 1024px | 64rem |
| xl | 1280px | 80rem |
| 2xl | 1536px | 96rem |

- Customizable via `@theme { --breakpoint-3xl: 120rem }` in CSS (v4), but **keep defaults** unless there's a real need: shadcn/ui and other component ecosystems assume defaults; custom breakpoints cost more to maintain than they save.
- `sm:` does NOT mean "mobile". Mobile = unprefixed base styles. `sm:` fires at ≥640px. A 360px artboard is base, not sm.

## Mapping client artboards to breakpoints
| Artboard | Tailwind bucket |
|---|---|
| 1920 | 2xl (≥1536) |
| 1440 | xl (1280-1535) |
| 1024 | lg |
| 768 | md |
| 360 | base (<640) |

Why 2xl = 1536 and not 1920: 1920 is one specific width (Full HD). 1536 = 1920 ÷ 1.25 — Full HD at the very common Windows 125% browser scaling. One 2xl bucket covers all screens ≥1536 (1600, 1920, 2560, 4K).

## Screen-resolution reality (StatCounter, worldwide, Jun 2025–Jul 2026)
- 1920×1080: ~22.3% — the single most common desktop width
- 1536×864: ~10% (3rd place) — that's Full HD at 125% scaling
- 1366×768: legacy but alive (~8-10%)
- 1440×900: ~5-7%
- Desktop is a distributed spectrum; no single width dominates.
- ⚠️ Do NOT claim "1440 is the most common desktop". 1440 is a *design convention* (Retina MacBook logical width, midpoint of the xl bucket that also covers 1366/1536), not a popularity stat. Ivan caught this exact error — verify stats before asserting.

## Container widths — 2026 standards
- Standard desktop design width: 1366-1440px; **content container ~1140-1280px** (WebHelpAgency 2026 guide). For Full HD screens the same 1140-1280px container is recommended — larger monitors just show more side fields.
- Modern pattern is **hybrid**: full-bleed sections (header, hero, footer, backgrounds) span the whole viewport; content inside is centered in a container. Nobody stretches body text across 1920 — unreadable.
- 1440 vs 1920 artboard: the content area looks identical; only the side fields differ. 1920 is for checking full-width/background elements, optional for non-key pages.

## Fluid design (the "2026 modern" layer)
- `clamp(min, preferred, max)` for type/spacing — scales smoothly, no font-size jumps.
- Container queries (`@container`, `@md:`) — component adapts to its wrapper, not the viewport. Fully supported since 2024.
- "Breakpoints that follow content": set breakpoints where the layout actually breaks, not off a device list (UXPin, Apr 2026).
- Percent/fr grids, `auto-fit/minmax` instead of fixed pixel layouts.
- Practical 5-breakpoint system (UXPin): 360-480 mobile, 481-767 landscape, 768-1023 tablet, 1024-1279 small desktop, 1280+ desktop.

## 4K myth-busting
- CSS pixels ≠ physical pixels. 4K at 150% OS scaling = 2560 CSS viewport; at 200% = 1920. Nobody runs 4K unscaled for browsing.
- 4K is ~2-3% of desktop (StatCounter), mostly gamers/devs — not a content site's audience.
- On a true 3840 viewport with a 1536 container: 1152px fields each side. That's *normal*; NYT/Guardian/Bloomberg look exactly like that on 4K. Fields are "air", not emptiness.
- Never adapt the container to 4K. Fix the background instead: full-bleed colored/gradient sections make wide monitors look intentional.

## Figma grid recipe (client-ready)
- 12 fluid columns (not fixed)
- Desktop: gutter 24px, outer margins 32px
- Tablet (768-1024): gutter 24px, margins 24px
- Mobile (360): gutter 16px, margins 16-20px

## Client communication pattern
Client's real fear behind "which widths do we use": (1) "am I drawing wrong artboards", (2) "will the build match my design". Kill both with confidence + exact numbers, skip the lecture:
1. "Your artboards are correct, the framework widths are just thresholds — no conflict."
2. Give the drawing recipe (which artboards are mandatory vs optional) and the grid numbers.
3. Decouple from third-party community Figma files: "adapting a foreign file takes longer than setting the grid by these numbers."

Ready-to-send client message and source citations: references/client-communication.md

## Pitfalls
- Breakpoint is a min-width threshold, not a screen width. 2xl ≠ 1536px screens; it's "≥1536".
- "1440 most common" is wrong — verify stats before asserting (see above).
- 360 artboard is base, NOT sm — mobile styles come unprefixed.
- 1920 artboard is optional for content sites; 1440 + 360 + 768 are the mandatory core (plus 1024).
- Don't lecture clients on breakpoint mechanics; they need certainty and numbers, not CSS theory.
