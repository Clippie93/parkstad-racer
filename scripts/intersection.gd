extends Node3D
# Kruising met Nederlandse verkeerslichten: een zijweg kruist de route haaks.
# - Hoofdweg (beide richtingen) en zijweg krijgen om de beurt groen.
# - Lichten: zwarte kasten met rood/oranje/groen op een paal met zwart-witte banden,
#   op de hoofdweg ook een uithouder (mast) boven de weg, zoals op Parkstad-kruisingen.
# - Verkeer op de route stopt voor rood (zie traffic_car.gd); op de zijweg rijdt
#   dwarsverkeer dat ook netjes wacht.
# - Rijdt de speler door rood (niet oranje), dan levert dat een kleine bonus op.
# Assen van deze node: -Z = rijrichting van de route, +X = rechts. Oorsprong = midden.
const Kit = preload("res://scripts/build_kit.gd")
const TrafficCar = preload("res://scripts/traffic_car.gd")

static var all: Array = []

const SIDE_HW := 3.6        # halve breedte van de zijweg
const SIDE_LEN := 48.0      # zo ver loopt de zijweg aan elke kant door
const CYCLE := [            # [hoofdweg, zijweg, duur]
	["green", "red", 10.0],
	["amber", "red", 3.0],
	["red", "red", 1.5],
	["red", "green", 7.0],
	["red", "amber", 3.0],
	["red", "red", 1.5],
]

var route
var level
var race
var s_c := 0.0
var hw := 4.0               # halve breedte van de hoofdweg
var edge := 8.0             # afstand van de wegas tot de buitenkant van het trottoir
var stop_d := 0.0           # afstand van het midden tot de stopstreep op de hoofdweg
var clock := 0.0
var phase := 0
var main_state := "green"
var side_state := "red"
var heads := {"main": [], "side": []}   # lampen per richting: [[rood, oranje, groen], ...]
var mats := {}
var cross_cars: Array = []
var prev_z := INF

func setup(lv, rc, s: float, offset: float) -> void:
	level = lv
	route = lv.route
	race = rc
	s_c = s
	hw = lv.road_hw
	edge = hw + lv.CURB_W + lv.BIKE_W + lv.WALK_W
	stop_d = SIDE_HW + 3.0
	name = "Intersection"
	transform = Transform3D(route.basis_at(s), route.pos_at(s))
	clock = offset
	_materials()
	_clear_corridor()
	_roads()
	_lights()
	_cross_traffic()
	_update_phase(true)
	all.append(self)

func _exit_tree() -> void:
	all.erase(self)

# ---------------------------------------------------------------- vragen van het verkeer
func main_must_stop() -> bool:
	return main_state != "green"

# Plek (route-afstand) van de stopstreep voor verkeer in deze richting.
func stop_s(oncoming: bool) -> float:
	var v: float = s_c + stop_d if oncoming else s_c - stop_d
	return fposmod(v, route.length) if route.closed else v

# ---------------------------------------------------------------- bouwen
func _materials() -> void:
	var cols := {"red": Color("ff2a1a"), "amber": Color("ffa31a"), "green": Color("2aff6a")}
	for k in cols:
		var on := StandardMaterial3D.new()
		on.albedo_color = cols[k]
		on.emission_enabled = true
		on.emission = cols[k]
		on.emission_energy_multiplier = 2.5
		mats[k + "_on"] = on
		var off := StandardMaterial3D.new()
		off.albedo_color = Color(cols[k]).darkened(0.82)
		mats[k + "_off"] = off

# Huizen, lantaarnpalen en ander los spul dat op de zijweg zou staan, gaat weg. Dit gaat
# op plek en grootte (namen van nodes zijn niet betrouwbaar): alles wat de strook van de
# zijweg raakt en kleiner is dan 40 m (dus niet de weg zelf, het gras of de heuvels).
func _clear_corridor() -> void:
	var inv: Transform3D = transform.affine_inverse()
	var lane := AABB(Vector3(hw + 0.5, -1.0, -SIDE_HW - 2.6), Vector3(SIDE_LEN + 2.0 - hw, 40.0, (SIDE_HW + 2.6) * 2.0))
	var lane_l := AABB(Vector3(-SIDE_LEN - 2.0, -1.0, -SIDE_HW - 2.6), lane.size)
	for c in level.get_children():
		if c == self or not (c is Node3D):
			continue
		var mi: MeshInstance3D = c as MeshInstance3D
		if mi == null and c is StaticBody3D:
			for k in c.get_children():
				if k is MeshInstance3D:
					mi = k
					break
		if mi == null or mi.mesh == null:
			continue
		var box: AABB = inv * (mi.global_transform * mi.mesh.get_aabb())
		if box.size.x > 40.0 or box.size.z > 40.0:
			continue
		if box.intersects(lane) or box.intersects(lane_l):
			c.queue_free()

func _roads() -> void:
	var asphalt := Color("353940")
	var walk := Color("9b9a90")
	var white := Color("e9e7df")
	# zijweg over fietspad en trottoir heen, tot aan de rijbaan van de route
	for sx in [-1.0, 1.0]:
		var x0: float = hw
		var x1: float = SIDE_LEN
		Kit.box(self, "Side road", Vector3(sx * (x0 + x1) * 0.5, 0.045, 0), Vector3(x1 - x0, 0.07, SIDE_HW * 2.0), asphalt)
		# trottoirs langs de zijweg, buiten het trottoir van de route
		for sz in [-1.0, 1.0]:
			Kit.box(self, "Side walk", Vector3(sx * (edge + x1) * 0.5, 0.06, sz * (SIDE_HW + 1.2)), Vector3(x1 - edge, 0.1, 2.4), walk)
		# middenstreep (onderbroken) en stopstreep op de zijweg
		var x := edge + 4.0
		while x < x1 - 2.0:
			Kit.box(self, "Side dash", Vector3(sx * (x + 1.5), 0.085, 0), Vector3(3.0, 0.01, 0.15), white)
			x += 6.0
		Kit.box(self, "Side stop line", Vector3(sx * (edge + 0.6), 0.085, -sx * SIDE_HW * 0.5), Vector3(0.4, 0.01, SIDE_HW - 0.2), white)
	# stopstrepen op de hoofdweg (alleen over de eigen rijhelft)
	Kit.box(self, "Stop line", Vector3(hw * 0.5, 0.05, stop_d), Vector3(hw - 0.3, 0.01, 0.4), white)
	Kit.box(self, "Stop line", Vector3(-hw * 0.5, 0.05, -stop_d), Vector3(hw - 0.3, 0.01, 0.4), white)

# Paal met zwart-witte banden onderaan.
func _pole(pos: Vector3, h: float) -> void:
	Kit.cyl(self, "Light pole", pos + Vector3(0, h * 0.5, 0), 0.09, 0.08, h, Color("b9bdb9"), 8, "y", true)
	Kit.cyl(self, "Light pole white", pos + Vector3(0, 1.3, 0), 0.1, 0.1, 2.6, Color("eeeeea"), 8)
	for i in range(5):
		Kit.cyl(self, "Light pole band", pos + Vector3(0, 0.25 + float(i) * 0.5, 0), 0.105, 0.105, 0.25, Color("1c1d1f"), 8)

# Lichtkast; yaw = richting waarin de lampen kijken (0 = naar +Z).
func _head(group: String, pos: Vector3, yaw: float) -> void:
	var f := Node3D.new()
	f.position = pos
	f.rotation.y = yaw
	add_child(f)
	Kit.box(f, "Signal box", Vector3(0, 0, 0), Vector3(0.38, 1.05, 0.26), Color("16171a"))
	var lamps: Array = []
	for k in ["red", "amber", "green"]:
		var y: float = {"red": 0.32, "amber": 0.0, "green": -0.32}[k]
		var lamp := Kit.cyl(f, "Lamp " + k, Vector3(0, y, 0.14), 0.12, 0.12, 0.03, Color.BLACK, 16, "z")
		Kit.box(f, "Visor", Vector3(0, y + 0.13, 0.2), Vector3(0.3, 0.03, 0.14), Color("16171a"))
		lamps.append(lamp)
	heads[group].append(lamps)

func _lights() -> void:
	var curb: float = hw + 0.7
	# hoofdweg, verkeer van +Z (rechts rijdend): paal rechts bij de stopstreep met kast
	# op ooghoogte en een uithouder over de weg met een tweede kast
	for dir in [1.0, -1.0]:
		var base := Vector3(dir * curb, 0, dir * (stop_d + 0.6))
		var yaw: float = 0.0 if dir > 0.0 else PI
		_pole(base, 6.4)
		_head("main", base + Vector3(-dir * 0.05, 3.0, dir * 0.2), yaw)
		var arm_end := Vector3(dir * hw * 0.3, 6.2, base.z)
		Kit.beam(self, "Signal arm", base + Vector3(0, 6.2, 0), arm_end, 0.12, Color("b9bdb9"))
		_head("main", arm_end + Vector3(0, -0.65, dir * 0.15), yaw)
		# klein blauw bordje 'rechtdoor' onder de kast, zoals op de foto
		Kit.cyl(self, "Arrow sign", base + Vector3(0, 2.2, dir * 0.14), 0.22, 0.22, 0.03, Color("1d4f9c"), 16, "z")
	# zijweg: per richting een paal rechts bij de stopstreep
	for sx in [1.0, -1.0]:
		var base := Vector3(sx * (edge + 1.0), 0, -sx * (SIDE_HW + 0.6))
		_pole(base, 4.0)
		_head("side", base + Vector3(sx * 0.2, 3.0, 0), sx * PI * 0.5)

func _cross_traffic() -> void:
	var colors := [Color("8c9196"), Color("2f5d8a"), Color("e8e6e0"), Color("a33a2f")]
	for i in range(2):
		var c := TrafficCar.new()
		c.name = "Cross traffic"
		add_child(c)
		c.build_look(colors[(i + int(s_c)) % colors.size()], false)
		var dir: float = -1.0 if i == 0 else 1.0        # rijrichting langs X
		cross_cars.append({"car": c, "dir": dir, "x": -dir * (SIDE_LEN - 4.0 - float(i) * 20.0), "v": 0.0})

# ---------------------------------------------------------------- lopen
func _physics_process(delta: float) -> void:
	clock += delta
	_update_phase(false)
	_move_cross(delta)
	_check_player()

func _update_phase(force: bool) -> void:
	var total := 0.0
	for p in CYCLE:
		total += float(p[2])
	var t: float = fposmod(clock, total)
	var i := 0
	while t >= float(CYCLE[i][2]):
		t -= float(CYCLE[i][2])
		i += 1
	if i == phase and not force:
		return
	phase = i
	main_state = CYCLE[i][0]
	side_state = CYCLE[i][1]
	for g in ["main", "side"]:
		var st: String = main_state if g == "main" else side_state
		for lamps in heads[g]:
			for k in range(3):
				var col: String = ["red", "amber", "green"][k]
				(lamps[k] as MeshInstance3D).material_override = mats[col + ("_on" if col == st else "_off")]

func _move_cross(delta: float) -> void:
	for cc in cross_cars:
		var dir: float = cc["dir"]
		var x: float = cc["x"]
		# afstand tot de stopstreep (alleen als de auto er nog voor zit)
		var stop_x: float = -dir * (edge + 3.0)
		var to_line: float = (stop_x - x) * dir
		var target := 9.0
		if side_state != "green" and to_line > -0.5 and to_line < 30.0:
			target = maxf(0.0, to_line * 0.7)
		cc["v"] = move_toward(cc["v"], target, (8.0 if target < cc["v"] else 3.5) * delta)
		x += dir * cc["v"] * delta
		if x * dir > SIDE_LEN:
			x = -dir * SIDE_LEN
		cc["x"] = x
		var car: Node3D = cc["car"]
		# rechts rijden: richting -X rijdt op -Z, richting +X op +Z
		car.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5 * dir), Vector3(x, 0.1, dir * SIDE_HW * 0.5))

# Door rood: de speler rijdt in rijrichting over de stopstreep terwijl de hoofdweg rood heeft
# (levert een bonus op, zie race.red_light_fine).
func _check_player() -> void:
	if race == null or race.car == null:
		return
	var p: Vector3 = transform.affine_inverse() * race.car.global_position
	if absf(p.x) > hw + 1.5:
		prev_z = INF
		return
	if prev_z != INF and main_state == "red":
		if prev_z > stop_d and p.z <= stop_d:
			race.red_light_fine()
		elif prev_z < -stop_d and p.z >= -stop_d:
			race.red_light_fine()
	prev_z = p.z
