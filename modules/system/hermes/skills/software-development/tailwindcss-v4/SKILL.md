---
name: tailwindcss-v4
description: Enforce correct Tailwind CSS v4 usage in all projects. Use when writing, reviewing, or modifying any component, page, or stylesheet that uses Tailwind CSS utility classes — new files, edits, code reviews, and v3 to v4 migrations.
trigger: Use when writing or reviewing Tailwind CSS utility classes, @theme, @apply, @utility, dark mode, cn(), twMerge, or any Tailwind utility pattern.
---

# Tailwind CSS v4 Skill

## Overview

This skill governs all Tailwind CSS usage. The current stable version is **v4.2.x** (latest: 4.2.4 as of May 2026). Always use v4 — never v3 — unless the project's `package.json` explicitly locks to v3 and migration is out of scope.

**Official docs**: https://tailwindcss.com/docs  
**Upgrade guide (v3 → v4)**: https://tailwindcss.com/docs/upgrade-guide  
**v4 blog post**: https://tailwindcss.com/blog/tailwindcss-v4  
**v4.1 blog post**: https://tailwindcss.com/blog/tailwindcss-v4-1  
**Compatibility**: https://tailwindcss.com/docs/compatibility  
**Dark mode**: https://tailwindcss.com/docs/dark-mode  

When unsure about a specific utility or API, `web_fetch` the relevant docs page before writing code.

---

## Rule 1: Always Use v4, Never v3

Install the latest v4:

```bash
# Next.js (PostCSS — required for Next.js)
npm install tailwindcss @tailwindcss/postcss postcss

# Vite / React
npm install tailwindcss @tailwindcss/vite

# Webpack (v4.2+)
npm install tailwindcss @tailwindcss/webpack
```

**CSS entry point** — one line, not `@tailwind` directives:

```css
/* globals.css or main.css */
@import "tailwindcss";
```

**No `tailwind.config.js`** — all customization lives in CSS via `@theme`:

```css
@import "tailwindcss";

@theme {
  --color-brand: oklch(62% 0.19 264);
  --font-sans: "Inter", sans-serif;
  --breakpoint-3xl: 1920px;
}
```

**Next.js `postcss.config.mjs`** (required — Next.js does not support the Vite plugin):

```js
const config = { plugins: { "@tailwindcss/postcss": {} } };
export default config;
```

### v3 → v4 Patterns to Never Use

| ❌ v3 (never use)                        | ✅ v4                             |
|------------------------------------------|-----------------------------------|
| `@tailwind base/components/utilities`    | `@import "tailwindcss"`           |
| `tailwind.config.js` theme              | `@theme { }` in CSS               |
| `bg-[--my-var]`                          | `bg-(--my-var)`                   |
| `shadow-sm` (was the smallest)           | `shadow-xs`                       |
| `shadow` (bare)                          | `shadow-sm`                       |
| `blur` (bare)                            | `blur-sm`                         |
| `rounded` (bare)                         | `rounded-sm`                      |
| `ring` (was 3px in v3)                   | `ring-3`                          |
| `@tailwindcss/container-queries` plugin  | Built-in `@container` support     |
| `overflow-ellipsis`                      | `text-ellipsis`                   |
| `start-*` / `end-*` (deprecated in v4.2)| `inset-s-*` / `inset-e-*`        |
| `tailwindcss-animate` plugin             | `tw-animate-css` package          |

---

## Rule 2: No Unnecessary Arbitrary Values

**Never use arbitrary values when a canonical class exists.** This is the most common AI mistake.

### Opacity Modifiers

```tsx
// ❌ Wrong — unnecessary bracket notation
border-black/[.08]
bg-white/[0.5]
text-black/[.25]

// ✅ Correct — integer 0–100, no brackets, no decimals
border-black/8
bg-white/50
text-black/25
```

### Spacing / Sizing

Default spacing scale: `1 unit = 0.25rem = 4px`. So `w-4 = 1rem = 16px`.

```tsx
// ❌ Wrong
w-[16px]  p-[8px]  m-[24px]  gap-[12px]

// ✅ Correct
w-4       p-2      m-6       gap-3
```

In v4 the scale is **dynamic and infinite** — `w-17`, `p-13`, `m-29` all work without config.

### Aspect Ratio (v4 fraction syntax)

```tsx
// ❌ Wrong — arbitrary when fraction syntax works
aspect-[16/9]   aspect-[4/3]   aspect-[1/1]

// ✅ Correct — v4 supports fraction syntax directly
aspect-16/9     aspect-4/3     aspect-square
```

### Colors

```tsx
// ❌ Wrong — arbitrary when a named color exists
bg-[#3b82f6]     // bg-blue-500
text-[#ef4444]   // text-red-500

// ✅ Correct
bg-blue-500
text-red-500
```

Only use arbitrary color values for truly custom colors not in the default palette.

### Fonts — define in @theme, never as arbitrary

```tsx
// ❌ Wrong — arbitrary font
font-['Inter']
font-[Inter]

// ✅ Correct — define in @theme, then use the utility
// In globals.css:
// @theme { --font-sans: "Inter", sans-serif; }
font-sans
```

### CSS Variable Shorthand (v4 syntax — parentheses, not brackets)

```tsx
// ❌ v3 style
bg-[--brand-color]   text-[--foreground]

// ✅ v4 style
bg-(--brand-color)   text-(--foreground)
```

### Shorthand Collapsing

Always collapse redundant class pairs:

```
px-[1.2rem] py-[1.2rem]          →  p-[1.2rem]
w-5 h-5                          →  size-5
w-1234 h-1234                    →  size-1234
border-t-2 border-b-2            →  border-y-2
border-l-2 border-r-2            →  border-x-2
overflow-x-hidden overflow-y-hidden  →  overflow-hidden
scroll-mt-4 scroll-mb-4          →  scroll-my-4
```

---

## Rule 3: Canonical Class Preference

Canonicalization checklist — run this mentally before finalising any class list:

1. Can the arbitrary value be replaced by a scale value? (px → spacing unit)
2. Can an opacity modifier be written as an integer with no brackets?
3. Can two directional utilities collapse into a shorthand (x/y/bare)?
4. Can `w-N h-N` collapse to `size-N`?
5. Is a CSS variable using `()` not `[]`?
6. Is shadow/blur/radius using the renamed v4 scale (`-xs`, `-sm` etc.)?
7. Is `aspect-[N/M]` replaceable with `aspect-N/M`?
8. Is `ring` (bare) written as `ring-3`?
9. Is a font defined as arbitrary instead of a `@theme` variable?

Additional canonicalization rules from v4's auto-migrator:
- `-tracking-tighter` → `tracking-wider` (prefer positive canonical)
- `-left-[9rem]` → `left-[-9rem]` (sign moves inside arbitrary value)
- `ml-[calc(-1*var(--width))]` → `-ml-(--width)`

---

## Rule 4: Dark Mode

**Default (media query)** — works out of the box, no config:

```tsx
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  ...
</div>
```

The `dark:` variant is active when `prefers-color-scheme: dark`. Pattern: **light class first, dark: class second**.

**Class-based dark mode** — use when the user can manually toggle. Configure with `@custom-variant` in CSS (replaces the old `darkMode: 'class'` config key, which no longer exists):

```css
/* globals.css */
@import "tailwindcss";

/* Option A: toggle via .dark class on <html> */
@custom-variant dark (&:where(.dark, .dark *));

/* Option B: toggle via data attribute */
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));
```

Then toggle in JS:

```ts
// Option A
document.documentElement.classList.toggle('dark')

// Option B
document.documentElement.setAttribute('data-theme', 'dark')
```

**Theme tokens for dark mode** — define semantic CSS variables and flip them:

```css
@import "tailwindcss";

@theme {
  --color-background: oklch(98% 0 0);
  --color-foreground: oklch(15% 0 0);
}

/* flip in dark */
@layer base {
  .dark {
    --color-background: oklch(12% 0 0);
    --color-foreground: oklch(95% 0 0);
  }
}
```

```tsx
<body className="bg-(--color-background) text-(--color-foreground)">
```

**Next.js with `next-themes`** (recommended for user-togglable + SSR-safe dark mode):

```bash
npm install next-themes
```

```tsx
// app/providers.tsx
import { ThemeProvider } from 'next-themes'
export function Providers({ children }) {
  return <ThemeProvider attribute="class">{children}</ThemeProvider>
}
```

Then use `@custom-variant dark (&:where(.dark, .dark *))` in CSS.

---

## Rule 5: Custom Utilities — `@utility`, not `@layer utilities`

In v4, define custom utilities with `@utility` (not the v3 `@layer utilities` approach). Always define them in your main CSS file (e.g. `globals.css`), never in component-scoped styles.

```css
/* globals.css */
@import "tailwindcss";

/* Static custom utility */
@utility card {
  border-radius: var(--radius-lg);
  padding: var(--spacing-6);
  background: var(--color-white);
  box-shadow: var(--shadow-md);
}

/* Functional (dynamic value) utility */
@utility text-stroke-* {
  -webkit-text-stroke-width: --value(integer)px;
  -webkit-text-stroke-width: --value([*]);
}
```

Usage in markup:

```tsx
<div className="card">...</div>
<h1 className="text-stroke-2">...</h1>
```

**`@apply` rules** — use sparingly; prefer utility classes in markup. When `@apply` is needed:

```css
/* ✅ Correct — in globals.css or a file processed as one unit */
@utility btn-primary {
  @apply bg-blue-500 text-white rounded-md px-4 py-2 hover:bg-blue-600;
}
```

```tsx
/* ❌ Never use @apply in component <style> blocks (Vue/Svelte) or CSS Modules
   without first importing globals as reference: */

/* ✅ Correct in a scoped style block */
@reference "../app/globals.css";
button { @apply bg-blue-500; }
```

The `@reference` directive tells Tailwind where to find your theme definitions without re-emitting them. Without it, `@apply` will silently fail or produce wrong output.

**Avoid `@apply` entirely when possible** — styling directly in markup is faster to build and easier to override.

---

## Rule 6: Class Merging with `cn()` — Always Use It in React/Next.js

Every Next.js / React project should have a `cn()` utility. Without it, dynamically composed class strings will produce **silent conflicts** (e.g. both `bg-blue-500` and `bg-red-500` in the final string — last writer wins unpredictably).

**Install once per project:**

```bash
npm install clsx tailwind-merge
```

**Create `src/lib/utils.ts` (or `lib/utils.ts`):**

```ts
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

**Always import and use `cn()` for className construction:**

```tsx
import { cn } from '@/lib/utils'

// ✅ Correct — conflict-free conditional classes
<button
  className={cn(
    'rounded-md px-4 py-2 text-white transition-colors',
    isPrimary ? 'bg-blue-500 hover:bg-blue-600' : 'bg-gray-500 hover:bg-gray-600',
    isDisabled && 'opacity-50 cursor-not-allowed',
    className   // always spread external className last so consumers can override
  )}
>

// ❌ Wrong — template literals don't resolve conflicts
<button className={`rounded-md ${isPrimary ? 'bg-blue-500' : 'bg-gray-500'} ${className}`}>
```

**Why `twMerge` matters:**

```ts
twMerge('px-4 py-2', 'px-6')      // → 'py-2 px-6'   ✅ px-4 removed
'px-4 py-2' + ' ' + 'px-6'        // → 'px-4 py-2 px-6'  ❌ conflict, px-4 wins (cascade order)
```

**Component pattern — always accept and merge `className` prop:**

```tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary'
}

export function Button({ variant = 'primary', className, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded-md px-4 py-2 font-medium transition-colors',
        variant === 'primary' && 'bg-blue-500 text-white hover:bg-blue-600',
        variant === 'secondary' && 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        className
      )}
      {...props}
    />
  )
}
```

---

## Rule 7: Variant Stacking Order

When stacking multiple variants, the correct order is:

```
responsive : dark : state : utility
```

```tsx
// ✅ Correct order
dark:md:hover:bg-fuchsia-600
md:hover:text-lg
sm:motion-safe:hover:animate-spin

// ❌ Wrong order (responsive after state)
hover:md:bg-blue-500   // broken — md: must come before hover:
```

Rule of thumb: **breakpoints outermost, state variants innermost**, dark/motion in between.

---

## Rule 8: Next.js Specific Guidelines

1. **PostCSS only** — Next.js does not support `@tailwindcss/vite`. Use `@tailwindcss/postcss`.
2. **Import `globals.css`** in `app/layout.tsx` (App Router) or `pages/_app.tsx` (Pages Router).
3. **No `tailwind.config.ts/js`** in v4 — all theme tokens go in `@theme {}` in `globals.css`.
4. **`className` not `class`** — always `className` in JSX.
5. **Animations** — use `tw-animate-css` not `tailwindcss-animate` (deprecated):
   ```bash
   npm install tw-animate-css
   ```
   ```css
   /* globals.css */
   @import "tailwindcss";
   @import "tw-animate-css";
   ```
6. **`@source` directive** — needed when Tailwind can't auto-detect classes (e.g. UI libraries outside the project root):
   ```css
   @source "../node_modules/@my-org/ui/src";
   ```

### Complete Next.js v4 Setup

```css
/* app/globals.css */
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --font-sans: "Inter", sans-serif;
  --color-brand: oklch(62% 0.19 264);
  --radius-lg: 0.75rem;
}
```

```js
/* postcss.config.mjs */
const config = { plugins: { "@tailwindcss/postcss": {} } };
export default config;
```

```json
/* .prettierrc */
{
  "plugins": ["prettier-plugin-tailwindcss"],
  "tailwindStylesheet": "./app/globals.css"
}
```

---

## Rule 9: Prettier Plugin Setup (Required for v4)

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

**Critical v4 change**: you must specify `tailwindStylesheet` (was `tailwindConfig` in v3):

```json
// .prettierrc
{
  "plugins": ["prettier-plugin-tailwindcss"],
  "tailwindStylesheet": "./app/globals.css"
}
```

Without `tailwindStylesheet`, the plugin won't see your `@theme` customizations and will sort classes incorrectly.

---

## Quick Anti-Pattern Reference

| Anti-pattern | Fix |
|---|---|
| `border-black/[.08]` | `border-black/8` |
| `bg-white/[0.5]` | `bg-white/50` |
| `w-[16px]` | `w-4` |
| `p-[8px]` | `p-2` |
| `aspect-[16/9]` | `aspect-16/9` |
| `font-['Inter']` | Define in `@theme`, use `font-sans` |
| `bg-[--brand]` | `bg-(--brand)` |
| `shadow` | `shadow-sm` (v4 renamed) |
| `shadow-sm` | `shadow-xs` (v4 renamed) |
| `rounded` | `rounded-sm` (v4 renamed) |
| `blur` | `blur-sm` (v4 renamed) |
| `ring` (bare) | `ring-3` (was 3px in v3) |
| `w-5 h-5` | `size-5` |
| `border-t-2 border-b-2` | `border-y-2` |
| `overflow-x-auto overflow-y-auto` | `overflow-auto` |
| `start-4` / `end-4` | `inset-s-4` / `inset-e-4` |
| `@tailwind base` | `@import "tailwindcss"` |
| `tailwind.config.js` | `@theme {}` in CSS |
| `@layer utilities { .foo { } }` | `@utility foo { }` |
| `darkMode: 'class'` in config | `@custom-variant dark (...)` in CSS |
| `tailwindcss-animate` | `tw-animate-css` |
| Template literal className concat | `cn()` from `clsx` + `tailwind-merge` |
| `hover:md:bg-blue-500` | `md:hover:bg-blue-500` |
| `@apply` in component `<style>` | Add `@reference "../globals.css"` first |

---

## When to Look Up Docs

Always `web_fetch` from `https://tailwindcss.com/docs/[topic]` when:
- You're unsure if a utility exists in v4 or was renamed
- You're about to use an arbitrary value and want to verify no canonical class exists
- You're implementing v4.1+ features (text-shadow, masks, colored drop-shadow)
- You need the exact `@custom-variant` syntax for a dark mode strategy
- You're unsure about browser support for a modern CSS feature

Key doc pages:
- `https://tailwindcss.com/docs/dark-mode`
- `https://tailwindcss.com/docs/adding-custom-styles` (for `@utility`)
- `https://tailwindcss.com/docs/compatibility` (for `@apply` and `@reference`)
- `https://tailwindcss.com/docs/hover-focus-and-other-states` (variant stacking)
