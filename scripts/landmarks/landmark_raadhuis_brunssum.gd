extends Node3D
# Het oude gemeentehuis (raadhuis) van Brunssum met de bollenfontein, naar jouw foto's (23-11).
# Los van het Lindeplein (24-11): op de kaart ligt het noordelijker, aan de overkant van de
# Ingenieur op Den Kampstraat. Wit op een breukstenen plint, rondboogramen met crème
# kozijnen, gele lijsten en hoekblokken, middenrisaliet met puntgevel, balkon en bordestrap,
# leien schilddak met dakkapellen en een klokkentorentje met spits en windvaan.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const WHITE := Color("efece4")
const CREAM := Color("e8dca8")
const YELLOW := Color("e2c878")
const SLATE := Color("474a52")
const GLASS := Color("37424a")

var root: Node3D
var rubble: Material

func _ready() -> void:
	name = "Oude gemeentehuis Brunssum"
	root = self
	rubble = Kit.tex_mat("res://assets/kerk_rubble.png", Color("cfc3a6"), 3.0)
	# klinkers rond het gebouw
	Kit.box(self, "Town hall square", Vector3(2, 0.02, -4), Vector3(32, 0.04, 30), Color("a86e58"))
	_town_hall(Vector3(0, 0, -7))
	_bulb_fountain(Vector3(10.5, 0, 4.5))
	for p in [Vector3(-12, 0, 2), Vector3(13, 0, -12)]:
		Kit.cyl(self, "Square tree trunk", p + Vector3(0, 2.5, 0), 0.2, 0.15, 5.0, Color("6a5a4a"), 6)
		var cr := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 2.4
		cm.height = 4.0
		cr.mesh = cm
		cr.material_override = Kit.mat(Color("7fa24e"))
		cr.position = p + Vector3(0, 6.0, 0)
		add_child(cr)

func _arch(f: Node3D, x: float, y: float, w: float, h: float) -> void:
	Kit.arch_window(f, x, y, w, h, 0.03, GLASS, CREAM)
	Kit.box(f, "Sill", Vector3(x, y - 0.1, 0.12), Vector3(w + 0.6, 0.12, 0.2), Color("b8b0a0"))

func _town_hall(c: Vector3) -> void:
	var w := 16.0
	var d := 13.0
	var top := 10.6
	var white := Kit.mat(WHITE)
	Kit.box(root, "Town hall plinth", c + Vector3(0, 0.8, 0), Vector3(w + 0.3, 1.6, d + 0.3), Color.WHITE, true, rubble)
	Kit.box(root, "Town hall", c + Vector3(0, 1.6 + (top - 1.6) * 0.5, 0), Vector3(w, top - 1.6, d), Color.WHITE, true, white)
	# kroonlijst met bruine overstek en gele banden
	Kit.box(root, "Cornice", c + Vector3(0, top + 0.15, 0), Vector3(w + 1.2, 0.3, d + 1.2), Color("6e5a46"))
	Kit.box(root, "Frieze", c + Vector3(0, top - 0.3, 0), Vector3(w + 0.1, 0.5, d + 0.1), YELLOW)
	Kit.box(root, "String course", c + Vector3(0, 5.9, 0), Vector3(w + 0.1, 0.18, d + 0.1), YELLOW)
	Kit.box(root, "Plinth course", c + Vector3(0, 1.65, 0), Vector3(w + 0.4, 0.15, d + 0.4), Color("c8c0b0"))
	# hoekpilasters met blokken
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var y := 1.8
			while y < top - 0.6:
				Kit.box(root, "Quoin", c + Vector3(sx * (w * 0.5 - 0.4), y + 0.2, sz * (d * 0.5 - 0.4)), Vector3(0.95, 0.42, 0.95), Color("e6e1d4"))
				y += 0.55
	# schilddak met dakkapellen
	Kit.frustum(root, "Town hall roof", c + Vector3(0, top + 0.3, 0), w + 1.0, d + 1.0, 4.2, 4.6, SLATE)
	var f := Kit.face(root, c + Vector3(0, 0, d * 0.5), 0.0)
	for x in [-5.6, 5.6]:
		Kit.box(f, "Dormer", Vector3(x, top + 1.6, -1.3), Vector3(1.8, 1.8, 1.4), SLATE)
		Kit.box(f, "Dormer face", Vector3(x, top + 1.6, -0.58), Vector3(1.5, 1.5, 0.05), CREAM)
		Kit.box(f, "Dormer glass", Vector3(x, top + 1.6, -0.54), Vector3(1.0, 1.0, 0.05), GLASS)
		Kit.gable(f, "Dormer roof", Vector3(x, top + 2.5, -1.3), 2.1, 1.6, 0.7, SLATE)
	# voorgevel: rondboogramen in twee lagen
	for x in [-6.0, -3.6, 3.6, 6.0]:
		_arch(f, x, 2.4, 1.5, 2.6)
		_arch(f, x, 6.5, 1.5, 2.8)
	# middenrisaliet met puntgevel, balkon en de voordeur
	var rw := 5.4
	Kit.box(f, "Risalit", Vector3(0, top * 0.5 + 0.6, 0.45), Vector3(rw, top + 1.2, 0.9), Color.WHITE, false, white)
	var g: Array = [Vector3(-rw * 0.5, top + 1.2, 0.9), Vector3(rw * 0.5, top + 1.2, 0.9), Vector3(0, top + 4.0, 0.9)]
	var gm := MeshInstance3D.new()
	gm.mesh = Kit._mesh_from(g, Kit._two_sided(WHITE))
	f.add_child(gm)
	var gb: Array = [Vector3(-rw * 0.5, top + 1.2, 0.0), Vector3(rw * 0.5, top + 1.2, 0.0), Vector3(0, top + 4.0, 0.0)]
	var gbm := MeshInstance3D.new()
	gbm.mesh = Kit._mesh_from(gb, Kit._two_sided(WHITE))
	f.add_child(gbm)
	for s in [-1.0, 1.0]:
		var e := Kit.beam(f, "Gable edge", Vector3(s * (rw * 0.5 + 0.2), top + 1.1, 0.95), Vector3(0, top + 4.2, 0.95), 0.35, YELLOW)
		e.name = "Gable edge"
		Kit.box(f, "Risalit pilaster", Vector3(s * (rw * 0.5 - 0.3), top * 0.5 + 0.6, 0.95), Vector3(0.6, top + 1.2, 0.1), YELLOW)
	Kit.box(f, "Gable base", Vector3(0, top + 1.2, 0.95), Vector3(rw + 0.4, 0.3, 0.2), YELLOW)
	Kit.box(f, "Gable finial", Vector3(0, top + 4.6, 0.6), Vector3(0.5, 0.8, 0.5), YELLOW)
	Kit.box(f, "Gable cross", Vector3(0, top + 5.3, 0.6), Vector3(0.08, 0.8, 0.08), Color("6a6a6a"))
	Kit.box(f, "Gable cross arm", Vector3(0, top + 5.45, 0.6), Vector3(0.45, 0.08, 0.08), Color("6a6a6a"))
	_arch(Kit.face(f, Vector3(0, 0, 0.92), 0.0), 0.0, top + 1.7, 1.0, 1.4)
	# balkon met balustrade boven de deur
	_arch(Kit.face(f, Vector3(0, 0, 0.92), 0.0), 0.0, 6.4, 1.5, 2.8)
	Kit.box(f, "Balcony", Vector3(0, 5.75, 1.5), Vector3(4.4, 0.3, 1.3), Color("e8e4d8"))
	Kit.box(f, "Balcony rail", Vector3(0, 6.85, 2.1), Vector3(4.4, 0.15, 0.15), Color("f2efe6"))
	for x in range(-10, 11, 2):
		Kit.box(f, "Baluster", Vector3(float(x) * 0.2, 6.3, 2.1), Vector3(0.14, 0.95, 0.14), Color("f2efe6"))
	for s in [-1.0, 1.0]:
		Kit.box(f, "Balcony bracket", Vector3(s * 1.6, 5.3, 1.3), Vector3(0.3, 0.6, 0.9), YELLOW)
	# voordeur in een boog met gele omlijsting, en de bordestrap
	var df := Kit.face(f, Vector3(0, 0, 0.92), 0.0)
	Kit.box(df, "Door surround", Vector3(0, 3.2, 0.02), Vector3(2.8, 3.2, 0.06), YELLOW)
	Kit.cyl(df, "Door surround arch", Vector3(0, 4.8, 0.02), 1.4, 1.4, 0.06, YELLOW, 20, "z")
	Kit.box(df, "Door", Vector3(0, 3.1, 0.06), Vector3(1.8, 3.0, 0.06), Color("5a3326"))
	Kit.cyl(df, "Door arch", Vector3(0, 4.6, 0.06), 0.9, 0.9, 0.06, Color("5a3326"), 20, "z")
	for k in range(6):
		var sy: float = 1.6 - float(k) * 0.27
		Kit.box(f, "Front step", Vector3(0, sy * 0.5, 1.2 + float(k) * 0.45), Vector3(3.6, sy, 0.45), Color("b8b2a4"), k == 5)
	for s in [-1.0, 1.0]:
		Kit.box(f, "Stair cheek", Vector3(s * 2.0, 1.0, 2.3), Vector3(0.4, 2.0, 2.6), Color.WHITE, false, rubble)
		Kit.box(f, "Lantern post", Vector3(s * 2.0, 2.3, 3.3), Vector3(0.5, 0.6, 0.5), Color("c8c2b4"))
		Kit.box(f, "Lantern", Vector3(s * 2.0, 2.9, 3.3), Vector3(0.4, 0.6, 0.4), Color("4a4a44"))
	# zijgevels en achtergevel: rondboogramen in paren
	for s in [-1.0, 1.0]:
		var sf := Kit.face(root, c + Vector3(s * w * 0.5, 0, 0), 90.0 * s)
		for x in [-4.0, -1.6, 2.4, 4.8]:
			_arch(sf, x, 2.4, 1.5, 2.6)
			_arch(sf, x, 6.5, 1.5, 2.8)
	var bf := Kit.face(root, c + Vector3(0, 0, -d * 0.5), 180.0)
	for x in [-5.0, 0.0, 5.0]:
		_arch(bf, x, 6.5, 1.5, 2.8)
	# lagere achtervleugel
	var bw := c + Vector3(-1.5, 0, -d * 0.5 - 4.5)
	Kit.box(root, "Rear wing plinth", bw + Vector3(0, 0.8, 0), Vector3(11.3, 1.6, 9.3), Color.WHITE, true, rubble)
	Kit.box(root, "Rear wing", bw + Vector3(0, 5.0, 0), Vector3(11.0, 6.8, 9.0), Color.WHITE, true, white)
	Kit.box(root, "Rear wing cornice", bw + Vector3(0, 8.5, 0), Vector3(12.0, 0.25, 10.0), Color("6e5a46"))
	Kit.frustum(root, "Rear wing roof", bw + Vector3(0, 8.6, 0), 11.6, 9.6, 3.0, 2.2, SLATE)
	for s in [-1.0, 1.0]:
		var sf := Kit.face(root, bw + Vector3(s * 5.5, 0, 0), 90.0 * s)
		for x in [-2.0, 2.0]:
			_arch(sf, x, 5.2, 1.4, 2.6)
		for x in [-3.0, -1.5, 0.0]:
			_arch(sf, x + 1.5, 2.2, 0.7, 1.1)
	# klokkentorentje: leien onderbouw, open lantaarn met klokken, spits en windvaan
	var tc: Vector3 = c + Vector3(0, 0, -1.0)
	Kit.box(root, "Clock tower base", tc + Vector3(0, 16.2, 0), Vector3(3.0, 4.2, 3.0), SLATE)
	Kit.box(root, "Clock tower ledge", tc + Vector3(0, 18.4, 0), Vector3(3.4, 0.2, 3.4), Color("6e5a46"))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Kit.box(root, "Lantern post", tc + Vector3(sx * 1.35, 19.6, sz * 1.35), Vector3(0.3, 2.2, 0.3), CREAM)
	Kit.box(root, "Lantern louvres", tc + Vector3(0, 19.2, 0), Vector3(2.5, 1.4, 2.5), Color("8a7a5a"))
	Kit.box(root, "Lantern top", tc + Vector3(0, 20.8, 0), Vector3(3.3, 0.25, 3.3), Color("6e5a46"))
	for k in range(4):
		var cf := Kit.face(root, tc + Vector3(sin(k * PI * 0.5), 0, cos(k * PI * 0.5)) * 1.66, k * 90.0)
		Kit.cyl(cf, "Clock face", Vector3(0, 19.95, 0.03), 0.62, 0.62, 0.06, Color("24305a"), 20, "z")
		Kit.box(cf, "Clock hand", Vector3(0.12, 20.1, 0.08), Vector3(0.07, 0.42, 0.03), Color("e2b84a"))
		Kit.box(cf, "Clock hand", Vector3(0.2, 19.9, 0.08), Vector3(0.38, 0.06, 0.03), Color("e2b84a"))
	Kit.pyramid(root, "Clock tower spire", tc + Vector3(0, 20.9, 0), 1.65, 4.2, SLATE)
	Kit.cyl(root, "Vane rod", tc + Vector3(0, 26.0, 0), 0.04, 0.04, 2.0, Color("3a3a3a"), 6)
	Kit.box(root, "Vane", tc + Vector3(0.35, 26.6, 0), Vector3(0.9, 0.35, 0.04), Color("3a3a3a"))
	Kit.box(root, "Vane cross", tc + Vector3(0, 26.2, 0), Vector3(0.6, 0.04, 0.6), Color("3a3a3a"))

# Bollenfontein: vierkante bak met kiezels en palen met gele bollen.
func _bulb_fountain(c: Vector3) -> void:
	Kit.box(root, "Bulb fountain rim", c + Vector3(0, 0.2, 0), Vector3(6.6, 0.4, 6.6), Color("8a8c8e"), true)
	Kit.box(root, "Bulb fountain pebbles", c + Vector3(0, 0.42, 0), Vector3(6.0, 0.06, 6.0), Color("b8b0a2"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var bulb := SphereMesh.new()
	bulb.radius = 0.45
	bulb.height = 0.75
	bulb.radial_segments = 10
	bulb.rings = 5
	var bm := Kit.mat(Color("ecd294"), 0.08)
	for i in range(5):
		for j in range(5):
			if (i + j) % 2 == 1 and rng.randf() < 0.4:
				continue
			var p := c + Vector3(-2.4 + float(i) * 1.2 + rng.randf_range(-0.2, 0.2), 0, -2.4 + float(j) * 1.2 + rng.randf_range(-0.2, 0.2))
			# hoger naar het midden toe, als een piramide
			var mid: float = 2.0 - maxf(absf(float(i) - 2.0), absf(float(j) - 2.0))
			var h: float = 1.3 + mid * 1.25 + rng.randf_range(-0.2, 0.3)
			Kit.cyl(root, "Bulb pole", p + Vector3(0, h * 0.5, 0), 0.04, 0.04, h, Color("6a6c6e"), 5)
			var b := MeshInstance3D.new()
			b.mesh = bulb
			b.material_override = bm
			b.position = p + Vector3(0, h + 0.3, 0)
			root.add_child(b)

