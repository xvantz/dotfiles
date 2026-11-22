# Rule packs: conventions and pitfalls

## Anatomy

One pack = one JSON file with three optional fields:

```json
{
  "include": ["**/*.spec.ts"],
  "exclude": ["**/generated/**"],
  "rules": [
    { "path": "**/Domain/**/*.ts", "rule": "…", "merge_system_rule": false }
  ]
}
```

- `rules[]` is evaluated **in declaration order, first match wins** for a file. The whole chain across layers
  is: private project pack → `common.json` → `stacks/<stack>.json` → `stacks/<lang>/base.json`.
- `merge_system_rule: true` keeps the built-in language doc and appends the pack's text
  ("System-Specific Rules" + "User-Specific Rules" in the resolved prompt). Default `false` **replaces** it.
- `include` is not a whitelist: it only bypasses the `unsupported_ext` and `default_path` gates. It is the
  only way to get `*.spec.ts` / `*_test.go` reviewed.
- `exclude` beats everything user-configurable, `include` included.

## Writing a stack pack

Rules must be imperative and checkable. Bad: "write clean code". Good: "money must use Decimal, rounding
mode must be explicit, no float comparison of amounts" — a reviewer can decide yes/no per line.

Keep each pack to 2-6 path rules. Every rule costs prompt tokens on every matching file; six narrow paths
beat one `**/*` catch-all.

Order inside a pack: narrowest path first. Concretely, a spec-file rule must be declared before any
directory rule that also covers that directory, otherwise the spec rule never fires.

## merge_system_rule decision

| Path | Value | Why |
|---|---|---|
| `**/*.proto`, `**/*.sql` | `true` | built-in language docs are accurate and domain-neutral |
| `**/*.{ts,tsx}` in a backend repo | `false` | embedded TS rule is React-shaped (hooks, inline styles, inner components) and pollutes backend prompts |
| `**/*.{tsx,jsx}` in a frontend repo | `false` | own rule is sharper; avoid duplicate React guidance |
| Go / Python | `false` | own rule covers error handling and concurrency better than the generic one |

With `false`, the pack owns the whole prompt — so carry the security items (secrets, injection, TLS,
error leakage) in your own text, or they are lost.

## Private project packs

Same schema, different location: `~/.config/ocr-review/projects/<name>.json`. Content here may name internal
services, money flows, or business rules — that is exactly why it never goes into the dotfiles repo.

Register the checkout so it resolves automatically:

```json
{
  "repos": {
    "/home/user/work/some-monorepo": { "project": "some", "stack": "typescript/nest-typeorm" }
  }
}
```

Longest path prefix wins, so nested checkouts can carry their own profile.

## Guarding the public tree

`~/.config/ocr-review/leak-terms.txt` holds one term per line (service names, product names, domain words).
`ocr-review --doctor` greps every file under `assets/rules/` for those terms and exits **4** with a list of
hits. Run it before committing changes to the public packs.

The check is a heuristic, not a proof: it catches names you remembered to list. The structural protection is
that project packs live outside the repository at all.

## Process for a new repository

1. `ocr-review --repo <path> --doctor` — see what resolves today.
2. `ocr-review --repo <path> --preview` and `ocr rules check <path>` on 3-5 real files.
3. Add the domain pack to the private root only if the stack pack is genuinely too generic.
4. Run 3-4 real diffs in `--mode audit` (advisory), drop rules that produce only style noise.
5. Only then wire the wrapper into a hook or CI gate.
