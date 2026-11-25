// Test van de multiplayer-server: draai eerst `npm run dev` (lokaal) en dan `npm test`,
// of SERVER=https://... npm test voor de echte server.
// Controleert: nieuwe code, binnenkomen, host, tekst en binair doorsturen, ping/pong,
// vertrekken met hostwissel, en een volle kamer (9e speler).
const BASE = process.env.SERVER || "http://127.0.0.1:8787";
const WS_BASE = BASE.replace(/^http/, "ws");

function connect(code, name) {
	return new Promise((resolve, reject) => {
		const ws = new WebSocket(`${WS_BASE}/room/${code}?name=${encodeURIComponent(name)}`);
		ws.binaryType = "arraybuffer";
		ws.inbox = [];
		ws.onmessage = (e) => ws.inbox.push(e.data);
		ws.onopen = () => resolve(ws);
		ws.onerror = (e) => reject(new Error("verbinding mislukt: " + name));
	});
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let failed = 0;
function check(ok, what) {
	console.log((ok ? "OK   " : "FOUT ") + what);
	if (!ok) failed++;
}
const texts = (ws) => ws.inbox.filter((m) => typeof m === "string").map((m) => JSON.parse(m));
const bins = (ws) => ws.inbox.filter((m) => typeof m !== "string").map((m) => new Uint8Array(m));

const res = await fetch(`${BASE}/new`);
const { code } = await res.json();
check(/^[A-Z]{4}$/.test(code), `nieuwe kamercode ${code}`);

const a = await connect(code, "Cliff");
await sleep(150);
const wa = texts(a).find((m) => m.t === "welcome");
check(wa && wa.id === 1 && wa.host === 1, "eerste speler is nummer 1 en host");

const b = await connect(code, "Bram");
await sleep(150);
const wb = texts(b).find((m) => m.t === "welcome");
check(wb && wb.id === 2 && wb.host === 1 && wb.players.length === 2, "tweede speler ziet beide spelers");
check(texts(a).some((m) => m.t === "join" && m.id === 2 && m.name === "Bram"), "host hoort dat Bram erbij komt");

a.send(JSON.stringify({ t: "chat", text: "hoi" }));
b.send(new Uint8Array([10, 20, 30]));
b.send(JSON.stringify({ t: "ping", c: 123 }));
await sleep(200);
check(texts(b).some((m) => m.t === "chat" && m.from === 1 && m.text === "hoi"), "tekstbericht komt aan met afzender");
const bin = bins(a).find((m) => m.length === 4);
check(bin && bin[0] === 2 && bin[1] === 10 && bin[3] === 30, "binair bericht komt aan met afzender-byte");
check(texts(b).some((m) => m.t === "pong" && m.c === 123 && m.s > 0), "ping krijgt pong met servertijd");
check(!texts(a).some((m) => m.t === "pong"), "pong gaat alleen naar wie pingde");

// vol: 6 extra (samen 8), dan een 9e
const extra = [];
for (let i = 3; i <= 8; i++) extra.push(await connect(code, "Speler" + i));
await sleep(200);
const ninth = await connect(code, "Negen");
await sleep(200);
check(texts(ninth).some((m) => m.t === "error" && m.reason === "full"), "9e speler krijgt 'kamer vol'");

// host vertrekt: nummer 2 wordt host
a.close();
await sleep(300);
check(texts(b).some((m) => m.t === "leave" && m.id === 1), "anderen horen dat de host weg is");
check(texts(b).some((m) => m.t === "host" && m.id === 2), "speler 2 wordt de nieuwe host");

for (const ws of [b, ninth, ...extra]) ws.close();
await sleep(200);
console.log(failed === 0 ? "\nAlles goed." : `\n${failed} fout(en).`);
process.exit(failed === 0 ? 0 : 1);
