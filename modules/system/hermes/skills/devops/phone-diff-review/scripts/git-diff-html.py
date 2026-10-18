#!/usr/bin/env python3
"""git diff -> single self-contained HTML, phone-friendly. stdlib only."""
import html
import subprocess
import sys


def run(repo, *args):
    r = subprocess.run(
        ["git", "-C", repo, *args], capture_output=True, text=True, check=True
    )
    return r.stdout


def parse(diff_text):
    files, cur = [], None
    for line in diff_text.splitlines():
        if line.startswith("diff --git "):
            parts = line.split(" b/", 1)
            name = parts[1] if len(parts) > 1 else line
            cur = {"name": name, "hunks": [], "add": 0, "del": 0}
            files.append(cur)
        elif cur is None:
            continue
        elif line.startswith("@@"):
            cur["hunks"].append({"head": line, "lines": []})
        elif line.startswith("+") and not line.startswith("+++"):
            cur["add"] += 1
            cur["hunks"][-1]["lines"].append(("a", line[1:])) if cur["hunks"] else None
        elif line.startswith("-") and not line.startswith("---"):
            cur["del"] += 1
            cur["hunks"][-1]["lines"].append(("d", line[1:])) if cur["hunks"] else None
        elif line.startswith(" ") and cur["hunks"]:
            cur["hunks"][-1]["lines"].append(("c", line[1:]))
    return files


CSS = (
    "body{font-family:-apple-system,system-ui,monospace;margin:0;background:#0d1117;color:#e6edf3}"
    "header{padding:12px 16px;background:#161b22;position:sticky;top:0}"
    "a{color:#58a6ff;text-decoration:none}"
    ".idx{padding:8px 16px}.idx li{margin:4px 0;font-size:14px}"
    "details{border-top:1px solid #30363d}"
    "summary{padding:10px 16px;cursor:pointer;font-size:14px;word-break:break-all}"
    ".add-pill{color:#3fb950}.del-pill{color:#f85149}"
    "pre{margin:0;padding:8px 0;overflow-x:auto;font-size:12px}"
    ".l{display:block;padding:0 12px;white-space:pre-wrap;word-break:break-word}"
    ".a{background:rgba(63,185,80,.15)}.d{background:rgba(248,81,73,.15)}"
    ".n{color:#8b949e;user-select:none;margin-right:8px}"
    ".h{color:#8b949e;padding:4px 12px;display:block}"
)

TPL = """<!DOCTYPE html><html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title><style>{css}</style></head><body>
<header><b>{title}</b><br><small>{stat}</small></header>
<ol class="idx">{idx}</ol>{body}</body></html>"""


def render(repo, base, head):
    diff = run(repo, "diff", f"{base}...{head}", "--no-color", "-U2")
    try:
        commits = run(repo, "log", "--format=%h %s", f"{base}..{head}").strip()
    except subprocess.CalledProcessError:
        commits = ""
    files = parse(diff)
    n_add = sum(f["add"] for f in files)
    n_del = sum(f["del"] for f in files)
    idx, body = [], []
    for i, f in enumerate(files):
        idx.append(
            f'<li><a href="#f{i}">{html.escape(f["name"])}</a> '
            f'<span class="add-pill">+{f["add"]}</span> '
            f'<span class="del-pill">-{f["del"]}</span></li>'
        )
        parts = [f'<details id="f{i}"' + (" open" if i == 0 else "") + ">"]
        parts.append(
            f'<summary>{html.escape(f["name"])} '
            f'<span class="add-pill">+{f["add"]}</span> '
            f'<span class="del-pill">-{f["del"]}</span></summary><pre>'
        )
        for h in f["hunks"]:
            parts.append(f'<span class="h">{html.escape(h["head"])}</span>')
            la = ld = 0
            for kind, text in h["lines"]:
                if kind == "a":
                    la += 1
                    pre = f'<span class="n">+{la}</span>'
                    parts.append(
                        f'<span class="l a">{pre}{html.escape(text)}</span>'
                    )
                elif kind == "d":
                    ld += 1
                    pre = f'<span class="n">-{ld}</span>'
                    parts.append(
                        f'<span class="l d">{pre}{html.escape(text)}</span>'
                    )
                else:
                    la += 1
                    ld += 1
                    parts.append(
                        f'<span class="l"><span class="n">{la}</span>'
                        f"{html.escape(text)}</span>"
                    )
        parts.append("</pre></details>")
        body.append("\n".join(parts))
    n_commits = len([c for c in commits.splitlines() if c.strip()])
    title = f"diff {html.escape(base)}...{html.escape(head)}"
    stat = (
        f"{n_commits} commits, {len(files)} files, "
        f"+{n_add}/-{n_del}. Commits: {html.escape(commits[:400])}"
    )
    return TPL.format(
        title=title, css=CSS, stat=stat, idx="\n".join(idx), body="\n".join(body)
    )


if __name__ == "__main__":
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    base = sys.argv[2] if len(sys.argv) > 2 else "origin/develop"
    head = sys.argv[3] if len(sys.argv) > 3 else "HEAD"
    out = sys.argv[4] if len(sys.argv) > 4 else "diff.html"
    page = render(repo, base, head)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(page)
    print(f"wrote {out} ({len(page)} bytes)")
