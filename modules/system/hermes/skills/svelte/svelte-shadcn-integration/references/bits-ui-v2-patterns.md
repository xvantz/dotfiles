# bits-ui v2 Patterns

## Component APIs

| Component | Import | Key Props |
|-----------|--------|-----------|
| Popover.Root | `import { Popover } from "bits-ui"` | `open`, `onOpenChange` |
| Popover.Trigger | same | uses `{#snippet child({ props })}` |
| Popover.Portal | same | renders content at document body |
| Popover.Content | same | `side`, `align`, `sideOffset`, `class` |
| Dialog.Root | `import { Dialog as D } from "bits-ui"` | `open`, `onOpenChange` |
| Dialog.Content | same | — |
| Dialog.Overlay | same | — |
| Dialog.Portal | same | — |
| Calendar.Root | `import { Calendar as C } from "bits-ui"` | needs `@internationalized/date` for DateValue |
| Calendar.Header | same | — |
| Calendar.Grid | same | — |

## Snippet Pattern (MANDATORY for Trigger)

bits-ui v2 components with interactive trigger elements require the `child` snippet pattern to forward DOM event handlers:

```svelte
<Popover.Trigger>
  {#snippet child({ props })}
    <button {...props}>Open</button>
  {/snippet}
</Popover.Trigger>
```

The `{props}` object includes:
- `onclick` — opens/closes the popover
- `aria-expanded` — accessibility
- `aria-haspopup` — accessibility
- `type="button"` — prevents form submission
- `id` — for ARIA linking with content

## Dialog Pattern

Dialog uses `Root → Portal → Overlay + Content`. No snippet needed for just rendering children:

```svelte
<DialogPrimitive.Root>
  <DialogPrimitive.Portal>
    <DialogPrimitive.Overlay class="..." />
    <DialogPrimitive.Content class="...">
      <DialogPrimitive.Close>✕</DialogPrimitive.Close>
      Content here
    </DialogPrimitive.Content>
  </DialogPrimitive.Portal>
</DialogPrimitive.Root>
```

## Popover with Calendar (DatePicker)

```svelte
<Popover.Root bind:open>
  <Popover.Trigger>
    {#snippet child({ props })}
      <button {...props}>{date}</button>
    {/snippet}
  </Popover.Trigger>
  <Popover.Portal>
    <Popover.Content>
      <Calendar />  <!-- or custom calendar grid -->
      <input type="time" />
    </Popover.Content>
  </Popover.Portal>
</Popover.Root>
```

## Version Compatibility

- bits-ui v2.18.x works with Svelte 5 and Runes
- Calendar component requires `@internationalized/date` package for DateValue types
