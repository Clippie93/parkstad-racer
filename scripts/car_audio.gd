extends Node3D
# Motor- en bandengeluid van een auto. De motor schakelt door 5 versnellingen: binnen een
# versnelling loopt het toerental op, bij het opschakelen zakt het weer.
# De eigen auto klinkt overal even hard; tegenstanders klinken in 3D (dichtbij = harder).
const Sfx = preload("res://scripts/sfx.gd")

const ENGINE_DB := -15.0
const RIVAL_DB := -9.0
# Echte motoropname ("rally car idle loop", Pixabay, zie README) als die er is, anders het
# motorgeluid uit sfx.gd. De opname is stationair, dus toonhoogte 1 = stationair.
const ENGINE_SAMPLE := "res://assets/engine_loop.wav"
# Heel korte loop (4 motorcycli uit dezelfde opname): bij hoog toerental vloeit het geluid
# hierheen over, zodat je op topsnelheid een continue motor op de begrenzer hoort in plaats
# van een herhalend stuk opname.
const LIMIT_SAMPLE := "res://assets/engine_limit.wav"
var pitch_base := 0.7
var pitch_range := 1.05
const GEARS := [0.16, 0.32, 0.5, 0.72, 1.0]   # bovengrens per versnelling (deel van topsnelheid)

var car: ArcadeCar
var engine: Node
var screech: Node
var engine_hi: Node       # korte begrenzer-loop (of null)
var rpm := 0.05
var gear := 0
var bump_cooldown := 0.0
var load_ := 0.0
var player := false

func _ready() -> void:
	car = get_parent() as ArcadeCar
	player = not car.ai
	var stream: AudioStream = Sfx.get_stream("engine")
	if ResourceLoader.exists(ENGINE_SAMPLE):
		stream = load(ENGINE_SAMPLE)
		pitch_base = 0.9
		pitch_range = 1.8
	engine = _player_node(stream, ENGINE_DB if player else RIVAL_DB)
	if stream != Sfx.get_stream("engine") and ResourceLoader.exists(LIMIT_SAMPLE):
		engine_hi = _player_node(load(LIMIT_SAMPLE), -80.0)
		engine_hi.play()
	screech = _player_node(Sfx.get_stream("screech"), -80.0)
	engine.play()
	screech.play()
	car.bumped.connect(_on_bump)

func _player_node(stream: AudioStream, db: float) -> Node:
	var p: Node
	if player:
		p = AudioStreamPlayer.new()
	else:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 9.0
		p3.max_distance = 140.0
		p3.max_db = 0.0
		p = p3
	p.stream = stream
	p.volume_db = db
	p.set("bus", "Motor")
	add_child(p)
	return p

func _process(delta: float) -> void:
	if car == null:
		return
	var top: float = maxf(car.max_forward_speed, 1.0)
	var v: float = absf(car.drive_speed) / top
	# schakelen met hysterese: pas opschakelen boven de grens, pas terugschakelen een
	# flink stuk eronder, zodat de motor rond een schakelpunt niet heen en weer springt
	if gear < GEARS.size() - 1 and v > GEARS[gear]:
		gear += 1
	elif gear > 0 and v < GEARS[gear - 1] * 0.8:
		gear -= 1
	var lo: float = 0.0 if gear == 0 else GEARS[gear - 1]
	var frac: float = clampf((v - lo) / (GEARS[gear] - lo), 0.0, 1.0)
	var target: float = (0.15 + 0.85 * frac) if gear == 0 else (0.42 + 0.58 * frac)
	var throttle: float
	if car.ai:
		throttle = car.ai_throttle
	else:
		throttle = Input.get_action_strength("accelerate") if InputMap.has_action("accelerate") else 0.0
	if not car.controls_enabled:
		# bij het aftellen: gas geven laat de motor brullen
		target = maxf(target, 0.15 + 0.6 * throttle)
	# rustig volgen: bij schakelen of een botsing glijdt de toon in plaats van te springen
	rpm = lerpf(rpm, target, minf(1.0, delta * 9.0))
	load_ = lerpf(load_, throttle, minf(1.0, delta * 5.0))
	bump_cooldown = maxf(0.0, bump_cooldown - delta)
	# Geen toonhoogte-'stuiteren' op de begrenzer: dat wordt per frame bijgewerkt en klinkt
	# op een telefoon met een lagere of wisselende framerate hakkelig. De korte
	# begrenzer-loop geeft het begrenzergeluid al.
	var pitch: float = pitch_base + rpm * pitch_range
	engine.pitch_scale = pitch
	var base_db: float = ENGINE_DB if player else RIVAL_DB
	var vol: float = base_db - 4.0 + 4.0 * load_ + 1.5 * rpm
	if engine_hi != null:
		# overvloeien (gelijk vermogen) van de lange naar de korte loop tussen 70% en 95% toeren
		var w: float = smoothstep(0.7, 0.95, rpm)
		engine.volume_db = vol + linear_to_db(maxf(cos(w * PI * 0.5), 0.001))
		engine_hi.volume_db = vol + linear_to_db(maxf(sin(w * PI * 0.5), 0.001))
		engine_hi.pitch_scale = pitch
	else:
		engine.volume_db = vol
	# banden: zijwaarts glijden of hard remmen/handrem op snelheid
	# (car.skid neemt ook donuts en de handrem mee, en houdt al rekening met gras)
	var amount: float = car.skid
	if amount > 0.01 and (absf(car.drive_speed) > 4.0 or car.donut_now):
		screech.volume_db = lerpf(-32.0, -12.0 if player else -10.0, amount)
		screech.pitch_scale = 0.85 + amount * 0.3
	else:
		screech.volume_db = -80.0

func _on_bump(power: float) -> void:
	# langs een muur schuren geeft elke frame een 'botsing': maximaal één geluid per 0,6 s
	if bump_cooldown > 0.0:
		return
	bump_cooldown = 0.6
	var db: float = -12.0 + clampf(power / 40.0, 0.0, 1.0) * 8.0
	if player:
		Sfx.play(self, "bump", db, randf_range(0.9, 1.1))
	else:
		var p := AudioStreamPlayer3D.new()
		p.stream = Sfx.get_stream("bump")
		p.bus = "SFX"
		p.volume_db = db
		p.pitch_scale = randf_range(0.9, 1.1)
		p.unit_size = 9.0
		p.max_distance = 100.0
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()
