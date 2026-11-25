extends Node3D
# Kasteel De Bongard (Simpelveld), naar jouw foto's (25-11). Gevels in brede horizontale
# banden: rode baksteen afgewisseld met lichte mergel/zandsteen; grijze hardstenen
# hoekblokken, vensteromlijstingen en waterlijsten. Witte kruisvensters.
# - hoofdblok met een hoog leien schilddak, schoorsteen en dakraampjes
# - links vooraan een dikke ronde toren met een leien kegeldak en een spitsje
# - rechts een iets hoger poortgebouw met een rondboogpoort in een hardstenen omlijsting
#   (met een wapensteen erboven) en een houten deur
# - voor de poort een brug met lage bakstenen muurtjes, grote gebeeldhouwde stenen
#   blokken aan het eind en bloempotten met rode geraniums
# - twee stenen bollen op sokkels, een treurwilg rechts, een gazon en een wei met een
#   draadhek langs de weg
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const BLUESTONE := Color("6e7176")
const SLATE := Color("3a3e45")
const FRAME := Color("eeeeea")
const GLASS := Color("2c3236")

var stripes: Material
var stripes_2s: Material

func _ready() -> void:
	name = "Kasteel De Bongard"
	stripes = Kit.tex_mat_tiles("res://assets/bongard_stripes.png", Vector2(1.6, 0.8))
	Kit.box(self, "Bongard lawn", Vector3(0, 0.03, 0), Vector3(56.0, 0.06, 46.0), Color("6f9a4a"))
	_main_block(Vector3(-1.0, 0, -8.0))
	_tower(Vector3(-9.5, 0, -2.5))
	_gatehouse(Vector3(8.5, 0, -7.4))
	_bridge(Vector3(8.5, 0, 0.0))
	for x in [1.5, 4.5]:
		Kit.box(self, "Ball plinth", Vector3(x, 0.4, 4.5), Vector3(0.5, 0.8, 0.5), BLUESTONE)
		var ball := Kit.cyl(self, "Stone ball", Vector3(x, 1.25, 4.5), 0.45, 0.45, 0.9, Color("7c7a74"), 12)
		ball.scale = Vector3(1.0, 1.0, 1.0)
	_willow(Vector3(17.0, 0, 2.0))
	_shed(Vector3(-20.0, 0, 6.0))
	_fence(19.5)

func _walls(c: Vector3, size: Vector3) -> void:
	Kit.box(self, "Striped wall", c + Vector3(0, size.y * 0.5, 0), size, Color.WHITE, true, stripes)
	# grijze hardstenen hoekblokken (verspringend)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var y := 0.4
			var k := 0
			while y < size.y - 0.3:
				var long: bool = k % 2 == 0
				var p: Vector3 = c + Vector3(sx * (size.x * 0.5 - (0.35 if long else 0.2)), y, sz * (size.z * 0.5 + 0.02))
				Kit.box(self, "Quoin", p, Vector3(0.7 if long else 0.4, 0.38, 0.06), BLUESTONE)
				y += 0.8
				k += 1
	# waterlijst tussen de verdiepingen
	Kit.box(self, "String course", c + Vector3(0, size.y * 0.47, 0), Vector3(size.x + 0.12, 0.16, size.z + 0.12), BLUESTONE)
	Kit.box(self, "Plinth", c + Vector3(0, 0.3, 0), Vector3(size.x + 0.1, 0.6, size.z + 0.1), Color("6a625a"))

# Kruisvenster met hardstenen omlijsting en kleine "oortjes" bovenaan.
func _window(f: Node3D, x: float, y: float, w := 1.1, h := 1.6, cross := true) -> void:
	Kit.box(f, "Window surround", Vector3(x, y + h * 0.5, 0.03), Vector3(w + 0.5, h + 0.5, 0.08), BLUESTONE)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.07), Vector3(w, h, 0.04), GLASS)
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.1), Vector3(0.08, h, 0.03), FRAME if cross else GLASS)
	Kit.box(f, "Window transom", Vector3(x, y + h * 0.62, 0.1), Vector3(w, 0.08, 0.03), FRAME)
	Kit.box(f, "Window head", Vector3(x, y + h + 0.32, 0.05), Vector3(w + 0.9, 0.14, 0.1), BLUESTONE)

func _hip_roof(c: Vector3, w: float, d: float, rise: float) -> void:
	var hx: float = w * 0.5 + 0.35
	var hz: float = d * 0.5 + 0.35
	var r: float = maxf(0.0, hx - hz)
	var t: Array = []
	var a := Vector3(-r, rise, 0)
	var b := Vector3(r, rise, 0)
	Kit._quad(t, Vector3(-hx, 0, hz), Vector3(hx, 0, hz), b, a)
	Kit._quad(t, Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), a, b)
	t.append_array([Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), a])
	t.append_array([Vector3(hx, 0, hz), Vector3(hx, 0, -hz), b])
	var roof := MeshInstance3D.new()
	roof.name = "Slate roof"
	roof.mesh = Kit._mesh_from(t, Kit._two_sided(SLATE))
	roof.position = c
	add_child(roof)
	Kit.box(self, "Eaves", c + Vector3(0, -0.08, 0), Vector3(w + 0.6, 0.18, d + 0.6), Color("4a4d52"))

func _main_block(c: Vector3) -> void:
	var w := 13.0
	var d := 11.0
	var h := 9.6
	_walls(c, Vector3(w, h, d))
	_hip_roof(c + Vector3(0, h, 0), w, d, 6.2)
	Kit.box(self, "Chimney", c + Vector3(1.5, h + 6.0, -1.0), Vector3(1.0, 2.4, 1.0), Color("7a4a3a"))
	for x in [-3.0, 3.5]:
		Kit.box(self, "Roof light", c + Vector3(x, h + 2.4, d * 0.5 - 1.6), Vector3(0.6, 0.06, 0.5), Color("cfd6da"))
	var f := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	for x in [-1.5, 2.8]:
		_window(f, x, 1.6, 1.1, 1.7)
		_window(f, x, 6.0, 1.1, 1.7)
	_window(f, 5.4, 6.4, 0.5, 1.0, false)
	for s in [-1.0, 1.0]:
		var sf := Kit.face(self, c + Vector3(s * w * 0.5, 0, 0), 90.0 * s)
		for x in [-2.6, 0.4, 3.2]:
			_window(sf, x, 1.6, 1.1, 1.7)
			_window(sf, x, 6.0, 1.1, 1.7)
	# achtergevel
	var bf := Kit.face(self, c + Vector3(0, 0, -d * 0.5), 180.0)
	for x in [-3.0, 0.0, 3.0]:
		_window(bf, x, 6.0, 1.1, 1.7)

func _tower(c: Vector3) -> void:
	var r := 3.9
	var h := 11.4
	Kit.cyl(self, "Round tower", c + Vector3(0, h * 0.5, 0), r, r, h, Color.WHITE, 24, "y", true, stripes)
	Kit.cyl(self, "Tower plinth", c + Vector3(0, 0.3, 0), r + 0.08, r + 0.08, 0.6, Color("6a625a"), 24)
	for y in [4.5, 9.0]:
		Kit.cyl(self, "Tower string course", c + Vector3(0, y, 0), r + 0.07, r + 0.07, 0.16, BLUESTONE, 24)
	Kit.cyl(self, "Tower cornice", c + Vector3(0, h + 0.1, 0), r + 0.3, r + 0.3, 0.25, Color("4a4d52"), 24)
	# leien kegeldak, onderaan iets uitlopend, met spitsje
	Kit.cyl(self, "Tower roof skirt", c + Vector3(0, h + 0.5, 0), r + 0.35, r - 0.2, 0.6, SLATE, 24)
	Kit.cyl(self, "Tower roof", c + Vector3(0, h + 3.3, 0), r - 0.2, 0.15, 5.0, SLATE, 24)
	Kit.cyl(self, "Tower finial", c + Vector3(0, h + 6.4, 0), 0.05, 0.03, 1.4, Color("8a8f94"), 6)
	# vensters naar de weg en opzij, en kleine schietgaatjes bovenaan
	for a in [0.0, -55.0, 40.0]:
		var dir := Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
		var f := Kit.face(self, c + dir * (r - 0.02), a)
		_window(f, 0.0, 2.0, 0.6, 1.5, false)
		_window(f, 0.0, 6.6, 0.6, 1.5)
	for k in range(10):
		var a: float = float(k) * 36.0
		var dir := Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
		var f := Kit.face(self, c + dir * (r + 0.01), a)
		Kit.box(f, "Loophole", Vector3(0, h - 0.7, 0.02), Vector3(0.22, 0.32, 0.04), Color("2a2622"))

func _gatehouse(c: Vector3) -> void:
	var w := 6.0
	var d := 10.0
	var h := 10.4
	_walls(c, Vector3(w, h, d))
	_hip_roof(c + Vector3(0, h, 0), w, d, 4.6)
	var f := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	# poort: hardstenen omlijsting, rondboog, houten deur, wapensteen erboven
	Kit.box(f, "Gate surround", Vector3(0, 1.75, 0.06), Vector3(3.2, 3.5, 0.14), BLUESTONE)
	Kit.box(f, "Gate opening", Vector3(0, 1.3, 0.1), Vector3(1.9, 2.6, 0.08), Color("8a5634"))
	Kit.cyl(f, "Gate arch", Vector3(0, 2.6, 0.1), 0.95, 0.95, 0.08, Color("8a5634"), 16, "z")
	for x in [-0.45, 0.45]:
		Kit.box(f, "Gate plank", Vector3(x, 1.5, 0.15), Vector3(0.05, 3.0, 0.03), Color("6a3f24"))
	Kit.box(f, "Coat of arms", Vector3(0, 4.15, 0.06), Vector3(1.6, 0.9, 0.12), Color("b8b2a4"))
	Kit.box(f, "Arms frame", Vector3(0, 4.15, 0.04), Vector3(2.0, 1.2, 0.08), BLUESTONE)
	_window(f, 0.0, 6.0, 1.1, 1.7)
	_window(f, -1.9, 8.4, 0.5, 0.9, false)

# Brug met lage muurtjes naar de poort, met gebeeldhouwde stenen blokken aan het eind.
func _bridge(c: Vector3) -> void:
	Kit.box(self, "Bridge paving", c + Vector3(0, 0.05, 2.5), Vector3(3.2, 0.1, 7.0), Color("9a8070"))
	for sx in [-1.0, 1.0]:
		Kit.box(self, "Bridge wall", c + Vector3(sx * 1.9, 0.55, 2.4), Vector3(0.5, 1.1, 6.8), Color("8a6a58"), true)
		Kit.box(self, "Bridge coping", c + Vector3(sx * 1.9, 1.15, 2.4), Vector3(0.62, 0.12, 6.9), Color("8a8a86"))
		Kit.box(self, "Carved block", c + Vector3(sx * 1.9, 1.5, 5.9), Vector3(0.9, 0.7, 1.1), Color("b6b2a8"))
		for k in range(3):
			Kit.box(self, "Carving", c + Vector3(sx * 1.9, 1.3 + float(k) * 0.2, 6.46), Vector3(0.8, 0.06, 0.03), Color("8e8a82"))
		# bloempot met rode geraniums
		var pp: Vector3 = c + Vector3(sx * 2.9, 0, 6.4)
		Kit.cyl(self, "Flower pot", pp + Vector3(0, 0.3, 0), 0.32, 0.25, 0.6, Color("9a5a3a"), 10)
		Kit.cyl(self, "Geraniums", pp + Vector3(0, 0.75, 0), 0.42, 0.3, 0.35, Color("d8323a"), 10)
	# lage borders met struiken langs de gevel
	Kit.box(self, "Shrubs", Vector3(-1.0, 0.5, -1.8), Vector3(10.0, 1.0, 1.4), Color("4e7a38"))

func _willow(p: Vector3) -> void:
	Kit.cyl(self, "Willow trunk", p + Vector3(0, 2.2, 0), 0.5, 0.4, 4.4, Color("5b4c3e"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 3.2
	cm.height = 3.4
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("7f9a44"))
	cr.position = p + Vector3(0, 7.0, 0)
	add_child(cr)
	# hangende takken: losse smalle slierten rondom (één mesh), verschillend lang
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var t: Array = []
	for i in range(44):
		var a: float = float(i) / 44.0 * TAU + rng.randf_range(-0.05, 0.05)
		var r: float = rng.randf_range(2.6, 4.4)
		var top: float = rng.randf_range(6.6, 7.6)
		var bot: float = rng.randf_range(1.0, 3.2)
		var c := Vector3(sin(a) * r, 0, cos(a) * r)
		var side := Vector3(cos(a), 0, -sin(a)) * rng.randf_range(0.25, 0.45)
		var out := Vector3(sin(a), 0, cos(a)) * 0.6
		Kit._quad(t, c - side + Vector3(0, top, 0), c + side + Vector3(0, top, 0), c + side + out + Vector3(0, bot, 0), c - side + out + Vector3(0, bot, 0))
	var strands := MeshInstance3D.new()
	strands.name = "Willow strands"
	strands.mesh = Kit._mesh_from(t, Kit._two_sided(Color("9ab456")))
	strands.position = p
	add_child(strands)

func _shed(p: Vector3) -> void:
	Kit.box(self, "Brick shed", p + Vector3(0, 1.4, 0), Vector3(5.0, 2.8, 4.0), Color("8a5a46"), true)
	Kit.gable(self, "Shed roof", p + Vector3(0, 2.8, 0), 5.4, 4.4, 1.2, Color("3f7a4a"), true)

# Draadhek met houten paaltjes langs de weg (de wei voor het kasteel).
func _fence(z: float) -> void:
	var x := -26.0
	while x <= 26.0:
		var post := Kit.box(self, "Fence post", Vector3(x, 0.6, z), Vector3(0.12, 1.2, 0.12), Color("7a6a54"))
		post.rotation_degrees.z = 3.0 if int(x) % 2 == 0 else -2.0
		x += 3.0
	for y in [0.55, 1.0]:
		Kit.box(self, "Fence wire", Vector3(0, y, z), Vector3(52.0, 0.03, 0.03), Color("9a9a96"))
