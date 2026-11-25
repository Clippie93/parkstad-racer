extends AnimatableBody3D
# Verkeer: rijdt over de route, in de rechterbaan (mee) of linkerbaan (tegemoet).
# Botsen kost de speler snelheid, het verkeer rijdt door. Het verkeer stopt voor rood
# licht bij kruisingen en houdt afstand tot een auto die ervoor stilstaat.
# Zonder route (route == null) rijdt de auto niet zelf: dan beweegt een kruising hem
# (dwarsverkeer op de zijweg).
const Kit = preload("res://scripts/build_kit.gd")
const Intersection = preload("res://scripts/intersection.gd")

static var all: Array = []   # alle verkeersauto's op de route (voor afstand houden)

var route   # Route
var s := 0.0
var s_max := 0.0
var speed := 13.0
var cur_speed := 13.0
var oncoming := false
var lane := 3.4

func setup(r, start_s: float, end_s: float, v: float, against: bool, color: Color, van: bool, kind: int = -1) -> void:
	route = r
	s = start_s
	s_max = end_s
	speed = v
	cur_speed = v
	oncoming = against
	if not all.has(self):
		all.append(self)
	build_look(color, van, kind)
	_apply()

func _enter_tree() -> void:
	if route != null and not all.has(self):
		all.append(self)

func _exit_tree() -> void:
	all.erase(self)

# Modellen uit de Car Kit van Kenney (CC0). Per model de kleurvlakken (64x64 op de
# colormap) die samen de lak vormen: eerst het lichte vlak, daarna het donkere.
# Een leeg lijstje = het model houdt zijn eigen kleur (taxi, bestelwagen).
const MODELS := {
	"sedan": [Vector2i(6, 2), Vector2i(6, 3)],
	"sedan-sports": [Vector2i(6, 2), Vector2i(6, 3)],
	"hatchback-sports": [Vector2i(3, 2), Vector2i(3, 3)],
	"suv": [Vector2i(3, 4)],
	"suv-luxury": [Vector2i(4, 2), Vector2i(4, 3)],
	"taxi": [],
	"van": [Vector2i(7, 2), Vector2i(7, 3)],
	"delivery": [],
}
const CARS := ["sedan", "sedan-sports", "hatchback-sports", "suv", "suv-luxury", "sedan", "taxi"]
const VANS := ["van", "delivery"]
# Kenney-auto's zijn kort en breed; zo groot dat ze naast de racers passen
const MODEL_SCALE := 1.35
static var _scenes := {}     # model -> PackedScene
static var _paints := {}     # "model|kleur" -> StandardMaterial3D

static func _paint_mat(model: String, color: Color, base: StandardMaterial3D) -> StandardMaterial3D:
	var cells: Array = MODELS[model]
	if cells.is_empty():
		return base
	var key := model + "|" + color.to_html(false)
	if _paints.has(key):
		return _paints[key]
	var img: Image = base.albedo_texture.get_image()
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var out: Image = img.duplicate()
	var c0: Vector2i = cells[0]
	var ref: float = maxf(img.get_pixel(c0.x * 64 + 32, c0.y * 64 + 32).get_luminance(), 0.01)
	# de vlakken zijn effen: één kleur per vlak, met dezelfde helderheidsverhouding
	for cell in cells:
		var k: float = img.get_pixel(cell.x * 64 + 32, cell.y * 64 + 32).get_luminance() / ref
		out.fill_rect(Rect2i(cell.x * 64, cell.y * 64, 64, 64), Color(color.r * k, color.g * k, color.b * k))
	var m: StandardMaterial3D = base.duplicate()
	m.albedo_texture = ImageTexture.create_from_image(out)
	_paints[key] = m
	return m

func build_look(color: Color, van: bool, kind: int = -1) -> void:
	sync_to_physics = false
	var list: Array = VANS if van else CARS
	if kind < 0:
		kind = absi(hash(color.to_html()) + get_instance_id())
	var model: String = list[kind % list.size()]
	if not _scenes.has(model):
		_scenes[model] = load("res://assets/traffic/%s.glb" % model)
	var vis: Node3D = (_scenes[model] as PackedScene).instantiate()
	vis.name = "Model"
	# Kenney-modellen kijken naar +Z, het verkeer rijdt naar -Z
	vis.rotation.y = PI
	vis.scale = Vector3.ONE * MODEL_SCALE
	add_child(vis)
	var size := Vector3.ZERO
	for mi in vis.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var t := Transform3D.IDENTITY
		var p: Node = m
		while p != vis:
			t = (p as Node3D).transform * t
			p = p.get_parent()
		var b: AABB = t * m.mesh.get_aabb()
		size = size.max(Vector3(maxf(absf(b.position.x), absf(b.end.x)) * 2.0, b.end.y, maxf(absf(b.position.z), absf(b.end.z)) * 2.0))
		for si in m.mesh.get_surface_count():
			var base := m.mesh.surface_get_material(si) as StandardMaterial3D
			if base != null and base.albedo_texture != null:
				m.set_surface_override_material(si, _paint_mat(model, color, base))
	size *= MODEL_SCALE
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.95, size.y - 0.2, size.z * 0.95)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = shape.size.y * 0.5 + 0.2
	add_child(cs)

func _physics_process(delta: float) -> void:
	if route == null:
		return
	var target: float = minf(speed, _room_ahead() * 0.8)
	cur_speed = move_toward(cur_speed, maxf(target, 0.0), (9.0 if target < cur_speed else 4.0) * delta)
	if oncoming:
		s -= cur_speed * delta
		if route.closed:
			s = fposmod(s, route.length)
		elif s < 5.0:
			s = s_max
	else:
		s += cur_speed * delta
		if route.closed:
			s = fposmod(s, route.length)
		elif s > s_max:
			s = 5.0
	_apply()

# Hoeveel meter vrije weg er voor de auto ligt: tot de stopstreep van een kruising met
# rood/oranje licht, of tot een andere verkeersauto in dezelfde richting.
func _room_ahead() -> float:
	var room := 1000.0
	for x in Intersection.all:
		if x.route != route or not x.main_must_stop():
			continue
		var line: float = x.stop_s(oncoming)
		var gap: float = _ahead(line) - 2.6
		if gap > -1.0 and gap < 40.0:
			room = minf(room, maxf(gap, 0.0))
	for o in all:
		if o == self or o.oncoming != oncoming or absf(o.lane - lane) > 1.0:
			continue
		var gap: float = _ahead(o.s) - 7.0
		if gap > -3.0 and gap < 40.0:
			room = minf(room, maxf(gap, 0.0))
	return room

# Afstand (in rijrichting) van deze auto tot plek s2 op de route.
func _ahead(s2: float) -> float:
	var d: float = (s2 - s) if not oncoming else (s - s2)
	if route.closed:
		d = fposmod(d + route.length * 0.5, route.length) - route.length * 0.5
	return d

func _apply() -> void:
	var side: float = -1.0 if oncoming else 1.0
	var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * lane
	var b: Basis = route.basis_at(s)
	if oncoming:
		b = b.rotated(Vector3.UP, PI)
	global_transform = Transform3D(b, p + Vector3(0, 0.05, 0))
