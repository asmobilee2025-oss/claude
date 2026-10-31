// Minimal static server with SPA fallback for testing build/web locally.
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
const root = normalize(process.argv[2] ?? '../build/web');
const port = Number(process.argv[3] ?? 5050);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.wasm': 'application/wasm', '.otf': 'font/otf', '.ttf': 'font/ttf' };
createServer(async (req, res) => {
  let p = normalize(join(root, decodeURIComponent(new URL(req.url, 'http://x').pathname)));
  if (!p.startsWith(root)) { res.writeHead(403).end(); return; }
  try { if ((await stat(p)).isDirectory()) p = join(p, 'index.html'); } catch { p = join(root, 'index.html'); }
  try { const b = await readFile(p); res.writeHead(200, { 'Content-Type': types[extname(p)] ?? 'application/octet-stream' }).end(b); }
  catch { res.writeHead(404).end(); }
}).listen(port, () => console.log(`serving ${root} on ${port}`));
