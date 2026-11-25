extends Node
# Politieauto. Zit als kind onder een ArcadeCar (ai = true), net als RivalDriver. Komt
# met sirene en zwaailichten achter je aan nadat je te hard langs een flitser bent gereden,
# haalt je in, gaat vóór je rijden en remt af om je op te houden. Houdt hij je lang genoeg
# vast (of tik je hem een paar keer), dan word je aangehouden: boete en tijdverlies.
# Rij je hem ver genoeg voorbij, of duurt de achtervolging te lang, dan geeft hij het op.
# Uiterlijk zoals de Nederlandse politie: witte stationwagen met rood-blauwe striping
# (zonder tekst of embleem). De politieauto groeit mee met jouw auto.
const Kit = preload("res://scripts/build_kit.gd")
const Sfx = preload("res://scripts/sfx.gd")

enum Mode { CHASE, BLOCK, LEAVE }

const ESCAPE_GAP := 300.0      # zoveel meter voor de politie uit = ontsnapt
const MAX_CHASE := 55.0        # langer dan dit en ver achter = hij geeft het op (ontsnapt)
const GIVE_UP_GAP := 80.0      # zo ver moet hij achter zijn om na MAX_CHASE op te geven
const MAX_CHASE_HARD := 100.0  # daarna stopt hij altijd (zonder "ontsnapt" als hij vlak bij is)
const HITS_TO_CATCH := 3

var race
var car: ArcadeCar
var route
var mode := Mode.CHASE
var lane := 3.8
var hint := 0
var s := 0.0
var lap := 0
var chase_t := 0.0
var pinned_t := 0.0
var pin_needed := 3.0
var hits := 0
var hit_cool := 0.0
var leave_t := 0.0
var speed_factor := 1.0
var prof := PackedFloat32Array()   # eigen snelheidsprofiel (zijn auto groeit mee met de jouwe)
var said_close := false
var said_block := false
var siren: AudioStreamPlayer3D
var lights: Array[MeshInstance3D] = []
var beacon: OmniLight3D
var blink := 0.0
var lens_on: StandardMaterial3D
var lens_off: StandardMaterial3D

func setup(r, c: ArcadeCar, start_lane: float, hard: bool) -> void:
	race = r
	car = c
	route = r.level.route
	lane = start_lane
	speed_factor = 1.04 if hard else 1.0
	prof = c.get_meta("profile") if c.has_meta("profile") else r.profile_for(c, route)
	pin_needed = 2.5 if hard else 3.2
	var res: Array = route.nearest(car.global_position, 0)
	hint = res[1]
	s = res[2]
	lap = r.player_lap if s <= r.player_s + route.length * 0.5 else r.player_lap - 1
	if siren == null:
		_dress()
	siren.play()
	car.bumped.connect(_on_bump)

# Alvast aankleden tijdens het laden, zodat er bij het flitsen niets meer gebouwd hoeft te worden.
func prepare(c: ArcadeCar) -> void:
	car = c
	_dress()

func progress() -> float:
	return float(lap) * route.length + s

# Zoals de Nederlandse politie (naar jouw foto): een witte stationwagen met schuine
# 'striping' van rood-oranje en blauwe banen over de voorkant van de flank (spatbord en
# voorportier) en een platte lichtbalk op het dak. Geen tekst en geen embleem.
func _dress() -> void:
	var blue := Color("1d3b94")
	var red := Color("f05a24")
	for x in [-1.0, 1.0]:
		var tris_r: Array = []
		var tris_b: Array = []
		var xs: float = x * 0.935
		var y0 := 0.36
		var y1 := 0.82
		var lean := 0.42            # de banen hellen naar achteren op
		var w := 0.2                # breedte van een baan langs de auto
		var k := 0
		var z := -2.3
		while z < 0.55:
			# volgorde zoals op de foto: rood, wit, blauw, wit, ...
			var col: int = k % 4
			if col == 0 or col == 2:
				var t: Array = tris_r if col == 0 else tris_b
				var za: float = maxf(z, -1.95)
				var zb: float = z + w
				# parallellogram tussen y0 en y1, onderkant op z, bovenkant op z + lean;
				# afgekapt aan de voorkant (-1,95) en achter het voorportier (0,55)
				var q := [Vector3(xs, y0, clampf(z, -1.95, 0.55)), Vector3(xs, y0, clampf(zb, -1.95, 0.55)),
					Vector3(xs, y1, clampf(zb + lean, -1.95, 0.55)), Vector3(xs, y1, clampf(z + lean, -1.95, 0.55))]
				if za < 0.55:
					Kit._quad(t, q[0], q[1], q[2], q[3])
			z += w if (col == 0 or col == 2) else 0.12
			k += 1
		for pair in [[tris_r, red], [tris_b, blue]]:
			var mi := MeshInstance3D.new()
			mi.name = "Police striping"
			mi.mesh = Kit._mesh_from(pair[0], Kit._two_sided(pair[1]))
			car.add_child(mi)
		# dunne blauwe lijn langs de onderkant
		Kit.box(car, "Police sill line", Vector3(xs, 0.34, -0.2), Vector3(0.012, 0.05, 3.4), blue)
	# Audi-achtige voorkant: grote donkere 'single frame'-grille, smalle koplampen en
	# dakrails (een A6 Avant, zonder merkteken)
	var dark := Color("17191c")
	var chrome := Color("b9bec4")
	# (de standaard koplampen en achterlichten tekent car_look niet voor de politie)
	Kit.box(car, "Grille frame", Vector3(0, 0.5, -1.985), Vector3(0.82, 0.4, 0.03), chrome)
	Kit.box(car, "Grille", Vector3(0, 0.5, -1.995), Vector3(0.74, 0.34, 0.03), dark)
	for k in range(4):
		Kit.box(car, "Grille bar", Vector3(0, 0.38 + float(k) * 0.08, -2.01), Vector3(0.72, 0.015, 0.01), Color("3a3e44"))
	for x in [-1.0, 1.0]:
		Kit.box(car, "Slim headlight", Vector3(x * 0.62, 0.6, -1.985), Vector3(0.38, 0.07, 0.03), Color("eef3f8"))
		Kit.box(car, "Headlight housing", Vector3(x * 0.62, 0.6, -1.98), Vector3(0.44, 0.12, 0.02), dark)
		Kit.box(car, "Fog light", Vector3(x * 0.6, 0.38, -1.99), Vector3(0.18, 0.06, 0.02), Color("2b2e33"))
		Kit.box(car, "Roof rail", Vector3(x * 0.6, 1.36, 0.75), Vector3(0.05, 0.05, 1.5), Color("2a2d31"))
		Kit.box(car, "Tail light bar", Vector3(x * 0.55, 0.78, 1.995), Vector3(0.6, 0.08, 0.02), Color("c8202a"))
	Kit.box(car, "Rear chrome strip", Vector3(0, 0.62, 2.0), Vector3(1.2, 0.03, 0.02), chrome)
	Kit.box(car, "Number plate", Vector3(0, 0.36, -2.0), Vector3(0.52, 0.12, 0.02), Color("f2c230"))
	Kit.box(car, "Rear number plate", Vector3(0, 0.55, 2.0), Vector3(0.52, 0.12, 0.02), Color("f2c230"))
	# rood-blauwe pijlpunt op de voorkant van de motorkap
	Kit.box(car, "Police hood red", Vector3(0, 0.82, -1.7), Vector3(1.5, 0.02, 0.12), red)
	Kit.box(car, "Police hood blue", Vector3(0, 0.81, -1.86), Vector3(1.6, 0.02, 0.1), blue)
	lens_on = StandardMaterial3D.new()
	lens_on.albedo_color = Color("3a7bff")
	lens_on.emission_enabled = true
	lens_on.emission = Color("3a7bff")
	lens_on.emission_energy_multiplier = 4.0
	lens_off = StandardMaterial3D.new()
	lens_off.albedo_color = Color("1a2a55")
	Kit.box(car, "Lightbar base", Vector3(0, 1.4, 0.1), Vector3(1.2, 0.06, 0.3), Color("2a2d31"))
	for x in [-0.33, 0.33]:
		var l := Kit.box(car, "Lightbar lens", Vector3(x, 1.48, 0.1), Vector3(0.52, 0.1, 0.26), Color.WHITE, false, lens_off)
		lights.append(l)
	beacon = OmniLight3D.new()
	beacon.light_color = Color("3a7bff")
	beacon.omni_range = 14.0
	beacon.light_energy = 0.0
	beacon.position = Vector3(0, 1.9, 0.1)
	car.add_child(beacon)
	siren = AudioStreamPlayer3D.new()
	siren.stream = Sfx.get_stream("siren")
	siren.unit_size = 22.0
	siren.max_distance = 450.0
	siren.volume_db = -4.0
	siren.bus = "SFX"
	car.add_child(siren)

func _on_bump(power: float) -> void:
	# alleen als hij vóór je rijdt en jij hem raakt (niet als hij jou van achteren aantikt)
	if mode != Mode.BLOCK or hit_cool > 0.0:
		return
	# alleen botsingen met jou tellen
	if car.global_position.distance_to(race.car.global_position) < 5.0 and power > 2.0:
		hits += 1
		hit_cool = 1.0
		if hits >= HITS_TO_CATCH:
			_caught()

func _process(delta: float) -> void:
	if car == null:
		return
	# zwaailichten: links en rechts om en om, met een blauwe gloed
	blink += delta
	var on: bool = mode != Mode.LEAVE or leave_t < 3.0
	var phase: int = int(blink * 6.0) % 4
	for i in range(lights.size()):
		lights[i].material_override = lens_on if on and (phase == i or phase == i + 2) else lens_off
	beacon.light_energy = (3.0 if phase % 2 == 0 else 1.2) if on else 0.0
	if not on and siren.playing:
		siren.stop()

func _physics_process(delta: float) -> void:
	if race == null or car == null:
		return
	var res: Array = route.nearest(car.global_position, hint)
	hint = res[1]
	var ns: float = res[2]
	if route.closed:
		if ns < s - route.length * 0.5:
			lap += 1
		elif ns > s + route.length * 0.5:
			lap -= 1
	s = ns
	hit_cool = maxf(0.0, hit_cool - delta)
	var player: ArcadeCar = race.car
	var pv: float = absf(player.drive_speed)
	var v: float = absf(car.drive_speed)
	# gap > 0: jij ligt voor; gap < 0: de politie ligt voor
	var gap: float = (float(race.player_lap) * route.length + race.player_s) - progress()
	var p_lat: float = (player.global_position - route.pos_at(race.player_s)).dot(route.right_at(race.player_s))
	var want: float
	var ideal: float = _ideal(v) * speed_factor
	if race.state != 1 and mode != Mode.LEAVE:   # 1 = racen
		mode = Mode.LEAVE
	match mode:
		Mode.CHASE:
			chase_t += delta
			# inhalen: harder dan jij, maar in bochten niet veel harder dan de ideale lijn
			want = minf(maxf(pv + 9.0, ideal), ideal * 1.1) if gap > 0.0 else ideal
			# ver achter: op de grens rijden om bij te komen
			if gap > 35.0:
				want = ideal * 1.15
			# naast je: naar de strook náást je, om je voorbij te gaan
			lane = move_toward(lane, _pass_lane(p_lat), 3.0 * delta)
			if gap < 60.0 and not said_close:
				said_close = true
				race.police_radio("Eenheid 12: we zitten erachter, sirene en zwaailicht aan.")
			if gap < -6.0:
				mode = Mode.BLOCK
				if not said_block:
					said_block = true
					race.police_radio("Eenheid 12: we zijn erlangs en gaan ervoor rijden.")
			_check_give_up(gap)
		Mode.BLOCK:
			chase_t += delta
			# voor je blijven en je strook volgen (met wat vertraging, zodat je kunt uitwijken)
			lane = move_toward(lane, p_lat, 2.2 * delta)
			var ahead: float = -gap
			if ahead < 8.0:
				want = maxf(6.0, pv - 4.0)        # remmen
			elif ahead < 20.0:
				want = maxf(6.0, pv - 1.5)
			else:
				want = maxf(6.0, pv - 4.0)        # wachten tot je weer achter hem zit
			want = minf(want, ideal * 1.1)
			# vastgezet: hij zit vlak voor je in jouw strook en je rijdt langzaam
			var p_ideal: float = prof[posmod(int(race.player_s / race.PROFILE_STEP), prof.size())]
			if ahead > 1.0 and ahead < 13.0 and absf(lane - p_lat) < 2.4 and pv < p_ideal * 0.6:
				pinned_t += delta
			else:
				pinned_t = maxf(0.0, pinned_t - delta * 0.5)
			if pinned_t >= pin_needed:
				_caught()
			elif gap > 4.0:
				mode = Mode.CHASE      # je bent er weer langs
			_check_give_up(gap)
		Mode.LEAVE:
			leave_t += delta
			want = 0.0
			lane = move_toward(lane, race.level.road_hw - 1.0, 2.0 * delta)
			if leave_t > 8.0:
				race.police_gone(self)
				car.queue_free()
				return
	car.ai_steer = _steer_to(s + maxf(12.0, v * 0.7))
	if v < want:
		car.ai_throttle = 1.0
		car.ai_brake = 0.0
	else:
		car.ai_throttle = 0.0
		car.ai_brake = clampf((v - want) / 5.0, 0.15, 1.0)

func _caught() -> void:
	if mode == Mode.LEAVE:
		return
	mode = Mode.LEAVE
	race.police_caught()

func _escaped(earned := true) -> void:
	if mode == Mode.LEAVE:
		return
	mode = Mode.LEAVE
	race.police_escaped(earned)

# Ontsnapt: 300 m voor hem uit, of na 55 s als hij flink achter is geraakt. Naast of vlak
# achter je gaf hij het vroeger ook na 55 s op, met "ONTSNAPT" in beeld terwijl hij naast je
# reed. Nu gaat hij dan door; pas na 100 s breekt hij af, zonder ontsnapbonus.
func _check_give_up(gap: float) -> void:
	if gap > ESCAPE_GAP or (chase_t > MAX_CHASE and gap > GIVE_UP_GAP):
		_escaped(true)
	elif chase_t > MAX_CHASE_HARD:
		_escaped(false)

# Ideale snelheid verderop met zijn eigen auto, zodat hij bochten haalt.
func _ideal(v: float) -> float:
	var want: float = 99.0
	var n: int = prof.size()
	var k := 0.0
	while k < v * 0.35 + 4.0:
		want = minf(want, prof[posmod(int((s + k) / race.PROFILE_STEP), n)])
		k += race.PROFILE_STEP
	return want

# Strook om je in te halen: de strook naast je (op een gewone weg is dat links, op de
# Buitenring de andere strook van de rijbaan). Verkeer vlak voor hem: uitwijken.
func _pass_lane(p_lat: float) -> float:
	var lanes: Array = race.level.traffic_lanes
	var options: Array = []
	if lanes.size() == 1:
		options = [float(lanes[0]), -float(lanes[0])]
	else:
		options = [float(lanes[0]), float(lanes[1])]
	var best: float = lane
	var best_score: float = -1e9
	for l in options:
		var score: float = absf(float(l) - p_lat)       # weg van jouw strook
		if _lane_busy(float(l)):
			score -= 20.0
		if score > best_score:
			best_score = score
			best = float(l)
	return best

func _lane_busy(l: float) -> bool:
	var center: Vector3 = route.pos_at(s) + route.right_at(s) * l
	var fwd: Vector3 = route.dir_at(s)
	var right: Vector3 = route.right_at(s)
	for o in race.obstacles():
		if o == car or o == race.car:
			continue
		var rel: Vector3 = o.global_position - center
		if absf(rel.dot(right)) > 2.4:
			continue
		var ahead: float = rel.dot(fwd)
		if ahead > -4.0 and ahead < 35.0:
			return true
	return false

func _steer_to(target_s: float) -> float:
	var target: Vector3 = route.pos_at(target_s) + route.right_at(target_s) * lane
	var to: Vector3 = target - car.global_position
	to.y = 0.0
	var fwd: Vector3 = -car.global_transform.basis.z
	var err: float = fwd.signed_angle_to(to.normalized(), Vector3.UP)
	return clampf(-err * 2.6, -1.0, 1.0)
