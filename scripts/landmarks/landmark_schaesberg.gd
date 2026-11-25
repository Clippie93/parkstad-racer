extends Node3D
# Slot Schaesberg (Landgraaf), naar jouw foto's (23-11): een kasteelruïne in een vijver.
# - een hoge vierkante toren waarvan de voor- en achtermuur grotendeels zijn ingestort: je
#   kijkt tussen twee hoge muurresten met rafelige bovenkanten in, met natuurstenen
#   hoekblokken; daarin een zwarte stalen trappentoren met kruisverbanden en een vlag erop
# - lagere ruïnemuren met kantelen en een stenen kruisvenster, kleine gaten in de muren
# - rondom een lage ommuring op het eiland met een loopbrug met donkere reling, een brug met
#   een boog naar de oever, en aan de overkant een rood gebouwtje
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const STONE := Color("d4cbb8")
const STEEL := Color("1d1f22")
const RAIL := Color("3a3430")
const WATER := Color("3d5a52")

var brick: Material

func _ready() -> void:
	name = "Slot Schaesberg"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("b48878"), 3.0)
	Kit.box(self, "Ruin park", Vector3(0, 0.03, 0), Vector3(90.0, 0.06, 70.0), Color("6d9a4c"))
	Kit.box(self, "Pond", Vector3(0, 0.07, -6), Vector3(72.0, 0.06, 52.0), Color.WHITE, false, Kit.mat(WATER, 0.0, 0.25, 0.12))
	_island()
	_tower(Vector3(8, 0, -10))
	_low_ruin()
	_bridge()
	_red_house(Vector3(-34, 0, -26))
	for p in [Vector3(-38, 0, 14), Vector3(38, 0, 14), Vector3(40, 0, -20), Vector3(-20, 0, -36), Vector3(24, 0, -36)]:
		_tree(p)

# Lage ommuring van het eiland (baksteen met lichte stroken), met een loopbrug erop.
func _island() -> void:
	var c := Vector3(0, 0, -8)
	var w := 34.0
	var d := 26.0
	var h := 4.0
	for side in [[Vector3(0, 0, d * 0.5), Vector3(w, h, 1.4)], [Vector3(0, 0, -d * 0.5), Vector3(w, h, 1.4)],
			[Vector3(-w * 0.5, 0, 0), Vector3(1.4, h, d)], [Vector3(w * 0.5, 0, 0), Vector3(1.4, h, d)]]:
		Kit.box(self, "Island wall", c + side[0] + Vector3(0, h * 0.5, 0), side[1], Color.WHITE, true, brick)
		Kit.box(self, "Wall band", c + side[0] + Vector3(0, 1.2, 0), side[1] * Vector3(1.01, 0.08, 1.01), STONE)
	Kit.box(self, "Island inside", c + Vector3(0, h - 0.3, 0), Vector3(w - 2.6, 0.1, d - 2.6), Color("8a8a66"))
	# loopbrug met reling bovenop de muren (voorkant en zijkanten)
	for r in [[Vector3(0, h + 0.55, d * 0.5 + 0.5), Vector3(w, 0.07, 0.07)], [Vector3(-w * 0.5 - 0.5, h + 0.55, 0), Vector3(0.07, 0.07, d)],
			[Vector3(w * 0.5 + 0.5, h + 0.55, 0), Vector3(0.07, 0.07, d)]]:
		Kit.box(self, "Walkway rail", c + r[0], r[1], RAIL)
	var x := -w * 0.5
	while x <= w * 0.5:
		Kit.box(self, "Rail post", c + Vector3(x, h + 0.3, d * 0.5 + 0.5), Vector3(0.08, 0.6, 0.08), RAIL)
		x += 2.0
	# kleine gaten in de muren
	for gx in [-12.0, -7.0, -2.0, 11.0, 14.0]:
		Kit.box(self, "Wall hole", c + Vector3(gx, 2.2, d * 0.5 + 0.72), Vector3(0.35, 0.35, 0.05), Color("2a2622"))

# Hoge toren met twee hoge zijmuren en grotendeels ingestorte voor- en achtermuur.
func _tower(c: Vector3) -> void:
	var w := 9.0
	var t := 1.5
	# zijmuren met een rafelige bovenkant (in trappen)
	for sx in [-1.0, 1.0]:
		var x: float = sx * (w * 0.5 - t * 0.5)
		var top: float = 22.0 if sx < 0.0 else 21.0
		Kit.box(self, "Tower side wall", c + Vector3(x, top * 0.5, 0), Vector3(t, top, w), Color.WHITE, true, brick)
		for k in range(3):
			var hh: float = top + 0.6 - float(k) * 0.7
			Kit.box(self, "Ragged top", c + Vector3(x, hh, -w * 0.5 + 1.5 + float(k) * 2.6), Vector3(t, 1.2, 1.4), Color.WHITE, false, brick)
		# hoekblokken
		for sz in [-1.0, 1.0]:
			var y := 1.0
			var k := 0
			while y < top - 1.0:
				var l: float = 1.0 if k % 2 == 0 else 0.55
				Kit.box(self, "Quoin", c + Vector3(sx * (w * 0.5 + 0.02), y, sz * (w * 0.5 - l * 0.5 + 0.02)), Vector3(0.08, 0.5, l), STONE)
				y += 0.65
				k += 1
	# voormuur tot halverwege, met een gebroken trapvormige bovenkant
	Kit.box(self, "Tower front low", c + Vector3(0, 4.5, w * 0.5 - t * 0.5), Vector3(w, 9.0, t), Color.WHITE, true, brick)
	for k in range(3):
		Kit.box(self, "Front rubble step", c + Vector3(1.5 + float(k) * 1.2, 9.5 + float(k) * 1.1, w * 0.5 - t * 0.5), Vector3(3.0 - float(k) * 0.6, 1.1, t), Color.WHITE, false, brick)
	Kit.box(self, "Tower back low", c + Vector3(0, 6.0, -w * 0.5 + t * 0.5), Vector3(w, 12.0, t), Color.WHITE, true, brick)
	# zwarte stalen trappentoren erin, met kruisverbanden en bordessen
	var s: float = 3.6
	var h0 := 4.0
	var h1 := 25.0
	var corners := [Vector3(-s, 0, -s), Vector3(s, 0, -s), Vector3(s, 0, s), Vector3(-s, 0, s)]
	for k in range(4):
		var a: Vector3 = corners[k] * 0.5
		var b: Vector3 = corners[(k + 1) % 4] * 0.5
		Kit.beam(self, "Stair post", c + a + Vector3(0, h0, 0), c + a + Vector3(0, h1, 0), 0.18, STEEL)
		var y: float = h0
		while y < h1 - 0.1:
			Kit.beam(self, "Stair beam", c + a + Vector3(0, y, 0), c + b + Vector3(0, y, 0), 0.14, STEEL)
			Kit.beam(self, "Stair brace", c + a + Vector3(0, y, 0), c + b + Vector3(0, y + 3.0, 0), 0.08, STEEL)
			y += 3.0
		Kit.beam(self, "Stair beam", c + a + Vector3(0, h1, 0), c + b + Vector3(0, h1, 0), 0.14, STEEL)
	var yy := h0 + 1.5
	while yy < h1:
		Kit.box(self, "Stair landing", c + Vector3(0, yy, 0), Vector3(s - 0.3, 0.1, s - 0.3), STEEL)
		yy += 3.0
	# vlag
	Kit.cyl(self, "Flag pole", c + Vector3(0, h1 + 4.0, 0), 0.07, 0.05, 8.0, Color("d8dadc"), 6)
	Kit.box(self, "Flag", c + Vector3(1.2, h1 + 7.0, 0), Vector3(2.2, 1.4, 0.04), Color("e3b52a"))
	Kit.box(self, "Flag stripe", c + Vector3(1.2, h1 + 6.4, 0.03), Vector3(2.2, 0.35, 0.03), Color("2b5aa0"))

# Lagere ruïnemuur met kantelen en een stenen kruisvenster, links van de toren.
func _low_ruin() -> void:
	var c := Vector3(-6, 0, -6.5)
	Kit.box(self, "Ruin wall", c + Vector3(0, 4.5, 0), Vector3(12.0, 9.0, 1.4), Color.WHITE, true, brick)
	for x in [-5.0, -2.5, 0.0, 2.5, 5.0]:
		Kit.box(self, "Merlon", c + Vector3(x, 9.6, 0), Vector3(1.4, 1.2, 1.4), Color.WHITE, false, brick)
	var f := Kit.face(self, c + Vector3(0, 0, 0.72), 0.0)
	Kit.box(f, "Cross window", Vector3(-2.0, 6.8, 0.02), Vector3(1.8, 2.2, 0.06), Color("4a5a66"))
	Kit.box(f, "Cross window mullion", Vector3(-2.0, 6.8, 0.06), Vector3(0.2, 2.2, 0.06), STONE)
	Kit.box(f, "Cross window transom", Vector3(-2.0, 7.3, 0.06), Vector3(1.8, 0.2, 0.06), STONE)
	Kit.box(f, "Cross window frame", Vector3(-2.0, 6.8, 0.0), Vector3(2.1, 2.5, 0.04), STONE)

# Brug met een boog van de ommuring van het eiland (bovenop, bij de loopbrug) schuin naar
# beneden tot op de oever.
func _bridge() -> void:
	var x := -12.0
	var a := Vector3(x, 3.9, 5.7)       # bovenkant van de ommuring (voorkant eiland op z 5)
	var b := Vector3(x, 0.35, 21.5)     # oever (vijver tot z 20)
	var d: Vector3 = b - a
	var ln: float = d.length()
	var mid: Vector3 = (a + b) * 0.5
	var tilt: float = atan2(-d.y, d.z)
	var deck := Kit.box(self, "Bridge", mid, Vector3(3.2, 0.5, ln), Color.WHITE, true, brick)
	deck.rotation.x = tilt
	for s in [-1.0, 1.0]:
		var par := Kit.box(self, "Bridge parapet", mid + Vector3(s * 1.5, 0.75, 0), Vector3(0.3, 1.0, ln), Color.WHITE, false, brick)
		par.rotation.x = tilt
	# pijler met een boog in het water
	var py: float = lerpf(a.y, b.y, 0.45)
	var pz: float = lerpf(a.z, b.z, 0.45)
	Kit.box(self, "Bridge pier", Vector3(x, py * 0.5, pz), Vector3(3.2, py, 2.4), Color.WHITE, false, brick)
	Kit.box(self, "Bridge arch", Vector3(x, py * 0.45, pz + 1.22), Vector3(1.8, py * 0.7, 0.05), Color("2a2622"))
	# landhoofd op de oever
	Kit.box(self, "Bridge abutment", Vector3(x, 0.3, 21.0), Vector3(4.0, 0.6, 2.0), Color.WHITE, false, brick)

func _red_house(p: Vector3) -> void:
	Kit.box(self, "Red house", p + Vector3(0, 2.0, 0), Vector3(14.0, 4.0, 7.0), Color("b23a32"), true)
	Kit.gable(self, "Red house roof", p + Vector3(0, 4.0, 0), 7.6, 14.4, 2.6, Color("5a5d62"), true)
	for x in [-4.0, 0.0, 4.0]:
		Kit.box(self, "Red house window", p + Vector3(x, 2.0, 3.52), Vector3(1.2, 1.3, 0.05), Color("f2f2ee"))

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 3.0, 0), 0.4, 0.3, 6.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 5.0
	cm.height = 8.0
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("5a8a3c"))
	cr.position = p + Vector3(0, 8.0, 0)
	add_child(cr)
