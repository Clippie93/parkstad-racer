extends RefCounted
# Alle geluiden worden in code opgebouwd (geen audiobestanden nodig). Elk geluid wordt één
# keer gemaakt en daarna hergebruikt. Sfx.play(parent, "naam") speelt een kort effect af.

const RATE := 22050

static var _cache := {}

static func play(parent: Node, sound: String, volume_db: float = 0.0, pitch: float = 1.0, bus: String = "SFX") -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(sound)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = bus
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

static func get_stream(sound: String) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = _make(sound)
	return _cache[sound]

static func _make(sound: String) -> AudioStreamWAV:
	match sound:
		"engine": return _make_engine()
		"screech": return _make_screech()
		"beep": return _make_beep()
		"go": return _make_go()
		"bump": return _make_bump()
		"crash": return _make_crash()
		"coin": return _make_coin()
		"flash": return _make_flash()
		"checkpoint": return _make_checkpoint()
		"lap": return _make_lap()
		"finish": return _make_finish()
		"fail": return _make_fail()
		"siren": return _make_siren()
		"radio": return _make_radio()
	return _make_click()

# ---------------------------------------------------------------- bouwstenen

static func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

static func _buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * RATE))
	return b

# Toon met zachte aanzet en uitsterven.
static func _tone(b: PackedFloat32Array, start: float, dur: float, freq: float, amp: float, square: bool = false) -> void:
	var i0: int = int(start * RATE)
	var n: int = int(dur * RATE)
	for k in n:
		if i0 + k >= b.size():
			break
		var t: float = float(k) / RATE
		var env: float = minf(1.0, t * 200.0) * exp(-3.0 * t / dur)
		var ph: float = TAU * freq * t
		var s: float = sin(ph) + (0.35 * sin(ph * 3.0) if square else 0.25 * sin(ph * 2.0))
		b[i0 + k] += s * amp * env

# ---------------------------------------------------------------- loops

# Motor: een zachte, ronde brom (grondtoon 50 Hz plus wat boventonen en laag gefilterde
# ruis), zonder scherpe zoem. Precies 1 s met hele perioden, zodat de loop naadloos is.
# De toonhoogte gaat via pitch_scale.
static func _make_engine() -> AudioStreamWAV:
	var b := _buf(1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n1 := 0.0
	var n2 := 0.0
	var f: float = 50.0
	for i in b.size():
		var t: float = float(i) / RATE
		var s: float = 0.6 * sin(TAU * f * t) + 0.22 * sin(TAU * 2.0 * f * t + 0.6) \
			+ 0.08 * sin(TAU * 3.0 * f * t + 1.1) + 0.3 * sin(TAU * 0.5 * f * t)
		# zacht 'roffelen' van de cilinders: lichte amplitudemodulatie op 25 Hz
		var am: float = 0.85 + 0.15 * sin(TAU * 25.0 * t)
		n1 += (rng.randf_range(-1.0, 1.0) - n1) * 0.03
		n2 += (n1 - n2) * 0.03
		b[i] = (s * am + n2 * 2.5) * 0.5
	return _wav(b, true)

# Piepende banden: gefilterde ruis met een zwevende piep rond 900-1100 Hz.
static func _make_screech() -> AudioStreamWAV:
	var b := _buf(1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var y1 := 0.0
	var y2 := 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var x: float = rng.randf_range(-1.0, 1.0)
		# eenvoudig resonantiefilter rond 1 kHz
		var y: float = x * 0.08 + 1.86 * y1 - 0.94 * y2
		y2 = y1
		y1 = y
		var squeal: float = sin(TAU * 1000.0 * t + 3.0 * sin(TAU * 7.0 * t))
		b[i] = y * 0.35 + squeal * 0.18
	return _wav(b, true)

# ---------------------------------------------------------------- effecten

static func _make_beep() -> AudioStreamWAV:
	var b := _buf(0.3)
	_tone(b, 0.0, 0.28, 660.0, 0.5, true)
	return _wav(b)

static func _make_go() -> AudioStreamWAV:
	var b := _buf(0.7)
	_tone(b, 0.0, 0.65, 1320.0, 0.45, true)
	_tone(b, 0.0, 0.65, 660.0, 0.2)
	return _wav(b)

# Botsing: een doffe dreun (dalende lage toon) met een korte, gedempte 'krak' van
# plaatwerk erbovenop. Geen scherpe ruis.
static func _make_bump() -> AudioStreamWAV:
	var b := _buf(0.45)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var y1 := 0.0
	var y2 := 0.0
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		# dreun: 95 Hz zakkend naar 45 Hz
		ph += TAU * (45.0 + 50.0 * exp(-18.0 * t)) / RATE
		var thud: float = sin(ph) * exp(-11.0 * t)
		# plaatwerk: ruis door een resonantiefilter rond 600 Hz, kort en gedempt
		var x: float = rng.randf_range(-1.0, 1.0)
		var y: float = x * 0.05 + 1.93 * y1 - 0.955 * y2
		y2 = y1
		y1 = y
		lp += (y - lp) * 0.35
		var crunch: float = lp * exp(-28.0 * t) * (1.0 if t > 0.004 else t / 0.004)
		b[i] = thud * 0.85 + crunch * 0.55
	# normaliseren naar 80%, zodat het filter nooit oversturing geeft
	var peak := 0.0001
	for v in b:
		peak = maxf(peak, absf(v))
	for i in b.size():
		b[i] *= 0.8 / peak
	return _wav(b)

static func _make_crash() -> AudioStreamWAV:
	var b := _buf(0.8)
	var rng := RandomNumberGenerator.new()
	for i in b.size():
		var t: float = float(i) / RATE
		var metal: float = sin(TAU * 1730.0 * t) * 0.3 + sin(TAU * 2410.0 * t) * 0.2
		b[i] = (rng.randf_range(-1.0, 1.0) * exp(-9.0 * t) + metal * exp(-5.0 * t)) * 0.6
	return _wav(b)

static func _make_coin() -> AudioStreamWAV:
	var b := _buf(0.5)
	_tone(b, 0.0, 0.1, 988.0, 0.4, true)
	_tone(b, 0.08, 0.4, 1319.0, 0.4, true)
	return _wav(b)

static func _make_flash() -> AudioStreamWAV:
	var b := _buf(0.6)
	var rng := RandomNumberGenerator.new()
	for i in int(0.05 * RATE):
		b[i] = rng.randf_range(-1.0, 1.0) * 0.6 * (1.0 - float(i) / (0.05 * RATE))
	_tone(b, 0.12, 0.45, 220.0, 0.45, true)
	_tone(b, 0.12, 0.45, 233.0, 0.3, true)
	return _wav(b)

static func _make_checkpoint() -> AudioStreamWAV:
	var b := _buf(0.45)
	_tone(b, 0.0, 0.2, 784.0, 0.35)
	_tone(b, 0.1, 0.33, 1175.0, 0.35)
	return _wav(b)

static func _make_lap() -> AudioStreamWAV:
	var b := _buf(0.8)
	_tone(b, 0.0, 0.25, 659.0, 0.35)
	_tone(b, 0.12, 0.25, 784.0, 0.35)
	_tone(b, 0.24, 0.5, 1047.0, 0.35)
	return _wav(b)

static func _make_finish() -> AudioStreamWAV:
	var b := _buf(1.6)
	var notes := [523.0, 659.0, 784.0, 1047.0]
	for k in notes.size():
		_tone(b, k * 0.13, 0.4, notes[k], 0.3, true)
	_tone(b, 0.55, 1.0, 1047.0, 0.3, true)
	_tone(b, 0.55, 1.0, 784.0, 0.22)
	_tone(b, 0.55, 1.0, 523.0, 0.2)
	return _wav(b)

static func _make_fail() -> AudioStreamWAV:
	var b := _buf(1.0)
	_tone(b, 0.0, 0.3, 392.0, 0.35, true)
	_tone(b, 0.25, 0.3, 349.0, 0.35, true)
	_tone(b, 0.5, 0.5, 262.0, 0.35, true)
	return _wav(b)

static func _make_click() -> AudioStreamWAV:
	var b := _buf(0.08)
	_tone(b, 0.0, 0.06, 1500.0, 0.25)
	return _wav(b)

# Sirene: Nederlandse twee-toon (hoog-laag), elke toon 0,5 s, met wat boventonen zodat hij
# 'blikkerig' klinkt. Hele perioden per toon, zodat de loop naadloos is.
static func _make_siren() -> AudioStreamWAV:
	var b := _buf(1.0)
	for i in b.size():
		var t: float = float(i) / RATE
		var f: float = 600.0 if t < 0.5 else 460.0
		var ph: float = TAU * f * t
		var s: float = sin(ph) + 0.4 * sin(ph * 3.0) + 0.18 * sin(ph * 5.0) + 0.08 * sin(ph * 2.0)
		# zachte overgang tussen de tonen (geen klik)
		var tt: float = fmod(t, 0.5)
		var env: float = minf(1.0, minf(tt, 0.5 - tt) * 120.0)
		b[i] = s * 0.32 * env
	return _wav(b, true)

# Portofoon: kort ruisje, een piepje en weer ruis (de 'squelch').
static func _make_radio() -> AudioStreamWAV:
	var b := _buf(0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var y := 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var x: float = rng.randf_range(-1.0, 1.0)
		y += (x - y) * 0.35
		var amp: float = 0.0
		if t < 0.12:
			amp = 0.35
		elif t > 0.34 and t < 0.48:
			amp = 0.25 * (1.0 - (t - 0.34) / 0.14)
		b[i] = y * amp
	_tone(b, 0.13, 0.16, 1250.0, 0.3, true)
	return _wav(b)
