---
name: phone-diff-review
description: "Use when Ivan reviews branch diffs from his phone."
version: 0.2.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [git, review, phone, telegram, diff]
    related_skills: []
---

# Phone Diff Review

Ivan does agent-driven development and reviews multi-commit branches from his
phone (Telegram, small screen, Tailscale-only terminal). Full diffs pasted in
chat are unreadable and TUI pagers over a phone terminal are painful.
Render the diff, never paste it.

**Source of truth:** this skill lives in the repo at
`/dotfiles/modules/system/hermes/skills/devops/phone-diff-review/`
(wired via `external_dirs`, edits apply live, no rebuild). Edit it there -
never keep a second copy under `~/.hermes/skills/`, it shadows the repo one
and drifts out of git.

## Invocation (agreed triggers)

- `review <branch>` (default base `origin/develop`): generate the page from
  the fork, start the server, reply with the URL. Range `A..B` on request.
- `ревью ветки` / `review` with your own findings: the board handed over already
  filled - your comments sit as threads on the lines (see "Ревью с моими замечаниями
  на строках"). A review markdown file in the repo is NOT the deliverable: he drops
  such a commit and asks for the board.
- `финальный ревью` / `ревью с последней проверки` / «дай ревью»: это запрос на ДОСКУ на
  дельте с прошлого замороженного коммита, а не на текстовый разбор в чате. Текстовый вердикт
  без ссылки на доску он возвращает («я именно phone diff review просил»): в чате — 5 строк
  чисел (коммиты, файлы, +/−, зелёные тесты) и URL, а сам дифф он смотрит на телефоне.
- `разбери комменты`: read `$REVIEW_COMMENTS` and answer point by point.
- `удали решённые комментарии` / "убери обработанные": back the file up, empty it, confirm the
  board is clean (procedure below).
- `потуши review`: stop the server.

## When to Use

- Ivan asks to review a branch, a commit range, or what the agent wrote, from his phone.
- Any multi-file diff that must be readable on a small screen without creating an MR.
- Do not use for the review verdict itself (correctness, architecture) - this skill covers the delivery mechanism, not the judgment.

## Procedure

1. Identify the comparison. Default to triple-dot (`base...head`), which shows
   only incoming changes since the merge base - what the branch actually
   introduced. Use double-dot (`A..B`) only when Ivan asks for the full
   difference between two exact points.
   Ivan reviews incrementally: once he says a commit is fully reviewed, that
   commit becomes the base for the next round. Mark it with a local annotated
   tag and build later rounds from it, so the range never drifts:
   `git tag -f -a reviewed-baseline -m "reviewed" <sha>` then diff
   `reviewed-baseline..HEAD`; move the tag forward after he confirms the next
   round. Local tags are not pushed by default.
   Move the tag after EVERY approved round, before starting the next block
   (tests, refactor, next feature): freeze at the last approved commit, then
   the page shows only the new delta. Leave the tag behind and the range grows
   with already-approved code - Ivan flags that immediately. After moving the
   tag, restart the review server (base is captured at startup) and regenerate
   the page. When he names a commit as the reference point ("текущий коммит -
   эталон, новые тесты показывай от него"), move the tag to exactly that commit
   BEFORE writing the new work and state the frozen range back to him - he treats
   every later round as a diff against that anchor.
   Anchor choice follows WHERE your findings sit. When the review you are handing over
   has comments on production code that already lives below `reviewed-baseline` (a full
   branch review, not a test-round delta), render the whole branch (`origin/develop...HEAD`)
   - a comment cannot be pinned to a file that is not in the page. Say which range you
   rendered and why in the handover line, and offer the incremental range as the next round;
   do not silently keep a stale tag that hides half the findings.
2. Pick the renderer, first fit wins:
   a. Branch is pushed: GitLab Compare revisions (Code > Compare revisions,
      Source = feature branch, Target = base). It lists commits plus a
      highlighted per-file diff and creates no MR.
   b. Branch is local/unpushed, or the diff is between two commits: generate a
      static HTML page and send it to Telegram as an attachment for the phone
      browser:
      `npx -y diff2html-cli -i command -F <out>.html -t "<title>" -- <range>`
      (file index, syntax highlight, word-level diff, line/side-by-side modes).
   c. No npm or no network: stdlib fallback `scripts/git-diff-html.py`:
      `python3 scripts/git-diff-html.py <repo> <base> <head> <out>.html`
      (single file, zero dependencies, collapsible per-file sections).
3. Reply short in chat: N commits, M files, +A/-D, files grouped by area
   (contract, producer, consumer, spec, tests). Attach the HTML file. Never
   paste the full diff into chat.
4. Do not create an MR and do not push the branch just to enable review unless
   Ivan asks - options 2b/2c exist exactly for the unpushed case.
5. Comment mode (Ivan taps lines on his phone and asks about them):
   `scripts/review-server.py` (stdlib only) serves the rendered diff plus a
   per-line comment box and stores comments in a JSON file the agent reads.
   ```bash
   export REVIEW_TOKEN=$(python3 -c "import secrets; print(secrets.token_urlsafe(18))")
   export REVIEW_TITLE="<repo> <branch> vs <base>"
   export REVIEW_COMMENTS=/data/.hermes/phone-review/<name>.json
   echo '[]' > "$REVIEW_COMMENTS"
   python3 scripts/review-server.py <repo> <base> <head> <tailscale-ip> 9000
   ```
   Rules: bind the Tailscale IP only (rediscover via ioctl SIOCGIFADDR on
   `tailscale0`, never hardcode), fresh token per session shown once to Ivan,
   run in background. Hand Ivan `http://<ts-ip>:<port>/?token=<token>`.
   Reachable ports: the real firewall is `allowedTCPPorts = [22 80 443 9000]` plus
   53 on `tailscale0` (`/dotfiles/modules/system/network.nix`); 80 and 443 are
   already occupied on the host, so **9000 is the only port Ivan can open from his
   phone**. Never hand him a link on any other port (22005/22006 are NOT open -
   verified 2026-10-19 after handing out a dead 22005 link; an earlier version of
   this note claimed they were). Consequences:
   - one review at a time on 9000. Switching ranges is a RESTART with the range as
     `base`/`head` and its own `REVIEW_COMMENTS` file (see "Reviewing a commit range" below), NOT a hot
     swap of `REVIEW_PAGE`: the swap leaves the server's own `base..head` (title and commit list) on the
     old range and keeps the branch board, so comments from two ranges land in one JSON. Ivan asked for
     "потуши старый и запусти новый на нём же" when I tried the swap.
   - to run two boards at once (e.g. branch + commit range), ask Ivan to add
     22005/22006 to `allowedTCPPorts`; that needs his `nixos-rebuild`, so propose
     the diff, never apply it silently.
   Default port 9000 is shared with `django-dev-preview` sessions, which bind
   `<ts-ip>:9000` and will kill the current occupant to take it, so a review
   server there can die mid-review (observed). Probe before binding
   (`socket.bind((TS_IP, p))`); if 9000 is busy, ask Ivan to tell the other
   session to stand down - never kill the occupant yourself. Verify what you
   actually serve by curling the page and checking `<title>` - a foreign page
   means someone else owns the port.
   `ss`, `nft` and the `tailscale` CLI do not exist on this host - do not build
   checks on them (a missing `ss` looks like "nothing is listening"); read
   `/proc/net/tcp` or try a bind instead. No push from
   server to agent exists: Ivan says "read the comments" when done, the
   agent reads `$REVIEW_COMMENTS` and answers point by point. Stop the server
   afterwards. Page assets (`REVIEW_PAGE`) are read per request, so regenerating
   the page applies live; handler code changes require a server restart.
6. Pretty page = our diff2html fork (no npm at review time). The fork is
   ours now: https://git.827482.xyz/xvantz/diff2html, `master` carries the
   native `Diff2HtmlComments` (tap a line number to open an inline editor
   under the line, second tap on the same line cancels; badges and
   GitHub-style threads mark commented lines). The skill carries a binary
   plus a generator, and the generator keeps the binary fresh by itself:
   - `assets/diff2html-fork.min.js` + `assets/diff2html-fork.min.css`: UMD
     bundle built from the fork. `assets/.fork-rev` stamps which fork rev
     it was built from - update the two together, never one without the other.
   - `scripts/generate-review.js`: before rendering, it compares the fork
     checkout (`$FORK_DIR`, default `/projects/diff2html`) HEAD against the
     stamp and rebuilds (`npm run build:bundles && npm run build:css`) on
     mismatch, then re-copies the bundle. A failed rebuild (or a missing
     checkout / node_modules) falls back to the bundled binary with a
     stderr warning instead of breaking the review. So the skill always
     renders with the current fork code without manual rebuilds.
   - `scripts/generate-review.js`: renders a diff file to a self-contained
   HTML page (fork bundle + CSS inlined, zero network). The page uses the
   fork-native flow: inline editor under the tapped line, submit posts to
   `api/comments`, threads render under commented lines on load. The editor
   is in normal document flow (no fixed dock): `overlaysContent` + scroll
   the focused textarea into view so the keyboard never covers it.
     ```bash
     git -C <repo> diff <range> --no-color > /tmp/x.diff
     node scripts/generate-review.js /tmp/x.diff review-page.html "<title>"
     REVIEW_PAGE=review-page.html REVIEW_TOKEN=... <server as in step 5>
     ```
   Reason: diff2html's upstream bundle is vendored code, extending it is
   fragile - the fork carries the comment layer as a first-class module
   (`src/comments.ts`, covered by `src/__tests__/comments-tests.ts`).
   Fallbacks when node is unavailable: 2c (stdlib generator, no comments)
   or 2b (npx diff2html-cli + `scripts/inject-comments.py`).
   Validate the injected script before serving: extract the layer's
   `<script>` block and run `node --check` on it - a syntax slip otherwise
   fails silently in the phone browser with no console to read.
   `INIT_JS` is itself a template literal in the generator source, so mind
   which layer decodes an escape: write `\\uXXXX` in the generator and the
   served page carries `\uXXXX` for the phone browser to decode - a single
   backslash is consumed by the generator's own literal and bakes the raw
   char into the page instead.
   Page extras (both live in `generate-review.js`, no fork rebuild):
   a floating `↑` button (`#d2h-to-top`, appears after 600 px) scrolls back
   to the file list; the `Viewed` checkbox in each file header collapses
   the file and persists in `localStorage` under `d2h-reviewed:<title>`
   together with its `+a/-d` stats - a file whose stats changed since
   checking comes back unchecked and expanded, reviewed ones get a `✓`
   in the file list. Pair list rows to file sections by index - both render
   from the same diff array in order. Storage is per title, so each
   branch/range keeps its own marks. The stdlib fallback (`review-server.py` render) has the same
   two extras cheaper: `↑` button plus `<details>` open state in
   `localStorage` keyed by file name.
   Sources: `rtfpessoa/diff2html` (MIT) - entry points are
   `src/diff2html.ts`, `src/line-by-line-renderer.ts`, `src/ui/`,
   `src/templates/`. Full tool-choice rationale lives in
   `references/oss-review-options.md`. The maintained fork (native
   comment layer) lives at `/projects/diff2html`, upkeep recipe in
   `references/fork-upkeep.md`.

## Ревью с моими замечаниями на строках ("чтобы я предметно ответил")

When Ivan asks for a branch review and wants to answer specific findings, hand over
the board with your findings already sitting as threads on the lines - not a markdown
review file in the repo (a committed one gets dropped). Ids (`C<n>` / `N<n>` / `Q<n>`)
are stable, every pin is a real line at HEAD, and each thread ends with the direct
question so he can answer "C1 ок". Seeding schema, anchor verification and the
handover checks: `references/seeding-review-comments.md`.

## Answering the comments ("почитай комментарии")

1. Read `$REVIEW_COMMENTS` in full: one JSON object per comment with `file`,
   `newLine`/`oldLine` and `text`. Comments land on ANY file in the diff
   (specs, `package.json`, docs), so open each one against that file's real
   current content - never answer from memory of the code.
2. Before writing any answer, grep the repo for what the comment invites:
   "почему any?", "а как в других системах?", "где так уже делают?". Answer with
   evidence - hit counts, `file:line`, the exact precedent, the house pattern -
   never with opinion. He checks these answers against the repo, and a claim you
   did not verify reads as noise. Include whether anyone TESTS what you cite
   (`grep -rn '<symbol>' --include='*.spec.ts'`), and when the thing is the first
   of its kind in the repo say so plainly ("three apps call it, no spec anywhere
   covers it, we would be the first") instead of dressing it as house style -
   then offer the weaker alternative (assert only that the call resolves).
   When he challenges a claim in the code or a spec comment ("Уверен в этом. Проверь"), prove it
   end-to-end before answering - write path -> storage -> read path -> consumer, each step as
   `file:line` - and end with the practical consequence ("`new Date(...)` works either way, but
   `.toISOString()` on that value would throw"). When the question is "how is this verified?", state
   the boundary of the proof: a mocked SDK proves OUR call, not delivery to the vendor - name what the
   check does NOT cover instead of letting it read as an end-to-end guarantee.
3. Answer point by point, numbered the way he numbered them, one short block per
   comment: what the code does, what the repo precedent is, what you changed or
   what you propose. He reads this on a phone; a wall of prose per comment is a
   failure.
4. Split the comments in two. Mechanics you can settle yourself (comment
   wording, silent returns, naming, cast cleanup, log text) - fix them, commit,
   and say so. Design questions with alternatives (retry policy, storage,
   semantics) - lay out the options with a recommendation and WAIT for his pick;
   do not silently implement one.
5. After the fixes: commit FIRST, then regenerate the page from the same range
   (`generate-review.js`) and tell him the same URL now shows the updated diff.
   The page renders the committed range, so uncommitted edits never appear; no
   server restart is needed (`REVIEW_PAGE` is read per request).
6. "Этот комментарий лишний" is a real signal, not nitpicking: he rejects code
   comments that justify a divergence from another component, placeholders he
   did not ask for, and any comment narrating the absence of code. That rationale
   belongs in the spec or the skill.
7. He often follows up on the SAME numbers instead of leaving new comments
   ("1. … 2. … 13. …"): a second wave on answers he already got. Re-open those
   exact lines before replying - the code changed since he wrote the comment, so
   his premise can be stale (he argued "мы не логируем, а просто выходим" about a
   branch that both logged and reported). Say plainly which part of his reading
   still holds and which does not, then show the current lines.
8. When he pushes back on a pattern, he wants the defence he can repeat upward:
   "объясни подробнее, чтобы я сам смог пояснить". Give (1) when the pattern IS
   genuinely bad - agree where he is right instead of defending blindly, (2) repo
   precedents as `file:line` plus counts, (3) one sentence he can quote verbatim,
   (4) the alternative form if he prefers it. Evidence-only answers that skip (1)
   and (3) read as defensiveness.
9. Split the evidence by domain: the REPO answers house style ("а как в других
   системах?" → grep, hit counts, exact file:line); the VENDOR DOC answers the
   outside world (broker semantics, API limits) - he says "погугли" and expects
   the quote plus the URL. Never answer an external-behaviour question from the
   repo alone.
10. He is the reviewer of his own repo: when he says a change is wrong ("ты
   сделал дичь"), agree where he is right, name the weak points in your own work,
   and offer the smaller option - do not defend it. Extra machinery he did not ask
   for (polling for a metric, a shared-package refactor) is the usual reason.
11. When a comment turns into a code change, paste the hunk in chat (`git show <sha> -- <file>`,
   added lines only) - he asks "покажи дифф потом, что добавил", and a sha plus prose is not an
   answer. Same for a revert: show the line that went away.
12. `СДЕЛАНО (<sha>):` goes stale the moment you amend that commit while answering a later round.
   Before quoting a sha, `git cat-file -e <sha>`; if it is gone, rewrite the board text with the
   current sha and say plainly that the old one no longer exists - the board is the only place he
   tracks which fix actually landed.
13. "Не понял, с кем мы боремся / почему мы чего-то ждём" = he wants the mechanism split into layers,
   with measurements, not a retelling. Answer in three parts: what we do NOT wait for (the vendor keeps
   running), what we DO and how long it takes (`app.close()` 4-7 ms, stdout flush 0 ms - measure, do
   not estimate), and why the awkward line exists at all (the specific handle that keeps the event loop
   alive, found by `git log -S '<symbol>' -- <file>` plus `process._getActiveHandles()`). End with the
   plain model he can repeat ("подключились → прочитали → сделали → вышли"). A prose restatement of the
   same design without numbers reads as evasion and he asks again.
14. "Не понял про пункт N" / "я всё ещё не понял" = пересказ теми же словами не работает. Три шага,
   в этом порядке: (1) конкретный пример из НАШЕГО кода - реальные классы и методы, кусок диффа или
   таблица «значение → что получается с механизмом → что без него»; (2) явная граница - что механизм
   НЕ ловит и на каком именно сценарии он слеп; (3) если прошлый ответ был слишком оптимистичным,
   назвать это поправкой к себе самому ("я написал слишком оптимистично: страж меняет текст ошибки,
   а не добавляет обнаружение"), а не защищать формулировку. Абстракции вида «компилятор проверяет
   сигнатуру» он читает как воду: ему нужен сценарий с именами его файлов.

## Clearing resolved comments ("удали решённые комментарии")

1. Read `$REVIEW_COMMENTS` and enumerate it — never work from the count he names. He keeps commenting
   while you fix (`18` when he said `17`), and a comment can sit on a file from a commit created AFTER
   your first read, so enumerate `id` + `file` + line before touching anything.
2. Back the file up first: `cp $REVIEW_COMMENTS /data/.hermes/phone-review/review-comments-resolved.json`. The texts and
   timestamps stay valuable for the MR description and for the next round — say where the backup is.
3. `echo '[]' > $REVIEW_COMMENTS` — the server reads it per request, so no restart, and the page is
   clean on his next refresh.
4. Verify BOTH sides and quote the result: `curl "$URL/api/comments?token=$TOKEN"` returns `[]`, and the
   served page contains no comment badges.
5. A comment whose file is no longer in the diff (its commit was dropped from history) is resolved by
   the drop itself — name that explicitly instead of silently discarding it, and mention it in the same
   breath as the resolved set.
6. Only clear comments you actually answered or fixed. An open design question is not "решённый" just
   because he moved on to another topic - and when he says "снеси точно решённые", keep the pending ones
   on the board and name them with the decision you are waiting for (he then answers by number, e.g.
   "23 ок. Пусть остаётся, как есть").

## Deleting one comment ("удали комментарий")

Each inline thread has a ✕ button (fork renders it when the page passes
`onDelete` to `setComments` - the generator does). It calls
`DELETE /api/comments?token=...&id=<n>` and reloads the list, no server
restart, no page rebuild: the thread drops out on his next refresh (or
immediately - `load()` re-renders after a successful DELETE).
Verify by id, not by text: `curl api/comments` → find the `id` → DELETE →
list again. A 404 means the id is already gone; 403 without token.

## "Что изменилось с последнего ревью моего?"

He reviews the same branch in rounds, so he asks for the delta since the round he just finished.

**Delivery first:** the delta arrives as a regenerated board on the range `<reviewed>..HEAD`, not as
prose. Chat carries only the numbers and the URL; a written review of the delta without a board
reads as ignoring the request.

1. Pin the revision he reviewed when you hand over the page (and again when he says he left comments):
   note `git rev-parse HEAD` next to the range you rendered. The page renders the committed range, so
   that hash IS what he read - without pinning it the question cannot be answered from hashes at all.
2. Answer with `git log --oneline <reviewed>..HEAD` and `git diff --stat <reviewed>..HEAD`, then the
   current totals (`git rev-list --count origin/develop..HEAD`, `git diff origin/develop...HEAD
   --shortstat`) plus the green numbers you actually ran (tsc configs, jest suites/tests).
3. Group by commit, one line each: what changed and why, in his vocabulary (typing, guard, Sentry
   visibility). Close with what did NOT change - the decisions from earlier rounds - so he sees the
   scope instead of re-reading the whole diff.
4. If history was rewritten between rounds (a rebase to drop a stray file, a squashed fixup), the
   reviewed hash may no longer exist: check with `git cat-file -e <hash>` first. When it is gone,
   compare by commit subject and file list and say so - a missing hash is not a reason to answer from
   memory.
5. The board is the other half of the answer: name the comments still open and the decision each waits
   for, so the delta and the outstanding questions arrive together.

## Reviewing a commit range instead of a branch ("умеет работать между коммитами?")

Yes - the server takes any commit-ish pair: `review-server.py <repo> <base> <head> <ip> <port>` runs
`git diff base...head` and `git log base..head`. On a linear branch `A...B` is identical to `A..B`
(when `A` is an ancestor of `B`); only a truly divergent pair needs a double-dot page generated by hand.

- Only ONE board fits on 9000, so a range review is a RESTART with the range as `base`/`head`, not a
  second server. Point `REVIEW_PAGE` at the range page and `REVIEW_COMMENTS` at a separate file
  (`review-comments-<topic>.json`) so the branch board and the range board never mix.
- Regenerate the page for the range (`git diff A...B` → `generate-review.js`) instead of reusing the
  branch page: the title and the commit list are baked into the page, and Ivan checks the title to be
  sure he is looking at YOUR server.
- When he goes back to the branch view, restart with `origin/develop..HEAD` and its own comments file -
  the old link stays valid only if the token is reused (see the token pitfall).
- **A greenfield repo has no base to diff against.** `git diff <empty-tree>...HEAD` fails with
  `object … is a tree, not a commit`, while the two-tree form `git diff <empty-tree> HEAD` produces the
  full-tree diff you want (`EMPTY=$(git hash-object -t tree /dev/null)`). Render the page from that file and
  start the server with `BASE=$(git rev-list --max-parents=0 HEAD)` plus `REVIEW_PAGE`: `git log root..HEAD`
  still lists the commits (the root one aside), and comment anchors come from the rendered page, not from the
  server's own diff. Exclude lockfiles and generated artefacts with `':(exclude)package-lock.json'` - a
  2000-line lockfile is most of the page and none of the review - and state the exclusion in the handover
  line so he knows the range is the whole tree minus noise.
- **A restart on a delta range hides the earlier threads, it does not delete them.** Seeded comments whose
  files are not in `reviewed-baseline..HEAD` simply have no line to render on, and the page comes up looking
  empty while `$REVIEW_COMMENTS` still holds every one of them. Say that in the handover: the file is intact,
  which threads are invisible and why, and how to get the full view back (restart on `origin/develop...HEAD`).
  Don't re-seed anything to "restore" them - re-seeding mints new ids and loses his answers.

## Pitfalls

- diff2html-cli runs git itself: pass the range AFTER `--`
  (`... -- origin/develop...HEAD`). Piping a diff file in while leaving
  mismatched input/output flags fails with ERR_INVALID_ARG_TYPE, which is a
  flag-shape error, not a broken install.
- An npm package sharing a tool's name is not the tool: `npm view lazygit`
  returns an unrelated JS wrapper, not the Go TUI. Check description and
  homepage before quoting a version as the tool's version.
- Triple-dot vs double-dot changes the answer: `A...B` shows only what the
  branch introduced since the merge base; `A B` also drags in everything that
  moved on the base afterwards. Default to triple-dot for "what changed on
  this branch".
- Tap selection must be visible in two places at once: on the line itself
  (background fill plus outline - an outline alone is unreadable on a phone
  screen) and in the comment dock (green `-> file:line` confirmation). If
  Ivan cannot tell what he selected, the selection feedback is the bug, not
  his understanding.
- Store comment anchors in the exact keys the matcher reads (`oldLine` /
  `newLine` for `matchComment`) end to end - server, JSON file, and client.
  A `line`-only record never matches, so badges and threads silently render
  nothing, which looks like a frontend bug while the data path is broken.
- Always pass `colorScheme: 'auto'` when generating diff2html pages - the
  library default is light, so a dark-theme phone gets a light page.
- Never chase the phone keyboard by rewriting `bottom` on every resize event:
  each keystroke triggers layout and the field lags. Prefer an in-flow editor
  plus `overlaysContent`, move it with `transform` (compositor-only), and keep
  a guarded visualViewport fallback for browsers without the VirtualKeyboard
  API. Textareas need 16px font or iOS zooms on focus, which also reads as lag.
- Port conflicts: an orphan-looking occupant (`PPID=1`) can still belong to a
  LIVE session that simply restarts it - a killed preview came back a minute
  later and retook the port. Identify it first (`ps -o pid,ppid,lstart,cmd -p
  <pid>`, `pgrep -af <port>`, which project it serves), say what it is, and let
  Ivan decide; killing a preview he is using costs him work. **The exception is a server you started
  yourself in this session** (an emulator or dev preview you were demoing): that one is yours to stop,
  and handing over a board on 9000 requires it. Kill it by explicit pid (`kill <pid>`, both the wrapper
  and the node/python child), never `pkill -f <path>` - the pattern matches the `bash -c` wrapper of the
  very call you are running, so the tool call dies with `-15` and the server keeps the port. Confirm with
  `curl --max-time 2` returning `000` before binding the review server.
- **`потуши review` = убить python-ребёнка, а не обёртку.** Сервер запущен через
  `terminal(background=true)`, то есть под `bash -c`; `kill` по pid обёртки (и даже по pid из
  списка процессов, если взят не тот) оставляет `review-server.py` живым, и порт продолжает
  отвечать `403` на запрос без токена. Правильно: `ps -eo pid,cmd | grep review-server.py`
  → убить КАЖДЫЙ найденный pid → `curl -m 2` должен дать `000`. `403` после kill — это не
  успех, это живой сервер; не отчитывайся «потушено» по коду ответа, пока он не станет `000`.
- **`pgrep -af review-server.py` matches YOUR OWN shell command line** — every tool call runs wrapped
  in `bash -c "…"`, so the pattern appears in that wrapper and pgrep reports the server as alive long
  after it died (and its first hit is your own pid). Judge liveness by behaviour instead:
  `curl --max-time 3` the URL — `000` or a timeout means stopped, 200/403 means it is up. When he says
  "ревью вроде уже потушено", confirm with the curl, not with pgrep.
- Restarting the server mints a NEW token and silently kills the link in his open tab. Persist the token
  under a stable dir, not scratch or `/tmp`: `echo $REVIEW_TOKEN > /data/.hermes/phone-review/review-token.txt`,
  and on a restart on the same port RE-USE it
  (`export REVIEW_TOKEN=$(cat /data/.hermes/phone-review/review-token.txt)`) instead of generating a fresh
  one - same URL, his tab keeps working. `/tmp` gets cleaned between rounds (the token file and the old
  link vanished mid-review once), so a token kept there is not a durable "same link" promise. Mint a new
  token only when the host or port changes, when the token file is gone, or when he asks for one - and say
  plainly that the previous link is dead.
- Moving the review server to another port (the default port was occupied, or
  another session killed the server to take it) invalidates the URL you already
  handed him - the token is minted per start. Say plainly that the old link is
  dead, give the new one, and re-check `<title>` after the move so he is not
  staring at a foreign page.
- **Before handing over a page, check the diff for junk hunks.** Run `git diff <range> --check` (must
  be empty) and scan for a hunk that deletes a line and re-adds the SAME line with different
  indentation - that is damage from scripted line removal (`str.replace` on an imports/providers list
  also matching inside the neighbour's longer indent), not a real change. He reports it as
  "отступ поплыл" on almost every round in which code was deleted. Fix the indent, fixup-commit, and
  regenerate the page before telling him it is ready. Stage explicit paths, never `git add -A`: a bulk
  add both sweeps untracked local artifacts into the diff and hides the real scope of the round.
- A file in the diff that is not part of the work is almost always an untracked local artifact
  swept in by a bulk `git add -A` (in c0 that is `apps/backoffice-api/config/polices-rules`, a local
  config `.gitignore` does not cover). Find the commit that added it with
  `git log --all --oneline -- <path>`, then remove it from history - the recipe lives in the
  c0-local-dev skill (its `repo-facts` reference, section "Removing a local file that got
  committed"). Name the mechanism
  ("my `git add -A` committed a local config") instead of guessing at what the file is, and
  regenerate the page afterwards so it drops out of the diff.
- `curl -s -o /dev/null -w '%{http_code}'` proves only that the server answered, NOT which page it
  served. After regenerating the page for a new range, verify the content: fetch the page and check its
  `<title>` plus a flat count of file headers/total lines against `git diff <range> --stat | tail -1`.
  A stale `REVIEW_PAGE` path or a page written to a different file leaves him reviewing the previous
  range while the chat claims it is updated.
  Check the gate and the layer in the same pass: the same URL WITHOUT `?token=` must answer 403 (a
  200 means the branch diff is open to everyone on the tailnet), and the served HTML must contain the
  comment layer (grep for `Diff2HtmlComments`). Three cheap curls — 200 with token, 403 without,
  `api/comments?token=` returning `[]` — are the whole handover proof.
- Do not tear the server down when a round ends: Ivan reviews the same branch more than once
  (a second pass is normal, and he says so). Keep it running, keep the same URL, and only stop
  it on `потуши review`. Before the next pass, make sure the page reflects the current HEAD -
  regenerate it after every commit, since the page renders the committed range.
- Start the server with `terminal(background=true)`, never as a foreground command carrying
  `nohup`/`&`/`setsid`: Hermes refuses those wrappers and the server never starts, so the next
  curl checks prove nothing. Readiness is a separate foreground call: `curl` with the token (200),
  without it (403), `api/comments` (your count), `<title>`, `grep -c Diff2HtmlComments`.
- **Anchors move under you.** Any commit that adds or removes lines above a seeded comment shifts its
  `newLine`; recompute each pin by grepping the symbol the comment sits on (`grep -n '<symbol>' <file>`)
  and rewrite the JSON - arithmetic "minus N lines" drifts the moment one hunk is not the one you
  counted. Re-check after an amend too, and quote the current sha (`git cat-file -e <sha>`).
- **File count: trust `grep -c '^diff --git' <diff>`, not the page.** The rendered HTML repeats header
  classes inside its inlined template and JS bundle (56 files showed as 58), so a mismatch there is a counting
  artefact - compare the page against the diff before claiming it is current.
- **A rebase orphans `reviewed-baseline`.** The tag keeps the pre-rebase sha, which is no longer an
  ancestor of HEAD, so `reviewed-baseline..HEAD` suddenly renders the whole branch again. After any
  rebase (or history rewrite) re-point the tag at the current HEAD - or at the post-rebase equivalent
  of the reviewed commit - before the next round, and say the new frozen sha in the handover line.
- Answers may come back in CHAT instead of on the board, in his own order ("C6, C7, N5, N1 …").
  Then answer in that same order with the same ids, one short block each, and update the board in
  the same pass: re-pinned anchors plus `СДЕЛАНО (<sha>):` in the text of the ones you fixed. Do not
  renumber, do not answer from the old JSON without re-reading the lines - your own commits moved them.
