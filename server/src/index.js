// Multiplayer-server van Parkstad Racer (fase 0, zie MULTIPLAYER_PLAN.md).
//
// De server rekent niets aan het spel uit: hij deelt kamercodes uit en stuurt berichten
// door tussen de spelers in een kamer. Elke kamer is een eigen Durable Object.
//
//   GET  /new              -> {"code": "ABCD"}  een nieuwe, vrije kamercode
//   GET  /room/ABCD?name=X -> WebSocket naar die kamer
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

const LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ";   // geen I en O: niet te verwarren met 1 en 0
const MAX_PLAYERS = 8;
const CLAIM_MS = 10 * 60 * 1000;              // een nieuwe code blijft 10 minuten gereserveerd

const CORS = { "Access-Control-Allow-Origin": "*" };

function randomCode() {
	const buf = new Uint8Array(4);
	crypto.getRandomValues(buf);
	return Array.from(buf, (b) => LETTERS[b % LETTERS.length]).join("");
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
