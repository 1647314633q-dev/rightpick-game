// RightPick 職場遊樂場 — 排行榜 API（Cloudflare Pages Functions + D1）
// GET    /api/scores?game=smash&limit=10        → 今日（香港時間）排行榜
// POST   /api/scores  {game,score,hits,name}     → 提交分數，回傳排名同改名用 token
// PATCH  /api/scores  {id,token,name}            → 玩家改花名
// DELETE /api/scores?id=123   (Header X-Staff-Key) → 職員刪除記錄（要喺 Cloudflare 設定 STAFF_KEY 先用得）

const GAMES = { smash: { maxScore: 3500, maxHits: 80, maxPerHit: 60 } };
const BAD = ['屌','撚','柒','閪','屄','肏','仆街','冚家','含家','戇鳩','戆鸠','操你','草泥','傻逼','fuck','shit','bitch','cunt','dick','nigg','porn','sex'];
const ADJ = ['避坑勇者','準時放工俠','反OT戰士','職場清道夫','打工超人','炒老細高手','WLB守護者','求職新星','避雷達人','搵工獵人'];

const json = (data, status = 200) => new Response(JSON.stringify(data), {
  status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
});
const hkDay = () => new Date(Date.now() + 8 * 3600e3).toISOString().slice(0, 10);

let schemaReady = false;
async function ensureSchema(db) {
  if (schemaReady) return;
  await db.batch([
    db.prepare(`CREATE TABLE IF NOT EXISTS scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      game TEXT NOT NULL, day TEXT NOT NULL, name TEXT NOT NULL,
      score INTEGER NOT NULL, hits INTEGER NOT NULL DEFAULT 0,
      token TEXT NOT NULL, iphash TEXT, created INTEGER NOT NULL,
      hidden INTEGER NOT NULL DEFAULT 0)`),
    db.prepare(`CREATE INDEX IF NOT EXISTS idx_board ON scores(game, day, hidden, score DESC)`),
    db.prepare(`CREATE INDEX IF NOT EXISTS idx_ip ON scores(iphash, created)`),
  ]);
  schemaReady = true;
}

function cleanName(raw) {
  let s = String(raw || '').replace(/[\u0000-\u001f<>"'`\\]/g, '').replace(/\s+/g, ' ').trim();
  s = Array.from(s).slice(0, 12).join('');
  const low = s.toLowerCase().replace(/[\s._\-*]/g, '');
  if (!s || BAD.some(w => low.includes(w))) return '';
  return s;
}
async function sha(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].slice(0, 8).map(b => b.toString(16).padStart(2, '0')).join('');
}
async function board(db, game, day, limit) {
  const { results } = await db.prepare(
    `SELECT id, name, score FROM scores WHERE game=? AND day=? AND hidden=0 ORDER BY score DESC, id ASC LIMIT ?`
  ).bind(game, day, limit).all();
  const total = await db.prepare(`SELECT COUNT(*) AS n FROM scores WHERE game=? AND day=? AND hidden=0`).bind(game, day).first('n');
  return { top: results, total };
}

export async function onRequest({ request, env }) {
  if (!env.DB) return json({ error: 'no-db' }, 503);
  const db = env.DB;
  await ensureSchema(db);
  const url = new URL(request.url);
  const day = hkDay();

  if (request.method === 'GET') {
    const game = url.searchParams.get('game') || 'smash';
    if (!GAMES[game]) return json({ error: 'game' }, 400);
    const limit = Math.min(50, Math.max(1, parseInt(url.searchParams.get('limit') || '10', 10)));
    return json({ day, ...(await board(db, game, day, limit)) });
  }

  if (request.method === 'POST') {
    let b; try { b = await request.json(); } catch { return json({ error: 'json' }, 400); }
    const rule = GAMES[b.game];
    if (!rule) return json({ error: 'game' }, 400);
    const score = Math.floor(Number(b.score)), hits = Math.floor(Number(b.hits));
    if (!Number.isFinite(score) || !Number.isFinite(hits) || score < 0 || hits < 0
      || score > rule.maxScore || hits > rule.maxHits || score > hits * rule.maxPerHit) {
      return json({ error: 'invalid-score' }, 400);
    }
    const now = Date.now();
    const ip = request.headers.get('cf-connecting-ip') || '';
    const iphash = await sha(ip + '|' + day);
    // 同一網絡（例如場地 Wi-Fi）會共用 IP，所以限制放寬：每分鐘最多 20 次
    const recent = await db.prepare(`SELECT COUNT(*) AS n FROM scores WHERE iphash=? AND created>?`).bind(iphash, now - 60e3).first('n');
    if (recent >= 20) return json({ error: 'rate' }, 429);
    const token = crypto.randomUUID();
    let name = cleanName(b.name);
    const ins = await db.prepare(
      `INSERT INTO scores (game, day, name, score, hits, token, iphash, created) VALUES (?,?,?,?,?,?,?,?)`
    ).bind(b.game, day, name || 'pending', score, hits, token, iphash, now).run();
    const id = ins.meta.last_row_id;
    if (!name) {
      name = `${ADJ[id % ADJ.length]} #${String(id).padStart(3, '0')}`;
      await db.prepare(`UPDATE scores SET name=? WHERE id=?`).bind(name, id).run();
    }
    const better = await db.prepare(
      `SELECT COUNT(*) AS n FROM scores WHERE game=? AND day=? AND hidden=0 AND (score>? OR (score=? AND id<?))`
    ).bind(b.game, day, score, score, id).first('n');
    return json({ id, token, name, rank: better + 1, day, ...(await board(db, b.game, day, 5)) });
  }

  if (request.method === 'PATCH') {
    let b; try { b = await request.json(); } catch { return json({ error: 'json' }, 400); }
    const name = cleanName(b.name);
    if (!name) return json({ error: 'name' }, 400);
    const r = await db.prepare(`UPDATE scores SET name=? WHERE id=? AND token=? AND day=?`).bind(name, Number(b.id), String(b.token || ''), day).run();
    if (!r.meta.changes) return json({ error: 'not-found' }, 404);
    return json({ ok: true, name });
  }

  if (request.method === 'DELETE') {
    const key = request.headers.get('x-staff-key') || '';
    if (!env.STAFF_KEY || key !== env.STAFF_KEY) return json({ error: 'forbidden' }, 403);
    const id = Number(url.searchParams.get('id'));
    await db.prepare(`UPDATE scores SET hidden=1 WHERE id=?`).bind(id).run();
    return json({ ok: true });
  }

  return json({ error: 'method' }, 405);
}
