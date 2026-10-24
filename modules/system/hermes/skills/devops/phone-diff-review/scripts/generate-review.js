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

const Diff2Html = require(bundlePath);
const diffText = fs.readFileSync(diffFile, 'utf8');
const css = fs.readFileSync(cssPath, 'utf8');
const bundle = fs.readFileSync(bundlePath, 'utf8');

const PAGE_CSS = [
  "body{margin:0;background:#fff;color:#24292e;}",
  "@media (prefers-color-scheme:dark){body{background:#0d1117;color:#e6edf3;}}",
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
