// Multiplayer-server van Parkstad Racer (fase 0, zie MULTIPLAYER_PLAN.md).
//
// De server rekent niets aan het spel uit: hij deelt kamercodes uit en stuurt berichten
// door tussen de spelers in een kamer. Elke kamer is een eigen Durable Object.
//
//   GET  /new              -> {"code": "ABCD"}  een nieuwe, vrije kamercode
//   GET  /room/ABCD?name=X -> WebSocket naar die kamer
//   POST /report           -> probleemrapport van het spel opslaan (JSON, max 16 kB; geen
//                             naam of IP-adres, alleen technische gegevens)
//   GET  /reports?n=50     -> de laatste rapporten (alleen met Authorization: Bearer <REPORT_KEY>)
//   POST /event            -> anonieme gebeurtenis van het spel (open, race_start, race_end)
//   GET  /stats?days=30    -> opgetelde statistieken (zelfde sleutel als /reports)
//   GET  /dashboard        -> de statistiekenpagina (inloggen met gebruikersnaam en wachtwoord)
//   POST /login            -> inloggen (DASHBOARD_USER / DASHBOARD_PASSWORD, geheimen op Cloudflare);
//                             geeft een cookie dat 30 dagen geldig is
//   POST /password         -> wachtwoord wijzigen (ingelogd, met het huidige wachtwoord); daarna
//                             staat het versleuteld (PBKDF2) in het Stats-object
//   GET  /logout           -> uitloggen
// /stats en /reports mogen met dat cookie, of met Authorization: Bearer <REPORT_KEY> (tools/reports.sh).
//
// Berichten van de server (tekst, JSON):
//   {"t":"welcome","id":1,"host":1,"code":"ABCD","players":[{"id":1,"name":"Cliff"}]}
//   {"t":"join","id":2,"name":"Bram"}     iemand komt erbij
//   {"t":"leave","id":2}                  iemand is weg
//   {"t":"host","id":3}                   nieuwe host (de vorige is weg)
//   {"t":"pong","c":<jouw tijd>,"s":<servertijd ms>}   antwoord op {"t":"ping","c":...}
//   {"t":"error","reason":"full"}          de kamer is vol (8 spelers)
//
// Berichten van spelers:
//   tekst (JSON): gaat met "from": <id> erbij naar alle anderen, of alleen naar "to": <id>
//   binair: gaat naar alle anderen, met de id van de afzender als eerste byte ervoor
//           (de autoposities, ~15 keer per seconde)

import { DurableObject } from "cloudflare:workers";
import DASHBOARD from "./dashboard.html";

const LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ";   // geen I en O: niet te verwarren met 1 en 0
const MAX_PLAYERS = 8;
const CLAIM_MS = 10 * 60 * 1000;              // een nieuwe code blijft 10 minuten gereserveerd

const CORS = { "Access-Control-Allow-Origin": "*" };
const REPORT_MAX = 16 * 1024;
const REPORTS_KEEP = 1000;

function randomCode() {
	const buf = new Uint8Array(4);
	crypto.getRandomValues(buf);
	return Array.from(buf, (b) => LETTERS[b % LETTERS.length]).join("");
}

// Alleen bekende velden, kort en van het juiste soort; de rest gaat niet mee.
const EVENTS = ["open", "race_start", "race_end"];
function cleanEvent(d) {
	if (!d || typeof d !== "object" || !EVENTS.includes(d.e)) return null;
	const str = (x, n = 40) => (typeof x === "string" ? x.slice(0, n) : "");
	const num = (x) => (typeof x === "number" && isFinite(x) ? x : null);
	return {
		e: d.e, vid: str(d.vid, 64), v: str(d.v, 12), dev: str(d.dev, 12), br: str(d.br, 20), app: d.app ? 1 : 0,
		lvl: str(d.lvl, 24), mode: str(d.mode, 8), diff: num(d.diff), car: str(d.car, 24),
		res: str(d.res, 10), pos: num(d.pos), secs: num(d.secs), n: num(d.n), cp: num(d.cp),
		boot_ms: num(d.boot_ms), load_ms: num(d.load_ms), prewarm_ms: num(d.prewarm_ms), fps: num(d.fps), slow: num(d.slow),
		gpu: str(d.gpu, 60), gfx: str(d.gfx, 8),
	};
}


// ---- inloggen voor de statistiekenpagina ----
// Het wachtwoord staat versleuteld (PBKDF2, met zout) in het Stats-object; zolang het nog niet
// gewijzigd is, geldt het geheim DASHBOARD_PASSWORD. Het cookie is "<verloopt>.<handtekening>":
// een HMAC met REPORT_KEY en het zout, dus niet na te maken, en na een wachtwoordwissel zijn
// alle oude cookies meteen ongeldig. Er staat niets persoonlijks in.
const SESSION_DAYS = 30;
const PBKDF2_ROUNDS = 100000;
const enc = new TextEncoder();

function b64(buf) {
	return btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/[+/=]/g, (c) => ({ "+": "-", "/": "_", "=": "" }[c]));
}

async function hmac(env, text) {
	const key = await crypto.subtle.importKey("raw", enc.encode("sessie:" + env.REPORT_KEY), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
	return b64(await crypto.subtle.sign("HMAC", key, enc.encode(text)));
}

async function pbkdf2(pass, salt) {
	const key = await crypto.subtle.importKey("raw", enc.encode(pass), "PBKDF2", false, ["deriveBits"]);
	return b64(await crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt: enc.encode(salt), iterations: PBKDF2_ROUNDS }, key, 256));
}

// vergelijken in vaste tijd (geen hint via de reactietijd)
async function same(a, b) {
	const [x, y] = await Promise.all([crypto.subtle.digest("SHA-256", enc.encode(String(a))), crypto.subtle.digest("SHA-256", enc.encode(String(b)))]);
	const u = new Uint8Array(x), v = new Uint8Array(y);
	let d = 0;
	for (let i = 0; i < u.length; i++) d |= u[i] ^ v[i];
	return d === 0;
}

function statsBox(env) {
	return env.STATS.get(env.STATS.idFromName("all"));
}

// het opgeslagen wachtwoord ({salt, hash}), of null als het nog het geheim is
async function storedPassword(env) {
	const res = await statsBox(env).fetch("https://stats/auth");
	const d = await res.json();
	return d && d.salt ? d : null;
}

async function checkPassword(env, pass) {
	const st = await storedPassword(env);
	if (st) return { ok: await same(await pbkdf2(pass, st.salt), st.hash), salt: st.salt };
	return { ok: !!env.DASHBOARD_PASSWORD && (await same(pass, env.DASHBOARD_PASSWORD)), salt: "" };
}

async function sessionCookie(env, salt) {
	const until = String(Date.now() + SESSION_DAYS * 86400000);
	return `pr_session=${until}.${await hmac(env, until + "|" + salt)}; Path=/; Max-Age=${SESSION_DAYS * 86400}; HttpOnly; Secure; SameSite=Strict`;
}

async function allowed(request, env) {
	if (!env.REPORT_KEY) return false;
	const auth = request.headers.get("Authorization") || "";
	if (auth.startsWith("Bearer ") && (await same(auth.slice(7), env.REPORT_KEY))) return true;
	const m = (request.headers.get("Cookie") || "").match(/(?:^|;\s*)pr_session=([0-9]+)\.([A-Za-z0-9_-]+)/);
	if (!m || parseInt(m[1], 10) < Date.now()) return false;
	const st = await storedPassword(env);
	return same(m[2], await hmac(env, m[1] + "|" + (st ? st.salt : "")));
}

const slow = () => new Promise((r) => setTimeout(r, 1200));   // raden kost tijd
const back = (where, cookie) => new Response(null, { status: 303, headers: cookie ? { Location: where, "Set-Cookie": cookie } : { Location: where } });

async function login(request, env) {
	const form = await request.formData().catch(() => null);
	const user = form ? String(form.get("username") || "") : "";
	const pass = form ? String(form.get("password") || "") : "";
	if (!env.DASHBOARD_USER || !env.REPORT_KEY || !(await same(user.trim().toLowerCase(), String(env.DASHBOARD_USER).toLowerCase()))) {
		await slow();
		return back("dashboard?fout=1");
	}
	const c = await checkPassword(env, pass);
	if (!c.ok) {
		await slow();
		return back("dashboard?fout=1");
	}
	return back("dashboard", await sessionCookie(env, c.salt));
}

// wachtwoord wijzigen: alleen ingelogd en met het huidige wachtwoord
async function changePassword(request, env) {
	if (!(await allowed(request, env))) return back("dashboard");
	const form = await request.formData().catch(() => null);
	const cur = form ? String(form.get("current") || "") : "";
	const nw = form ? String(form.get("new") || "") : "";
	const nw2 = form ? String(form.get("repeat") || "") : "";
	if (!(await checkPassword(env, cur)).ok) {
		await slow();
		return back("dashboard?pw=huidig");
	}
	if (nw.length < 10) return back("dashboard?pw=kort");
	if (nw !== nw2) return back("dashboard?pw=anders");
	const salt = b64(crypto.getRandomValues(new Uint8Array(16)));
	await statsBox(env).fetch("https://stats/auth", { method: "POST", body: JSON.stringify({ salt, hash: await pbkdf2(nw, salt) }) });
	return back("dashboard?pw=ok", await sessionCookie(env, salt));
}

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		if (url.pathname === "/new") {
			for (let i = 0; i < 20; i++) {
				const code = randomCode();
				const room = env.ROOMS.get(env.ROOMS.idFromName(code));
				const res = await room.fetch("https://room/claim");
				if (res.ok) {
					return Response.json({ code }, { headers: CORS });
				}
			}
			return new Response("Geen vrije kamercode gevonden", { status: 503, headers: CORS });
		}
		const m = url.pathname.match(/^\/room\/([A-Z]{4})$/);
		if (m) {
			if (request.headers.get("Upgrade") !== "websocket") {
				return new Response("Verwacht een WebSocket", { status: 426, headers: CORS });
			}
			const room = env.ROOMS.get(env.ROOMS.idFromName(m[1]));
			return room.fetch(request);
		}
		if (url.pathname === "/report") {
			if (request.method === "OPTIONS") {
				return new Response(null, { headers: { ...CORS, "Access-Control-Allow-Methods": "POST", "Access-Control-Allow-Headers": "Content-Type" } });
			}
			if (request.method !== "POST") {
				return new Response("Verwacht POST", { status: 405, headers: CORS });
			}
			const body = await request.text();
			if (body.length > REPORT_MAX) {
				return new Response("Te groot", { status: 413, headers: CORS });
			}
			let data;
			try { data = JSON.parse(body); } catch (e) { data = null; }
			if (!data || typeof data !== "object") {
				return new Response("Geen JSON", { status: 400, headers: CORS });
			}
			// land (grof, van Cloudflare) is handig; het IP-adres bewaren we niet
			data.country = (request.cf && request.cf.country) || "";
			const box = env.REPORTS.get(env.REPORTS.idFromName("all"));
			await box.fetch("https://reports/add", { method: "POST", body: JSON.stringify(data) });
			return new Response("ok", { headers: CORS });
		}
		if (url.pathname === "/reports") {
			if (!(await allowed(request, env))) {
				return new Response("Geen toegang", { status: 401, headers: CORS });
			}
			const box = env.REPORTS.get(env.REPORTS.idFromName("all"));
			return box.fetch("https://reports/list?n=" + (url.searchParams.get("n") || "50"));
		}
		if (url.pathname === "/event") {
			if (request.method === "OPTIONS") {
				return new Response(null, { headers: { ...CORS, "Access-Control-Allow-Methods": "POST", "Access-Control-Allow-Headers": "Content-Type" } });
			}
			if (request.method !== "POST") {
				return new Response("Verwacht POST", { status: 405, headers: CORS });
			}
			const body = await request.text();
			if (body.length > 2048) {
				return new Response("Te groot", { status: 413, headers: CORS });
			}
			let d;
			try { d = JSON.parse(body); } catch (e) { d = null; }
			const ev = cleanEvent(d);
			if (!ev) {
				return new Response("Ongeldig", { status: 400, headers: CORS });
			}
			const box = env.STATS.get(env.STATS.idFromName("all"));
			await box.fetch("https://stats/add", { method: "POST", body: JSON.stringify(ev) });
			return new Response("ok", { headers: CORS });
		}
		if (url.pathname === "/stats") {
			if (!(await allowed(request, env))) {
				return new Response("Geen toegang", { status: 401, headers: CORS });
			}
			const box = env.STATS.get(env.STATS.idFromName("all"));
			const res = await box.fetch("https://stats/sum?days=" + (url.searchParams.get("days") || "30"));
			return new Response(res.body, { headers: { ...CORS, "Content-Type": "application/json" } });
		}
		if (url.pathname === "/login" && request.method === "POST") {
			return login(request, env);
		}
		if (url.pathname === "/password" && request.method === "POST") {
			return changePassword(request, env);
		}
		if (url.pathname === "/logout") {
			return new Response(null, { status: 303, headers: { Location: "dashboard", "Set-Cookie": "pr_session=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Strict" } });
		}
		if (url.pathname === "/dashboard") {
			return new Response(DASHBOARD, { headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" } });
		}
		if (url.pathname === "/") {
			return new Response("Parkstad Racer multiplayer", { headers: CORS });
		}
		return new Response("Niet gevonden", { status: 404, headers: CORS });
	},
};

export class Room extends DurableObject {
	// Spelers in de kamer: [{ws, id, name}], uit de WebSockets zelf (blijft werken als het
	// object tussendoor slaapt; de gegevens hangen als "attachment" aan elke WebSocket).
	players() {
		// zonder attachment: geweigerd (kamer vol) of al vertrokken
		return this.ctx.getWebSockets()
			.map((ws) => ({ ws, ...(ws.deserializeAttachment() || {}) }))
			.filter((p) => p.id);
	}

	async fetch(request) {
		const url = new URL(request.url);
		const code = (url.pathname.match(/([A-Z]{4})$/) || [])[1] || "";
		if (url.pathname === "/claim") {
			// vrij als er niemand in zit en de code niet net door een ander is gereserveerd
			const claimed = (await this.ctx.storage.get("claimed")) || 0;
			if (this.players().length > 0 || Date.now() - claimed < CLAIM_MS) {
				return new Response("bezet", { status: 409 });
			}
			await this.ctx.storage.put("claimed", Date.now());
			return new Response("ok");
		}

		const pair = new WebSocketPair();
		const [client, server] = Object.values(pair);
		this.ctx.acceptWebSocket(server);
		const others = this.players().filter((p) => p.ws !== server);
		if (others.length >= MAX_PLAYERS) {
			server.send(JSON.stringify({ t: "error", reason: "full" }));
			server.close(4000, "full");
			return new Response(null, { status: 101, webSocket: client });
		}
		// laagste vrije nummer, 1 t/m 8
		const taken = new Set(others.map((p) => p.id));
		let id = 1;
		while (taken.has(id)) id++;
		const name = (url.searchParams.get("name") || "Speler " + id).slice(0, 20);
		server.serializeAttachment({ id, name });

		let host = (await this.ctx.storage.get("host")) || 0;
		if (!taken.has(host)) {
			host = id;
			await this.ctx.storage.put("host", host);
		}
		await this.ctx.storage.put("code", code);
		server.send(JSON.stringify({
			t: "welcome", id, host, code,
			players: others.map((p) => ({ id: p.id, name: p.name })).concat([{ id, name }]),
		}));
		this.broadcast(server, JSON.stringify({ t: "join", id, name }));
		return new Response(null, { status: 101, webSocket: client });
	}

	broadcast(from, data) {
		for (const p of this.players()) {
			if (p.ws === from) continue;
			try {
				p.ws.send(data);
			} catch (e) {
				// verbinding net weg: wordt via webSocketClose opgeruimd
			}
		}
	}

	async webSocketMessage(ws, message) {
		const me = ws.deserializeAttachment();
		if (!me) return;
		if (typeof message === "string") {
			let msg;
			try {
				msg = JSON.parse(message);
			} catch (e) {
				return;
			}
			if (msg.t === "ping") {
				ws.send(JSON.stringify({ t: "pong", c: msg.c, s: Date.now() }));
				return;
			}
			msg.from = me.id;
			const out = JSON.stringify(msg);
			if (typeof msg.to === "number") {
				const target = this.players().find((p) => p.id === msg.to);
				if (target) target.ws.send(out);
			} else {
				this.broadcast(ws, out);
			}
			return;
		}
		// binair: afzender ervoor en door naar alle anderen
		const src = new Uint8Array(message);
		const out = new Uint8Array(src.length + 1);
		out[0] = me.id;
		out.set(src, 1);
		this.broadcast(ws, out);
	}

	async webSocketClose(ws, code, reason, wasClean) {
		await this.leave(ws);
	}

	async webSocketError(ws, error) {
		await this.leave(ws);
	}

	async leave(ws) {
		const me = ws.deserializeAttachment();
		try {
			ws.close(1000, "bye");
		} catch (e) {
			// al dicht
		}
		if (!me) return;
		ws.serializeAttachment(null);
		const rest = this.players().filter((p) => p.ws !== ws && p.id);
		this.broadcast(ws, JSON.stringify({ t: "leave", id: me.id }));
		if (rest.length === 0) {
			// lege kamer: alles weg, de code is daarna weer vrij
			await this.ctx.storage.deleteAll();
			return;
		}
		const host = (await this.ctx.storage.get("host")) || 0;
		if (host === me.id) {
			const next = Math.min(...rest.map((p) => p.id));
			await this.ctx.storage.put("host", next);
			this.broadcast(ws, JSON.stringify({ t: "host", id: next }));
		}
	}
}

// Alle probleemrapporten in één Durable Object (SQLite); de oudste gaan eruit boven REPORTS_KEEP.
export class Reports extends DurableObject {
	constructor(ctx, env) {
		super(ctx, env);
		this.ctx.storage.sql.exec("CREATE TABLE IF NOT EXISTS reports (id INTEGER PRIMARY KEY AUTOINCREMENT, t INTEGER, data TEXT)");
	}

	async fetch(request) {
		const url = new URL(request.url);
		const sql = this.ctx.storage.sql;
		if (url.pathname === "/add") {
			sql.exec("INSERT INTO reports (t, data) VALUES (?, ?)", Date.now(), await request.text());
			sql.exec("DELETE FROM reports WHERE id <= (SELECT MAX(id) FROM reports) - ?", REPORTS_KEEP);
			return new Response("ok");
		}
		if (url.pathname === "/list") {
			const n = Math.max(1, Math.min(500, parseInt(url.searchParams.get("n") || "50", 10) || 50));
			const rows = sql.exec("SELECT id, t, data FROM reports ORDER BY id DESC LIMIT ?", n).toArray()
				.map((r) => ({ id: r.id, time: new Date(r.t).toISOString(), ...JSON.parse(r.data) }));
			return Response.json(rows);
		}
		return new Response("Niet gevonden", { status: 404 });
	}
}

// Statistieken: elke gebeurtenis een regel (SQLite), opgeteld bij het opvragen. Dagen en uren
// in Nederlandse tijd. Ouder dan een jaar gaat eruit.
export class Stats extends DurableObject {
	constructor(ctx, env) {
		super(ctx, env);
		this.ctx.storage.sql.exec(`CREATE TABLE IF NOT EXISTS ev (
			id INTEGER PRIMARY KEY AUTOINCREMENT, t INTEGER, day TEXT, hour INTEGER, e TEXT, vid TEXT, v TEXT,
			dev TEXT, br TEXT, app INTEGER, lvl TEXT, mode TEXT, diff INTEGER, car TEXT, res TEXT,
			pos INTEGER, secs REAL, n INTEGER, cp INTEGER, boot_ms INTEGER, load_ms INTEGER, prewarm_ms INTEGER,
			fps REAL, slow REAL, gpu TEXT, gfx TEXT)`);
		this.ctx.storage.sql.exec("CREATE INDEX IF NOT EXISTS ev_day ON ev (day)");
	}

	async fetch(request) {
		const url = new URL(request.url);
		const sql = this.ctx.storage.sql;
		if (url.pathname === "/add") {
			const d = JSON.parse(await request.text());
			const now = new Date();
			const parts = Object.fromEntries(new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Amsterdam", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", hourCycle: "h23" })
				.formatToParts(now).map((p) => [p.type, p.value]));
			sql.exec(`INSERT INTO ev (t, day, hour, e, vid, v, dev, br, app, lvl, mode, diff, car, res, pos, secs, n, cp,
				boot_ms, load_ms, prewarm_ms, fps, slow, gpu, gfx)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
				now.getTime(), `${parts.year}-${parts.month}-${parts.day}`, parseInt(parts.hour, 10), d.e, d.vid, d.v, d.dev, d.br, d.app,
				d.lvl, d.mode, d.diff, d.car, d.res, d.pos, d.secs, d.n, d.cp,
				d.boot_ms, d.load_ms, d.prewarm_ms, d.fps, d.slow, d.gpu, d.gfx);
			if (Math.random() < 0.01) {
				sql.exec("DELETE FROM ev WHERE t < ?", now.getTime() - 366 * 86400000);
			}
			return new Response("ok");
		}
		if (url.pathname === "/auth") {
			if (request.method === "POST") {
				await this.ctx.storage.put("auth", JSON.parse(await request.text()));
				return new Response("ok");
			}
			return Response.json((await this.ctx.storage.get("auth")) || {});
		}
		if (url.pathname === "/sum") {
			const days = Math.max(1, Math.min(365, parseInt(url.searchParams.get("days") || "30", 10) || 30));
			const since = new Date(Date.now() - (days - 1) * 86400000).toLocaleDateString("en-CA", { timeZone: "Europe/Amsterdam" });
			const today = new Date().toLocaleDateString("en-CA", { timeZone: "Europe/Amsterdam" });
			const q = (text, ...args) => sql.exec(text, ...args).toArray();
			const one = (text, ...args) => q(text, ...args)[0] || {};
			const players = (from) => one("SELECT COUNT(DISTINCT vid) AS n FROM ev WHERE day >= ? AND vid != ''", from).n || 0;
			const dayAgo = (n) => new Date(Date.now() - n * 86400000).toLocaleDateString("en-CA", { timeZone: "Europe/Amsterdam" });
			const out = {
				days, since, today,
				totals: {
					players_today: players(today),
					players_7: players(dayAgo(6)),
					players_period: players(since),
					players_all: one("SELECT COUNT(DISTINCT vid) AS n FROM ev WHERE vid != ''").n || 0,
					...one(`SELECT SUM(e = 'race_start') AS starts, SUM(e = 'race_end' AND res = 'finish') AS finishes,
						SUM(e = 'race_end' AND res = 'time_up') AS time_ups, SUM(e = 'race_end' AND res = 'quit') AS quits,
						SUM(e = 'race_start' AND mode = 'mp') AS mp_races, SUM(e = 'race_start' AND mode = 'free') AS free_rides,
						SUM(e = 'race_end' AND res = 'finish' AND pos = 1 AND mode = 'race') AS wins,
						SUM(CASE WHEN e = 'race_end' THEN secs ELSE 0 END) AS secs_driven
						FROM ev WHERE day >= ?`, since),
					installed: one(`SELECT COUNT(DISTINCT vid) AS n FROM ev WHERE day >= ? AND app = 1 AND vid != ''`, since).n || 0,
				},
				daily: q(`SELECT day, COUNT(DISTINCT vid) AS players, SUM(e = 'race_start') AS starts,
					SUM(e = 'race_end' AND res = 'finish') AS finishes FROM ev WHERE day >= ? GROUP BY day ORDER BY day`, since),
				levels: q(`SELECT lvl, SUM(e = 'race_start') AS starts, SUM(e = 'race_end' AND res = 'finish') AS finishes,
					SUM(e = 'race_end' AND res = 'time_up') AS time_ups, SUM(e = 'race_end' AND res = 'quit') AS quits,
					AVG(CASE WHEN e = 'race_end' AND res = 'finish' AND mode = 'race' THEN pos END) AS avg_pos,
					MIN(CASE WHEN e = 'race_end' AND res = 'finish' AND mode != 'free' THEN secs END) AS best_secs,
					COUNT(DISTINCT vid) AS players
					FROM ev WHERE day >= ? AND lvl != '' AND mode != 'free' GROUP BY lvl`, since),
				devices: q(`SELECT dev AS k, COUNT(DISTINCT vid) AS n FROM ev WHERE day >= ? GROUP BY dev ORDER BY n DESC`, since),
				browsers: q(`SELECT br AS k, COUNT(DISTINCT vid) AS n FROM ev WHERE day >= ? GROUP BY br ORDER BY n DESC`, since),
				difficulty: q(`SELECT diff AS k, COUNT(*) AS n FROM ev WHERE day >= ? AND e = 'race_start' AND mode = 'race' GROUP BY diff ORDER BY diff`, since),
				cars: q(`SELECT car AS k, COUNT(*) AS n FROM ev WHERE day >= ? AND e = 'race_start' AND car != '' GROUP BY car ORDER BY n DESC`, since),
				modes: q(`SELECT mode AS k, COUNT(*) AS n FROM ev WHERE day >= ? AND e = 'race_start' GROUP BY mode ORDER BY n DESC`, since),
				hours: q(`SELECT hour AS k, COUNT(*) AS n FROM ev WHERE day >= ? AND e = 'race_start' GROUP BY hour ORDER BY hour`, since),
				versions: q(`SELECT v AS k, COUNT(DISTINCT vid) AS n FROM ev WHERE day >= ? GROUP BY v ORDER BY v DESC`, since),
			};
			// prestaties: mediaan en de traagste 10% (p90), per apparaat, level en grafische chip
			const pct = (arr, p) => {
				const v = arr.filter((x) => x != null && x > 0).sort((a, b) => a - b);
				return v.length ? v[Math.min(v.length - 1, Math.floor(p * v.length))] : null;
			};
			const group = (rows, key, fields) => {
				const g = {};
				rows.forEach((r) => { const k = r[key] || "?"; (g[k] = g[k] || []).push(r); });
				return Object.entries(g).map(([k, list]) => {
					const o = { k, n: list.length };
					fields.forEach((f) => { o[f + "_med"] = pct(list.map((r) => r[f]), 0.5); o[f + "_p90"] = pct(list.map((r) => r[f]), 0.9); });
					return o;
				}).sort((a, b) => b.n - a.n);
			};
			const opens = q(`SELECT dev, gpu, boot_ms FROM ev WHERE day >= ? AND e = 'open'`, since);
			const loads = q(`SELECT dev, gpu, lvl, load_ms, prewarm_ms FROM ev WHERE day >= ? AND e = 'race_start'`, since);
			const runs = q(`SELECT dev, gpu, lvl, fps, slow FROM ev WHERE day >= ? AND e = 'race_end' AND secs > 20`, since);
			const merge = (a, b) => {
				const m = {};
				a.concat(b).forEach((r) => { m[r.k] = Object.assign(m[r.k] || { k: r.k }, r, { n: Math.max((m[r.k] || {}).n || 0, r.n) }); });
				return Object.values(m).sort((x, y) => y.n - x.n);
			};
			out.perf = {
				boot: { med: pct(opens.map((r) => r.boot_ms), 0.5), p90: pct(opens.map((r) => r.boot_ms), 0.9) },
				load: { med: pct(loads.map((r) => r.load_ms), 0.5), p90: pct(loads.map((r) => r.load_ms), 0.9) },
				fps: { med: pct(runs.map((r) => r.fps), 0.5), p10: pct(runs.map((r) => r.fps), 0.1) },
				devices: merge(merge(group(opens, "dev", ["boot_ms"]), group(loads, "dev", ["load_ms", "prewarm_ms"])), group(runs, "dev", ["fps", "slow"])),
				levels: merge(group(loads, "lvl", ["load_ms", "prewarm_ms"]), group(runs, "lvl", ["fps", "slow"])),
				gpus: merge(group(loads, "gpu", ["load_ms"]), group(runs, "gpu", ["fps", "slow"])).filter((r) => r.k !== "?").slice(0, 12),
			};
			return Response.json(out);
		}
		return new Response("Niet gevonden", { status: 404 });
	}
}
