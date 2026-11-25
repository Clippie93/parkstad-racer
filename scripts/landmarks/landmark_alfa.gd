extends Node3D
# Alfa Bierbrouwerij (Thull, Schinnen), naar jouw foto's (25-11, tweede ronde).
# - langs de weg een lage witte hal met een rood pannen-schilddak en een rode dakrand,
#   links twee garagedeuren met glazen ruitjes, rechts drie bakstenen vakken met een
#   beeld in reliëf en rode deuren ertussen; op het dak rode losse letters met de naam
#   (gewone letters, geen logo) en achter de hal een leien torenspitsje
# - een laantje naar achteren; links daarvan de witte brouwerij: een lange hal met hoge
#   rondboogramen, een kroonlijst en een buitentrap, en een hoog wit blok met een leien
#   schilddak en drie stalen schoorstenen (één dampt)
# - een witte silo met een trechter op een stalen poort over het laantje
# - achterin, met de gevels naar de weg: een wit huis met rode luiken, bloembakken en een
#   rode houten top, een bakstenen huis met twee rondboogdeuren, raampjes met hardstenen
#   lateien en bloembakken, en een witte poortschuur met rode top, rondboog en rode deur
# - op het gras een achtkantig glazen paviljoen met rode stijlen, bankjes en bomen
# - achter alles de roestvrijstalen tanks
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const WHITE := Color("f2f0ea")
const RED_TILE := Color("b4523a")
const RED := Color("b8262a")
const BRICK := Color("9a5442")
const STEEL := Color("c4c8cc")
const SLATE := Color("43474f")
const GLASS := Color("2c3438")
const STONE := Color("b4b0a6")

var steam: Node3D
var steam_t := 0.0

func _ready() -> void:
	name = "Alfa Bierbrouwerij"
	Kit.box(self, "Brewery lawn", Vector3(16, 0.03, 0.5), Vector3(26, 0.06, 13), Color("6f9a4a"))
	Kit.box(self, "Brewery yard", Vector3(-1, 0.04, -22), Vector3(62, 0.06, 52), Color("6e6c6a"))
	_front_hall(Vector3(-12, 0, -3))
	_brewhouse(Vector3(-14, 0, -24))
	_silo_portal(Vector3(2.5, 0, -27.5))
	_cluster(Vector3(14, 0, -30))
	_gazebo(Vector3(14, 0, 2))
	_tanks(Vector3(-24, 0, -40))
	for p in [Vector3(6, 0, 5), Vector3(22, 0, 5), Vector3(26, 0, -6), Vector3(7, 0, -7)]:
		_tree(p)
	for x in [10.0, 18.0]:
		Kit.box(self, "Bench", Vector3(x, 0.45, 5.0), Vector3(1.8, 0.1, 0.5), Color("8a6a4a"))

# Lage witte hal langs de weg.
func _front_hall(c: Vector3) -> void:
	var w := 22.0
	var d := 9.0
	var h := 4.6
	Kit.box(self, "Front hall", c + Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d), WHITE, true)
	Kit.box(self, "Hall plinth", c + Vector3(0, 0.2, -d * 0.5), Vector3(w + 0.1, 0.4, d + 0.1), Color("6a6662"))
	Kit.frustum(self, "Hall roof", c + Vector3(0, h, -d * 0.5), w + 1.0, d + 1.0, 3.2, 3.0, RED_TILE)
	Kit.box(self, "Red fascia", c + Vector3(0, h + 0.05, -d * 0.5), Vector3(w + 1.1, 0.25, d + 1.1), RED)
	var f := Kit.face(self, c, 0.0)
	# twee garagedeuren met glazen ruitjes, rode stijlen ertussen
	for x in [-8.2, -4.6]:
		Kit.box(f, "Garage door", Vector3(x, 1.5, 0.04), Vector3(3.2, 3.0, 0.05), Color("dcdcd8"))
		for row in range(3):
			Kit.box(f, "Garage glass", Vector3(x, 0.7 + float(row) * 0.9, 0.07), Vector3(3.0, 0.45, 0.03), Color("7a8a94"))
	for x in [-10.0, -6.4, -2.8]:
		Kit.box(f, "Red post", Vector3(x, h * 0.5, 0.05), Vector3(0.25, h, 0.06), RED)
	# drie bakstenen vakken met een beeld in reliëf, rode deuren ertussen
	for x in [0.0, 4.0, 8.0]:
		Kit.box(f, "Brick panel", Vector3(x, 2.1, 0.04), Vector3(1.9, 3.8, 0.06), BRICK)
		Kit.box(f, "Relief", Vector3(x, 2.4, 0.09), Vector3(0.6, 1.8, 0.06), Color("6e7a6a"))
		Kit.cyl(f, "Relief head", Vector3(x, 3.5, 0.1), 0.22, 0.22, 0.06, Color("6e7a6a"), 10, "z")
	for x in [2.0, 6.0]:
		Kit.box(f, "Red door", Vector3(x, 1.3, 0.05), Vector3(1.2, 2.6, 0.05), RED)
	# rode losse letters op het dak
	var lf := Kit.face(self, c + Vector3(0, 0, -d * 0.5 + 0.5), 0.0)
	Kit.box(lf, "Letter frame", Vector3(0, h + 3.4, -0.05), Vector3(12.0, 0.08, 0.08), Color("5a5a5a"))
	Kit.label(lf, "ALFA  BROUWERIJ", Vector3(0, h + 3.9, 0.0), 0.012, RED, 90)
	# leien torenspitsje achter de hal
	Kit.box(self, "Spire base", c + Vector3(5.0, h + 2.4, -d - 1.0), Vector3(1.8, 2.0, 1.8), WHITE)
	Kit.pyramid(self, "Spire", c + Vector3(5.0, h + 3.4, -d - 1.0), 1.25, 3.4, SLATE)

# Witte brouwerij links van het laantje: lange hal met rondboogramen en een hoog blok.
func _brewhouse(c: Vector3) -> void:
	var w := 26.0
	var d := 10.0
	var h := 7.0
	Kit.box(self, "Brew hall", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), WHITE, true)
	Kit.box(self, "Brew hall cornice", c + Vector3(0, h + 0.15, 0), Vector3(w + 0.5, 0.3, d + 0.5), Color("e4e2dc"))
	Kit.gable(self, "Brew hall roof", c + Vector3(0, h + 0.3, 0), d + 0.6, w + 0.4, 2.8, RED_TILE, true)
	# hoge rondboogramen naar het laantje (+X) en naar de weg (+Z)
	var f := Kit.face(self, c + Vector3(w * 0.5, 0, 0), 90.0)
	for x in [-3.0, 0.0, 3.0]:
		Kit.box(f, "Arched window", Vector3(x, 3.4, 0.04), Vector3(1.4, 3.6, 0.05), GLASS)
		Kit.cyl(f, "Arched window top", Vector3(x, 5.2, 0.04), 0.7, 0.7, 0.05, GLASS, 12, "z")
	var ff := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	var x := -w * 0.5 + 2.0
	while x < w * 0.5 - 1.0:
		Kit.box(ff, "Arched window", Vector3(x, 3.4, 0.04), Vector3(1.4, 3.6, 0.05), GLASS)
		Kit.cyl(ff, "Arched window top", Vector3(x, 5.2, 0.04), 0.7, 0.7, 0.05, GLASS, 12, "z")
		x += 3.0
	# buitentrap met bordes
	Kit.box(self, "Stair landing", c + Vector3(w * 0.5 + 1.0, 2.6, 2.0), Vector3(2.0, 0.15, 2.2), WHITE)
	var st := Kit.box(self, "Outside stair", c + Vector3(w * 0.5 + 1.0, 1.3, 4.6), Vector3(1.2, 0.12, 3.8), Color("6a6e72"))
	st.rotation.x = 0.6
	# hoog wit blok met leien schilddak en schoorstenen
	var t: Vector3 = c + Vector3(6.0, 0, -1.0)
	Kit.box(self, "Brew tower", t + Vector3(0, 6.5, 0), Vector3(9.0, 13.0, 9.0), WHITE, true)
	Kit.box(self, "Tower cornice", t + Vector3(0, 13.1, 0), Vector3(9.6, 0.3, 9.6), Color("e4e2dc"))
	Kit.frustum(self, "Tower roof", t + Vector3(0, 13.2, 0), 9.8, 9.8, 2.8, 2.6, SLATE)
	var tf := Kit.face(self, t + Vector3(4.5, 0, 0), 90.0)
	for z in [-2.0, 2.0]:
		Kit.box(tf, "Tower window", Vector3(z, 10.0, 0.04), Vector3(0.9, 1.6, 0.05), GLASS)
	for e in [[-2.5, -2.0, 8.0], [-0.5, -3.0, 6.0], [1.2, -2.6, 5.0]]:
		Kit.cyl(self, "Stack", t + Vector3(e[0], 15.8 + e[2] * 0.5, e[1]), 0.35, 0.3, e[2], Color("8a8e92"), 10)
	steam = Node3D.new()
	steam.position = t + Vector3(1.2, 18.6, -2.6)
	add_child(steam)
	for k in range(4):
		var puff := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.8 + float(k) * 0.4
		sm.height = sm.radius * 1.6
		sm.radial_segments = 8
		sm.rings = 4
		puff.mesh = sm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1, 0.55 - float(k) * 0.1)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = m
		steam.add_child(puff)

# Witte silo met trechter op een stalen poort.
func _silo_portal(c: Vector3) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Kit.box(self, "Portal leg", c + Vector3(sx * 2.4, 2.5, sz * 1.4), Vector3(0.25, 5.0, 0.25), Color("4a4e52"))
	Kit.box(self, "Portal beam", c + Vector3(0, 5.1, 0), Vector3(5.4, 0.35, 3.2), Color("4a4e52"))
	for sx in [-1.0, 1.0]:
		Kit.beam(self, "Silo leg", c + Vector3(sx * 1.2, 5.2, 0), c + Vector3(sx * 1.4, 7.0, 0), 0.15, Color("6a6e72"))
	Kit.cyl(self, "Silo hopper", c + Vector3(0, 7.2, 0), 0.4, 1.9, 1.8, Color("d8d6d0"), 14)
	Kit.cyl(self, "Silo", c + Vector3(0, 10.2, 0), 1.9, 1.9, 4.2, Color("e4e2dc"), 14)
	Kit.cyl(self, "Silo top", c + Vector3(0, 12.6, 0), 1.9, 0.3, 0.7, Color("e4e2dc"), 14)

func _window(f: Node3D, x: float, y: float, shutters := false) -> void:
	Kit.box(f, "Window frame", Vector3(x, y + 0.75, 0.03), Vector3(1.0, 1.6, 0.05), WHITE)
	Kit.box(f, "Window", Vector3(x, y + 0.75, 0.06), Vector3(0.8, 1.4, 0.03), GLASS)
	Kit.box(f, "Window bar", Vector3(x, y + 0.95, 0.08), Vector3(0.8, 0.05, 0.02), WHITE)
	Kit.box(f, "Window bar", Vector3(x, y + 0.75, 0.08), Vector3(0.05, 1.4, 0.02), WHITE)
	Kit.box(f, "Lintel", Vector3(x, y + 1.66, 0.05), Vector3(1.2, 0.18, 0.08), STONE)
	Kit.box(f, "Flower box", Vector3(x, y - 0.05, 0.15), Vector3(0.95, 0.2, 0.25), Color("6a4a7a"))
	if shutters:
		for s in [-1.0, 1.0]:
			Kit.box(f, "Red shutter", Vector3(x + s * 0.78, y + 0.75, 0.05), Vector3(0.5, 1.6, 0.05), RED)

# Rode houten top in een puntgevel.
func _red_gable(f: Node3D, w: float, y0: float, rise: float) -> void:
	var t: Array = [Vector3(-w * 0.5, y0, 0.02), Vector3(w * 0.5, y0, 0.02), Vector3(0, y0 + rise, 0.02)]
	var g := MeshInstance3D.new()
	g.mesh = Kit._mesh_from(t, Kit._two_sided(RED))
	f.add_child(g)

# Achterin, gevels naar de weg: wit huis, bakstenen huis, witte poortschuur.
func _cluster(c: Vector3) -> void:
	# wit huis met rode luiken
	var a: Vector3 = c + Vector3(-7.0, 0, 0)
	Kit.box(self, "White house", a + Vector3(0, 3.4, -4.0), Vector3(6.4, 6.8, 8.0), WHITE, true)
	Kit.gable(self, "White house roof", a + Vector3(0, 6.8, -4.0), 7.0, 8.6, 3.2, RED_TILE)
	var af := Kit.face(self, a, 0.0)
	_red_gable(af, 6.4, 6.8, 3.2)
	Kit.box(af, "Chimney", Vector3(0, 10.6, -1.0), Vector3(0.7, 1.2, 0.7), BRICK)
	for x in [-1.5, 1.5]:
		for y in [0.9, 4.0]:
			_window(af, x, y, true)
	# bakstenen huis
	var b: Vector3 = c + Vector3(1.5, 0, 0)
	Kit.box(self, "Brick house", b + Vector3(0, 3.1, -3.5), Vector3(10.6, 6.2, 7.0), BRICK, true)
	Kit.gable(self, "Brick house roof", b + Vector3(0, 6.2, -3.5), 7.6, 11.0, 2.6, RED_TILE, true)
	var bf := Kit.face(self, b, 0.0)
	for x in [-4.4, -2.6]:
		Kit.box(bf, "Arched door", Vector3(x, 1.1, 0.04), Vector3(1.1, 2.2, 0.05), Color("a8683a") if x > -4.0 else GLASS)
		Kit.cyl(bf, "Door arch", Vector3(x, 2.2, 0.04), 0.55, 0.55, 0.05, Color("a8683a") if x > -4.0 else GLASS, 12, "z")
		Kit.cyl(bf, "Brick arch", Vector3(x, 2.2, 0.02), 0.72, 0.72, 0.04, Color("7a3a2a"), 12, "z")
	for x in [0.0, 1.8, 3.6]:
		_window(bf, x, 0.9)
	for x in [-4.4, -2.6, -0.8, 1.0, 2.8, 4.4]:
		_window(bf, x, 3.9)
	# witte poortschuur
	var s3: Vector3 = c + Vector3(10.5, 0, 0)
	Kit.box(self, "Gate barn", s3 + Vector3(0, 3.6, -5.0), Vector3(7.0, 7.2, 10.0), WHITE, true)
	Kit.gable(self, "Gate barn roof", s3 + Vector3(0, 7.2, -5.0), 7.6, 10.6, 3.6, RED_TILE)
	var sf := Kit.face(self, s3, 0.0)
	_red_gable(sf, 7.0, 7.2, 3.6)
	for x in [-0.6, 0.6]:
		Kit.box(sf, "Vent hole", Vector3(x, 8.2, 0.05), Vector3(0.25, 0.3, 0.03), Color("2a2a2a"))
	Kit.box(sf, "Gate", Vector3(0, 1.4, 0.04), Vector3(2.4, 2.8, 0.05), GLASS)
	Kit.cyl(sf, "Gate arch", Vector3(0, 2.8, 0.04), 1.2, 1.2, 0.05, GLASS, 14, "z")
	Kit.cyl(sf, "Gate surround", Vector3(0, 2.8, 0.02), 1.45, 1.45, 0.04, STONE, 14, "z")
	Kit.box(sf, "Red door", Vector3(0.3, 1.2, 0.07), Vector3(1.2, 2.4, 0.04), RED)
	Kit.box(sf, "Lamp", Vector3(-1.9, 2.6, 0.2), Vector3(0.3, 0.5, 0.3), Color("2a2a2a"))
	Kit.box(sf, "Lamp", Vector3(1.9, 2.6, 0.2), Vector3(0.3, 0.5, 0.3), Color("2a2a2a"))

# Achtkantig glazen paviljoen met rode stijlen en een donker dak met lantaarntje.
func _gazebo(c: Vector3) -> void:
	Kit.cyl(self, "Gazebo floor", c + Vector3(0, 0.15, 0), 3.0, 3.0, 0.3, Color("8a8680"), 8)
	var glass := Kit.cyl(self, "Gazebo glass", c + Vector3(0, 1.6, 0), 2.8, 2.8, 2.6, Color("8aa0a8"), 8)
	(glass as MeshInstance3D).material_override = Kit.mat(Color(0.55, 0.65, 0.7))
	for k in range(8):
		var a: float = float(k) * TAU / 8.0 + TAU / 16.0
		Kit.box(self, "Gazebo post", c + Vector3(sin(a) * 2.85, 1.6, cos(a) * 2.85), Vector3(0.16, 2.8, 0.16), RED)
	Kit.cyl(self, "Gazebo roof", c + Vector3(0, 3.6, 0), 3.4, 0.9, 1.4, SLATE, 8)
	Kit.cyl(self, "Gazebo lantern", c + Vector3(0, 4.6, 0), 0.8, 0.8, 0.6, Color("6a6e72"), 8)
	Kit.cyl(self, "Lantern roof", c + Vector3(0, 5.15, 0), 0.95, 0.1, 0.5, SLATE, 8)

func _tanks(c: Vector3) -> void:
	for row in range(2):
		for i in range(6):
			var p: Vector3 = c + Vector3(float(i) * 4.4, 0, -float(row) * 4.6)
			var h: float = 11.0 + float((i + row) % 3) * 1.2
			Kit.cyl(self, "Tank", p + Vector3(0, h * 0.5, 0), 1.9, 1.9, h, STEEL, 14, "y", row == 0)
			Kit.cyl(self, "Tank top", p + Vector3(0, h + 0.6, 0), 1.9, 0.4, 1.2, Color("d4d8dc"), 14)

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 2.5, 0), 0.35, 0.28, 5.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 3.6
	cm.height = 6.0
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("5a8a3a"))
	cr.position = p + Vector3(0, 6.5, 0)
	add_child(cr)

# Damp uit de schoorsteen: de wolkjes stijgen op, worden groter en beginnen opnieuw.
func _process(delta: float) -> void:
	if steam == null:
		return
	steam_t += delta
	for k in range(steam.get_child_count()):
		var u: float = fmod(steam_t * 0.25 + float(k) * 0.25, 1.0)
		var puff: Node3D = steam.get_child(k)
		puff.position = Vector3(u * 1.5, u * 6.0, -u * 0.8)
		puff.scale = Vector3.ONE * (0.6 + u * 1.2)
