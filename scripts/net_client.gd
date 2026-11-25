extends Node
# Verbinding met de multiplayer-server (zie MULTIPLAYER_PLAN.md en server/src/index.js).
# Werkt in de browser (ook op de iPhone) en op de computer: WebSocket naar een Cloudflare-
# kamer met een code van 4 letters. De server stuurt alleen door; dit script houdt bij wie
# er in de kamer zit, wie de host is, en hoe de klok van de server loopt.
#
#   var net := NetClient.new(); add_child(net)
#   net.new_room()                 -> signaal room_created(code), of failed(reden)
#   net.join("ABCD", "Cliff")      -> signaal welcomed(id, host, players)
#   net.send_json({"t": "start", ...}) / net.send_state(bytes)
#
# Elke seconde een ping: daarmee schatten we de servertijd (server_time_ms()), zodat
# iedereen op hetzelfde moment kan starten.

signal room_created(code: String)
signal welcomed(id: int, host: int, players: Array)
signal joined(id: int, name: String)
signal left(id: int)
signal host_changed(id: int)
signal message(from: int, msg: Dictionary)
signal state(from: int, data: PackedByteArray)
signal failed(reason: String)
signal disconnected()

const DEFAULT_SERVER := "https://parkstad-racer-mp.workers.dev"   # na het uploaden aanpassen
const PING_EVERY := 1.0

var server := DEFAULT_SERVER
var ws: WebSocketPeer = null
var my_id := 0
var host_id := 0
var code := ""
var players := {}            # id -> naam
var rtt_ms := -1.0           # laatste rondetijd van een ping
var _offset_ms := 0.0        # servertijd - eigen klok
var _have_offset := false
var _ping_t := 0.0
var _was_open := false

func _init() -> void:
	var env := OS.get_environment("PARKSTAD_SERVER")
	if env != "":
		server = env

func is_host() -> bool:
	return my_id != 0 and my_id == host_id

func is_open() -> bool:
	return ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN

# Servertijd in milliseconden, geschat uit de pings.
func server_time_ms() -> float:
	return Time.get_unix_time_from_system() * 1000.0 + _offset_ms

# Vraag de server om een nieuwe, vrije kamercode.
func new_room() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result: int, status: int, _h: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or status != 200:
			failed.emit("Geen verbinding met de server (%d/%d)" % [result, status])
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if typeof(data) != TYPE_DICTIONARY or not data.has("code"):
			failed.emit("Onverwacht antwoord van de server")
			return
		room_created.emit(String(data["code"])))
	var err := http.request(server + "/new")
	if err != OK:
		http.queue_free()
		failed.emit("Kan de server niet bereiken (%d)" % err)

func join(room_code: String, player_name: String) -> void:
	close()
	code = room_code.strip_edges().to_upper()
	ws = WebSocketPeer.new()
	ws.inbound_buffer_size = 1 << 18
	ws.outbound_buffer_size = 1 << 18
	var url := server.replace("https://", "wss://").replace("http://", "ws://")
	var err := ws.connect_to_url("%s/room/%s?name=%s" % [url, code, player_name.uri_encode()])
	if err != OK:
		ws = null
		failed.emit("Kan niet verbinden (%d)" % err)

func close() -> void:
	if ws != null:
		ws.close()
	ws = null
	my_id = 0
	host_id = 0
	players.clear()
	_was_open = false
	_have_offset = false

func send_json(msg: Dictionary) -> void:
	if is_open():
		ws.send_text(JSON.stringify(msg))

func send_state(data: PackedByteArray) -> void:
	if is_open():
		ws.send(data, WebSocketPeer.WRITE_MODE_BINARY)

func _process(delta: float) -> void:
	if ws == null:
		return
	ws.poll()
	var st := ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		_was_open = true
		while ws.get_available_packet_count() > 0:
			var pkt := ws.get_packet()
			if ws.was_string_packet():
				_on_text(pkt.get_string_from_utf8())
			elif pkt.size() > 0:
				state.emit(int(pkt[0]), pkt.slice(1))
		_ping_t -= delta
		if _ping_t <= 0.0:
			_ping_t = PING_EVERY
			send_json({"t": "ping", "c": Time.get_unix_time_from_system() * 1000.0})
	elif st == WebSocketPeer.STATE_CLOSED:
		var was := _was_open
		ws = null
		if was:
			disconnected.emit()
		else:
			failed.emit("Kamer %s niet bereikbaar" % code)

func _on_text(text: String) -> void:
	var msg = JSON.parse_string(text)
	if typeof(msg) != TYPE_DICTIONARY:
		return
	match String(msg.get("t", "")):
		"welcome":
			my_id = int(msg["id"])
			host_id = int(msg["host"])
			players.clear()
			for p in msg["players"]:
				players[int(p["id"])] = String(p["name"])
			welcomed.emit(my_id, host_id, msg["players"])
		"join":
			players[int(msg["id"])] = String(msg["name"])
			joined.emit(int(msg["id"]), String(msg["name"]))
		"leave":
			players.erase(int(msg["id"]))
			left.emit(int(msg["id"]))
		"host":
			host_id = int(msg["id"])
			host_changed.emit(host_id)
		"pong":
			var now := Time.get_unix_time_from_system() * 1000.0
			var rtt: float = now - float(msg["c"])
			rtt_ms = rtt
			# servertijd ligt ongeveer halverwege de ping
			var off: float = float(msg["s"]) + rtt * 0.5 - now
			_offset_ms = off if not _have_offset else lerpf(_offset_ms, off, 0.2)
			_have_offset = true
		"error":
			failed.emit("Kamer vol" if String(msg.get("reason", "")) == "full" else String(msg.get("reason", "fout")))
		_:
			message.emit(int(msg.get("from", 0)), msg)
