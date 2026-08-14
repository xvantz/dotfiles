# Tailwind CSS v4 — Compatibility
> Source: https://tailwindcss.com/docs/compatibility  
> Fetched: May 2026 (v4.2)

## Browser support

| Browser | Minimum version | Released |
|---|---|---|
| Chrome | 111 | March 2023 |
| Safari | 16.4 | March 2023 |
| Firefox | 128 | July 2024 |

Some utilities use bleeding-edge features (`field-sizing`, `@starting-style`, `text-wrap: balance`) with limited support — check [caniuse.com](https://caniuse.com) before using them.

---

## No CSS preprocessors

Tailwind v4 **replaces** preprocessors. Do not use Sass, Less, or Stylus alongside it.

- **Imports**: Tailwind bundles `@import` automatically — no `postcss-import` needed
- **Variables**: use native CSS variables (`var(--foo)`) — no Sass vars
- **Nesting**: Tailwind uses Lightning CSS for nesting — no plugins needed
- **Vendor prefixes**: Tailwind adds them automatically — no autoprefixer needed

---

## CSS Modules

Tailwind can co-exist with CSS Modules but they're processed separately — each module is isolated from Tailwind's pipeline. Limitations:

- `@apply` won't see utilities defined in other modules
- Custom utilities from `@utility` are only available in the file they're defined in

**Recommendation**: avoid CSS Modules + Tailwind together where possible. Style with utility classes directly in markup.

---

## @apply in component style blocks (Vue, Svelte, Astro)

Component `<style>` blocks are processed separately from your main CSS file — `@apply` breaks because Tailwind's theme variables aren't in scope.

**Fix**: add `@reference` at the top of the style block to import definitions without re-emitting them:

```vue
<template>
  <button><slot /></button>
</template>

<style scoped>
@reference "../app/globals.css";

button {
  @apply bg-blue-500 text-white rounded-md px-4 py-2;
}
</style>
```

**Alternative (better performance)**: use CSS variables directly instead of `@apply`:

```vue
<style scoped>
button {
  background-color: var(--color-blue-500);
  color: var(--color-white);
  border-radius: var(--radius-md);
}
</style>
```

Using CSS variables skips Tailwind's processing entirely for that file — faster builds.

**Best practice**: avoid `<style>` blocks altogether and style with utility classes in `<template>`.

---

## @apply in Next.js / React (CSS Modules or global CSS)

In Next.js, `@apply` works fine in `app/globals.css` (processed as a single unit). It also works in `.module.css` files but only for utilities defined in that same file.

For `@layer` or `@utility` defined in `globals.css` to be usable with `@apply` in a module:

```css
/* component.module.css */
@reference "../app/globals.css";

.button {
  @apply btn-primary;
}
```

---

## Sass / Less interop

Not supported. Remove Sass/Less entirely when migrating to v4. Everything they provided (variables, nesting, imports, math) is now handled by native CSS + Tailwind's engine.
