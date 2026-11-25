extends Node3D
# Een AWACS-vliegtuig van de NAVO-vliegbasis Geilenkirchen, vlak over de grens, in de
# landing over de Schinveldse bossen. Naar jouw foto's (20-11):
# - lange witgrijze romp (Boeing 707-vorm) met een spitse neus, zwarte cockpitramen en
#   langwerpige gondels opzij voorin
# - laag geplaatste vleugels met pijlstand en een beetje V-stand, vier motoren in gondels
#   aan pylonen onder de vleugels
# - hoge pijlvormige staart met hoogteroer
# - de ronde radarschotel op twee schuine steunen: bovenkant zwart met een witte streep,
#   witte rand, onderkant zwart
# - in de landing: landingsgestel uit, landingslichten aan, licht neus omhoog
# Opschriften en emblemen laten we weg. Hij vliegt in een rechte, licht dalende lijn.
const Kit = preload("res://scripts/build_kit.gd")

const WHITE := Color("dfe2e3")
const DARK := Color("25282d")

var from := Vector3.ZERO
var to := Vector3.ZERO
var speed := 75.0
var t := 0.0
var pause := 0.0       # wachttijd (s) tussen twee overvluchten, onzichtbaar en stil
# geluid: het motorgeraas uit een opname van een overvliegend vliegtuig (Pixabay, zie de
# uitleg) als loop, vast aan het vliegtuig: hoe dichterbij, hoe harder, en hoger als hij op
# je af komt en lager als hij wegvliegt (Doppler).
var jet: AudioStreamPlayer3D

func setup(a: Vector3, b: Vector3, v: float, start := 0.0) -> void:
	from = a
	to = b
	speed = v
	t = start
	_apply()

func _ready() -> void:
	name = "AWACS"
	add_to_group("keep_far")
	_fuselage()
	for side in [-1.0, 1.0]:
		_wing(side)
		_stabiliser(side)
	_fin()
	_rotodome()
	_gear()
	jet = AudioStreamPlayer3D.new()
	jet.stream = load("res://assets/awacs_loop.wav")
	jet.unit_size = 60.0
	jet.max_distance = 2200.0
	jet.max_db = 6.0
	jet.volume_db = 3.0
	jet.bus = "SFX"
	jet.autoplay = true
	add_child(jet)

func _mesh(n: String, tris: Array, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, Kit._two_sided(color))
	add_child(mi)
	return mi

func _fuselage() -> void:
	# romp langs -Z (neus vooruit)
	Kit.cyl(self, "Fuselage", Vector3(0, 0, 0), 1.9, 1.9, 38.0, WHITE, 18, "z")
	Kit.cyl(self, "Nose", Vector3(0, -0.25, -21.0), 0.55, 1.9, 4.0, WHITE, 18, "z")
	var tip := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.0
	tip.mesh = sm
	tip.material_override = Kit.mat(WHITE)
	tip.position = Vector3(0, -0.3, -23.0)
	add_child(tip)
	var tail := Kit.cyl(self, "Tail cone", Vector3(0, 0.5, 22.0), 1.9, 0.35, 6.0, WHITE, 18, "z")
	tail.rotation_degrees.x = 90.0 - 4.0
	# cockpitramen: een donkere band schuin over de neus
	for s in [-1.0, 1.0]:
		var w := Kit.box(self, "Cockpit window", Vector3(s * 0.9, 0.95, -19.6), Vector3(1.1, 0.42, 1.0), DARK)
		w.rotation = Vector3(0.35, s * 0.45, 0.0)
	Kit.box(self, "Cockpit window front", Vector3(0, 1.05, -19.9), Vector3(1.0, 0.4, 0.6), DARK)
	# langwerpige gondels opzij voorin
	for s in [-1.0, 1.0]:
		Kit.cyl(self, "Side pod", Vector3(s * 1.85, 0.0, -12.0), 0.42, 0.42, 5.0, Color("c9cdcf"), 10, "z")
		for k in range(4):
			Kit.cyl(self, "Side pod port", Vector3(s * 2.2, 0.0, -13.3 + float(k) * 0.55), 0.14, 0.14, 0.1, DARK, 8, "x")
	# rood zwaailicht en een paar antennes
	Kit.box(self, "Beacon", Vector3(0, -1.95, 2.0), Vector3(0.25, 0.15, 0.4), Color("d0302a"))
	for z in [-8.0, -4.0, 12.0]:
		Kit.box(self, "Antenna", Vector3(0, 2.1, z), Vector3(0.08, 0.5, 0.3), Color("9aa0a4"))

# Vleugel met pijlstand en V-stand, met twee motorgondels aan pylonen.
func _wing(side: float) -> void:
	var root_x := 1.7
	var tip_x := 22.0
	var root_y := -1.25
	var tip_y := 0.4
	var le_root := -3.0
	var te_root := 6.5
	var le_tip := 11.5
	var te_tip := 14.0
	var t: Array = []
	for dy in [0.0, 0.32]:
		Kit._quad(t, Vector3(side * root_x, root_y + dy, le_root), Vector3(side * tip_x, tip_y + dy, le_tip),
			Vector3(side * tip_x, tip_y + dy * 0.4, te_tip), Vector3(side * root_x, root_y + dy, te_root))
	# voorrand dicht
	Kit._quad(t, Vector3(side * root_x, root_y, le_root), Vector3(side * tip_x, tip_y, le_tip),
		Vector3(side * tip_x, tip_y + 0.13, le_tip), Vector3(side * root_x, root_y + 0.32, le_root))
	_mesh("Wing", t, WHITE)
	# vleugelwortel-kuip onder de romp
	Kit.box(self, "Wing fairing", Vector3(side * 1.2, -1.5, 2.0), Vector3(1.6, 0.8, 9.0), WHITE)
	for fx in [7.5, 14.0]:
		var f: float = (fx - root_x) / (tip_x - root_x)
		var le: float = lerpf(le_root, le_tip, f)
		var wy: float = lerpf(root_y, tip_y, f)
		var e := Vector3(side * fx, wy - 1.55, le - 1.2)
		Kit.cyl(self, "Engine", e, 0.78, 0.68, 4.6, WHITE, 14, "z")
		Kit.cyl(self, "Engine intake", e + Vector3(0, 0, -2.32), 0.66, 0.66, 0.06, DARK, 14, "z")
		Kit.cyl(self, "Engine fan", e + Vector3(0, 0, -2.2), 0.25, 0.25, 0.08, Color("6a6e72"), 10, "z")
		Kit.cyl(self, "Engine exhaust", e + Vector3(0, 0, 2.5), 0.45, 0.4, 0.5, Color("8a8e92"), 12, "z")
		var py := Kit.box(self, "Pylon", e + Vector3(0, 0.95, 1.0), Vector3(0.22, 1.0, 3.6), WHITE)
		py.rotation.x = -0.12
	# landingslichten in de vleugelwortel
	Kit.box(self, "Landing light", Vector3(side * 3.0, -1.2, -1.6), Vector3(0.5, 0.18, 0.1), Color("fff6d0"))

func _stabiliser(side: float) -> void:
	var t: Array = []
	var y := 1.0
	Kit._quad(t, Vector3(side * 0.6, y, 18.0), Vector3(side * 7.8, y + 0.6, 23.4),
		Vector3(side * 7.8, y + 0.6, 24.6), Vector3(side * 0.6, y, 22.6))
	_mesh("Stabiliser", t, WHITE)

func _fin() -> void:
	var t: Array = []
	for dx in [-0.18, 0.18]:
		Kit._quad(t, Vector3(dx, 1.6, 15.5), Vector3(dx, 10.6, 22.6), Vector3(dx, 10.6, 24.4), Vector3(dx, 1.6, 23.5))
	Kit._quad(t, Vector3(-0.18, 1.6, 15.5), Vector3(0.18, 1.6, 15.5), Vector3(0.18, 10.6, 22.6), Vector3(-0.18, 10.6, 22.6))
	_mesh("Fin", t, WHITE)
	Kit.box(self, "Fin tip", Vector3(0, 10.65, 23.6), Vector3(0.4, 0.15, 2.2), Color("c9cdcf"))

# Radarschotel: zwarte bovenkant met witte streep, witte rand, zwarte onderkant.
func _rotodome() -> void:
	var c := Vector3(0, 5.4, 6.5)
	Kit.cyl(self, "Rotodome top", c + Vector3(0, 0.45, 0), 4.2, 4.6, 0.5, DARK, 32)
	Kit.cyl(self, "Rotodome rim", c + Vector3(0, 0.0, 0), 4.6, 4.6, 0.4, WHITE, 32)
	Kit.cyl(self, "Rotodome bottom", c + Vector3(0, -0.4, 0), 4.6, 4.0, 0.4, DARK, 32)
	Kit.box(self, "Rotodome stripe", c + Vector3(0, 0.71, 0), Vector3(1.6, 0.04, 8.4), WHITE)
	# twee schuine steunen (van opzij gezien een V)
	for k in [-1.0, 1.0]:
		var st := Kit.beam(self, "Rotodome strut", Vector3(0, 1.7, c.z + k * 2.4), Vector3(0, c.y - 0.6, c.z + k * 0.9), 0.55, WHITE)
		st.scale.z = 2.2

func _gear() -> void:
	var tyre := Color("1e1f21")
	var leg := Color("a9adb0")
	# neuswiel
	Kit.box(self, "Nose gear leg", Vector3(0, -2.9, -16.5), Vector3(0.2, 2.2, 0.2), leg)
	for s in [-1.0, 1.0]:
		Kit.cyl(self, "Nose wheel", Vector3(s * 0.3, -4.0, -16.5), 0.45, 0.45, 0.3, tyre, 12, "x")
	# hoofdlandingsgestel: twee draaistellen van vier wielen
	for s in [-1.0, 1.0]:
		Kit.box(self, "Main gear leg", Vector3(s * 3.2, -2.9, 4.5), Vector3(0.3, 2.6, 0.3), leg)
		Kit.box(self, "Main gear bogie", Vector3(s * 3.2, -4.1, 4.5), Vector3(0.25, 0.25, 2.0), leg)
		for dz in [-0.75, 0.75]:
			for dx in [-0.35, 0.35]:
				Kit.cyl(self, "Main wheel", Vector3(s * 3.2 + dx, -4.2, 4.5 + dz), 0.55, 0.55, 0.3, tyre, 12, "x")

# Vlieg schuin over de route op afstand s (van voren, iets van links), zodat hij na
# `after` seconden op hoogte h recht boven de weg is: dan zie je hem vanaf de start vóór
# je overkomen in plaats van recht boven je (buiten beeld van de volgcamera). Hij daalt
# rustig, alsof hij gaat landen op de basis achter je.
func cross_route(route, s: float, h: float, after: float, v := 80.0) -> void:
	var c: Vector3 = route.pos_at(s)
	var d: Vector3 = approach_dir(route, s)
	var half := 950.0
	var drop: float = half * 0.035
	setup(c - d * half + Vector3(0, h + drop, 0), c + d * half + Vector3(0, h - drop, 0), v, half / v - after)
	# niet elke 24 s opnieuw: na elke overvlucht ruim een halve minuut niets
	pause = 40.0

# Richting van de aanvliegroute (horizontaal) bij afstand s op de route.
static func approach_dir(route, s: float) -> Vector3:
	return (route.right_at(s) * 0.35 - route.dir_at(s)).normalized()

func _apply() -> void:
	var d: Vector3 = to - from
	var dist: float = d.length()
	if dist < 1.0:
		return
	var fly: float = dist / speed
	var u: float = fmod(t, fly + pause)
	var flying: bool = u < fly
	if visible != flying:
		visible = flying
		if jet != null:
			jet.stream_paused = not flying
	var p: Vector3 = from + d.normalized() * minf(u, fly) * speed
	var flat := Vector3(d.x, 0, d.z).normalized()
	# licht neus omhoog terwijl hij daalt
	var b := Basis.looking_at(flat, Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(3.0))
	transform = Transform3D(b, p)

func _process(delta: float) -> void:
	t += delta
	_apply()
	_doppler()

# Doppler zelf berekend uit de vliegrichting (de lus springt aan het eind terug naar het
# begin, dan zou Godot een enorme snelheid zien).
func _doppler() -> void:
	var cam := get_viewport().get_camera_3d()
	var d: Vector3 = to - from
	if jet == null or cam == null or d.length() < 1.0:
		return
	var rel: Vector3 = global_position - cam.global_position
	if rel.length() < 1.0:
		return
	var away: float = (d.normalized() * speed).dot(rel.normalized())
	# iets afgezwakt: de opname komt al uit het naderen en klinkt zelf al wat hoog
	jet.pitch_scale = clampf(343.0 / (343.0 + away * 0.65), 0.8, 1.2)
