---
name: paraglide-js
description: Use when adding or modifying Paraglide JS internationalization, locale detection strategies, localized routing, or generated message usage in Vite, SSR, TanStack Start, or monorepo setups.
trigger: "Paraglide i18n setup, locale detection, SvelteKit SSR"
---

# Paraglide JS

## Overview

Paraglide JS is a compiler-based i18n library that generates typed message functions and runtime helpers. Use this skill when a project needs Paraglide setup, message usage, locale detection, SSR integration, or refactoring around generated `paraglide/` output.

## When To Use

- Adding Paraglide JS to a new or existing app
- Updating locale strategy order or custom strategies
- Wiring SSR locale detection with `paraglideMiddleware()`
- Integrating Paraglide into TanStack Start
- Reusing one `project.inlang` across a monorepo

Do not use this skill for generic copywriting or translation quality review. It is for code integration and runtime behavior.

## Core Workflow

1. Identify the app shape: Vite app, SSR app, TanStack Start app, or monorepo.
2. Prefer the Vite plugin for Vite-based apps.
3. Use CLI compilation when bundler integration is unavailable or when a package needs explicit compile scripts.
4. Add server middleware only for SSR/server request flows.
5. Keep `project.inlang` and message files as the source of truth; treat generated `paraglide/` output as build artifacts.
6. Recompile after changing messages, locales, strategy, or output settings.

## Rules Of Thumb

- Prefer `paraglideVitePlugin()` in Vite projects instead of hand-rolling generated output.
- Prefer built-in strategies before adding custom ones.
- Order strategies intentionally. Earlier strategies win.
- Use one owner for URL rewriting. Do not combine router-level URL rewrites and middleware-driven URL localization without checking for redirect loops.
- In monorepos, default to "each package compiles" unless every consumer can share one identical strategy/runtime.

## Reference Guide

- Read [`references/basics.md`](./references/basics.md) for setup, generated files, and message/runtime usage.
- Read [`references/strategies.md`](./references/strategies.md) for strategy ordering and custom strategies.
- Read [`references/tanstack-start.md`](./references/tanstack-start.md) for TanStack Start integration patterns.
- Read [`references/monorepo.md`](./references/monorepo.md) for shared `project.inlang` patterns across packages.

## Common Mistakes

- Editing generated `src/paraglide/*` files directly instead of changing source messages or config
- Forgetting to recompile after changing `messages/*.json` or `project.inlang/settings.json`
- Adding `paraglideMiddleware()` to client-only SPAs
- Putting a preference strategy before `url` without expecting redirect behavior
- Using TanStack Router rewrites and URL-based middleware localization together without testing for loops

## External Sources

- Official docs: https://inlang.com/m/gerre34r/library-inlang-paraglideJs/
- Vite guide: https://inlang.com/m/gerre34r/library-inlang-paraglideJs/vite
- Monorepo guide: https://inlang.com/m/gerre34r/library-inlang-paraglideJs/monorepo
- Middleware guide: https://inlang.com/m/gerre34r/library-inlang-paraglideJs/middleware
- TanStack Router i18n guide: https://tanstack.com/router/v1/docs/framework/react/guide/internationalization-i18n

