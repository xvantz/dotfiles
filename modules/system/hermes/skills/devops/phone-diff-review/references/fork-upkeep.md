# diff2html fork upkeep

Fork lives at `/projects/diff2html`, review work happens on branch
`feature/phone-comments`. It adds a first-class comment layer to the
render library in `src/comments.ts`:

- `Diff2HtmlComments` — tap a line-number cell selects
  `{file, oldLine, newLine}`; second tap on the same row clears the
  selection. `openEditor({onSubmit, onCancel, ...})` inserts an inline
  editor row under the selected line, `closeEditor()` removes it
  (selecting another row closes the old editor first).
- `setComments(comments, {onDelete})` — badges plus GitHub-style
  threads under commented lines; each thread item carries a delete
  button reporting the comment index. No `onDelete` means no button.
- `matchComment` — file + new-line match, old-line match for deleted
  rows; the server must store anchors in the same `oldLine`/`newLine`
  keys or nothing matches.
- Styles in `src/ui/css/diff2html.css`: `d2h-selected-line`,
  `d2h-comment-badge`, `d2h-comment-thread`/`d2h-comment-body`/
  `d2h-comment`/`d2h-comment-delete`, `d2h-comment-editor` — every
  colored rule needs a dark-scheme variant, otherwise the control
  renders browser-default (white textarea on a dark page).

## Validation gates (all must pass before committing)

```bash
cd /projects/diff2html
npm install --no-audit --no-fund   # once per fresh checkout
npm run build:templates            # generates gitignored src/diff2html-templates.ts; tsc fails without it
npx prettier --check <changed files>
npx eslint <changed files>
npx tsc -p tsconfig.json -m CommonJS --outDir /tmp/d2h-check
npx jest --coverage                 # global thresholds enforced, functions bar is 98%
```

## Rules

- Generate templates before compiling: `tsc` errors about a missing
  `./diff2html-templates` mean the generation step was skipped, not
  that the tree is broken.
- A new module must arrive with tests covering it: coverage
  thresholds are global, so one untested file turns the whole suite
  gate red for everyone.
- Import the module surface from the package index in tests, not from
  the module file directly: compiled re-exports become getter
  functions that istanbul counts, and only an index import exercises
  them (direct-file imports leave them uncovered and the functions
  gate fails).
- Test DOM behavior without a DOM: `testEnvironment` is `node`, so
  build a minimal stub-element harness instead of adding jsdom - a
  `MiniEl` class (`className`/`textContent`/`children`/`appendChild`,
  a listener map with `click()` dispatch, `remove()` raising a flag,
  no-op `focus()`/`setAttribute()`) plus a `MiniText` for text nodes
  and an `ownerDocument` returning fresh stubs. Drive selection,
  editor open/submit/cancel/replace, badge and thread insertion
  through it and assert on the stub tree.
- Keep the comment schema identical on both sides of the wire: the
  `ReviewComment` keys in the fork, the JSON keys in the comments
  file, and the keys the page POSTs must all match. A mismatch
  renders nothing and looks exactly like a frontend bug while the
  data path is broken - prove the round trip with curl, not just
  unit tests.
- The skill generates review pages from the fork bundle
  (`assets/diff2html-fork.min.js`/`.css`, built with
  `npm run build:bundles build:css` and copied into the skill), not
  from the npm CLI - CLI output cannot reach native fork behavior.
  Rebuild and re-copy the assets after every fork change that
  affects rendering, then regenerate the served page.
