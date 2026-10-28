# Seeding the board with your own review findings

When Ivan asks for a branch review and wants to answer specific findings, the board
goes to him already filled: your comments sit as threads on the lines, he answers
under them. The deliverable is the board - never a markdown review file in the repo
(a committed one gets dropped with `git reset --mixed HEAD~1` plus removing the file).

## Procedure

1. Range: `origin/develop...HEAD` by default. `reviewed-baseline` may point at an
   earlier commit - findings often sit in code that already passed review, and in
   `reviewed-baseline..HEAD` those files are absent, so there is no line to pin to.
   Say where the tag stands and offer the delta as a separate round.
2. Page: `git diff <range> --no-color > <scratch>/x.diff`, then `generate-review.js`
   into `REVIEW_PAGE`; confirm `git diff --check` is empty and the `<title>` is yours.
3. Seed `$REVIEW_COMMENTS` BEFORE starting the server, one object per finding:
   ```json
   {"id": 1, "file": "apps/<app>/src/<path>.ts", "newLine": 157, "text": "C1 (жёлтый) ..."}
   ```
   - `file` is the path exactly as in the diff; a file outside the diff has nowhere
     to land and the thread silently never renders.
   - `newLine` is the absolute line number in the NEW file, not an index into the
     diff: `matchComment` compares `file` + `newLine`, and a `line`-only record never
     matches (badges and threads just do not appear).
   - `id` is yours to assign; it only has to be unique and stable.
4. Verify every anchor before serving: `sed -n "${n}p" <file>` must print the code the
   comment talks about. A thread hanging on a neighbouring line reads as a review
   error and costs a round.
5. Comment text: stable id and severity first (`C1 (жёлтый)`, `N4 (нит)`,
   `Q2 (вопрос)`), then 2-4 lines of substance, then the direct question as the last
   line. He answers "C1 ок" / "C2 нет" by number, so ids must not renumber between
   rounds - add `C9` instead of reflowing.
6. Handover proof, all in one pass: page answers 200 with the token and 403 without,
   `api/comments?token=...` returns your count, `<title>` is yours, and
   `grep -c Diff2HtmlComments` on the served HTML is > 0. In chat: the URL, how many
   comments and by which ids, and where `reviewed-baseline` stands.

## Comment id scheme

- `C<n>` - a decision needed in production code (blocking or not), with a concrete
  proposal and the question.
- `N<n>` - nits: duplication, dead code, naming, provider scope, conventions.
- `Q<n>` - questions outside the diff: pre-existing risks the change now exposes,
  product decisions, upstream idempotency. They never block the MR.

## After he answers

Answers come back by id, on the board or in chat. Group them: mechanics you can
settle yourself (comment wording, silent returns, naming, cast cleanup) - fix and
commit; design questions with alternatives (retry policy, storage, semantics) - lay
out options with a recommendation and wait. Regenerate the page after each commit so
the same URL shows the fixes.

Before pushing a convention change (add `@IsOptional`, move a provider, extract a
helper), COUNT the precedent in that file or package: `grep -c` the decorator or the
pattern. A file with 145 plain decorators and 3 `@IsOptional` means your proposal is
the outlier - close the finding in the answer ("так устроен весь файл") instead of
defending it, and say what the house style actually is. Same for "move this out of
the shared module": grep every caller first.

## После правок: перезакрепить якоря (обязательно)

Your fixes shift line numbers, and `matchComment` compares `file` + `newLine`, so a
stale anchor renders no thread at all - the board silently loses the item and it
looks like a frontend bug.

1. Commit first, then regenerate the diff and the page from the new HEAD.
2. Recompute `newLine` for EVERY comment, not just the ones you touched: a line
   removed above shifts everything under it. Anchor on a distinctive line and read
   it back with `grep -n` / `sed -n "${n}p"`.
3. Rewrite the JSON, keeping ids. For fixed items change the text to
   `C2 - СДЕЛАНО (<sha>): <что сделано>` plus the residue he still has to decide;
   do not delete threads on your own - он говорит "удали решённые" when he wants the
   board cleared, and a deleted thread loses the answer he was reading on the line.
4. Comments whose code was deleted outright move to the replacement line (point
   `N1` at the provider list that stayed, not at the removed export line).
5. Verify after the rewrite: `api/comments` count unchanged, page 200/403 as before,
   and each new anchor still prints the code it talks about.
