#!/usr/bin/env python3
"""Inject comment layer into a diff2html page. stdlib only.

Usage: python3 inject-comments.py <in.html> <out.html>
Inserts a sticky comment dock + tap-on-line-number JS before </body>.
Works with the api/comments endpoints served from the same origin.
"""
import sys

CSS = (
    "#rc-dock{position:fixed;bottom:0;left:0;right:0;background:#161b22;color:#e6edf3;"
    "border-top:1px solid #30363d;padding:10px 12px;z-index:9999;font-family:-apple-system,system-ui,monospace}"
    "#rc-t{font-size:13px;margin-bottom:6px;word-break:break-all}"
    "#rc-x{width:100%;box-sizing:border-box;background:#0d1117;color:#e6edf3;border:1px solid #30363d;border-radius:8px;font-size:14px;padding:8px}"
    "#rc-dock button{background:#238636;color:#fff;border:0;border-radius:8px;padding:10px 14px;font-size:15px;margin:6px 6px 0 0}"
    "#rc-toggle{background:#21262d!important}"
    "#rc-ok{color:#3fb950;font-size:13px;margin-left:8px}"
    "#rc-list{max-height:40vh;overflow-y:auto;margin-top:8px}"
    ".rc-cmt{background:#0d1117;border:1px solid #30363d;border-radius:8px;margin:6px 0;padding:8px 12px;font-size:13px}"
    ".rc-cmt b{color:#58a6ff}"
    "tr.rc-sel td{background:rgba(56,139,253,.35)!important;outline:2px solid #58a6ff!important}"
    ".rc-b{color:#f0883e;font-weight:bold}"
    "#rc-t.sel{color:#3fb950;font-weight:bold}"
)

DOCK = (
    '<div id="rc-dock"><div id="rc-t">tap a line number, then write</div>'
    '<textarea id="rc-x" rows="2" placeholder="what is unclear?"></textarea><br>'
    '<button id="rc-send">Send</button>'
    '<button id="rc-toggle">Comments (<span id="rc-n">0</span>)</button>'
    '<span id="rc-ok"></span><div id="rc-list" style="display:none"></div></div>'
)

JS = """(function(){let sel=null;const qs=location.search;
function fname(w){const e=w.querySelector('.d2h-file-name');return e?e.textContent.trim():'';}
function nums(tr){const a=tr.querySelector('.line-num1'),b=tr.querySelector('.line-num2');
return {o:a?a.textContent.trim():'',n:b?b.textContent.trim():''};}
async function load(){try{const r=await fetch('api/comments'+qs);if(!r.ok)return;
const items=await r.json();const box=document.getElementById('rc-list');box.innerHTML='';
document.getElementById('rc-n').textContent=items.length;
items.forEach(c=>{const d=document.createElement('div');d.className='rc-cmt';
const b=document.createElement('b');b.textContent=c.file+':'+(c.new||c.old||c.line);d.appendChild(b);
d.appendChild(document.createTextNode(' '+(c.text||'')));box.appendChild(d);});
document.querySelectorAll('.rc-b').forEach(e=>e.remove());
items.forEach(c=>{document.querySelectorAll('.d2h-file-wrapper').forEach(w=>{
if(fname(w)!==c.file)return;
w.querySelectorAll('tbody.d2h-diff-tbody > tr').forEach(tr=>{const t=nums(tr);
if((c.new&&String(c.new)===t.n)||(c.old&&String(c.old)===t.o&&!t.n)){
const td=tr.querySelector('td.d2h-code-linenumber');
if(td&&!td.querySelector('.rc-b')){const s=document.createElement('span');
s.className='rc-b';s.textContent=' \uD83D\uDCAC';td.appendChild(s);}}});});});}catch(e){}}
function pick(td){const tr=td.closest('tr');const t=nums(tr);
if(!t.o&&!t.n)return;
document.querySelectorAll('tr.rc-sel').forEach(e=>e.classList.remove('rc-sel'));
tr.classList.add('rc-sel');const w=td.closest('.d2h-file-wrapper');
sel={file:fname(w),old:t.o,new:t.n};
const rt=document.getElementById('rc-t');
rt.textContent='\u2192 '+sel.file+':'+(t.n||('-'+t.o));rt.classList.add('sel');}
async function send(){if(!sel){alert('tap a line number first');return;}
const tx=document.getElementById('rc-x');const text=tx.value.trim();if(!text)return;
const ok=document.getElementById('rc-ok');
try{const r=await fetch('api/comments'+qs,{method:'POST',headers:{'Content-Type':'application/json'},
body:JSON.stringify({file:sel.file,old:sel.old,new:sel.new,line:sel.new||sel.old,text:text.slice(0,2000)})});
if(r.ok){tx.value='';ok.textContent='saved ok';load();}else{ok.textContent='error '+r.status;}
}catch(e){ok.textContent='network error';}}
document.addEventListener('DOMContentLoaded',()=>{
document.querySelectorAll('td.d2h-code-linenumber').forEach(td=>{
td.addEventListener('click',()=>pick(td));});
document.getElementById('rc-send').addEventListener('click',send);
document.getElementById('rc-toggle').addEventListener('click',()=>{
const l=document.getElementById('rc-list');
l.style.display=l.style.display==='none'?'block':'none';});
load();});})();"""


def main():
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as fh:
        page = fh.read()
    layer = f"<style>{CSS}</style>{DOCK}<script>{JS}</script></body>"
    if "</body>" not in page:
        raise SystemExit("no </body> in input")
    page = page.replace("</body>", layer, 1)
    with open(dst, "w", encoding="utf-8") as fh:
        fh.write(page)
    print(f"wrote {dst} ({len(page)} bytes)")


if __name__ == "__main__":
    main()
