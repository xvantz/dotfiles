# Tailwind CSS v4 — Adding Custom Styles
> Source: https://tailwindcss.com/docs/adding-custom-styles  
> Fetched: May 2026 (v4.2)

## Customizing the theme

All theme customization goes in `@theme` in your CSS file. No `tailwind.config.js`.

```css
@theme {
  --font-display: "Satoshi", sans-serif;
  --breakpoint-3xl: 120rem;
  --color-avocado-100: oklch(0.99 0 0);
  --color-avocado-500: oklch(0.84 0.18 117.33);
  --ease-fluid: cubic-bezier(0.3, 0, 0, 1);
}
```

---

## Arbitrary values

Use square brackets for one-off values when no scale value fits:

```html
<div class="top-[117px] bg-[#bada55] text-[22px]">...</div>
```

Works with responsive and state variants:

```html
<div class="top-[117px] lg:top-[344px] hover:bg-[#bada55]">...</div>
```

CSS variables in arbitrary values — use parentheses syntax (v4):

```html
<!-- ✅ v4 -->
<div class="fill-(--my-brand-color)">...</div>

<!-- ❌ v3 style — still works but not idiomatic -->
<div class="fill-[var(--my-brand-color)]">...</div>
```

---

## Custom utilities with @utility

Define reusable utilities in `globals.css`. These gain full variant support (`hover:`, `md:`, `dark:`, etc.) and appear in IntelliSense.

### Static utility

```css
@utility card {
  border-radius: var(--radius-lg);
  padding: var(--spacing-6);
  background: var(--color-white);
  box-shadow: var(--shadow-md);
}
```

```html
<div class="card hover:shadow-lg dark:bg-gray-800">...</div>
```

### Functional (dynamic value) utility

```css
/* Integer value: text-stroke-2 */
@utility text-stroke-* {
  -webkit-text-stroke-width: --value(integer)px;
}

/* Arbitrary value: text-stroke-[3px] */
@utility text-stroke-* {
  -webkit-text-stroke-width: --value([*]);
}

/* Both combined */
@utility text-stroke-* {
  -webkit-text-stroke-width: --value(integer)px;
  -webkit-text-stroke-width: --value([*]);
}
```

### Container utility (v4 pattern)

```css
@utility container {
  margin-inline: auto;
  padding-inline: var(--spacing-4);

  @media (width >= theme(--breakpoint-sm)) { max-width: theme(--breakpoint-sm); }
  @media (width >= theme(--breakpoint-md)) { max-width: theme(--breakpoint-md); }
  @media (width >= theme(--breakpoint-lg)) { max-width: theme(--breakpoint-lg); }
}
```

---

## Base styles

Add global base styles using `@layer base`:

```css
@layer base {
  h1 { font-size: var(--text-2xl); }
  h2 { font-size: var(--text-xl); }
  a { color: var(--color-blue-500); text-decoration: underline; }
}
```

---

## Using @apply in @utility

`@apply` works inside `@utility` definitions in your main CSS file:

```css
@utility btn-primary {
  @apply bg-blue-500 text-white rounded-md px-4 py-2 hover:bg-blue-600 transition-colors;
}
```

**Warning**: avoid `@apply` for component-scoped styles (Vue `<style>`, CSS Modules).  
If you must, add `@reference` first — see compatibility.md.

---

## Plugins

v4 supports plugins via `@plugin`:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";
```

Or a local plugin file:

```css
@plugin "./my-plugin.js";
```

---

## @source directive

When Tailwind can't auto-detect classes (e.g. component libraries, generated files):

```css
@import "tailwindcss";

/* Scan a library outside the project root */
@source "../node_modules/@my-org/ui/src";

/* Scan a specific glob */
@source "../scripts/**/*.ts";
```
