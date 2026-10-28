#!/usr/bin/env node
/* Generate a self-contained phone review page from our diff2html fork.
 *
 * Usage: node generate-review.js <diff-file> <out.html> "<title>"
 *   [--bundle <diff2html.min.js>] [--css <diff2html.min.css>]
 *
 * Renders the diff with the fork bundle and inlines CSS + bundle.
 * Review flow is GitHub-style and lives in the fork itself
 * (Diff2HtmlComments): tap a line number to open an inline editor
 * right under the line, second tap on the same line cancels.
 * Submitted comments persist via the same-origin api/comments
 * endpoints served by review-server.py.
 *
 * Page extras (no fork rebuild): floating ↑ button back to the file list;
 * per-file `Viewed` checkbox collapses the file and persists in
 * localStorage (`d2h-reviewed:<title>` + +/- stats, stale if changed).
 */
const fs = require('fs');
const path = require('path');

const here = __dirname;
const rawArgs = process.argv.slice(2);
const seenValues = [];
for (let i = 0; i < rawArgs.length; i++) {
  if (rawArgs[i].startsWith('--') && rawArgs[i + 1]) seenValues.push(rawArgs[i + 1]);
}
const positional = rawArgs.filter(a => !a.startsWith('--') && !seenValues.includes(a));
const opt = (name, fallback) => {
  const i = rawArgs.indexOf(name);
  return i >= 0 && rawArgs[i + 1] ? rawArgs[i + 1] : fallback;
};

const [diffFile, outFile, title] = positional;
if (!diffFile || !outFile) {
  console.error('usage: node generate-review.js <diff-file> <out.html> "<title>"');
  process.exit(1);
}
const bundlePath = opt('--bundle', path.join(here, '..', 'assets', 'diff2html-fork.min.js'));
const cssPath = opt('--css', path.join(here, '..', 'assets', 'diff2html-fork.min.css'));

function ensureFreshBundle(bundlePath, cssPath) {
  const { execSync } = require('child_process');
  const forkDir = process.env.FORK_DIR || '/projects/diff2html';
  const stampPath = path.join(path.dirname(bundlePath), '.fork-rev');
  let head = null;
  try {
    head = execSync('git rev-parse HEAD', { cwd: forkDir, encoding: 'utf8' }).trim();
  } catch (e) {
    return;
  }
  let stamped = null;
  try {
    stamped = fs.readFileSync(stampPath, 'utf8').trim();
  } catch (e) {}
  if (head && head === stamped) return;
  if (!fs.existsSync(path.join(forkDir, 'node_modules'))) {
    console.error('[generate-review] no node_modules in fork, using bundled binary as is');
    return;
  }
  console.error(`[generate-review] fork ${head.slice(0, 8)} != bundled, rebuilding...`);
  try {
    execSync('npm run build:bundles && npm run build:css', { cwd: forkDir, stdio: 'inherit' });
    fs.copyFileSync(path.join(forkDir, 'bundles/js/diff2html.min.js'), bundlePath);
    fs.copyFileSync(path.join(forkDir, 'bundles/css/diff2html.min.css'), cssPath);
    fs.writeFileSync(stampPath, head + '\n');
  } catch (e) {
    console.error('[generate-review] rebuild failed, using bundled binary as is');
  }
}

ensureFreshBundle(bundlePath, cssPath);

const Diff2Html = require(bundlePath);
const diffText = fs.readFileSync(diffFile, 'utf8');
const css = fs.readFileSync(cssPath, 'utf8');
const bundle = fs.readFileSync(bundlePath, 'utf8');

const PAGE_CSS = [
  "body{margin:0;background:#fff;color:#24292e;}",
  "@media (prefers-color-scheme:dark){body{background:#0d1117;color:#e6edf3;}}",
  ".d2h-file-collapse{display:flex!important;}",
  ".d2h-file-wrapper.d2h-reviewed .d2h-file-header{opacity:.6;}",
  ".d2h-file-list-line.d2h-reviewed{opacity:.55;}",
  ".d2h-reviewed-mark{color:#3fb950;font-weight:700;}",
  "#d2h-to-top{position:fixed;right:16px;bottom:24px;width:52px;height:52px;border-radius:50%;",
  "border:1px solid #30363d;background:#161b22;color:#e6edf3;font-size:24px;display:none;z-index:50;cursor:pointer;opacity:.9;}",
  "#d2h-to-top.show{display:block;}",
].join('');

const body = Diff2Html.html(diffText, {
  outputFormat: 'line-by-line',
  drawFileList: true,
  fileContentToggle: false,
  colorScheme: 'auto',
});

const INIT_JS = `(function(){const qs=location.search;let sel=null;
if('virtualKeyboard' in navigator){try{navigator.virtualKeyboard.overlaysContent=true;}catch(e){}}
document.addEventListener('focusin',e=>{const el=e.target;
if(el&&el.tagName==='TEXTAREA'){setTimeout(()=>{try{el.scrollIntoView({block:'nearest'});}catch(_){}},350);}});
const comments=new Diff2Html.Diff2HtmlComments(document,s=>{sel=s;
if(s){comments.openEditor({placeholder:'Write a comment...',submitLabel:'Comment',
onSubmit:text=>send(s,text)});}});
async function load(){try{const r=await fetch('api/comments'+qs);if(!r.ok)return;
const items=await r.json();comments.setComments(items,{onDelete:i=>del(items[i]&&items[i].id)});}catch(e){}}
async function del(id){if(id==null)return;
try{await fetch('api/comments'+qs+'&id='+encodeURIComponent(id),{method:'DELETE'});load();}catch(e){}}
async function send(s,text){try{const r=await fetch('api/comments'+qs,{method:'POST',
headers:{'Content-Type':'application/json'},
body:JSON.stringify({file:s.file,oldLine:s.oldLine,newLine:s.newLine,
line:s.newLine==null?s.oldLine:s.newLine,text:String(text).slice(0,2000)})});
if(r.ok){comments.closeEditor();comments.clearSelection();load();}}catch(e){}}
const top=document.createElement('button');top.id='d2h-to-top';top.textContent='\\u2191';
top.setAttribute('aria-label','Back to top');
top.addEventListener('click',()=>window.scrollTo({top:0,behavior:'smooth'}));
document.body.appendChild(top);
addEventListener('scroll',()=>{top.classList.toggle('show',scrollY>600)},{passive:true});
const storeKey='d2h-reviewed:'+document.title;let store={};
try{store=JSON.parse(localStorage.getItem(storeKey)||'{}')||{}}catch(e){store={}}
const saveStore=()=>{try{localStorage.setItem(storeKey,JSON.stringify(store))}catch(e){}};
const listItems=Array.from(document.querySelectorAll('.d2h-file-list-line'));
const wrappers=Array.from(document.querySelectorAll('.d2h-file-wrapper'));
function curStats(i){const li=listItems[i];if(!li)return{a:null,d:null};
const a=li.querySelector('.d2h-lines-added');const d=li.querySelector('.d2h-lines-deleted');
return{a:a?a.textContent.trim():null,d:d?d.textContent.trim():null};}
function markList(i,on){const li=listItems[i];if(!li)return;
li.classList.toggle('d2h-reviewed',!!on);
let b=li.querySelector('.d2h-reviewed-mark');
if(on&&!b){b=document.createElement('span');b.className='d2h-reviewed-mark';
b.textContent='\\u2713 ';li.insertBefore(b,li.firstChild);}if(!on&&b)b.remove();}
function setCollapsed(w,i,on){const diff=w.querySelector('.d2h-file-diff,.d2h-files-diff');
if(diff)diff.classList.toggle('d2h-d-none',!!on);
w.classList.toggle('d2h-reviewed',!!on);
const lb=w.querySelector('.d2h-file-collapse');if(lb)lb.classList.toggle('d2h-selected',!!on);
markList(i,on);}
wrappers.forEach((w,i)=>{const n=w.querySelector('.d2h-file-name');
const file=n?(n.textContent||'').trim():'';
const box=w.querySelector('.d2h-file-collapse-input');if(!file||!box)return;
box.checked=false;const s=curStats(i);const kept=store[file];
if(kept&&kept.a===s.a&&kept.d===s.d&&kept.v){box.checked=true;setCollapsed(w,i,true);}
box.addEventListener('change',()=>{const on=box.checked;
if(on)store[file]={a:s.a,d:s.d,v:true};else delete store[file];
saveStore();setCollapsed(w,i,on);});});
document.addEventListener('DOMContentLoaded',()=>{load();});})();`;

const escTitle = String(title || 'diff review')
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;');
const page = [
  "<!DOCTYPE html><html lang='ru'><head><meta charset='utf-8'>",
  "<meta name='viewport' content='width=device-width,initial-scale=1,interactive-widget=resizes-content'>",
  `<title>${escTitle}</title><style>${css}</style><style>${PAGE_CSS}</style></head><body>`,
  `<div style="padding:12px 16px;font-family:-apple-system,system-ui,monospace"><b>${escTitle}</b></div>`,
  body,
  `<script>${bundle}</script>`,
  `<script>${INIT_JS}</script></body></html>`,
].join('\n');

fs.writeFileSync(outFile, page);
console.log(`wrote ${outFile} (${page.length} bytes)`);
