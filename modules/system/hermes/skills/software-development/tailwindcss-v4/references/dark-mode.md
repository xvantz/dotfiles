# Tailwind CSS v4 — Dark Mode
> Source: https://tailwindcss.com/docs/dark-mode  
> Fetched: May 2026 (v4.2)

## Default — media query (no config needed)

The `dark:` variant responds to `prefers-color-scheme: dark` automatically. Zero configuration required.

```html
<div class="bg-white dark:bg-gray-800 text-gray-900 dark:text-white">
  ...
</div>
```

Pattern: **light class first, `dark:` class second.**

---

## Manual toggle — class strategy

Override the `dark` variant in your CSS to use a selector instead of the media query.  
The `darkMode: 'class'` config key **no longer exists in v4** — use `@custom-variant` instead.

```css
/* app/globals.css */
@import "tailwindcss";

/* Toggle via .dark class on <html> */
@custom-variant dark (&:where(.dark, .dark *));
```

```html
<html class="dark">
  <body>
    <div class="bg-white dark:bg-black">...</div>
  </body>
</html>
```

Toggle with JS:

```js
document.documentElement.classList.toggle('dark')
```

---

## Manual toggle — data attribute strategy

```css
@import "tailwindcss";

@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));
```

```html
<html data-theme="dark">
  ...
</html>
```

Toggle with JS:

```js
document.documentElement.setAttribute('data-theme', 'dark')
```

---

## Three-way toggle (light / dark / system)

Use `@custom-variant` with the `.dark` class, then sync via `window.matchMedia()`:

```js
// Add inline in <head> to prevent FOUC
document.documentElement.classList.toggle(
  "dark",
  localStorage.theme === "dark" ||
    (!("theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
);

// User picks light
localStorage.theme = "light";

// User picks dark
localStorage.theme = "dark";

// User picks system
localStorage.removeItem("theme");
```

---

## Semantic token pattern (recommended for design systems)

Define light/dark values as CSS variables in `@theme`, flip them in `.dark`:

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-background: oklch(98% 0 0);
  --color-foreground: oklch(15% 0 0);
  --color-surface: oklch(94% 0 0);
  --color-border: oklch(88% 0 0);
}

@layer base {
  .dark {
    --color-background: oklch(12% 0 0);
    --color-foreground: oklch(95% 0 0);
    --color-surface: oklch(18% 0 0);
    --color-border: oklch(28% 0 0);
  }
}
```

```tsx
<body className="bg-(--color-background) text-(--color-foreground)">
  <div className="bg-(--color-surface) border border-(--color-border)">
    ...
  </div>
</body>
```

Switching `.dark` on `<html>` flips every token instantly without component re-renders.

---

## Next.js — use next-themes

```bash
npm install next-themes
```

```tsx
// app/providers.tsx
'use client'
import { ThemeProvider } from 'next-themes'

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      {children}
    </ThemeProvider>
  )
}
```

```tsx
// app/layout.tsx
import { Providers } from './providers'

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

Pair with `@custom-variant dark (&:where(.dark, .dark *))` in `globals.css`.  
`suppressHydrationWarning` is required to avoid React hydration mismatch from class toggling.
