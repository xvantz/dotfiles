---
name: svelte-shadcn-integration
category: svelte
description: Set up and use shadcn-svelte with Tailwind v4 in a SvelteKit project. Covers installation, bits-ui v2 patterns (Popover, Dialog, Calendar), custom DatePicker, and admin CRUD component patterns.
trigger: |
  User asks to add shadcn-svelte to a SvelteKit project, create components with bits-ui, build admin panel UI, or replace native form elements with shadcn equivalents.
version: '1.0'
---

# svelte-shadcn-integration

## Setup

### Dependencies
```bash
npm install tailwindcss @tailwindcss/vite bits-ui lucide-svelte clsx tailwind-merge tailwind-variants
```

### vite.config.js
```js
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss(), sveltekit()],
});
```

### app.css (Tailwind v4 + shadcn CSS variables)
```css
@import "tailwindcss";

@theme inline {
  --color-background: hsl(var(--background));
  --color-foreground: hsl(var(--foreground));
  --color-primary: hsl(var(--primary));
  --color-primary-foreground: hsl(var(--primary-foreground));
  /* ... other shadcn tokens */
}

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --primary: 156 100% 20%;
    --primary-foreground: 0 0% 98%;
    /* ... other colors */
  }
}
```

Import `app.css` in the layout (`+layout.svelte` or admin `+layout.svelte`):
```typescript
import '../../src/app.css';  // path relative to the layout
```

### utils.ts (`$lib/utils.ts`)
```typescript
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### components.json (shadcn-svelte config)
```json
{
  "$schema": "https://shadcn-svelte.com/schema.json",
  "style": "default",
  "tailwind": {
    "css": "src/app.css",
    "baseColor": "zinc"
  },
  "aliases": {
    "components": "$lib/components",
    "utils": "$lib/utils",
    "ui": "$lib/components/ui",
    "hooks": "$lib/hooks"
  }
}
```

## bits-ui v2 Patterns

### Popover — `{#snippet child({ props })}` is MANDATORY
bits-ui v2 Popover.Trigger requires Svelte 5 snippet pattern to forward event handlers and ARIA attributes. **Do NOT** just put children inside Trigger — they won't receive click handlers.

**✅ Correct:**
```svelte
<Popover.Root>
  <Popover.Trigger>
    {#snippet child({ props })}
      <button {...props} class={cn(buttonVariants({ variant: "outline" }))}>
        Click me
      </button>
    {/snippet}
  </Popover.Trigger>
  <Popover.Portal>
    <Popover.Content side="bottom" align="start" class="bg-white border rounded-lg shadow-lg p-3 z-[999]">
      Content
    </Popover.Content>
  </Popover.Portal>
</Popover.Root>
```

**❌ Wrong — won't open:**
```svelte
<Popover.Trigger>
  <button class="...">Click me</button>  <!-- no child snippet → no handler forwarding -->
</Popover.Trigger>
```

### Dialog — use `Root`, `Content`, `Portal`, `Overlay`
```svelte
<script lang="ts">
  import { Dialog as DialogPrimitive } from "bits-ui";
</script>

<DialogPrimitive.Root bind:open>
  <DialogPrimitive.Portal>
    <DialogPrimitive.Overlay class="fixed inset-0 bg-black/40 z-50" />
    <DialogPrimitive.Content class="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 bg-white rounded-lg p-6 z-50 max-w-lg w-full">
      <slot />
    </DialogPrimitive.Content>
  </DialogPrimitive.Portal>
</DialogPrimitive.Root>
```

### Popover with content outside Portal
When Popover is used inside a modal/overlay, render content INSIDE a `Popover.Portal` so it appears above the overlay's z-index. Without Portal, the content renders inside the modal and may be clipped or hidden.

## Custom DatePicker

Build a DatePicker using Popover + a hand-rolled calendar grid (no `@internationalized/date` needed):

- Trigger: Button with `buttonVariants({ variant: "outline" })`
- Calendar grid: native `Date` object, generate weeks with `new Date(y, m+1, 0).getDate()` and `(new Date(y, m, 1).getDay() + 6) % 7`
- Time selector: `<input type="time">` inside the popover
- Navigation: prev/next month buttons, display month/year
- Selection: `onclick` on each day cell, update bindable `date` string

Key state:
```typescript
let date = $bindable("");
let time = $bindable("");
let viewDate = $state(new Date(date || Date.now()));
let open = $state(false);
```

## Shadcn Component Files Structure

```
$lib/
  utils.ts                      ← cn() function
  components/
    ui/
      button/
        index.ts                  ← buttonVariants (tailwind-variants)
        button.svelte             ← <Button> component
      input/
        index.ts
        input.svelte              ← <Input> component
      dialog/
        index.ts
        dialog.svelte             ← Root wrapper
        dialog-content.svelte     ← Portal + Overlay + Content
      popover/
        index.ts
        popover-content.svelte
      calendar/
        index.ts
        calendar.svelte
      date-picker/
        date-picker.svelte
```

## Pitfalls

- **Tailwind classes might not be detected** in Tailwind v4 for dynamically constructed class strings. Keep classes as full strings, not concatenated.
- **$lib alias path differences** between dev and Docker: the SvelteKit project root is `src/frontend/` on dev but `/app/frontend/` in Docker. Relative aliases like `$shared: '../shared'` resolve differently. Prefer `$lib` (built-in, works everywhere) or copy shared files inside the frontend dir.
- **MCP API file writes can desync git** — when creating/updating files via Forgejo REST API, the database representation may go out of sync. Do `git clone + git push` after batches to resync.
- **`COPY drizzle ./drizzle` in Dockerfile** — `COPY drizzle ./` copies folder CONTENTS to root, not the folder itself. If migration files end up at `/app/0000_*.sql` instead of `/app/drizzle/0000_*.sql`, the migrator can't find `meta/_journal.json`.
- **Force push loses API-created files** — files created via MCP API before a force push are lost because the API writes are not in the local git history. Always pull/git sync before force push.
