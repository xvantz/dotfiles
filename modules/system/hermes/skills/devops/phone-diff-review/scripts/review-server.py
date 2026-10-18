#!/usr/bin/env python3
"""Phone diff review server. stdlib only.

Serves a rendered git diff with per-line comments over Tailscale.
Binds the Tailscale IP only, token in query string (?token=...).
Comments persist to a JSON file the agent can read later.

Usage:
  REVIEW_TOKEN=<token> REVIEW_TITLE=<title> REVIEW_COMMENTS=<path.json> \
    python3 review-server.py <repo> <base> <head> <tailscale-ip> <port>

Flow: Ivan taps a diff line, writes a comment, then tells the agent
"read the comments" - the agent reads the same JSON file.
"""
import html
import json
import os
import subprocess
import sys
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REPO = sys.argv[1] if len(sys.argv) > 1 else "."
BASE = sys.argv[2] if len(sys.argv) > 2 else "origin/develop"
HEAD = sys.argv[3] if len(sys.argv) > 3 else "HEAD"
BIND = sys.argv[4] if len(sys.argv) > 4 else "127.0.0.1"
PORT = int(sys.argv[5]) if len(sys.argv) > 5 else 9000
TOKEN = os.environ.get("REVIEW_TOKEN", "dev")
COMMENTS_FILE = os.environ.get("REVIEW_COMMENTS", "review-comments.json")
TITLE = os.environ.get("REVIEW_TITLE", f"diff {BASE}...{HEAD}")
PAGE_FILE = os.environ.get("REVIEW_PAGE", "")


def git(*args):
    r = subprocess.run(
        ["git", "-C", REPO, *args], capture_output=True, text=True, check=True
    )
    return r.stdout


def load_comments():
    try:
        with open(COMMENTS_FILE, encoding="utf-8") as fh:
            data = json.load(fh)
            return data if isinstance(data, list) else []
    except (OSError, ValueError):
        return []


def save_comments(items):
    tmp = COMMENTS_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(items, fh, ensure_ascii=False, indent=1)
    os.replace(tmp, COMMENTS_FILE)


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
            if cur["hunks"]:
                cur["hunks"][-1]["lines"].append(("a", line[1:]))
        elif line.startswith("-") and not line.startswith("---"):
            cur["del"] += 1
            if cur["hunks"]:
                cur["hunks"][-1]["lines"].append(("d", line[1:]))
        elif line.startswith(" ") and cur["hunks"]:
            cur["hunks"][-1]["lines"].append(("c", line[1:]))
    return files


DIFF = git("diff", f"{BASE}...{HEAD}", "--no-color", "-U2")
try:
    COMMITS = git("log", "--format=%h %s", f"{BASE}..{HEAD}").strip()
except subprocess.CalledProcessError:
    COMMITS = ""
FILES = parse(DIFF)

CSS = (
    "body{font-family:-apple-system,system-ui,monospace;margin:0;background:#0d1117;color:#e6edf3;padding-bottom:180px}"
    "header{padding:12px 16px;background:#161b22;position:sticky;top:0;z-index:5}"
    "a{color:#58a6ff;text-decoration:none}"
    ".idx{padding:8px 16px}.idx li{margin:4px 0;font-size:14px}"
    "details{border-top:1px solid #30363d}"
    "summary{padding:10px 16px;cursor:pointer;font-size:14px;word-break:break-all}"
    ".add-pill{color:#3fb950}.del-pill{color:#f85149}"
    "pre{margin:0;padding:8px 0;overflow-x:auto;font-size:12px}"
    ".l{display:block;padding:2px 12px;white-space:pre-wrap;word-break:break-word;cursor:pointer}"
    ".l.sel{outline:2px solid #58a6ff}"
    ".a{background:rgba(63,185,80,.15)}.d{background:rgba(248,81,73,.15)}"
    ".n{color:#8b949e;user-select:none;margin-right:8px}"
    ".h{color:#8b949e;padding:4px 12px;display:block}"
    ".cmt{background:#161b22;border:1px solid #30363d;border-radius:8px;margin:8px 16px;padding:8px 12px;font-size:13px}"
    ".cmt b{color:#58a6ff}"
    "#dock{position:fixed;bottom:0;left:0;right:0;background:#161b22;border-top:1px solid #30363d;padding:10px 12px;z-index:10}"
    "#dock .t{font-size:13px;margin-bottom:6px}"
    "#dock textarea{width:100%;box-sizing:border-box;background:#0d1117;color:#e6edf3;border:1px solid #30363d;border-radius:8px;font-size:14px;padding:8px}"
    "#dock button{background:#238636;color:#fff;border:0;border-radius:8px;padding:10px 18px;font-size:15px;margin-top:6px}"
    "#dock .ok{color:#3fb950;font-size:13px;margin-left:8px}"
)

JS = """let sel=null;
function tap(el){document.querySelectorAll('.l.sel').forEach(e=>e.classList.remove('sel'));
el.classList.add('sel');sel={f:el.dataset.f,n:el.dataset.n};
document.getElementById('t').textContent=el.dataset.f+':'+el.dataset.n;}
async function send(){if(!sel){alert('tap a diff line first');return;}
const tx=document.getElementById('x');const text=tx.value.trim();if(!text)return;
const r=await fetch('api/comments'+location.search,{method:'POST',headers:{'Content-Type':'application/json'},
body:JSON.stringify({file:sel.f,line:sel.n,text:text.slice(0,2000)})});
if(r.ok){tx.value='';document.getElementById('ok').textContent='saved ok';load();}
else{document.getElementById('ok').textContent='error '+r.status;}}
async function load(){const r=await fetch('api/comments'+location.search);if(!r.ok)return;
const items=await r.json();const box=document.getElementById('list');box.innerHTML='';
items.forEach(c=>{const d=document.createElement('div');d.className='cmt';
d.innerHTML='<b>'+c.file+':'+c.line+'</b> '+c.text.replace(/</g,'&lt;');box.appendChild(d);});}
load();"""


def render():
    comments = load_comments()
    counts = {}
    for c in comments:
        counts[(c.get("file"), str(c.get("line")))] = (
            counts.get((c.get("file"), str(c.get("line"))), 0) + 1
        )
    n_add = sum(f["add"] for f in FILES)
    n_del = sum(f["del"] for f in FILES)
    n_commits = len([c for c in COMMITS.splitlines() if c.strip()])
    idx, body = [], []
    for i, f in enumerate(FILES):
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
        ln, la, ld = 0, 0, 0
        for h in f["hunks"]:
            parts.append(f'<span class="h">{html.escape(h["head"])}</span>')
            for kind, text in h["lines"]:
                ln += 1
                if kind == "a":
                    la += 1
                    num, cls = f"+{la}", "l a"
                elif kind == "d":
                    ld += 1
                    num, cls = f"-{ld}", "l d"
                else:
                    la += 1
                    ld += 1
                    num, cls = str(la), "l"
                mark = " [cmt x%d]" % counts[(f["name"], str(ln))] if (
                    f["name"], str(ln)) in counts else ""
                parts.append(
                    f'<span class="{cls}" data-f="{html.escape(f["name"])}" '
                    f'data-n="{ln}" onclick="tap(this)">'
                    f'<span class="n">{num}{mark}</span>'
                    f"{html.escape(text)}</span>"
                )
        parts.append("</pre></details>")
        body.append("\n".join(parts))
    stat = (
        f"{n_commits} commits, {len(FILES)} files, "
        f"+{n_add}/-{n_del}. {html.escape(COMMITS[:300])}"
    )
    clist = "".join(
        f'<div class="cmt"><b>{html.escape(str(c.get("file")))}:'
        f'{html.escape(str(c.get("line")))}</b> '
        f"{html.escape(str(c.get('text', '')))}"
        f"<br><small>{html.escape(str(c.get('ts', '')))}</small></div>"
        for c in comments
    )
    return (
        "<!DOCTYPE html><html lang='ru'><head><meta charset='utf-8'>"
        "<meta name='viewport' content='width=device-width,initial-scale=1'>"
        f"<title>{html.escape(TITLE)}</title><style>{CSS}</style></head><body>"
        f"<header><b>{html.escape(TITLE)}</b><br><small>{stat}</small></header>"
        f"<ol class='idx'>{''.join(idx)}</ol>"
        f"{''.join(body)}"
        f"<h3 style='padding:0 16px'>Comments ({len(comments)})</h3>"
        f"<div id='list'>{clist}</div>"
        "<div id='dock'><div class='t' id='t'>tap a diff line, then write</div>"
        "<textarea id='x' rows='2' placeholder='what is unclear?'></textarea><br>"
        "<button onclick='send()'>Send</button><span class='ok' id='ok'></span></div>"
        f"<script>{JS}</script></body></html>"
    )


class Handler(BaseHTTPRequestHandler):
    server_version = "Review/1.0"

    def log_message(self, *a):
        pass

    def authed(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        return q.get("token", [""])[0] == TOKEN

    def send_page(self):
        if PAGE_FILE:
            with open(PAGE_FILE, "rb") as fh:
                page = fh.read()
        else:
            page = render().encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(page)))
        self.end_headers()
        self.wfile.write(page)

    def do_GET(self):
        if not self.authed():
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"forbidden")
            return
        path = urllib.parse.urlparse(self.path).path
        if path == "/api/comments":
            data = json.dumps(load_comments(), ensure_ascii=False).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        elif path in ("/", "/index.html"):
            self.send_page()
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if not self.authed():
            self.send_response(403)
            self.end_headers()
            return
        if urllib.parse.urlparse(self.path).path != "/api/comments":
            self.send_response(404)
            self.end_headers()
            return
        try:
            body = json.loads(
                self.rfile.read(int(self.headers.get("Content-Length", 0))))
        except (ValueError, OSError):
            self.send_response(400)
            self.end_headers()
            return
        items = load_comments()
        items.append(
            {
                "id": len(items) + 1,
                "ts": time.strftime("%Y-%m-%d %H:%M:%S"),
                "file": str(body.get("file", ""))[:300],
                "oldLine": body.get("oldLine", body.get("old")),
                "newLine": body.get("newLine", body.get("new")),
                "line": str(body.get("line", ""))[:20],
                "text": str(body.get("text", ""))[:2000],
            }
        )
        save_comments(items)
        data = b'{"ok":true}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    print(f"serving {TITLE} on {BIND}:{PORT}", flush=True)
    ThreadingHTTPServer((BIND, PORT), Handler).serve_forever()
