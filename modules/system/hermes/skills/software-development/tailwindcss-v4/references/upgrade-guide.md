# Tailwind CSS v4 — Upgrade Guide
> Source: https://tailwindcss.com/docs/upgrade-guide  
> Fetched: May 2026 (v4.2)

## Automated upgrade tool

```bash
npx @tailwindcss/upgrade
```

Handles: dependency updates, config file → CSS migration, template changes.  
Requires Node.js 20+. Run in a new branch, review the diff before merging.

## Browser requirements

v4.0 targets **Chrome 111+, Safari 16.4+, Firefox 128+**.  
If you need older browser support, stay on v3.4.

---

## Manual upgrade steps

### PostCSS

Replace `tailwindcss` + `postcss-import` + `autoprefixer` with a single package:

```js
// postcss.config.mjs — BEFORE (v3)
export default {
  plugins: {
    "postcss-import": {},
    tailwindcss: {},
    autoprefixer: {},
  },
};

// postcss.config.mjs — AFTER (v4)
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

### Vite

```ts
// vite.config.ts
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss()],
});
```

### Tailwind CLI

```bash
# v3
npx tailwindcss -i input.css -o output.css

# v4
npx @tailwindcss/cli -i input.css -o output.css
```

---

## Breaking changes from v3

### @tailwind directives removed

```css
/* v3 — REMOVE */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* v4 — USE */
@import "tailwindcss";
```

### Deprecated utilities removed

| Removed | Replacement |
|---|---|
| `bg-opacity-*` | `bg-black/50` |
| `text-opacity-*` | `text-black/50` |
| `border-opacity-*` | `border-black/50` |
| `divide-opacity-*` | `divide-black/50` |
| `ring-opacity-*` | `ring-black/50` |
| `placeholder-opacity-*` | `placeholder-black/50` |
| `flex-shrink-*` | `shrink-*` |
| `flex-grow-*` | `grow-*` |
| `overflow-ellipsis` | `text-ellipsis` |
| `decoration-slice` | `box-decoration-slice` |
| `decoration-clone` | `box-decoration-clone` |

### Renamed utilities

| v3 | v4 |
|---|---|
| `shadow-sm` | `shadow-xs` |
| `shadow` | `shadow-sm` |
| `drop-shadow-sm` | `drop-shadow-xs` |
| `drop-shadow` | `drop-shadow-sm` |
| `blur-sm` | `blur-xs` |
| `blur` | `blur-sm` |
| `backdrop-blur-sm` | `backdrop-blur-xs` |
| `backdrop-blur` | `backdrop-blur-sm` |
| `rounded-sm` | `rounded-xs` |
| `rounded` | `rounded-sm` |
| `outline-none` | `outline-hidden` |
| `ring` | `ring-3` |

### Gradient changes

In v4, gradient stop values are preserved across variants. Use `via-none` to explicitly unset a middle stop:

```html
<!-- v3 behaviour was to reset; v4 preserves, so be explicit -->
<div class="bg-linear-to-r from-red-500 via-orange-400 to-yellow-400
            dark:via-none dark:from-blue-500 dark:to-teal-400">
```

### Default border/divide color

v3 defaulted to `gray-200`. v4 defaults to `currentColor` at 10% opacity. To restore v3 behavior add to CSS:

```css
@layer base {
  *, ::after, ::before, ::backdrop, ::file-selector-button {
    border-color: var(--color-gray-200, currentColor);
  }
}
```

### Preflight changes

- Placeholder text: now `currentColor` at 50% opacity (was `gray-400`)
- Buttons: `cursor: default` (was `cursor: pointer`)
- `<dialog>` margins reset to 0
