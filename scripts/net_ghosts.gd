extends Node
# Samen racen, fase 1 (zie MULTIPLAYER_PLAN.md): je eigen auto gaat ~15 keer per seconde
# naar de andere spelers in de kamer, en hun auto's verschijnen hier als spookauto's
# (nog zonder botsen) met hun naam erboven. Alleen spelers in hetzelfde level zijn te zien.
#
# De spookauto's worden getoond waar ze naar verwachting NU zijn: de laatste positie plus
# snelheid x (servertijd nu - servertijd van het bericht), en daar vloeiend naartoe. Zo
# staan ze ook goed naast het verkeer (dat op elk scherm op dezelfde plek rijdt).
const CarLook = preload("res://scripts/car_look.gd")

const SEND_EVERY := 1.0 / 15.0
const LOOK_EVERY := 5.0          # uiterlijk (auto, kleur, naam) af en toe opnieuw sturen
const PREDICT_MAX := 0.35        # hoogstens zo ver vooruit voorspellen (s)
const SNAP_DIST := 12.0          # verder ernaast: meteen naar de juiste plek
const STALE := 2.0               # zo lang niets gehoord: spookauto verbergen
const VERSION := 2               # 2: met afgelegde afstand (voor de stand)

var race: Node
var net: Node
var ghosts := {}                 # id -> {node, look, p, v, yaw, rx, rz, t, level, lap, got, ...}
var _send_t := 0.0
var _look_t := 0.0
var _stats_t := 0.0
var sent := 0
var status: Label
# ---- gezamenlijke race (fase 2) ----
const GO_DELAY_MS := 3500.0      # tussen het startsein en GO: het aftellen 3-2-1
const LOAD_WAIT := 25.0          # host wacht hoogstens zo lang op trage laders
var go_at := -1.0                # servertijd (ms) van GO; -1 = nog niet bekend
var loaded := {}                 # host: wie is klaar met laden
var _my_loaded_t := -1.0
var finished := {}               # id -> racetijd (s) van andere spelers die binnen zijn

func setup(r: Node) -> void:
	race = r
	net = Game.net()
	net.state.connect(_on_state)
	net.message.connect(_on_message)
	net.joined.connect(_on_joined)
	net.left.connect(_on_left)
	_send_look()
	# statusregel bovenin: kamer, aantal spelers en ping
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("f3df68"))
	status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	status.add_theme_constant_override("outline_size", 4)
	status.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status.position = Vector2(-150, 4)
	status.size = Vector2(300, 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(status)

func _exit_tree() -> void:
	for id in ghosts.keys():
		_drop(id)
	if net != null:
		for sig in [net.state, net.message, net.left, net.joined]:
			for c in sig.get_connections():
				if c["callable"].get_object() == self:
					sig.disconnect(c["callable"])

# ---------------------------------------------------------------- versturen
func _send_look() -> void:
	var car = race.car
	if car == null:
		return
	net.send_json({"t": "car", "level": Game.current_index, "style": String(car.car_style),
		"color": (car.body_color as Color).to_html(false), "stripe": (car.stripe_color as Color).to_html(false),
		"name": Game.player_name()})

func _send_state() -> void:
	var car: Node3D = race.car
	if car == null:
		return
	var b := StreamPeerBuffer.new()
	b.put_u8(VERSION)
	b.put_u8(Game.current_index)
	b.put_u8(clampi(int(race.player_lap), 0, 255))
	b.put_double(net.server_time_ms())
	var p: Vector3 = car.global_position
	var v: Vector3 = car.velocity
	for f in [p.x, p.y, p.z, v.x, v.y, v.z, car.global_rotation.y]:
		b.put_float(f)
	var tilt: Node3D = car.get("tilt")
	b.put_float(tilt.rotation.x if tilt != null else 0.0)
	b.put_float(tilt.rotation.z if tilt != null else 0.0)
	b.put_float(race.player_progress())
	net.send_state(b.data_array)
	sent += 1

# ---------------------------------------------------------------- ontvangen
func _on_message(from: int, msg: Dictionary) -> void:
	match String(msg.get("t", "")):
		"loaded":
			loaded[from] = true
			return
		"go":
			go_at = float(msg.get("at", -1.0))
			return
		"finish":
			if not finished.has(from):
				finished[from] = float(msg.get("time", 0.0))
				race.finish_order.append(name_of(from))
			return
		"car":
			pass
		_:
			return
	var g := _ghost(from)
	var look := [String(msg.get("style", "hatch")), String(msg.get("color", "c72d28")),
		String(msg.get("stripe", "f4f4ee")), String(msg.get("name", "Speler"))]
	g["level"] = int(msg.get("level", -1))
	if g["look"] != look:
		g["look"] = look
		_build(from)

func _on_state(from: int, data: PackedByteArray) -> void:
	if data.size() < 51 or data[0] != VERSION:
		return
	var b := StreamPeerBuffer.new()
	b.data_array = data
	b.seek(1)
	var g := _ghost(from)
	g["level"] = b.get_u8()
	g["lap"] = b.get_u8()
	var t: float = b.get_double()
	var now: float = net.server_time_ms()
	g["p"] = Vector3(b.get_float(), b.get_float(), b.get_float())
	g["v"] = Vector3(b.get_float(), b.get_float(), b.get_float())
	g["yaw"] = b.get_float()
	g["rx"] = b.get_float()
	g["rz"] = b.get_float()
	g["progress"] = b.get_float()
	# metingen: hoe oud is een bericht als het aankomt, en hoe regelmatig komen ze
	var age: float = now - t
	if g["t"] > 0.0:
		var gap: float = t - float(g["t"])
		g["gaps"].append(gap)
		if g["gaps"].size() > 150:
			g["gaps"].pop_front()
	g["ages"].append(age)
	if g["ages"].size() > 150:
		g["ages"].pop_front()
	g["t"] = t
	g["heard"] = Time.get_ticks_msec()
	g["got"] += 1

func _on_joined(_id: int, _name: String) -> void:
	_send_look()

func _on_left(id: int) -> void:
	_drop(id)

func _ghost(id: int) -> Dictionary:
	if not ghosts.has(id):
		ghosts[id] = {"node": null, "look": [], "p": Vector3.ZERO, "v": Vector3.ZERO, "yaw": 0.0,
			"rx": 0.0, "rz": 0.0, "t": 0.0, "level": -1, "lap": 0, "got": 0, "heard": 0,
			"gaps": [], "ages": [], "placed": false, "progress": 0.0}
	return ghosts[id]

func _drop(id: int) -> void:
	if ghosts.has(id):
		var n = ghosts[id]["node"]
		if n != null and is_instance_valid(n):
			n.queue_free()
		ghosts.erase(id)

# Spookauto opbouwen in het uiterlijk dat de speler heeft gekozen.
func _build(id: int) -> void:
	var g: Dictionary = ghosts[id]
	if g["node"] != null and is_instance_valid(g["node"]):
		g["node"].queue_free()
	var look: Array = g["look"]
	var root := Node3D.new()
	root.name = "Ghost_%d" % id
	var tilt := Node3D.new()
	tilt.name = "Tilt"
	root.add_child(tilt)
	CarLook.build(tilt, Color(look[1]), Color(look[2]), look[0], id)     # spelernummer als startnummer
	var lab := Label3D.new()
	lab.text = look[3]
	lab.font_size = 56
	lab.pixel_size = 0.01
	lab.outline_size = 12
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	lab.fixed_size = false
	lab.position = Vector3(0, 2.6, 0)
	lab.modulate = Color("f3df68")
	root.add_child(lab)
	root.visible = false
	race.world.add_child(root)
	g["node"] = root
	g["placed"] = false

# ---------------------------------------------------------------- elk beeldje
func _process(delta: float) -> void:
	if net == null or not Game.in_room():
		return
	_host_go()
	_send_t -= delta
	if _send_t <= 0.0:
		_send_t += SEND_EVERY
		if _send_t < 0.0:
			_send_t = SEND_EVERY
		_send_state()
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = LOOK_EVERY
		_send_look()
	var now: float = net.server_time_ms()
	var k: float = 1.0 - exp(-14.0 * delta)
	for id in ghosts:
		var g: Dictionary = ghosts[id]
		var n: Node3D = g["node"]
		if n == null or not is_instance_valid(n):
			continue
		var fresh: bool = Time.get_ticks_msec() - int(g["heard"]) < int(STALE * 1000.0)
		n.visible = fresh and int(g["level"]) == Game.current_index and int(g["got"]) > 0 and in_race(id)
		if not n.visible:
			continue
		var ahead: float = clampf((now - float(g["t"])) / 1000.0, 0.0, PREDICT_MAX)
		var target: Vector3 = g["p"] + g["v"] * ahead
		if not g["placed"] or n.global_position.distance_to(target) > SNAP_DIST:
			n.global_position = target
			n.rotation.y = g["yaw"]
			g["placed"] = true
		else:
			n.global_position = n.global_position.lerp(target, k)
			n.rotation.y = lerp_angle(n.rotation.y, g["yaw"], k)
		var tilt: Node3D = n.get_node("Tilt")
		tilt.rotation.x = lerpf(tilt.rotation.x, g["rx"], k)
		tilt.rotation.z = lerpf(tilt.rotation.z, g["rz"], k)
	if status != null:
		var here := 1
		for id in ghosts:
			if int(ghosts[id]["level"]) == Game.current_index:
				here += 1
		status.text = "Samen  %s  ·  %d in dit level  ·  ping %d ms" % [net.code, here, int(net.rtt_ms)]
	_stats_t -= delta
	if _stats_t <= 0.0:
		_stats_t = 5.0
		print(stats_text())

# Metingen voor fase 1: per spookauto hoe oud de berichten bij aankomst zijn en hoe
# regelmatig ze komen (gemiddeld en de grootste gat).
func stats_text() -> String:
	var parts := ["NET ping %d ms, verstuurd %d" % [int(net.rtt_ms), sent]]
	for id in ghosts:
		var g: Dictionary = ghosts[id]
		var ages: Array = g["ages"]
		var gaps: Array = g["gaps"]
		if ages.is_empty():
			continue
		var a := 0.0
		for x in ages:
			a += float(x)
		var gm := 0.0
		var gx := 0.0
		for x in gaps:
			gm += float(x)
			gx = maxf(gx, float(x))
		parts.append("speler %d (%s): ontvangen %d, leeftijd %d ms, tussenpoos %d ms (max %d)" % [id,
			(g["look"] as Array)[3] if not (g["look"] as Array).is_empty() else "?", int(g["got"]),
			int(a / float(ages.size())), int(gm / maxf(1.0, float(gaps.size()))), int(gx)])
	return " | ".join(parts)

# ---------------------------------------------------------------- gezamenlijke race
func mp() -> bool:
	return Game.mp_active()

# Speelt deze speler mee in de race die nu loopt? (Buiten een gezamenlijke race: iedereen.)
func in_race(id: int) -> bool:
	return not mp() or (Game.mp["grid"] as Array).has(id)

func name_of(id: int) -> String:
	if ghosts.has(id) and not (ghosts[id]["look"] as Array).is_empty():
		return String(ghosts[id]["look"][3])
	return String(net.players.get(id, "Speler %d" % id))

# Klaar met laden: de host weet dan dat hij (bijna) kan starten.
func mp_loaded() -> void:
	_my_loaded_t = Time.get_ticks_msec() / 1000.0
	loaded[net.my_id] = true
	net.send_json({"t": "loaded"})

# Host: GO zodra iedereen van de startgrid die nog in de kamer zit geladen is, of na
# LOAD_WAIT seconden (dan beginnen de trage laders iets later).
func _host_go() -> void:
	if not mp() or go_at >= 0.0 or _my_loaded_t < 0.0 or not net.is_host():
		return
	var waiting := false
	for id in Game.mp["grid"]:
		if net.players.has(int(id)) and not loaded.has(int(id)):
			waiting = true
	if waiting and Time.get_ticks_msec() / 1000.0 - _my_loaded_t < LOAD_WAIT:
		return
	go_at = net.server_time_ms() + GO_DELAY_MS
	net.send_json({"t": "go", "at": go_at})

# Seconden tot GO (+0,5 zoals het gewone aftellen), of -1 als het startsein er nog niet is.
func countdown_left() -> float:
	if go_at < 0.0:
		return -1.0
	return (go_at - net.server_time_ms()) / 1000.0 + 0.5

func send_finish(time: float) -> void:
	net.send_json({"t": "finish", "time": time})

# De andere spelers in de stand (zelfde vorm als bij de tegenstanders van de computer).
func rows() -> Array:
	var out: Array = []
	if not mp():
		return out
	for id in Game.mp["grid"]:
		var i := int(id)
		if i == net.my_id:
			continue
		var g: Dictionary = _ghost(i)
		var done: bool = finished.has(i)
		out.append({"name": name_of(i), "progress": float(g["progress"]), "finished": done,
			"time": float(finished.get(i, 0.0)), "lap": int(g["lap"]), "start": race.START_S})
	return out

# Plaats van wie al binnen is: aantal anderen dat eerder finishte + 1.
func finish_position() -> int:
	return finished.size() + 1
