extends Node3D
# Lindeplein, het nieuwe gemeentehuis en het Vijverpark in Brunssum, naar jouw foto's en kaart
# (23/24-11). Het oude gemeentehuis staat apart, een stukje eerder (landmark_raadhuis_brunssum.gd).
# - het Lindeplein ligt aan de weg: rood klinkerplein met een donkerder rond vlak, grijze
#   plantenbakken (schuine kanten) met kale boompjes, betonnen bankjes, een grondfontein en
#   lichtsnoeren tussen hoge grijze masten
# - links van het plein (gezien vanaf de weg, naar jouw luchtfoto van 25-11) het nieuwe gemeentehuis: laag gebouw van gele baksteen
#   met een glazen pui, een zwart trappenhuis aan de pleinkant, een hogere schijf met
#   lintramen en een toren met een stalen sierkroon
# - achter het plein de trap met de waterval naar het park, dat lager ligt (er zit een echt
#   gat in de grond): de Eendjesvijver met taluds, een eilandje met een treurwilg, een fontein,
#   een beeld van twee bollen, moerascipressen en grote bomen
# De inhoud staat in een kind-node die zo verschoven is dat het geheel rond de oorsprong
# ligt. Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const OFFSET := Vector3(-6.75, 0, 33)
const PARK_SHIFT := -16.0   # het park (plein, trap, vijver) ligt 16 m naar -x; het gemeentehuis staat links ervan (-x)
const DEPTH := 3.5
# het gat in de grond (inhoudsruimte): buitenrand op maaiveld en de bodem; aan de pleinkant
# (z = 10) is het een rechte keermuur
const PIT_OUT := Rect2(-48, -112, 110, 122)    # x -48..62, z -112..10
const PIT_IN := Rect2(-38, -102, 90, 112)      # x -38..52, z -102..10
const PLAZA_EDGE := 10.0

const GREEN_METAL := Color("4d7468")
const WATER := Color("4a6e78")
const GRASS := Color("6d9a4c")
const YELLOW_BRICK := Color("c9a46a")
const DARK := Color("2b2e33")
const GLASS := Color("3c4a52")

var root: Node3D

# Het gat in de grond in lokale ruimte van deze node (voor de grond van het level).
func pit_rect() -> Rect2:
	return Rect2(PIT_OUT.position + Vector2(OFFSET.x + PARK_SHIFT, OFFSET.z), PIT_OUT.size)

func _ready() -> void:
	name = "Lindeplein en Vijverpark Brunssum"
	var base := Node3D.new()
	base.position = OFFSET
	add_child(base)
	root = Node3D.new()
	root.position = Vector3(PARK_SHIFT, 0, 0)
	base.add_child(root)
	_pit()
	_pond()
	_plaza()
	_cascade(0.0)
	_park_trees()
	root = base
	_town_hall_new()

# ------------------------------------------------------------------ gat en taluds
func _pit() -> void:
	var o := PIT_OUT
	var i := PIT_IN
	var y := -DEPTH
	var t: Array = []
	# taluds: west (x min), achter (z min) en oost (x max); aan de pleinkant de keermuur
	Kit._quad(t, Vector3(o.position.x, 0, o.end.y), Vector3(o.position.x, 0, o.position.y), Vector3(i.position.x, y, i.position.y), Vector3(i.position.x, y, i.end.y))
	Kit._quad(t, Vector3(o.position.x, 0, o.position.y), Vector3(o.end.x, 0, o.position.y), Vector3(i.end.x, y, i.position.y), Vector3(i.position.x, y, i.position.y))
	Kit._quad(t, Vector3(o.end.x, 0, o.position.y), Vector3(o.end.x, 0, o.end.y), Vector3(i.end.x, y, i.end.y), Vector3(i.end.x, y, i.position.y))
	var mi := MeshInstance3D.new()
	mi.name = "Pond banks"
	mi.mesh = Kit._mesh_from(t, Kit._two_sided(Color("648f45")))
	root.add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(PackedVector3Array(t))
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)
	var wt: Array = []
	Kit._quad(wt, Vector3(o.position.x, 0, o.end.y), Vector3(o.end.x, 0, o.end.y), Vector3(i.end.x, y, i.end.y), Vector3(i.position.x, y, i.end.y))
	var wall := MeshInstance3D.new()
	wall.name = "Plaza retaining wall"
	wall.mesh = Kit._mesh_from(wt, Kit._two_sided(Color("b9b2a2")))
	root.add_child(wall)
	Kit.box(root, "Plaza wall coping", Vector3((o.position.x + o.end.x) * 0.5, 0.08, PLAZA_EDGE + 0.25), Vector3(o.size.x, 0.16, 0.6), Color("cfc9bb"))
	var c := i.get_center()
	Kit.box(root, "Park floor", Vector3(c.x, y - 0.35, c.y), Vector3(i.size.x + 0.2, 0.7, i.size.y + 0.2), GRASS, true)
	# hek langs de pleinrand, behalve bij de trap (x -7..7): daar kun je de trap af rijden
	_blocker(Vector3((o.position.x - 7.0) * 0.5, 1.0, PLAZA_EDGE + 0.3), Vector3(-7.0 - o.position.x, 2.0, 0.3))
	_blocker(Vector3((7.0 + o.end.x) * 0.5, 1.0, PLAZA_EDGE + 0.3), Vector3(o.end.x - 7.0, 2.0, 0.3))
	_rail_line(Vector3(o.position.x, 0, PLAZA_EDGE + 0.3), Vector3(-8.0, 0, PLAZA_EDGE + 0.3))
	_rail_line(Vector3(8.0, 0, PLAZA_EDGE + 0.3), Vector3(o.end.x, 0, PLAZA_EDGE + 0.3))
	# grindpaden rond de vijver
	var py := y + 0.03
	for p in [[Vector3(7, py, -6), Vector3(84, 0.04, 2.4)], [Vector3(-34, py, -52), Vector3(2.4, 0.04, 92)], [Vector3(7, py, -98), Vector3(84, 0.04, 2.4)],
			[Vector3(48, py, -52), Vector3(2.4, 0.04, 92)]]:
		Kit.box(root, "Park path", p[0], p[1], Color("d6cdb6"))

func _blocker(p: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.position = p
	root.add_child(body)

# Groen sierhek: bovenregel, stijlen en een golvende tussenregel.
func _rail_line(a: Vector3, b: Vector3, h := 1.1) -> void:
	Kit.beam(root, "Rail top", a + Vector3(0, h, 0), b + Vector3(0, h, 0), 0.08, GREEN_METAL)
	var n: int = maxi(2, int(a.distance_to(b) / 1.4))
	var prev := Vector3.ZERO
	for k in range(n + 1):
		var f: float = float(k) / float(n)
		var p: Vector3 = a.lerp(b, f)
		Kit.box(root, "Rail post", p + Vector3(0, h * 0.5, 0), Vector3(0.07, h, 0.07), GREEN_METAL)
		var w: Vector3 = p + Vector3(0, h * 0.55 + sin(f * float(n) * 1.6) * 0.25, 0)
		if k > 0:
			Kit.beam(root, "Rail wave", prev, w, 0.05, GREEN_METAL)
		prev = w

# ------------------------------------------------------------------ vijver
var _spray: StandardMaterial3D

func _spray_mat() -> StandardMaterial3D:
	if _spray != null:
		return _spray
	var m := StandardMaterial3D.new()
	_spray = m
	m.albedo_color = Color(0.95, 0.97, 1.0, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _pond() -> void:
	var y := -DEPTH + 0.3
	var wm := Kit.mat(WATER, 0.0, 0.25, 0.12)
	for b in [[Vector3(7, y, -55), Vector2(39, 38)], [Vector3(-14, y + 0.005, -30), Vector2(18, 14)], [Vector3(30, y + 0.01, -80), Vector2(16, 14)]]:
		var w := Kit.cyl(root, "Pond", b[0], 1.0, 1.0, 0.1, Color.WHITE, 32, "y", false, wm)
		w.scale = Vector3(b[1].x, 1.0, b[1].y)
	for p in [Vector3(-30, 0, -40), Vector3(-28, 0, -64), Vector3(44, 0, -40), Vector3(42, 0, -64)]:
		for k in range(4):
			Kit.cyl(root, "Reeds", p + Vector3(sin(k * 2.1) * 0.6, -DEPTH + 0.6, float(k) * 1.4 - 2.1), 0.5, 0.15, 1.2, Color("7d8a4a"), 6)
	# eilandje met een treurwilg
	var isl := Vector3(-14, -DEPTH, -66)
	Kit.cyl(root, "Island", isl + Vector3(0, 0.4, 0), 5.5, 4.5, 0.6, Color("5f8a40"), 14)
	_willow(isl + Vector3(0, 0.6, 0), 1.0)
	for k in range(5):
		var a: float = float(k) * 1.3
		_bush(isl + Vector3(cos(a) * 3.5, 0.7, sin(a) * 3.5), 1.4, Color("5a8a3e"))
	# fontein
	var fp := Vector3(12, y + 0.05, -48)
	var spray := _spray_mat()
	Kit.cyl(root, "Fountain float", fp, 1.2, 1.2, 0.15, Color("d8dcdc"), 12)
	Kit.cyl(root, "Fountain jet", fp + Vector3(0, 3.5, 0), 0.35, 0.08, 7.0, Color.WHITE, 10, "y", false, spray)
	Kit.cyl(root, "Fountain top", fp + Vector3(0, 7.2, 0), 0.5, 0.0, 0.8, Color.WHITE, 10, "y", false, spray)
	Kit.cyl(root, "Fountain spray", fp + Vector3(0, 0.8, 0), 3.0, 0.4, 1.6, Color.WHITE, 16, "y", false, spray)
	Kit.cyl(root, "Fountain foam", fp + Vector3(0, 0.05, 0), 3.4, 3.4, 0.08, Color("e6eef0"), 16)
	# beeld van twee gestapelde bollen in het water
	var sp := Vector3(28, y, -26)
	Kit.cyl(root, "Sculpture neck", sp + Vector3(0, 1.0, 0), 0.35, 0.35, 2.0, DARK, 10)
	for s in [[1.1, 0.95], [2.75, 1.0]]:
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = s[1]
		sm.height = s[1] * 2.0
		ball.mesh = sm
		ball.material_override = Kit.mat(DARK, 0.0, 0.4, 0.5)
		ball.position = sp + Vector3(0, s[0], 0)
		root.add_child(ball)

# ------------------------------------------------------------------ Lindeplein
func _planter(p: Vector3) -> void:
	# grijze bak met schuin aflopende kanten, op een betonnen voet, met een kaal boompje
	Kit.box(root, "Planter foot", p + Vector3(0, 0.12, 0), Vector3(3.0, 0.24, 3.0), Color("8a8c90"))
	Kit.frustum(root, "Planter", p + Vector3(0, 0.24, 0), 3.2, 3.2, 0.35, 0.9, Color("4e5054"))
	Kit.box(root, "Planter top", p + Vector3(0, 1.16, 0), Vector3(2.5, 0.06, 2.5), Color("6a6c70"))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.0, 1.2, 3.0)
	cs.shape = sh
	body.add_child(cs)
	body.position = p + Vector3(0, 0.6, 0)
	root.add_child(body)
	Kit.cyl(root, "Plaza tree trunk", p + Vector3(0, 3.2, 0), 0.14, 0.08, 4.2, Color("6a5a4a"), 6)
	for k in range(4):
		var a: float = float(k) * 1.6 + p.x
		Kit.beam(root, "Plaza tree branch", p + Vector3(0, 3.6 + float(k) * 0.5, 0), p + Vector3(cos(a) * 1.6, 5.4 + float(k) * 0.4, sin(a) * 1.6), 0.07, Color("6a5a4a"))
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 1.7
	cm.height = 2.8
	cm.radial_segments = 8
	cm.rings = 4
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("8aa858"))
	cr.position = p + Vector3(0, 5.8, 0)
	root.add_child(cr)

func _bench(p: Vector3, yaw: float) -> void:
	var b := Node3D.new()
	b.position = p
	b.rotation.y = yaw
	root.add_child(b)
	Kit.box(b, "Bench", Vector3(0, 0.42, 0), Vector3(2.6, 0.12, 0.6), Color("9a9a96"))
	for sx in [-1.1, 1.1]:
		Kit.box(b, "Bench leg", Vector3(sx, 0.2, 0), Vector3(0.18, 0.4, 0.6), Color("8a8a86"))

func _plaza() -> void:
	# klinkers van het plein, met een donkerder rond vlak aan de kant van de weg
	Kit.box(root, "Lindeplein", Vector3(4, 0.02, 28), Vector3(116, 0.04, 36.6), Color("b0745c"))
	Kit.cyl(root, "Plaza circle", Vector3(38, 0.045, 38), 11.0, 11.0, 0.02, Color("8a5e52"), 28)
	Kit.box(root, "Plaza kerb", Vector3(4, 0.05, 46.0), Vector3(116, 0.1, 0.5), Color("8a8c90"))
	for p in [Vector3(-36, 0, 30), Vector3(-22, 0, 18), Vector3(-14, 0, 34), Vector3(6, 0, 24), Vector3(22, 0, 16),
			Vector3(26, 0, 32), Vector3(46, 0, 22), Vector3(-36, 0, 15)]:
		_planter(p)
	for b in [[Vector3(-28, 0, 26), 0.2], [Vector3(-6, 0, 30), -0.1], [Vector3(12, 0, 36), 0.15], [Vector3(14, 0, 20), 0.0],
			[Vector3(34, 0, 24), -0.2], [Vector3(-12, 0, 14), 0.0], [Vector3(30, 0, 13), 0.0], [Vector3(54, 0, 30), 0.3]]:
		_bench(b[0], b[1])
	# grondfontein bij de trap, op een donker rond vlak
	var gf := Vector3(-12, 0, 21)
	Kit.cyl(root, "Plaza fountain", gf + Vector3(0, 0.05, 0), 5.0, 5.0, 0.04, Color("6c6e72"), 20)
	for k in range(6):
		var a: float = TAU * float(k) / 6.0
		Kit.cyl(root, "Plaza fountain jet", gf + Vector3(cos(a) * 2.2, 0.5, sin(a) * 2.2), 0.12, 0.04, 1.0, Color.WHITE, 6, "y", false, _spray_mat())
	Kit.cyl(root, "Plaza fountain jet", gf + Vector3(0, 1.1, 0), 0.2, 0.05, 2.2, Color.WHITE, 8, "y", false, _spray_mat())
	# hoge grijze lichtmasten met lichtsnoeren over het plein
	var poles := [Vector3(-44, 0, 12), Vector3(-44, 0, 44), Vector3(8, 0, 12), Vector3(8, 0, 44), Vector3(58, 0, 12), Vector3(58, 0, 44)]
	for p in poles:
		Kit.box(root, "Light mast", p + Vector3(0, 4.5, 0), Vector3(0.45, 9.0, 0.45), Color("6c6f74"))
		Kit.box(root, "Light mast panel", p + Vector3(0, 5.0, 0.24), Vector3(0.3, 6.0, 0.04), Color("4a4d52"))
	for pair in [[0, 2], [2, 4], [1, 3], [3, 5], [0, 3], [2, 5], [1, 2], [3, 4]]:
		var a: Vector3 = poles[pair[0]] + Vector3(0, 8.6, 0)
		var b: Vector3 = poles[pair[1]] + Vector3(0, 8.6, 0)
		var prev: Vector3 = a
		for k in range(1, 11):
			var f: float = float(k) / 10.0
			var q: Vector3 = a.lerp(b, f) - Vector3(0, sin(f * PI) * 1.3, 0)
			Kit.beam(root, "Light string", prev, q, 0.025, Color("2a2a2a"))
			Kit.box(root, "Light bulb", q - Vector3(0, 0.1, 0), Vector3(0.14, 0.14, 0.14), Color("fff2c0"))
			prev = q

# Trap met in het midden de waterval, van het plein (z = 10) naar beneden het park in.
func _cascade(xc: float) -> void:
	var steps := 12
	var run: float = 14.0 / float(steps)
	var rise: float = DEPTH / float(steps)
	var stone := Color("d9d2c0")
	var water := Color("cfe4ea")
	for k in range(steps):
		var z1: float = PLAZA_EDGE - float(k) * run
		var top: float = -float(k + 1) * rise
		var h: float = top + DEPTH
		if h < 0.02:
			continue
		var cy: float = -DEPTH + h * 0.5
		for side in [[xc - 4.6, 4.8, stone], [xc + 4.6, 4.8, stone], [xc, 3.6, water if k % 2 == 0 else Color("b8d6de")]]:
			Kit.box(root, "Stair step", Vector3(side[0], cy, z1 - run * 0.5), Vector3(side[1], h, run), side[2])
	# onzichtbare helling over de treden: je kunt de trap echt af en op rijden (eerst zakte
	# je er doorheen, de treden waren alleen beeld)
	var run_len: float = sqrt(14.0 * 14.0 + DEPTH * DEPTH)
	var ramp := StaticBody3D.new()
	ramp.name = "Stair ramp"
	var rcs := CollisionShape3D.new()
	var rbox := BoxShape3D.new()
	rbox.size = Vector3(14.0, 0.3, run_len)
	rcs.shape = rbox
	ramp.add_child(rcs)
	var slope: float = atan2(DEPTH, 14.0)
	ramp.rotation.x = -slope
	ramp.position = Vector3(xc, -DEPTH * 0.5, PLAZA_EDGE - 7.0) - Vector3(0, 0.15 / cos(slope), 0)
	root.add_child(ramp)
	for s in [-1.0, 1.0]:
		var x: float = xc + s * 2.0
		var a := Vector3(x, 0.3, PLAZA_EDGE)
		var b := Vector3(x, -DEPTH + 0.3, PLAZA_EDGE - 14.0)
		Kit.beam(root, "Cascade cheek", a, b, 0.4, Color("b08a4a"))
		_rail_line(a, b, 1.0)
	for s in [-1.0, 1.0]:
		var x: float = xc + s * 7.0
		_rail_line(Vector3(x, 0.1, PLAZA_EDGE), Vector3(x, -DEPTH + 0.1, PLAZA_EDGE - 14.0), 1.0)
	# bovenaan een boog met een wiel (half rad met spaken)
	var wc := Vector3(xc, 0.9, PLAZA_EDGE + 0.4)
	var r := 2.3
	var prev := wc + Vector3(-r, 0, 0)
	for k in range(1, 13):
		var a: float = PI * float(k) / 12.0
		var q: Vector3 = wc + Vector3(-cos(a) * r, sin(a) * r, 0)
		Kit.beam(root, "Wheel rim", prev, q, 0.1, GREEN_METAL)
		if k % 2 == 0 and k < 12:
			Kit.beam(root, "Wheel spoke", wc, q, 0.06, GREEN_METAL)
		prev = q
	Kit.cyl(root, "Wheel hub", wc, 0.35, 0.35, 0.1, GREEN_METAL, 12, "z")

# ------------------------------------------------------------------ nieuwe gemeentehuis
# Laag gebouw van gele baksteen met een glazen pui, een zwart trappenhuis aan de pleinkant,
# een hogere schijf met lintramen en een toren met een stalen sierkroon.
func _town_hall_new() -> void:
	# Links van het plein, gezien vanaf de weg (jouw luchtfoto, 25-11): alles gespiegeld in x
	# ten opzichte van de vorige versie (die stond rechts). H = -1 spiegelt.
	var H := -1.0
	var brick := Kit.mat(YELLOW_BRICK)
	var c := Vector3(-85, 0, 16)        # laag deel: x -98..-72, z -8..40
	var w := 26.0
	var d := 48.0
	var h := 8.0
	Kit.box(root, "New town hall", c + Vector3(0, h * 0.5 + 1.5, 0), Vector3(w, h - 3.0, d), Color.WHITE, true, brick)
	Kit.box(root, "New town hall glass", c + Vector3(0, 1.5, 0), Vector3(w - 0.6, 3.0, d - 0.6), GLASS, true)
	Kit.box(root, "New town hall roof edge", c + Vector3(0, h + 0.1, 0), Vector3(w + 0.3, 0.25, d + 0.3), Color("9a9c9a"))
	# glazen pui met stijlen aan de weg- en pleinkant (de pleinkant is nu +x)
	var fr := Kit.face(root, c + Vector3(0, 0, d * 0.5 - 0.3), 0.0)
	var fp := Kit.face(root, c + Vector3(w * 0.5 - 0.3, 0, 0), 90.0)
	for f in [[fr, w], [fp, d]]:
		var x: float = -float(f[1]) * 0.5 + 1.5
		while x < float(f[1]) * 0.5 - 1.0:
			Kit.box(f[0], "Mullion", Vector3(x, 1.5, 0.02), Vector3(0.12, 3.0, 0.06), Color("8a8e92"))
			x += 2.0
	Kit.box(fr, "Entrance canopy", Vector3(4 * H, 3.2, 1.0), Vector3(8.0, 0.2, 2.0), Color("8a8e92"))
	Kit.label(fr, "GEMEENTE BRUNSSUM", Vector3(4 * H, 5.6, 0.35), 0.02, Color("3a3a3a"), 64)
	# vierkante raampjes in een rij boven de pui (pleinkant); face-x loopt nu andersom langs z
	for x in [18.0, 14.0, 10.0, 6.0, -2.0, -6.0]:
		Kit.box(fp, "Small window", Vector3(x, 6.0, 0.33), Vector3(1.4, 1.2, 0.06), GLASS)
	# zwart trappenhuis aan de pleinkant, met een raster en een groot raam
	var st := c + Vector3(w * 0.5 + 1.3, 0, -12.0)
	Kit.box(root, "Black stair block", st + Vector3(0, 4.8, 0), Vector3(2.6, 9.6, 7.0), DARK, true)
	var sf := Kit.face(root, st + Vector3(1.3, 0, 0), 90.0)
	for k in range(5):
		Kit.box(sf, "Stair grid", Vector3(0, 1.0 + float(k) * 1.8, 0.03), Vector3(6.6, 0.06, 0.04), Color("4a4e54"))
	Kit.box(sf, "Stair window", Vector3(-1.6, 7.6, 0.04), Vector3(3.0, 2.4, 0.05), Color("5a7480"))
	# hogere schijf met lintramen (achter, kijkt naar de weg)
	var sl := Vector3(-86, 0, -2)
	Kit.box(root, "Office slab", sl + Vector3(0, 10.0, 0), Vector3(22.0, 20.0, 11.0), Color.WHITE, true, brick)
	Kit.box(root, "Office slab roof", sl + Vector3(0, 20.1, 0), Vector3(22.3, 0.25, 11.3), Color("9a9c9a"))
	var slf := Kit.face(root, sl + Vector3(0, 0, 5.5), 0.0)
	var slp := Kit.face(root, sl + Vector3(11.0, 0, 0), 90.0)
	for y in [10.0, 13.2, 16.4]:
		Kit.box(slf, "Ribbon window", Vector3(-1.0, y, 0.03), Vector3(18.0, 1.5, 0.06), GLASS)
		Kit.box(slp, "Ribbon window", Vector3(0, y, 0.03), Vector3(8.0, 1.5, 0.06), GLASS)
	Kit.box(root, "Roof plant", sl + Vector3(3.0, 21.0, 0), Vector3(5.0, 1.6, 4.0), Color("b8b8b4"))
	# toren met de stalen sierkroon (aan de buitenkant, verst van het plein)
	var tw := Vector3(-99.5, 0, -4)
	Kit.box(root, "Tower", tw + Vector3(0, 12.5, 0), Vector3(4.0, 25.0, 5.0), Color.WHITE, true, brick)
	var tf := Kit.face(root, tw + Vector3(0, 0, 2.5), 0.0)
	Kit.box(tf, "Tower slit", Vector3(0, 14.0, 0.03), Vector3(0.6, 18.0, 0.05), GLASS)
	var k0 := tw + Vector3(0, 28.0, 0)
	var steel := Color("3a3d42")
	var pts := [Vector3(1.6, 0, 0), Vector3(0, 0, 1.6), Vector3(-1.6, 0, 0), Vector3(0, 0, -1.6)]
	for i in range(4):
		var a: Vector3 = k0 + pts[i]
		var b: Vector3 = k0 + pts[(i + 1) % 4]
		Kit.beam(root, "Crown ring", a, b, 0.12, steel)
		Kit.beam(root, "Crown strut", a, k0 + Vector3(0, 2.0, 0), 0.1, steel)
		Kit.beam(root, "Crown strut", a, k0 + Vector3(0, -2.0, 0), 0.1, steel)
		Kit.beam(root, "Crown strut", a, b + Vector3(0, 1.4, 0), 0.06, steel)
	Kit.box(root, "Crown mast", tw + Vector3(0, 26.0, 0), Vector3(0.25, 2.0, 0.25), steel)
	# vlaggen voor de ingang
	var flag_cols := [Color("c8302c"), Color("f2f2ee"), Color("2a5aa8")]
	for i in range(3):
		var fp2 := c + Vector3((11.0 - float(i) * 1.6) * H, 0, d * 0.5 + 3.0)
		Kit.cyl(root, "Flag pole", fp2 + Vector3(0, 4.0, 0), 0.06, 0.05, 8.0, Color("d8dadc"), 6)
		Kit.box(root, "Flag", fp2 + Vector3(0.6, 7.2, 0), Vector3(1.2, 0.8, 0.03), flag_cols[i])

# ------------------------------------------------------------------ bomen
func _park_trees() -> void:
	var fl := -DEPTH
	for p in [Vector3(-30, fl, -96), Vector3(-12, fl, -99), Vector3(6, fl, -97), Vector3(24, fl, -99), Vector3(42, fl, -95),
			Vector3(-43, -1.8, -30), Vector3(-43, -1.8, -60), Vector3(-43, -1.8, -88), Vector3(57, -1.8, -20), Vector3(57, -1.8, -50),
			Vector3(57, -1.8, -82), Vector3(-46, 0, -108), Vector3(60, 0, -108)]:
		_tree(p, 11.0 + absf(sin(p.x * 0.7 + p.z)) * 5.0)
	for p in [Vector3(-2, fl, -94), Vector3(14, fl, -95), Vector3(34, fl, -93)]:
		Kit.cyl(root, "Swamp cypress", p + Vector3(0, 7.0, 0), 2.6, 0.3, 14.0, Color("3f6a3a"), 10)
	for p in [Vector3(-30, fl, -12), Vector3(44, fl, -12), Vector3(-30, fl, -82)]:
		_willow(p, 1.1)
	for x in [-28.0, -18.0, 18.0, 30.0, 40.0]:
		_bush(Vector3(x, fl, -3.0), 1.8, Color("4f7a36"))

func _tree(p: Vector3, h: float) -> void:
	Kit.cyl(root, "Tree trunk", p + Vector3(0, h * 0.35, 0), 0.5, 0.35, h * 0.7, Color("5b5148"), 8)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = h * 0.33
	cm.height = h * 0.6
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("4f7a36") if int(p.x) % 3 != 0 else Color("5d8a3e"))
	cr.position = p + Vector3(0, h * 0.72, 0)
	root.add_child(cr)

func _willow(p: Vector3, sc: float) -> void:
	Kit.cyl(root, "Willow trunk", p + Vector3(0, 2.5 * sc, 0), 0.4, 0.3, 5.0 * sc, Color("6a5a48"), 8)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 4.2 * sc
	cm.height = 7.5 * sc
	cm.radial_segments = 12
	cm.rings = 6
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("9ab54e"))
	cr.position = p + Vector3(0, 4.4 * sc, 0)
	root.add_child(cr)

func _bush(p: Vector3, r: float, col: Color) -> void:
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = r
	cm.height = r * 1.3
	cm.radial_segments = 8
	cm.rings = 4
	cr.mesh = cm
	cr.material_override = Kit.mat(col)
	cr.position = p + Vector3(0, r * 0.4, 0)
	root.add_child(cr)
