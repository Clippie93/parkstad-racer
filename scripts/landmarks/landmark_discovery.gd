extends Node3D
# Discovery Museum (Kerkrade, bij station Kerkrade-Centrum), naar jouw foto's (23-11):
# - links een hoge grijze doos met verticaal geribbelde metalen gevelbekleding, een
#   verticale glasstrook en het naambord
# - een grote groengrijze koepel in een betonnen bak, met een lijn eromheen
# - een lange donkere vleugel die boven een glazen pui zweeft, met aan het eind een groot
#   raam, een rode paal eronder en een schuin oranje portaal; ervoor een gestreept plein
# - erachter een lange bakstenen muur met een paars bovendeel en een groen blok
# - rechts het schachttoren-kunstwerk: een wit schuin vlak met een stalen vakwerk, twee
#   schachtwielen en een rode wenteltrap
# - voor het museum mijnrelikwieën: een kogelmolen op betonnen steunen en een rode
#   stoommachine met vliegwiel
# Lokale ruimte: +Z = naar de weg; +X = rechts gezien vanaf de weg.
const Kit = preload("res://scripts/build_kit.gd")

const CLAD := Color("8e9297")
const RIB := Color("a7abb0")
const DARK := Color("33353a")
const PANEL := Color("4a4d53")
const GLASS := Color("2a3238")
const ORANGE := Color("dd4f25")
const BRICK := Color("8b5040")
const PURPLE := Color("5b3a4c")
const TEAL := Color("2f6a5c")
const DOME := Color("8da197")
const CONCRETE := Color("b3afa6")
const STEEL := Color("7d8288")

func _ready() -> void:
	name = "Discovery Museum"
	Kit.box(self, "Museum grounds", Vector3(20, 0.03, -16), Vector3(140.0, 0.06, 60.0), Color("9d998f"))
	_tall_box()
	_dome()
	_wing()
	_back_buildings()
	_headframe()
	# grasveld vóór het museum (aan de kant waar je aan komt rijden) met de mijnrelikwieën:
	# eerst de groene kogelmolen, zo'n honderd meter verder de rode stoommachine
	Kit.box(self, "Museum field", Vector3(-103, 0.03, -8), Vector3(124.0, 0.06, 44.0), Color("6d9a4c"))
	_ball_mill(Vector3(-150, 0, 4))
	_steam_engine(Vector3(-52, 0, 6))
	_hedge(Vector3(-52, 0, 3.5), 9.0)

func _mesh(n: String, tris: Array, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, Kit._two_sided(color))
	add_child(mi)

# ---------------------------------------------------------------- hoge grijze doos
func _tall_box() -> void:
	var c := Vector3(-30, 0, -20)
	var w := 22.0
	var d := 22.0
	var h := 22.0
	Kit.box(self, "Tall box", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), CLAD, true)
	# ribbels op de voorgevel en de zijgevels
	var x: float = -w * 0.5 + 0.4
	while x < w * 0.5:
		Kit.box(self, "Cladding rib", c + Vector3(x, h * 0.5, d * 0.5 + 0.08), Vector3(0.18, h, 0.16), RIB)
		x += 0.75
	for s in [-1.0, 1.0]:
		var z: float = -d * 0.5 + 0.4
		while z < d * 0.5:
			Kit.box(self, "Cladding rib", c + Vector3(s * (w * 0.5 + 0.08), h * 0.5, z), Vector3(0.16, h, 0.18), RIB)
			z += 0.75
	Kit.box(self, "Glass strip", c + Vector3(w * 0.5 - 3.0, h * 0.5 + 0.5, d * 0.5 + 0.2), Vector3(2.2, h - 1.0, 0.1), GLASS)
	Kit.box(self, "Glass strip lower", c + Vector3(w * 0.5 - 4.5, 7.5, d * 0.5 + 0.21), Vector3(3.0, 2.4, 0.1), Color("c9ccd0"))
	Kit.box(self, "Name board", c + Vector3(-4.0, h - 3.2, d * 0.5 + 0.22), Vector3(7.4, 2.2, 0.1), Color("2b2c30"))
	Kit.label(self, "DISCOVERY\nMUSEUM", c + Vector3(-4.0, h - 3.2, d * 0.5 + 0.3), 0.012, Color("f2f2ee"), 64)
	Kit.box(self, "Tall box base", c + Vector3(0, 0.6, 0), Vector3(w + 0.3, 1.2, d + 0.3), DARK)

# ---------------------------------------------------------------- koepel
func _dome() -> void:
	var c := Vector3(-6, 0, -6)
	var r := 12.0
	Kit.cyl(self, "Dome planter", c + Vector3(0, 0.7, 0), r + 1.6, r + 1.6, 1.4, CONCRETE, 32, "y", true)
	Kit.cyl(self, "Dome planter green", c + Vector3(0, 1.42, 0), r + 1.3, r + 1.3, 0.06, Color("5f8240"), 32)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 32
	sm.rings = 16
	sm.is_hemisphere = true
	dome.mesh = sm
	dome.material_override = Kit.mat(DOME)
	dome.position = c + Vector3(0, 0.6, 0)
	dome.scale = Vector3(1.0, 0.4, 1.0)    # lage, brede koepel
	add_child(dome)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(r * 1.5, 5.0, r * 1.5)
	cs.shape = sh
	cs.position = Vector3(0, 2.5, 0)
	body.add_child(cs)
	body.position = c
	add_child(body)
	# lijn om de koepel
	var yb := 2.6
	var rb: float = r * sqrt(1.0 - pow((yb - 0.6) / (r * 0.4), 2.0))
	Kit.cyl(self, "Dome band", c + Vector3(0, yb, 0), rb + 0.06, rb + 0.06, 0.16, Color("c7cfca"), 40)

# ---------------------------------------------------------------- vleugel
func _wing() -> void:
	var x0 := 6.0
	var x1 := 46.0
	# glazen pui op de begane grond, iets naar achteren
	Kit.box(self, "Wing ground floor", Vector3((x0 + x1) * 0.5, 2.1, -16.0), Vector3(x1 - x0 - 4.0, 4.2, 12.0), DARK, true)
	Kit.box(self, "Wing ground glass", Vector3((x0 + x1) * 0.5, 2.1, -9.95), Vector3(x1 - x0 - 5.0, 3.8, 0.08), GLASS)
	for x in range(int(x0) + 4, int(x1) - 2, 4):
		Kit.box(self, "Glass mullion", Vector3(float(x), 2.1, -9.9), Vector3(0.12, 3.8, 0.1), DARK)
	# zwevende donkere doos erboven, verder naar voren
	var zc := -14.0
	var dd := 16.0
	Kit.box(self, "Wing upper", Vector3((x0 + x1) * 0.5, 7.8, zc), Vector3(x1 - x0, 6.6, dd), DARK, true)
	# panelen met naden en een paar ramen
	var f := Kit.face(self, Vector3((x0 + x1) * 0.5, 0, zc + dd * 0.5), 0.0)
	var cols := 9
	for i in range(cols):
		var px: float = -(x1 - x0) * 0.5 + (x1 - x0) * (float(i) + 0.5) / float(cols) - 2.0
		for row in [6.3, 9.3]:
			Kit.box(f, "Wing panel", Vector3(px, row, 0.04), Vector3((x1 - x0) / float(cols) - 0.35, 2.6, 0.06), PANEL)
	Kit.box(f, "Wing window", Vector3(-8.0, 7.6, 0.08), Vector3(5.0, 1.6, 0.05), Color("7d93a6"))
	# groot raam aan het eind, met een lichte omlijsting
	Kit.box(f, "End frame", Vector3((x1 - x0) * 0.5 - 5.0, 7.8, 0.05), Vector3(10.0, 6.6, 0.08), Color("c6c9cc"))
	Kit.box(f, "End glass", Vector3((x1 - x0) * 0.5 - 5.0, 7.6, 0.1), Vector3(9.2, 5.0, 0.06), GLASS)
	var sf := Kit.face(self, Vector3(x1, 0, zc), 90.0)
	Kit.box(sf, "End side frame", Vector3(0, 7.8, 0.05), Vector3(dd, 6.6, 0.08), Color("c6c9cc"))
	Kit.box(sf, "End side glass", Vector3(0, 7.6, 0.1), Vector3(dd - 1.0, 5.0, 0.06), GLASS)
	# rode paal onder het uiteinde en een schuin oranje portaal
	Kit.box(self, "Red column", Vector3(x1 - 9.0, 5.5, -6.6), Vector3(0.5, 11.0, 0.5), ORANGE, true)
	var p0 := Vector3(x1 + 1.5, 0, -5.0)
	Kit.beam(self, "Orange frame leg", p0, p0 + Vector3(-2.0, 12.0, 0), 0.8, ORANGE)
	Kit.beam(self, "Orange frame top", p0 + Vector3(-2.0, 12.0, 0), p0 + Vector3(-2.0, 12.0, -12.0), 0.8, ORANGE)
	# gestreept plein (donker en licht) voor de ingang
	var x: float = x0
	var k := 0
	while x < x1:
		Kit.box(self, "Plaza stripe", Vector3(x + 0.8, 0.07, -2.5), Vector3(1.6, 0.04, 14.0), Color("5b5b5c") if k % 2 == 0 else Color("cfccc4"))
		x += 1.6
		k += 1

# ---------------------------------------------------------------- erachter
func _back_buildings() -> void:
	Kit.box(self, "Brick hall", Vector3(61, 4.0, -30), Vector3(66.0, 8.0, 22.0), BRICK, true)   # loopt rechts van de toren nog door
	var f := Kit.face(self, Vector3(56, 0, -19.0), 0.0)
	Kit.box(f, "Brick hall door", Vector3(-6.0, 1.6, 0.05), Vector3(1.8, 3.2, 0.06), Color("b5302a"))
	Kit.box(f, "Brick hall vent", Vector3(-16.0, 5.6, 0.05), Vector3(2.4, 1.4, 0.06), Color("8f9296"))
	Kit.box(self, "Purple top", Vector3(48, 10.0, -34), Vector3(40.0, 4.0, 14.0), PURPLE)
	var pf := Kit.face(self, Vector3(48, 0, -27.0), 0.0)
	Kit.box(pf, "Purple window band", Vector3(0, 9.0, 0.05), Vector3(36.0, 1.0, 0.06), Color("9aa6b0"))
	Kit.box(self, "Teal block", Vector3(76, 8.0, -40), Vector3(14.0, 16.0, 12.0), TEAL)

# ---------------------------------------------------------------- schachttoren-kunstwerk
# Naar jouw foto's: een rechtopstaand wit blok van horizontale planken, daarop links een hoge
# kast van grijze geperforeerde panelen en een stalen kooi die naar rechts uitsteekt (met
# staanders tot op de grond), aan de voorkant twee schachtwielen naast elkaar, een dunne
# paal ervoor en links bij de bakstenen muur een rode wenteltrap.
func _frame_box(o: Vector3, size: Vector3, thick: float) -> void:
	var xs := [0.0, size.x]
	var zs := [0.0, size.z]
	for x in xs:
		for z in zs:
			Kit.beam(self, "Cage post", o + Vector3(x, 0, z), o + Vector3(x, size.y, z), thick, STEEL)
	for y in [0.0, size.y * 0.5, size.y]:
		Kit.beam(self, "Cage beam", o + Vector3(0, y, 0), o + Vector3(size.x, y, 0), thick, STEEL)
		Kit.beam(self, "Cage beam", o + Vector3(0, y, size.z), o + Vector3(size.x, y, size.z), thick, STEEL)
		Kit.beam(self, "Cage beam", o + Vector3(0, y, 0), o + Vector3(0, y, size.z), thick, STEEL)
		Kit.beam(self, "Cage beam", o + Vector3(size.x, y, 0), o + Vector3(size.x, y, size.z), thick, STEEL)
	# kruisverbanden aan de voor- en zijkant
	Kit.beam(self, "Cage brace", o + Vector3(0, 0, size.z), o + Vector3(size.x, size.y * 0.5, size.z), thick * 0.6, STEEL)
	Kit.beam(self, "Cage brace", o + Vector3(size.x, 0, 0), o + Vector3(size.x, size.y * 0.5, size.z), thick * 0.6, STEEL)

func _wheel_ring(c: Vector3, r: float, thick: float, segs: int) -> void:
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		Kit.beam(self, "Sheave ring", c + Vector3(cos(a0), sin(a0), 0) * r, c + Vector3(cos(a1), sin(a1), 0) * r, thick, Color("bfc3c6"))

func _headframe() -> void:
	# het witte blok staat met de achterkant tegen de bakstenen hal (voorgevel op z = -19)
	var c := Vector3(80, 0, -16.5)
	var bw := 5.0
	var bd := 5.0
	var bh := 11.0
	# wit blok van horizontale planken
	Kit.box(self, "Headframe block", c + Vector3(0, bh * 0.5, 0), Vector3(bw, bh, bd), Color("e3e5e6"), true)
	var y := 0.5
	while y < bh:
		Kit.box(self, "Plank line", c + Vector3(0, y, bd * 0.5 + 0.03), Vector3(bw, 0.06, 0.04), Color("b9bdc0"))
		Kit.box(self, "Plank line", c + Vector3(bw * 0.5 + 0.03, y, 0), Vector3(0.04, 0.06, bd), Color("b9bdc0"))
		y += 0.45
	var top: Vector3 = c + Vector3(-bw * 0.5, bh, -bd * 0.5)
	# hoge kast van geperforeerde panelen links bovenop
	Kit.box(self, "Mesh box", top + Vector3(1.6, 5.5, 2.5), Vector3(3.2, 11.0, 5.0), Color("8e979e"))
	_frame_box(top, Vector3(3.2, 11.0, 5.0), 0.18)
	for k in range(1, 5):
		Kit.box(self, "Mesh box rail", top + Vector3(1.6, float(k) * 2.2, 5.05), Vector3(3.3, 0.12, 0.05), Color("5f666c"))
	# stalen kooi die naar rechts uitsteekt, met staanders tot op de grond
	var cage := top + Vector3(3.2, 0.0, 0.0)
	_frame_box(cage, Vector3(6.5, 8.0, 5.0), 0.22)
	for z in [0.0, 5.0]:
		Kit.beam(self, "Cage leg", cage + Vector3(6.5, 0, z) - Vector3(0, bh, 0), cage + Vector3(6.5, 0, z), 0.22, STEEL)
		Kit.beam(self, "Cage leg brace", cage + Vector3(6.5, -bh, z), cage + Vector3(1.8, 0, z), 0.12, STEEL)
	# twee open schachtwielen naast elkaar aan de voorkant: buitenring, binnenring, spaken
	# op één as, achter elkaar met wat ruimte ertussen (van voren gezien overlappen ze)
	for wz in [0.4, -1.9]:
		var wc: Vector3 = c + Vector3(2.9, bh + 4.0, bd * 0.5 + wz)
		_wheel_ring(wc, 2.1, 0.2, 28)
		_wheel_ring(wc, 1.25, 0.12, 20)
		_wheel_ring(wc, 0.45, 0.12, 12)
		for i in range(14):
			var a: float = TAU * float(i) / 14.0
			Kit.beam(self, "Sheave spoke", wc + Vector3(cos(a), sin(a), 0) * 0.45, wc + Vector3(cos(a), sin(a), 0) * 2.05, 0.07, Color("bfc3c6"))
		Kit.cyl(self, "Sheave hub", wc, 0.22, 0.22, 0.4, Color("8d9297"), 10, "z")
	Kit.beam(self, "Sheave axle", c + Vector3(2.9, bh + 4.0, bd * 0.5 + 0.8), c + Vector3(2.9, bh + 4.0, bd * 0.5 - 2.4), 0.15, STEEL)
	# dunne paal ervoor
	Kit.cyl(self, "Thin pole", c + Vector3(-1.8, (bh + 3.0) * 0.5, bd * 0.5 + 1.2), 0.12, 0.12, bh + 3.0, STEEL, 6)
	# rode wenteltrap tegen de bakstenen hal, naar een bordes met reling en een deur
	var red := Color("b02a24")
	var wall_z := -19.0                       # voorgevel van de bakstenen hal
	var sp := Vector3(c.x - 6.5, 0, wall_z + 1.3)
	var land_y := 6.0
	Kit.cyl(self, "Spiral stair core", sp + Vector3(0, land_y * 0.5, 0), 0.12, 0.12, land_y, red, 6)
	for i in range(16):
		var a: float = float(i) * 0.7
		var yy: float = 0.4 + float(i) * (land_y - 0.4) / 16.0
		Kit.beam(self, "Spiral step", sp + Vector3(0, yy, 0), sp + Vector3(cos(a), 0, sin(a)) * 1.1 + Vector3(0, yy, 0), 0.12, red)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		Kit.beam(self, "Spiral rail", sp + Vector3(cos(a), 0, sin(a)) * 1.15 + Vector3(0, 1.0 + float(i) * 0.65, 0), sp + Vector3(cos(a + TAU / 8.0), 0, sin(a + TAU / 8.0)) * 1.15 + Vector3(0, 1.65 + float(i) * 0.65, 0), 0.05, red)
	# bordes tegen de muur, met reling, en een deur erachter
	var lp := Vector3(sp.x - 1.9, land_y, wall_z + 0.9)
	Kit.box(self, "Stair landing", lp, Vector3(4.4, 0.12, 1.8), red)
	Kit.box(self, "Landing rail", lp + Vector3(0, 1.0, 0.9), Vector3(4.4, 0.06, 0.06), red)
	Kit.box(self, "Landing rail", lp + Vector3(-2.2, 1.0, 0), Vector3(0.06, 0.06, 1.8), red)
	for x in [-2.2, -1.1, 0.0, 1.1, 2.2]:
		Kit.box(self, "Landing baluster", lp + Vector3(x, 0.5, 0.9), Vector3(0.05, 1.0, 0.05), red)
	Kit.box(self, "Landing door", Vector3(lp.x - 1.0, land_y + 1.1, wall_z + 0.04), Vector3(1.0, 2.1, 0.06), Color("8e2a24"))
	Kit.box(self, "Landing support", Vector3(lp.x - 2.0, land_y * 0.5, lp.z + 0.7), Vector3(0.12, land_y, 0.12), red)

# ---------------------------------------------------------------- mijnrelikwieën
func _ball_mill(p: Vector3) -> void:
	for s in [-1.0, 1.0]:
		Kit.box(self, "Mill support", p + Vector3(s * 3.2, 1.0, 0), Vector3(1.0, 2.0, 2.2), CONCRETE, true)
		Kit.box(self, "Mill bearing", p + Vector3(s * 2.8, 2.3, 0), Vector3(0.8, 0.8, 1.0), Color("6f7a72"))
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.2
	sm.height = 4.4
	sm.radial_segments = 20
	sm.rings = 10
	ball.mesh = sm
	ball.material_override = Kit.mat(Color("7f8c80"))
	ball.position = p + Vector3(0, 2.4, 0)
	add_child(ball)
	Kit.cyl(self, "Mill gear", p + Vector3(-2.0, 2.4, 0), 1.7, 1.7, 0.3, Color("6f7a72"), 20, "x")
	Kit.cyl(self, "Mill hatch", p + Vector3(0, 2.4, 2.15), 0.7, 0.7, 0.15, Color("5f6a62"), 14, "z")
	Kit.box(self, "Mill pit", p + Vector3(0, 0.05, 0), Vector3(6.0, 0.1, 3.0), Color("6a5d4e"))

func _hedge(p: Vector3, l: float) -> void:
	Kit.box(self, "Hedge", p + Vector3(0, 0.6, 0), Vector3(l, 1.2, 0.9), Color("3f6b35"))

func _steam_engine(p: Vector3) -> void:
	var red := Color("9a3a33")
	Kit.box(self, "Engine bed", p + Vector3(0, 0.3, 0), Vector3(4.6, 0.6, 1.0), Color("4e4f52"))
	Kit.cyl(self, "Engine cylinder", p + Vector3(-1.2, 1.0, 0), 0.45, 0.45, 1.8, red, 14, "x")
	Kit.cyl(self, "Engine rod", p + Vector3(0.4, 1.0, 0), 0.08, 0.08, 1.6, Color("8a8f94"), 6, "x")
	Kit.cyl(self, "Flywheel rim", p + Vector3(1.6, 1.25, 0.6), 0.95, 0.95, 0.12, Color("d6d8d3"), 20, "z")
	Kit.cyl(self, "Flywheel hub", p + Vector3(1.6, 1.25, 0.62), 0.2, 0.2, 0.16, Color("d6d8d3"), 10, "z")
	for i in range(6):
		var a: float = TAU * float(i) / 6.0
		Kit.beam(self, "Flywheel spoke", p + Vector3(1.6, 1.25, 0.66), p + Vector3(1.6 + cos(a) * 0.85, 1.25 + sin(a) * 0.85, 0.66), 0.07, Color("d6d8d3"))
