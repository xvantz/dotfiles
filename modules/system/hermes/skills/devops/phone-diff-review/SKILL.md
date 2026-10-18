---
name: phone-diff-review
description: "Use when Ivan reviews branch diffs from his phone."
version: 0.1.0
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

## Invocation (agreed triggers)

- `review <branch>` (default base `origin/develop`): generate the page from
  the fork, start the server, reply with the URL. Range `A..B` on request.
- `разбери комменты`: read `$REVIEW_COMMENTS` and answer point by point.
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
   export REVIEW_COMMENTS=/data/.hermes/cache/scratch/review-comments.json
   echo '[]' > "$REVIEW_COMMENTS"
   python3 scripts/review-server.py <repo> <base> <head> <tailscale-ip> 9000
   ```
   Rules: bind the Tailscale IP only (rediscover via ioctl SIOCGIFADDR on
   `tailscale0`, never hardcode), port 9000 (the only open high port per
   firewall config), fresh token per session shown once to Ivan, run in
   background. Hand Ivan `http://<ts-ip>:9000/?token=<token>`. No push from
   server to agent exists: Ivan says "read the comments" when done, the
   agent reads `$REVIEW_COMMENTS` and answers point by point. Stop the server
   afterwards.
6. Pretty page = our diff2html fork (no npm at review time). The skill carries
   a prebuilt binary plus a generator, both versioned with the skill:
   - `assets/diff2html-fork.min.js` + `assets/diff2html-fork.min.css`: UMD
     bundle built from https://git.827482.xyz/xvantz/diff2html
     (`feature/phone-comments`: native `Diff2HtmlComments` - tap a line
     number to open an inline editor under the line, second tap on the
     same line cancels; badges and GitHub-style threads mark commented
     lines).
     Rebuild after pulling the fork: `npm run build:bundles build:css`.
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
   Sources: `rtfpessoa/diff2html` (MIT) - entry points are
   `src/diff2html.ts`, `src/line-by-line-renderer.ts`, `src/ui/`,
   `src/templates/`. Full tool-choice rationale lives in
   `references/oss-review-options.md`. The maintained fork (native
   comment layer) lives at `/projects/diff2html`, upkeep recipe in
   `references/fork-upkeep.md`.

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
