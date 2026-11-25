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

func setup(r, start_s: float, end_s: float, v: float, against: bool, color: Color, van: bool) -> void:
	route = r
	s = start_s
	s_max = end_s
	speed = v
	cur_speed = v
	oncoming = against
	if not all.has(self):
		all.append(self)
	build_look(color, van)
	_apply()

func _enter_tree() -> void:
	if route != null and not all.has(self):
		all.append(self)

func _exit_tree() -> void:
	all.erase(self)

func build_look(color: Color, van: bool) -> void:
	sync_to_physics = false
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.6 if not van else 2.3, 4.2 if not van else 4.9)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = shape.size.y * 0.5 + 0.2
	add_child(cs)
	var dark := Color("23272c")
	if van:
		Kit.box(self, "Van body", Vector3(0, 1.3, 0.2), Vector3(1.9, 2.1, 4.4), color)
		Kit.box(self, "Van windscreen", Vector3(0, 1.75, -2.03), Vector3(1.7, 0.7, 0.06), Color("4f6f7c"))
	else:
		Kit.box(self, "Body", Vector3(0, 0.8, 0), Vector3(1.8, 0.6, 4.1), color)
		Kit.box(self, "Cabin", Vector3(0, 1.38, 0.2), Vector3(1.6, 0.58, 2.1), color)
		Kit.box(self, "Windscreen", Vector3(0, 1.4, -0.87), Vector3(1.45, 0.42, 0.05), Color("4f6f7c"))
	for x in [-0.85, 0.85]:
		for z in [-1.3, 1.35]:
			Kit.cyl(self, "Wheel", Vector3(x, 0.4, z), 0.38, 0.38, 0.24, dark, 10, "x")
		Kit.box(self, "Rear lamp", Vector3(x * 0.8, 0.95, 2.06 if not van else 2.42), Vector3(0.3, 0.18, 0.04), Color("b0262a"))
		Kit.box(self, "Head lamp", Vector3(x * 0.8, 0.9, -2.06 if not van else -2.0), Vector3(0.3, 0.16, 0.04), Color("f2ecc4"))

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
