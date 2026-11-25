extends Node3D
# Kasteel Amstenrade (Beekdaelen), naar jouw foto's (25-11). Groot barok kasteel van
# oranjerode baksteen met grijze hardstenen lisenen (verticale stroken), banden en
# vensteromlijstingen; drie bouwlagen met hoge witte ramen, op de begane grond van het
# middendeel drie rondboogdeuren. Leien mansardedak met dakkapellen en rode schoorstenen.
# In het midden een licht vooruitspringend deel met een driehoekig fronton met een rond
# venster. Links een vleugel naar voren, met in de hoek een toren met een uurwerk, een
# leien koepel en een witte lantaarn met een koepeltje en windvaan. Ervoor een groot
# grindplein, en aan de straat twee hekpijlers van baksteen met hardstenen banden en een
# stenen bol erop, een lage balustrade en een zwart hek.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const BRICK := Color("c4683e")
const STONE := Color("8a8a84")
const SLATE := Color("454a52")
const FRAME := Color("f2f2ee")
const GLASS := Color("2c3438")

const H := 13.5            # tot de kroonlijst
const FLOORS := [0.9, 5.2, 9.4]

func _ready() -> void:
	name = "Kasteel Amstenrade"
	Kit.box(self, "Gravel court", Vector3(0, 0.03, 4), Vector3(64, 0.06, 40), Color("c8c0ae"))
	_block(Vector3(4, 0, -14), 32.0, 14.0, true)
	_block(Vector3(-17, 0, -4), 12.0, 34.0, false)
	_tower(Vector3(-11, 0, -11))
	_gate(18.5)
	for p in [Vector3(-28, 0, 16), Vector3(26, 0, -4), Vector3(28, 0, 14), Vector3(-26, 0, -24)]:
		_tree(p)

func _window(f: Node3D, x: float, y: float, w := 1.3, h := 2.6, door := false) -> void:
	Kit.box(f, "Window surround", Vector3(x, y + h * 0.5, 0.03), Vector3(w + 0.5, h + 0.45, 0.07), STONE)
	if door:
		_door(f, x, y, w, h)
		return
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.07), Vector3(w, h, 0.04), GLASS)
	Kit.box(f, "Window bar", Vector3(x, y + h * 0.5, 0.1), Vector3(0.07, h, 0.03), FRAME)
	Kit.box(f, "Window bar", Vector3(x, y + h * 0.66, 0.1), Vector3(w, 0.07, 0.03), FRAME)

# Openslaande glasdeur met rondboog (naar jouw foto, 25-11): wit kozijn, twee glazen
# deurvleugels met roedes, en een halfrond bovenlicht met glas.
func _door(f: Node3D, x: float, y: float, w: float, h: float) -> void:
	var r: float = w * 0.5
	# boog: stenen omlijsting, wit kozijn en glas (onderste helft valt achter de deur)
	Kit.cyl(f, "Door arch surround", Vector3(x, y + h, 0.03), r + 0.25, r + 0.25, 0.07, STONE, 16, "z")
	Kit.cyl(f, "Door arch frame", Vector3(x, y + h, 0.06), r, r, 0.04, FRAME, 16, "z")
	Kit.cyl(f, "Door arch glass", Vector3(x, y + h, 0.075), r - 0.12, r - 0.12, 0.03, GLASS, 16, "z")
	for a in [-0.6, 0.0, 0.6]:
		var bar := Kit.box(f, "Fanlight bar", Vector3(x + sin(a) * r * 0.45, y + h + cos(a) * r * 0.45, 0.095), Vector3(0.05, r * 0.9, 0.02), FRAME)
		bar.rotation.z = -a
	# deur: wit kozijn, glas, middenstijl en roedes
	Kit.box(f, "Door frame", Vector3(x, y + h * 0.5, 0.09), Vector3(w, h, 0.04), FRAME)
	Kit.box(f, "Door glass", Vector3(x, y + h * 0.5 + 0.1, 0.115), Vector3(w - 0.24, h - 0.5, 0.02), GLASS)
	Kit.box(f, "Door panel", Vector3(x, y + 0.2, 0.115), Vector3(w - 0.24, 0.3, 0.02), FRAME)
	Kit.box(f, "Door stile", Vector3(x, y + h * 0.5, 0.13), Vector3(0.09, h, 0.02), FRAME)
	Kit.box(f, "Door transom", Vector3(x, y + h - 0.05, 0.13), Vector3(w, 0.1, 0.02), FRAME)
	for k in range(1, 4):
		Kit.box(f, "Door bar", Vector3(x, y + 0.35 + (h - 0.5) * float(k) / 4.0, 0.13), Vector3(w - 0.24, 0.04, 0.02), FRAME)

# Rechthoekig blok met mansardedak; front = de lange zijde naar +Z (of +X voor de vleugel).
func _block(c: Vector3, w: float, d: float, main: bool) -> void:
	Kit.box(self, "Castle block", c + Vector3(0, H * 0.5, 0), Vector3(w, H, d), BRICK, true)
	Kit.box(self, "Plinth", c + Vector3(0, 0.45, 0), Vector3(w + 0.15, 0.9, d + 0.15), STONE)
	Kit.box(self, "Cornice", c + Vector3(0, H + 0.15, 0), Vector3(w + 0.6, 0.3, d + 0.6), STONE)
	Kit.box(self, "Floor band", c + Vector3(0, 4.85, 0), Vector3(w + 0.1, 0.2, d + 0.1), STONE)
	# mansardedak: steil onderdeel en een flauwe bovenkant
	Kit.frustum(self, "Mansard", c + Vector3(0, H + 0.3, 0), w + 0.4, d + 0.4, 1.0, 2.6, SLATE)
	Kit.frustum(self, "Mansard top", c + Vector3(0, H + 2.9, 0), w - 1.6, d - 1.6, minf(w, d) * 0.5 - 0.8, 1.6, SLATE)
	for e in [[-w * 0.38, -d * 0.2], [w * 0.38, d * 0.2], [0.0, -d * 0.3]]:
		# van de kroonlijst door het dak omhoog, zodat hij nergens boven het dak zweeft
		Kit.box(self, "Chimney", c + Vector3(e[0], H + 2.9, e[1]), Vector3(1.0, 5.2, 0.8), Color("a0482e"))
		Kit.box(self, "Chimney cap", c + Vector3(e[0], H + 5.6, e[1]), Vector3(1.2, 0.2, 1.0), STONE)
	var yaw := 0.0 if main else 90.0
	var fw: float = w if main else d
	var fpos: Vector3 = c + (Vector3(0, 0, d * 0.5) if main else Vector3(w * 0.5, 0, 0))
	var f := Kit.face(self, fpos, yaw)
	var n: int = 9 if main else 7
	var step: float = (fw - 3.0) / float(n - 1)
	for i in range(n):
		var x: float = -fw * 0.5 + 1.5 + float(i) * step
		# lisenen tussen de traveeën
		if i < n - 1:
			Kit.box(f, "Pilaster", Vector3(x + step * 0.5, H * 0.5, 0.04), Vector3(0.6, H, 0.08), STONE)
		var mid: bool = main and absi(i - 4) <= 1
		_window(f, x, FLOORS[0], 1.3, 2.9, mid)
		_window(f, x, FLOORS[1], 1.3, 2.7)
		_window(f, x, FLOORS[2], 1.2, 2.3)
		# dakkapel boven elke tweede travee
		if i % 2 == 0:
			Kit.box(f, "Dormer", Vector3(x, H + 1.5, -0.4), Vector3(1.2, 1.6, 0.8), FRAME)
			Kit.box(f, "Dormer roof", Vector3(x, H + 2.45, -0.4), Vector3(1.5, 0.3, 1.0), SLATE)
	if not main:
		# kopgevel naar de weg (+Z): twee ramen per verdieping tussen hoeklisenen (jouw foto)
		var ef := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
		for x in [-w * 0.5 + 0.35, w * 0.5 - 0.35]:
			Kit.box(ef, "Corner pilaster", Vector3(x, H * 0.5, 0.04), Vector3(0.7, H, 0.08), STONE)
		for x in [-2.2, 2.2]:
			_window(ef, x, FLOORS[0], 1.3, 2.9)
			_window(ef, x, FLOORS[1], 1.3, 2.7)
			_window(ef, x, FLOORS[2], 1.2, 2.3)
		Kit.box(ef, "Dormer", Vector3(0, H + 1.5, -0.4), Vector3(1.2, 1.6, 0.8), FRAME)
		Kit.box(ef, "Dormer roof", Vector3(0, H + 2.45, -0.4), Vector3(1.5, 0.3, 1.0), SLATE)
	if main:
		# middenrisaliet met fronton en rond venster
		Kit.box(self, "Risalit", c + Vector3(0, H * 0.5, d * 0.5 + 0.3), Vector3(step * 3.0 + 1.0, H, 0.6), BRICK)
		var rf := Kit.face(self, c + Vector3(0, 0, d * 0.5 + 0.6), 0.0)
		for i in range(3, 6):
			var x: float = -fw * 0.5 + 1.5 + float(i) * step
			_window(rf, x, FLOORS[0], 1.3, 2.9, true)
			_window(rf, x, FLOORS[1], 1.3, 2.7)
			_window(rf, x, FLOORS[2], 1.2, 2.3)
		var pw: float = step * 3.0 + 1.6
		var t: Array = [Vector3(-pw * 0.5, H + 0.3, 0.0), Vector3(pw * 0.5, H + 0.3, 0.0), Vector3(0, H + 3.0, 0.0)]
		var g := MeshInstance3D.new()
		g.mesh = Kit._mesh_from(t, Kit._two_sided(Color("a8a69e")))
		rf.add_child(g)
		Kit.cyl(rf, "Oculus rim", Vector3(0, H + 1.3, 0.05), 0.6, 0.6, 0.08, STONE, 16, "z")
		Kit.cyl(rf, "Oculus", Vector3(0, H + 1.3, 0.09), 0.42, 0.42, 0.04, GLASS, 16, "z")
		Kit.box(self, "Front steps", c + Vector3(0, 0.25, d * 0.5 + 1.6), Vector3(step * 3.0, 0.5, 1.6), STONE)

func _tower(c: Vector3) -> void:
	var s := 6.0
	var h := 19.0
	Kit.box(self, "Tower", c + Vector3(0, h * 0.5, 0), Vector3(s, h, s), BRICK, true)
	Kit.box(self, "Tower cornice", c + Vector3(0, h + 0.15, 0), Vector3(s + 0.5, 0.3, s + 0.5), STONE)
	for k in range(4):
		var a: float = float(k) * 90.0
		var dir := Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
		var f := Kit.face(self, c + dir * (s * 0.5), a)
		Kit.cyl(f, "Clock", Vector3(0, h - 1.6, 0.05), 0.85, 0.85, 0.08, FRAME, 20, "z")
		Kit.cyl(f, "Clock rim", Vector3(0, h - 1.6, 0.02), 1.05, 1.05, 0.06, STONE, 20, "z")
		Kit.box(f, "Clock hand", Vector3(0, h - 1.4, 0.11), Vector3(0.06, 0.5, 0.02), Color("1e1e20"))
		for x in [-s * 0.5 + 0.3, s * 0.5 - 0.3]:
			Kit.box(f, "Tower quoin", Vector3(x, h * 0.5, 0.03), Vector3(0.6, h, 0.06), STONE)
	# leien koepel, witte lantaarn, koepeltje, windvaan
	Kit.cyl(self, "Dome", c + Vector3(0, h + 1.6, 0), s * 0.62, s * 0.3, 3.0, SLATE, 16)
	Kit.cyl(self, "Dome top", c + Vector3(0, h + 3.4, 0), s * 0.3, s * 0.2, 0.6, SLATE, 16)
	Kit.cyl(self, "Lantern", c + Vector3(0, h + 4.8, 0), 1.1, 1.1, 2.2, FRAME, 12)
	for k in range(6):
		var a: float = float(k) * TAU / 6.0
		var wf := Kit.face(self, c + Vector3(sin(a) * 1.12, 0, cos(a) * 1.12), rad_to_deg(a))
		Kit.box(wf, "Lantern opening", Vector3(0, h + 4.8, 0.01), Vector3(0.45, 1.3, 0.03), Color("3a3e44"))
	Kit.cyl(self, "Lantern dome", c + Vector3(0, h + 6.3, 0), 1.25, 0.2, 0.9, SLATE, 12)
	Kit.cyl(self, "Lantern ball", c + Vector3(0, h + 6.9, 0), 0.2, 0.2, 0.3, Color("8a8e92"), 8)
	Kit.box(self, "Vane", c + Vector3(0, h + 7.7, 0), Vector3(0.05, 1.4, 0.05), Color("2a2a2a"))
	Kit.box(self, "Vane flag", c + Vector3(0.3, h + 8.1, 0), Vector3(0.6, 0.3, 0.02), Color("2a2a2a"))

# Hekpijlers met stenen bollen, balustrade en hek langs de straat.
func _gate(z: float) -> void:
	for sx in [-1.0, 1.0]:
		var p := Vector3(sx * 3.2, 0, z)
		# naar jouw foto: lichtgrijze natuursteen met smalle, gedempte baksteenbanden,
		# een geprofileerde kap en een stenen bol op een halsje
		var pale := Color("a9a69e")
		var band := Color("8d6f62")
		Kit.box(self, "Gate pillar", p + Vector3(0, 1.8, 0), Vector3(1.0, 3.6, 1.0), pale, true)
		Kit.box(self, "Pillar base", p + Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 1.2), Color("9a978f"))
		for k in range(5):
			Kit.box(self, "Pillar band", p + Vector3(0, 1.0 + float(k) * 0.55, 0), Vector3(1.02, 0.2, 1.02), band)
		Kit.box(self, "Pillar cap", p + Vector3(0, 3.7, 0), Vector3(1.25, 0.2, 1.25), pale)
		Kit.box(self, "Pillar cap", p + Vector3(0, 3.88, 0), Vector3(1.05, 0.16, 1.05), pale)
		Kit.cyl(self, "Pillar neck", p + Vector3(0, 4.1, 0), 0.3, 0.2, 0.3, pale, 10)
		var ball := MeshInstance3D.new()
		ball.name = "Pillar ball"
		var bm := SphereMesh.new()
		bm.radius = 0.36
		bm.height = 0.72
		bm.radial_segments = 14
		bm.rings = 7
		ball.mesh = bm
		ball.material_override = Kit.mat(pale)
		ball.position = p + Vector3(0, 4.55, 0)
		add_child(ball)
		# balustrade en hek naar de zijkant
		var a: float = sx * 3.8
		var b: float = sx * 30.0
		Kit.box(self, "Garden wall", Vector3((a + b) * 0.5, 0.45, z), Vector3(absf(b - a), 0.9, 0.5), Color("b4b0a4"), true)
		Kit.box(self, "Railing", Vector3((a + b) * 0.5, 1.6, z), Vector3(absf(b - a), 0.05, 0.05), Color("2a2a2c"))
		var x := a
		while absf(x) < absf(b):
			Kit.box(self, "Railing spear", Vector3(x, 1.3, z), Vector3(0.04, 0.85, 0.04), Color("2a2a2c"))
			x += sx * 0.35
		Kit.box(self, "Balustrade", Vector3(sx * 2.0, 0.6, z - 2.0), Vector3(0.4, 1.2, 4.0), Color("8e8a80"))

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 3.5, 0), 0.5, 0.4, 7.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 5.5
	cm.height = 9.0
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("4f7a36"))
	cr.position = p + Vector3(0, 10.0, 0)
	add_child(cr)
