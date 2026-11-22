---
name: ocr-code-review
description: "Use when reviewing diffs with Alibaba's ocr CLI."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [CodeReview, CLI, Agents, Quality]
    related_skills: [code-review-skill, phone-diff-review]
---

# Code review via Open Code Review (ocr)

`ocr` (github.com/alibaba/open-code-review) is a review-only CLI: deterministic pipeline (file selection,
file bundling, rule matching, comment positioning) plus an LLM agent for judgement. Use it instead of asking
a coding agent to "review its own work" — self-review in the same context is worthless, an isolated pipeline
with the same model is not.

**It never edits code.** Its command surface has no write/patch command; the only writes are
`~/.opencodereview/sessions/` and the `-o` output file. `suggestion_code` in the report is text, not an
applied patch. Only an agent acting on findings can change files — which is why the write policy lives in
the wrapper, not in the tool.

## Entry point

`scripts/ocr-review` (in this skill) wraps the binary for any repo and any agent: composes rules from
layered packs, keeps artifacts out of the reviewed repo, enforces the write policy.

```bash
SK=/dotfiles/modules/system/hermes/skills/software-development/ocr-code-review
$SK/scripts/ocr-review --repo <path> --doctor               # что откуда берётся + проверка утечек
$SK/scripts/ocr-review --repo <path> --preview              # выбор файлов, ноль токенов
$SK/scripts/ocr-review --repo <path> --from origin/main --gate          # чужой код: audit (правки запрещены)
$SK/scripts/ocr-review --repo <path> --mode fix -B task.md --json       # свой код: правки разрешены
```

- **`--mode audit`** (default) fingerprints the worktree before and after (`git status` + `git diff HEAD` +
  hashes of untracked files) and exits **3** with `AUDIT VIOLATION` if anything changed. Use it when
  reviewing someone else's code or a branch you must not touch.
- **`--mode fix`** allows edits and points at `ocr session compare <before> <after>` so resolved findings
  are proven, not assumed.
- Exit codes: 0 ok · 1 ocr failure or gate hit · 2 no JSON · 3 audit violation · 4 leak found by `--doctor`.
- Artifacts and composed rule files go to `~/.cache/ocr-review/` (`OCR_REVIEW_HOME` overrides).
  Nothing is written inside the reviewed repo.

## Rules: public packs vs private packs

Two roots, and the split is the whole point because the skill lives in a public dotfiles repo.

**Public** (`assets/rules/`, safe to commit): generic stacks only.
```
common.json                        .proto, .sql — stack-independent
stacks/typescript/base.json        generic TS/JS quality + security
stacks/typescript/nest-typeorm.json backend: money, transactions, idempotency, API boundary
stacks/typescript/react.json       hooks discipline, a11y, SSR safety
stacks/go/base.json  stacks/python/base.json
```

**Private** (`~/.config/ocr-review/`, outside git, never committed):
```
projects/<name>.json   доменные правила конкретной системы
repos.json             {"repos": {"/abs/path": {"project": "<name>", "stack": "<stack>"}}}
leak-terms.txt         слова, которых не должно быть в публичном дереве (по строке на термин)
provider.env           KEY=VALUE для OCR_LLM_* — подхватывается обёрткой, если переменные не заданы
```

Resolution order for one file, first match wins:
`project (private)` → `common` → `stacks/<stack>` → `stacks/<lang>/base`.
The repo profile in `repos.json` is picked up automatically by longest path prefix, so the agent does not
have to remember which project a checkout belongs to; `--project` / `--stack` override it.

Why this shape:
- the agent picks the stack pack by detection (`package.json` / `go.mod` / `pyproject.toml`) or by profile —
  no per-repo configuration file has to be committed anywhere;
- domain knowledge (business terms, service names, money rules of a specific product) stays on the machine;
- `--doctor` scans the public rule tree for every term in `leak-terms.txt` and exits 4 on a hit, so a rule
  that leaks an internal name cannot be committed unnoticed.

Add a stack pack when a new stack shows up; add a project pack only in the private root. See
`references/rule-packs.md` for packing conventions and the ordering pitfall.

## Environment

`ocr` must be in PATH (release binary from GitHub releases; `npm i -g` breaks on NixOS read-only store).
Provider is any OpenAI/Anthropic-compatible endpoint:

```bash
export OCR_LLM_URL=https://gateway.example/v1
export OCR_LLM_PROTOCOL=openai
export OCR_LLM_TOKEN=$KEY
export OCR_LLM_MODEL=some-coding-model
export OCR_LLM_EXTRA_HEADERS="header=value"   # ONLY key=value, comma-separated
ocr llm test                                  # must print a clean ✓
```

### Provider credentials in a managed agent environment

Agent tool shells often carry provider keys as **empty strings** (the runtime exports the name, scrubs the
value). A loader that uses `os.environ.setdefault` then never repairs them — treat an empty value as unset:
`if not os.environ.get(key): os.environ[key] = value`.

The wrapper's precedence is: real non-empty env → `~/.config/ocr-review/provider.env` → values resolved from
`$HERMES_HOME/.env` (default `/data/.hermes/.env`). `provider.env` supports `${OTHER_VAR}` indirection, so
the secret never has to be copied — one line points at the variable that already exists:

```
OCR_LLM_URL=https://gateway.example/v1
OCR_LLM_PROTOCOL=openai
OCR_LLM_MODEL=some-coding-model
OCR_LLM_TOKEN=${OPENCODE_GO_API_KEY}
OCR_LLM_EXTRA_HEADERS=x-opencode-session=ses_stable_id
```

Verify through the wrapper, never by eye: `scripts/ocr-review --repo <path> --llm-test` — it runs
`ocr llm test` and fails on `! Tool-call round trip unverified`.

## Invocation cheat sheet

```bash
ocr review --from origin/main            # branch vs merge-base
ocr review --commit abc123
ocr scan --path apps/api/src             # whole files, no diff — audit of inherited code
ocr review -f json -o out.json --audience agent
ocr review --background-file task.md     # review AGAINST the requirement
ocr review --resume <session-id>
ocr viewer                               # WebUI over saved sessions
ocr rules check <path>                   # which rule resolves and from which layer
```

Flags worth knowing: `--effort low|medium|high` (review rounds), `--max-tokens-budget` (ceiling against a
runaway tool loop; the wrapper defaults to 900000), `--concurrency`, `--timeout`, `--max-tools`,
`--no-filter`, `--analysis` (separate impact analysis, commit/range only).

## Cost and latency (measured 2026-11-22, effort medium)

On a monorepo diff of ~30 changed files:

| Metric | Value |
|---|---|
| wall clock | ~2.5 min (8 concurrent subtasks) |
| tokens per file | ~17k |
| cost per run | ~$0.14 |
| share of actionable findings | ~60%; the rest is test hygiene and "confirm this is intended" |

Budget sizing: **~30k tokens per file** at `--effort medium` (rules + file contents + tool rounds).
A ceiling below that truncates the run: `status: partial`, `summary.budget_exceeded: true`, and the affected
groups stop mid-review. The wrapper defaults to 900k and shouts when the budget runs out. Cache-read is
~50x cheaper than fresh input, so repeated runs on a stable ruleset cost a fraction of the first one.

## Using it per feature

One run per feature, before the MR, after tests pass — not per save, not per file. Typing a 1-3 file change
inline beats waiting 60s for a pipeline.

- `--effort low` for intermediate iterations, `medium` for the final pass before review.
- Gate `--gate --gate-severity high` in hooks/CI; `medium` is read by the author; `low` is ignored unless the
  file is unfamiliar. A gate on `low` trains everyone to bypass it.
- Expect roughly 60% actionable findings, the rest test hygiene and "confirm this is intended" questions. Read
  the `high`/`medium` block first and stop when it is exhausted.
- Stop-signal: if actionable findings fall below half across three consecutive features, tune the rules
  (narrow broad project rules, exclude generated paths) instead of getting used to the noise. A reviewer
  nobody believes is worse than no reviewer.
- Reviewing someone else's branch: `--mode audit`, always. The worktree fingerprint is what catches an agent
  that "helpfully fixed" a finding mid-audit (exit 3), so do not soften it to keep a run green.

## Pitfalls

- Generated code (`*.pb.ts`, codegen output, vendored SDKs) belongs in `exclude`, not in a rule. A rule saying
  "do not hand-edit generated code" still pays a full review pass and comes back with comments about the
  generator — pure noise that costs triage time on every run.
- `ocr llm test` does a tool-call round trip; `! Tool-call round trip unverified` means the model never
  called the test tool — treat it as FAIL, the review will be blind.
- Test files are excluded by default (`default_path` gate). Only `include` in a rule pack brings them back;
  `include` is not a whitelist, it bypasses `unsupported_ext` and `default_path`.
- Built-in rules encode one company's monorepo culture. For a backend the embedded TS rule is React-shaped:
  set `merge_system_rule: false` there and carry security checks in your own text. Keep it `true` for
  `.proto` / `.sql`, where the built-in docs are good.
- Narrow patterns must be declared first inside a pack — first match wins, so a `**/services/**` rule placed
  above `**/*.spec.ts` swallows every spec under `services/`.
- The same shadowing happens ACROSS layers: an app-wide project rule (`apps/foo/**/*.ts`) beats the stack's
  `**/services/**` rule, because the private project layer is consulted first and matching never falls
  through per-path. Either narrow the project rule, or re-declare the specific rule first, or rely on the
wrapper hoisting test-path rules to the top when it composes packs. Check with `ocr rules check <file>`
after every pack edit: the printed `Pattern` is the rule that actually won.
- It never runs tests, never reproduces bugs, and its recall is deliberately traded for precision.
  Pipeline order stays: linter → tests → ocr → human judgement — it replaces none of the earlier steps.
- Vendor benchmark numbers (higher precision/F1, ~1/9 tokens, lower recall) come from the project's own
  run — directionally useful, not gospel.
- `ocr` writes session evidence under `~/.opencodereview/sessions/`, including source fragments. Keep that
  in mind when reviewing code you are not allowed to copy.
