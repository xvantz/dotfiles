# diff2html fork upkeep

Fork lives at `/projects/diff2html`, review work happens on branch
`feature/phone-comments`. It adds a first-class comment layer to the
render library: `src/comments.ts` exports `Diff2HtmlComments`
(tap a line-number cell selects `{file, oldLine, newLine}`),
`matchComment` (file + new-line match, old-line match for deleted
rows), plus `d2h-selected-line` / `d2h-comment-badge` styles in
`src/ui/css/diff2html.css`.

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
- Prefer the npm CLI plus `scripts/inject-comments.py` for one-off
  review pages (tracks upstream for free); rebuild from the fork only
  when the comment layer needs native behavior the injection cannot
  reach.
