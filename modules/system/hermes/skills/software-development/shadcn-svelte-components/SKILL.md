---
name: shadcn-svelte-components
category: svelte
description: Patterns for building and integrating shadcn-svelte components with bits-ui in Svelte 5 projects. Covers Tailwind v4 setup, bits-ui v2 API quirks, Svelte 5 rune compatibility, and common pitfalls.
triggers:
  - 'shadcn-svelte component (button, dialog, calendar, date-picker, popover)'
  - 'bits-ui v2 integration'
  - 'Tailwind v4 + SvelteKit setup'
  - 'Svelte 5 component patterns with bits-ui'
  - 'custom DatePicker or calendar component'
---

# shadcn-svelte Components

## Architecture

```
Svelte 5 + SvelteKit 2
  ├── Tailwind CSS v4 (via @tailwindcss/vite)
  ├── bits-ui v2 (headless primitives, runes-native)
  ├── lucide-svelte (icons)
  ├── clsx + tailwind-merge (cn utility)
  └── shadcn-svelte (wrappers around bits-ui)
```

shadcn-svelte is NOT a component library in the traditional sense — it copies source files into your project. You own the components and can modify them freely.

> Choosing between shadcn-svelte and other UI libraries (Mantine, DaisyUI, TanStack Start)? See skill `frontend-ui-library-selection` for the decision framework.

## Setup

### Dependencies

```json
{
  "dependencies": {
    "bits-ui": "^2.18.0",
    "clsx": "^2.1.0",
    "lucide-svelte": "^1.0.0",
    "tailwind-merge": "^3.6.0",
    "tailwind-variants": "^1.0.0",
    "tailwindcss": "^4.3.0",
    "@tailwindcss/vite": "^4.3.0",
    "@internationalized/date": "^3.7.0"  // required for Calendar
  }
}
```

### Vite config

```javascript
// vite.config.js — add @tailwindcss/vite plugin BEFORE sveltekit()
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss(), sveltekit()],
});
```

### Global CSS (`src/app.css`)

```css
@import "tailwindcss";

@theme inline {
  --color-background: hsl(var(--background));
  --color-foreground: hsl(var(--foreground));
  --color-primary: hsl(var(--primary));
  --color-primary-foreground: hsl(var(--primary-foreground));
  --color-muted: hsl(var(--muted));
  --color-muted-foreground: hsl(var(--muted-foreground));
  --color-border: hsl(var(--border));
  --color-input: hsl(var(--input));
  --color-ring: hsl(var(--ring));
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);
}

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --primary: 156 100% 20%;
    --primary-foreground: 0 0% 98%;
    --border: 240 5.9% 90%;
    --input: 240 5.9% 90%;
    --ring: 156 100% 20%;
    --radius: 0.5rem;
    /* ... other shadcn CSS variables */
  }
  * { @apply border-border; }
  body { @apply bg-background text-foreground; }
}
```

### Utils (`$lib/utils.ts`)

```typescript
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## Component Patterns

### Button (tailwind-variants)

Button variants are defined via `tailwind-variants` (not through Tailwind component classes):

```typescript
// $lib/components/ui/button/index.ts
import { tv, type VariantProps } from "tailwind-variants";
export const buttonVariants = tv({
  base: "inline-flex items-center justify-center ...",
  variants: {
    variant: {
      default: "bg-primary text-primary-foreground ...",
      destructive: "bg-destructive text-destructive-foreground ...",
      outline: "border border-input bg-background ...",
      ghost: "hover:bg-accent hover:text-accent-foreground ...",
    },
    size: { default: "h-9 px-4 py-2", sm: "h-8 rounded-md px-3 text-xs", icon: "h-9 w-9" },
  },
  defaultVariants: { variant: "default", size: "default" },
});
```

The .svelte file applies them with `cn()`:

```svelte
<script lang="ts">
  import { cn } from "$lib/utils.js";
  import { buttonVariants, type ButtonVariants } from "./index.js";
  type Props = ButtonVariants & { class?: string; children?: import("svelte").Snippet; } & Record<string, unknown>;
  let { variant = "default", size = "default", class: className, children, ...rest }: Props = $props();
</script>
<button class={cn(buttonVariants({ variant, size }), className)} {...rest}>
  {#if children}{@render children()}{/if}
</button>
```

### bits-ui Trigger components (required: `child` snippet)

**bits-ui v2 uses Svelte 5 snippets.** The Trigger component expects either a `child` snippet that receives `{ props }` (including event handlers and ARIA attributes), or it wraps its children in a default `<button>`.

**Always use the `child` snippet pattern** for triggers to ensure all event handlers (onclick, aria-expanded, aria-haspopup) are forwarded:

```svelte
<Popover.Trigger>
  {#snippet child({ props })}
    <button {...props} class={cn(buttonVariants({ variant: "outline" }), "...")}>
      {date || "Выберите дату"}
    </button>
  {/snippet}
</Popover.Trigger>
```

Without the `child` snippet, the Trigger wraps children in its own `<button>` — but the wrapper button may not pass through all the styling you need. The `child` pattern gives you full control.

### Two-way binding with `$bindable()`

For components that need `bind:` support (e.g., DatePicker), mark props as bindable:

```typescript
let { date = $bindable(""), time = $bindable("") }: Props = $props();
```

Then the parent can use `bind:`:
```svelte
<DatePicker bind:date={formDate} bind:time={formTime} />
```

Without `$bindable()`, you get the error: `Cannot use 'bind:' with this property. It is declared as non-bindable`.

### Controlled open state (`open`/`onOpenChange` over `bind:open`)

For bits-ui popover/dialog state, prefer controlled props over `bind:open`:

```svelte
<script lang="ts">
  let open = $state(false);
  function onOpenChange(o: boolean) { open = o; }
</script>
<Popover.Root open={open} onOpenChange={onOpenChange}>
```

This avoids issues with context propagation and is more explicit than `bind:open`.

### Portal for content outside modal/dialog

When rendering popovers/calendars inside a modal, always use `Popover.Portal` to teleport the content outside the modal's DOM tree:

```svelte
<Popover.Root>
  <Popover.Trigger>...</Popover.Trigger>
  <Popover.Portal>
    <Popover.Content side="bottom" align="start" class="z-50 bg-white border rounded-lg shadow-xl p-3">
      <!-- calendar grid here -->
    </Popover.Content>
  </Popover.Portal>
</Popover.Root>
```

Without the Portal, the popover content renders inside the modal and can be clipped by `overflow: hidden` or hidden behind a higher z-index modal overlay.

## Custom DatePicker

When bits-ui's Calendar doesn't work (wrong types, missing `@internationalized/date`), build a custom DatePicker using Popover + native Date:

```svelte
<script lang="ts">
  let viewDate = $state(new Date(date || Date.now()));
  // Calendar grid: calculate daysInMonth, firstDayOfWeek, build weeks
  function grid() {
    const y = viewDate.getFullYear(), m = viewDate.getMonth();
    const total = new Date(y, m + 1, 0).getDate();
    const firstDow = (new Date(y, m, 1).getDay() + 6) % 7;
    // Build 6x7 grid with null padding for offset days
  }
</script>
```

Key functions needed:
- `daysInMonth(y, m)` → `new Date(y, m+1, 0).getDate()`
- `firstDayOfWeek(y, m)` → `(new Date(y, m, 1).getDay() + 6) % 7` (Monday-first)
- Date formatting: `String(n).padStart(2, "0")`

## Pitfalls

### Tailwind classes not processed for files outside `src/` directory

Tailwind v4 scans source files for class names. If shared schemas or components are outside the expected directory tree, classes may not be detected. Use `@tailwindcss/vite` which handles this automatically for all imported files.

### Dialog/Modal z-index conflicts with popovers

Popover z-index must exceed modal overlay z-index. In the admin layout, the modal overlay has `z-index: 100`. Popover content needs `z-50` (Tailwind) or `z-[999]` (custom). When rendered via Portal, the popover is outside the modal DOM tree, so z-index is relative to the viewport.

### Calendar requires `@internationalized/date`

bits-ui's Calendar component uses `DateValue` from `@internationalized/date`. Without this package installed, TypeScript will error on Calendar prop types. Install it explicitly:
```bash
npm install @internationalized/date
```

### `tailwindcss` v4 vs v3 config

Tailwind v4 uses CSS-based configuration (`@import "tailwindcss"`, `@theme`, `@layer`), NOT `tailwind.config.js`. The `@tailwindcss/vite` plugin replaces PostCSS. Do NOT install `tailwindcss/postcss` — use the Vite plugin instead.

### Inline calendar grid avoids bits-ui Calendar complexity

Building a calendar grid manually with native `Date` API is simpler than wiring up bits-ui's Calendar (which needs `@internationalized/date` types + complex prop forwarding). The grid is ~30 lines: month navigation buttons, a 7x6 table, and day cell `<button>` elements with `isSelected()` / `isToday()` helpers.

### Relative path aliases in SvelteKit (`$shared`)

When using `$shared: '../shared'` in `svelte.config.js`, the path resolves relative to the **SvelteKit project root** (where `svelte.config.js` lives). In Docker, the builder stage copies files independently, so the alias must resolve at build time:

```dockerfile
COPY src/shared ./shared          # → /app/shared/
COPY src/frontend ./frontend      # → /app/frontend/ (SvelteKit root)
```

The alias `../shared` from `/app/frontend/` goes to `/app/shared/` ✅. Without the COPY, Vite resolves the alias to a non-existent path and the build fails.

On the dev machine, the same alias from `src/frontend/` goes to `src/shared/` ✅ — works identically.
