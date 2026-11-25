extends Node3D
# Huize Loreto, Simpelveld (klooster uit 1878). Naar jouw foto's (20-11): een symmetrisch
# complex met in het midden de neogotische kapel met de puntgevel naar de straat en aan
# weerszijden een lange kloostervleugel.
# - kapel: hoge spitsboogvensters met natuurstenen tracering, een trap naar het portaal,
#   op de hoeken torentjes met pinakels, balustrades, een steile puntgevel met een kruis,
#   steunberen met pinakels langs de zijkanten en een slanke dakruiter op de nok
# - vleugels: vier lagen rode baksteen met gele en donkere sierbanden, witte vensters
#   (onder rondbogen, erboven rechte vensters onder sierbogen), een rondboogfries onder de
#   goot, een steil leien dak met een rij dakkapellen met trapgeveltjes, en aan de uiteinden
#   een hogere kopbouw met een trapgevel naar de straat
# - langs de straat een laag bakstenen muurtje met een zwart smeedijzeren hek
# Lokale ruimte: +Z = straatkant, de vleugels liggen langs X.
const Kit = preload("res://scripts/build_kit.gd")

const STONE := Color("d3cab4")
const SLATE := Color("454950")
const GLASS := Color("2c3438")
const FRAME := Color("eeece4")
const YELLOW := Color("c89a5c")
const DARK := Color("4a2a22")
const IRON := Color("1e1f20")

const WING_X0 := 7.0       # vleugels beginnen naast de kapel
const WING_X1 := 38.0
const WING_D := 14.0
const EAVES := 12.6
const CH_W := 14.0
const CH_FRONT := 4.0
const CH_BACK := -40.0
const CH_H := 15.0

var brick: Material

func _ready() -> void:
	name = "Huize Loreto"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("ecc9bc"), 3.0)
	for side in [-1.0, 1.0]:
		_wing(side)
	_chapel()
	_fence()

# ---------------------------------------------------------------- hulpjes
func _tri_mesh(parent: Node3D, n: String, tris: Array, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, m)
	parent.add_child(mi)
	return mi

# Zadeldak zonder kopse driehoeken (de geveltoppen zijn baksteen). Nok langs Z of langs X.
func _roof(n: String, base: Vector3, width: float, length: float, rise: float, along_x: bool) -> void:
	var hw: float = width * 0.5
	var hl: float = length * 0.5
	var t: Array = []
	Kit._quad(t, Vector3(-hw, 0, -hl), Vector3(-hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	Kit._quad(t, Vector3(hw, 0, -hl), Vector3(hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	var mi := _tri_mesh(self, n, t, Kit._two_sided(SLATE))
	mi.position = base
	if along_x:
		mi.rotation_degrees.y = 90.0

# Driehoekige bakstenen geveltop in face-ruimte.
func _gable_tri(f: Node3D, y: float, w: float, rise: float, z: float = 0.0) -> void:
	var hw: float = w * 0.5
	_tri_mesh(f, "Gable brick", [Vector3(hw, y, z), Vector3(-hw, y, z), Vector3(0, y + rise, z)], brick)

# Spitsboog (gelijkzijdig) in face-ruimte: rechthoek + punt. y0 = onderkant, h = totaal.
func _pointed(f: Node3D, n: String, x: float, y0: float, w: float, h: float, color: Color, z: float) -> void:
	var r: float = w
	var ys: float = y0 + h - 0.866 * w
	var t: Array = []
	Kit._quad(t, Vector3(x - w * 0.5, y0, z), Vector3(x + w * 0.5, y0, z), Vector3(x + w * 0.5, ys, z), Vector3(x - w * 0.5, ys, z))
	var steps := 8
	var mid := Vector3(x, ys, z)
	for k in range(steps):
		# linkerboog: middelpunt rechts, van 180 naar 120 graden
		var a0: float = deg_to_rad(180.0 - 60.0 * float(k) / float(steps))
		var a1: float = deg_to_rad(180.0 - 60.0 * float(k + 1) / float(steps))
		t.append_array([mid, Vector3(x + w * 0.5 + cos(a0) * r, ys + sin(a0) * r, z), Vector3(x + w * 0.5 + cos(a1) * r, ys + sin(a1) * r, z)])
		var b0: float = deg_to_rad(60.0 * float(k) / float(steps))
		var b1: float = deg_to_rad(60.0 * float(k + 1) / float(steps))
		t.append_array([mid, Vector3(x - w * 0.5 + cos(b0) * r, ys + sin(b0) * r, z), Vector3(x - w * 0.5 + cos(b1) * r, ys + sin(b1) * r, z)])
	_tri_mesh(f, n, t, Kit._two_sided(color))

# Trapgevel in face-ruimte: oplopende blokken met natuurstenen afdekking.
func _stepped(f: Node3D, y: float, w: float, h: float, steps: int, z: float, depth: float = 0.6) -> void:
	for k in range(steps):
		var sw: float = w * (1.0 - float(k) / float(steps))
		var sh: float = h / float(steps)
		Kit.box(f, "Step", Vector3(0, y + sh * (float(k) + 0.5), z), Vector3(sw, sh, depth), Color.WHITE, false, brick)
		for s in [-1.0, 1.0]:
			Kit.box(f, "Step cap", Vector3(s * (sw * 0.5 - 0.15), y + sh * (float(k) + 1.0) + 0.06, z + 0.05), Vector3(0.45, 0.12, depth + 0.1), STONE)
	Kit.box(f, "Step top", Vector3(0, y + h + 0.06, z + 0.05), Vector3(w / float(steps) + 0.1, 0.12, depth + 0.1), STONE)

# Venster met witte kozijnen; arch = rondboog, anders recht met een sierboog erboven.
func _window(f: Node3D, x: float, y: float, w: float, h: float, arch: bool) -> void:
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.03), Vector3(w + 0.14, h, 0.08), FRAME)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5 - 0.05, 0.06), Vector3(w - 0.14, h - 0.2, 0.04), GLASS)
	Kit.box(f, "Mullion", Vector3(x, y + h * 0.5, 0.09), Vector3(0.08, h - 0.1, 0.03), FRAME)
	Kit.box(f, "Transom", Vector3(x, y + h * 0.7, 0.09), Vector3(w - 0.1, 0.07, 0.03), FRAME)
	Kit.box(f, "Sill", Vector3(x, y - 0.06, 0.12), Vector3(w + 0.3, 0.12, 0.22), STONE)
	if arch:
		Kit.cyl(f, "Window arch", Vector3(x, y + h, 0.03), w * 0.5 + 0.07, w * 0.5 + 0.07, 0.08, FRAME, 14, "z")
		Kit.cyl(f, "Window arch glass", Vector3(x, y + h, 0.06), w * 0.5 - 0.07, w * 0.5 - 0.07, 0.04, GLASS, 14, "z")
		Kit.box(f, "Window arch plug", Vector3(x, y + h - w * 0.25, 0.0), Vector3(w + 0.6, w * 0.5, 0.02), Color("8e5444"))
		_polyarch(f, x, y + h, w * 0.5 + 0.12, 0.3)
	else:
		_polyarch(f, x, y + h, w * 0.5 + 0.12, 0.28, 0.35)

# Sierboog van afwisselend gele en donkere stenen.
func _polyarch(f: Node3D, x: float, y: float, r: float, thick: float, flat: float = 1.0) -> void:
	var n := 9
	for k in range(n):
		var a: float = PI * (float(k) + 0.5) / float(n)
		var p := Vector3(x + cos(a) * (r + thick * 0.5), y + sin(a) * (r + thick * 0.5) * flat, 0.05)
		var b := Kit.box(f, "Arch brick", p, Vector3(thick, PI * r / float(n) + 0.02, 0.06), YELLOW if k % 2 == 0 else Color("a8453a"))
		b.rotation.z = a

# ---------------------------------------------------------------- vleugels
func _wing(side: float) -> void:
	var x0: float = WING_X0 * side
	var x1: float = WING_X1 * side
	var cx: float = (x0 + x1) * 0.5
	var ln: float = absf(x1 - x0)
	var zc: float = -WING_D * 0.5
	Kit.box(self, "Wing", Vector3(cx, EAVES * 0.5, zc), Vector3(ln, EAVES, WING_D), Color.WHITE, true, brick)
	Kit.box(self, "Wing plinth", Vector3(cx, 0.45, 0.04), Vector3(ln, 0.9, 0.14), Color("9a958c"))
	_roof("Wing roof", Vector3(cx, EAVES - 0.1, zc), WING_D + 1.0, ln, 8.0, true)
	Kit.box(self, "Wing ridge", Vector3(cx, EAVES + 7.9, zc), Vector3(ln, 0.2, 0.3), Color("3a3d42"))
	var f := Kit.face(self, Vector3(cx, 0, 0.0), 0.0)
	# sierbanden: gele en donkere lagen tussen de verdiepingen
	for y in [3.7, 7.2, 10.6]:
		Kit.box(f, "Band", Vector3(0, y, 0.04), Vector3(ln, 0.16, 0.06), YELLOW)
		Kit.box(f, "Band dark", Vector3(0, y + 0.22, 0.04), Vector3(ln, 0.1, 0.06), DARK)
		Kit.box(f, "Band dark", Vector3(0, y - 0.22, 0.04), Vector3(ln, 0.1, 0.06), DARK)
	# rondboogfries onder de goot
	var n: int = int(ln / 0.7)
	for k in range(n):
		var fx: float = -ln * 0.5 + 0.35 + float(k) * ln / float(n)
		Kit.box(f, "Corbel", Vector3(fx, EAVES - 0.45, 0.08), Vector3(0.12, 0.5, 0.14), DARK)
		Kit.cyl(f, "Corbel arch", Vector3(fx + ln / float(n) * 0.5, EAVES - 0.2, 0.06), 0.24, 0.24, 0.08, YELLOW, 10, "z")
	Kit.box(f, "Cornice", Vector3(0, EAVES - 0.05, 0.2), Vector3(ln + 0.3, 0.3, 0.45), STONE)
	# vensters: 9 traveeën; aan de kopbouw (buitenste 6 m) eigen ritme
	var bays := 8
	var span: float = ln - 7.6
	for k in range(bays):
		var a: float = -ln * 0.5 + (0.6 if side > 0.0 else 7.0)
		var bx: float = a + (ln - 7.6) * (float(k) + 0.5) / float(bays)
		_window(f, bx, 1.1, 1.3, 1.9, true)
		_window(f, bx, 4.4, 1.4, 2.2, false)
		_window(f, bx, 7.9, 1.4, 2.1, false)
		Kit.box(f, "Basement window", Vector3(bx, 0.45, 0.1), Vector3(0.9, 0.4, 0.04), GLASS)
	# kopbouw aan het uiteinde: iets naar voren, hoger, met een trapgevel naar de straat
	var px: float = x1 - 3.5 * side
	Kit.box(self, "End pavilion", Vector3(px, (EAVES + 1.6) * 0.5, -WING_D * 0.5 + 0.6), Vector3(7.4, EAVES + 1.6, WING_D + 1.2), Color.WHITE, true, brick)
	_roof("End pavilion roof", Vector3(px, EAVES + 1.5, -WING_D * 0.5 + 0.6), 7.6, WING_D + 1.0, 8.0, false)
	var pf := Kit.face(self, Vector3(px, 0, 1.2), 0.0)
	_stepped(pf, EAVES + 1.6, 7.4, 8.5, 5, -0.3)
	_stepped(Kit.face(self, Vector3(px, 0, -WING_D - 0.2), 180.0), EAVES + 1.6, 7.4, 8.5, 5, -0.3)
	Kit.cyl(pf, "Pavilion rose", Vector3(0, EAVES + 4.6, 0.02), 0.55, 0.55, 0.06, STONE, 14, "z")
	Kit.cyl(pf, "Pavilion rose glass", Vector3(0, EAVES + 4.6, 0.05), 0.38, 0.38, 0.04, GLASS, 14, "z")
	for wx in [-0.9, 0.9]:
		_window(pf, wx, EAVES + 2.0, 0.8, 1.6, true)
	for wx in [-1.7, 1.7]:
		_window(pf, wx, 1.1, 1.3, 1.9, true)
		_window(pf, wx, 4.4, 1.4, 2.2, false)
		_window(pf, wx, 7.9, 1.4, 2.1, false)
	for y in [3.7, 7.2, 10.6]:
		Kit.box(pf, "Band", Vector3(0, y, 0.04), Vector3(7.4, 0.16, 0.06), YELLOW)
	# torenspits-windvaan op de trapgevel
	Kit.cyl(pf, "Vane rod", Vector3(0, EAVES + 1.6 + 8.5 + 1.0, -0.3), 0.04, 0.04, 2.0, IRON, 6)
	Kit.box(pf, "Vane", Vector3(0.3, EAVES + 1.6 + 8.5 + 1.6, -0.3), Vector3(0.6, 0.3, 0.03), IRON)
	# dakkapellen met trapgeveltjes op het dak van de vleugel
	for k in range(6):
		var dx: float = (WING_X0 + 2.6 + float(k) * (span - 1.5) / 6.0) * side
		var d := Kit.face(self, Vector3(dx, 0, 0.3), 0.0)
		Kit.box(d, "Dormer", Vector3(0, EAVES + 1.1, -0.6), Vector3(1.8, 2.2, 1.2), Color.WHITE, false, brick)
		_stepped(d, EAVES + 2.2, 1.8, 1.4, 3, -0.2, 0.4)
		_window(d, 0, EAVES + 0.5, 0.8, 1.2, true)
		var dr := Kit.gable(self, "Dormer roof", Vector3(dx, EAVES + 2.1, -2.2), 1.9, 2.6, 1.2, SLATE)
		dr.name = "Dormer roof"
	# schoorstenen
	for cz in [-4.0, -10.0]:
		Kit.box(self, "Chimney", Vector3(cx + side * 3.0, EAVES + 7.5, cz), Vector3(0.9, 3.5, 0.9), Color("6e3e32"))

# ---------------------------------------------------------------- kapel
func _chapel() -> void:
	var ln: float = CH_FRONT - CH_BACK
	var zc: float = (CH_FRONT + CH_BACK) * 0.5
	var hw: float = CH_W * 0.5
	Kit.box(self, "Chapel", Vector3(0, CH_H * 0.5, zc), Vector3(CH_W, CH_H, ln), Color.WHITE, true, brick)
	Kit.box(self, "Chapel plinth", Vector3(0, 0.6, zc), Vector3(CH_W + 0.2, 1.2, ln + 0.2), Color("b7b0a2"))
	var rise := 12.0
	_roof("Chapel roof", Vector3(0, CH_H - 0.1, zc - 0.5), CH_W + 1.2, ln + 0.6, rise + 0.6, false)
	# voorgevel
	var f := Kit.face(self, Vector3(0, 0, CH_FRONT), 0.0)
	_gable_tri(f, CH_H, CH_W - 0.4, rise, 0.0)
	for s in [-1.0, 1.0]:
		Kit.beam(f, "Gable coping", Vector3(s * (hw - 0.1), CH_H, 0.25), Vector3(0, CH_H + rise + 0.2, 0.25), 0.45, STONE)
	Kit.box(f, "Gable cross", Vector3(0, CH_H + rise + 1.3, 0.2), Vector3(0.18, 2.0, 0.18), Color("b8962e"))
	Kit.box(f, "Gable cross arm", Vector3(0, CH_H + rise + 1.6, 0.2), Vector3(1.0, 0.18, 0.18), Color("b8962e"))
	# blinde spitsboog met venstertjes in de geveltop
	_pointed(f, "Gable arch", 0, CH_H + 1.2, 4.6, 3.8, STONE, 0.02)
	_pointed(f, "Gable arch inner", 0, CH_H + 1.3, 4.2, 3.6, Color("7d4a3c"), 0.03)
	for k in range(5):
		var gx: float = -1.6 + float(k) * 0.8
		_pointed(f, "Gable lancet", gx, CH_H + 1.6, 0.5, 2.6 - absf(gx) * 0.5, GLASS, 0.06)
	# hoog spitsboogvenster met tracering
	_pointed(f, "Main window frame", 0, 3.6, 4.4, 12.2, STONE, 0.03)
	_pointed(f, "Main window", 0, 3.8, 3.9, 11.8, Color("33404a"), 0.05)
	for k in range(4):
		Kit.box(f, "Tracery mullion", Vector3(-1.2 + float(k) * 0.8, 9.0, 0.08), Vector3(0.12, 9.6, 0.05), STONE)
	Kit.box(f, "Tracery transom", Vector3(0, 9.0, 0.08), Vector3(3.9, 0.14, 0.05), STONE)
	Kit.cyl(f, "Tracery rose", Vector3(0, 14.6, 0.08), 0.8, 0.8, 0.05, STONE, 14, "z")
	Kit.cyl(f, "Tracery rose glass", Vector3(0, 14.6, 0.1), 0.6, 0.6, 0.04, Color("33404a"), 14, "z")
	# balustrade onder het venster en het portaal met glazen deuren
	Kit.box(f, "Window balustrade", Vector3(0, 3.6, 0.2), Vector3(4.6, 0.9, 0.4), STONE)
	for k in range(8):
		_pointed(f, "Balustrade arch", -1.9 + float(k) * 0.54, 3.25, 0.32, 0.6, Color("7d4a3c"), 0.42)
	Kit.box(f, "Portal frame", Vector3(0, 1.6 + 0.1, 0.04), Vector3(3.6, 2.6, 0.08), Color("6a5a4a"))
	Kit.box(f, "Portal doors", Vector3(0, 1.6, 0.08), Vector3(3.2, 2.4, 0.05), Color("3a4448"))
	Kit.box(f, "Portal door split", Vector3(0, 1.6, 0.12), Vector3(0.1, 2.4, 0.03), Color("6a5a4a"))
	# trap van vier treden naar het portaal
	for k in range(4):
		var dpt: float = float(4 - k) * 0.45
		Kit.box(f, "Step", Vector3(0, 0.12 + float(k) * 0.24, dpt * 0.5), Vector3(5.0, 0.24, dpt), STONE, true)
	for s in [-1.0, 1.0]:
		Kit.beam(f, "Stair rail", Vector3(s * 2.6, 0.9, 2.0), Vector3(s * 2.6, 1.6, 0.2), 0.05, IRON)
		# zijvensters naast het grote venster, met een lantaarn
		_pointed(f, "Side lancet frame", s * 3.8, 2.6, 1.3, 3.6, STONE, 0.03)
		_pointed(f, "Side lancet", s * 3.8, 2.7, 1.05, 3.4, GLASS, 0.05)
		_pointed(f, "Upper lancet frame", s * 3.8, 8.6, 1.3, 3.4, STONE, 0.03)
		_pointed(f, "Upper lancet", s * 3.8, 8.7, 1.05, 3.2, GLASS, 0.05)
		Kit.box(f, "Lantern", Vector3(s * 2.6, 3.4, 0.35), Vector3(0.3, 0.5, 0.3), IRON)
		# hoektorentjes met pinakels
		var tx: float = s * (hw + 0.6)
		Kit.box(f, "Corner tower", Vector3(tx, 9.5, -0.2), Vector3(2.2, 19.0, 2.2), Color.WHITE, true, brick)
		for y in [4.0, 9.0, 13.5]:
			Kit.box(f, "Tower ledge", Vector3(tx, y, -0.2), Vector3(2.5, 0.25, 2.5), STONE)
		Kit.box(f, "Tower cap", Vector3(tx, 19.2, -0.2), Vector3(2.6, 0.4, 2.6), STONE)
		Kit.pyramid(f, "Tower pinnacle", Vector3(tx, 19.4, -0.2), 0.9, 3.0, STONE)
		for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			Kit.pyramid(f, "Small pinnacle", Vector3(tx + c.x * 1.0, 19.4, -0.2 + c.y * 1.0), 0.2, 1.4, STONE)
		# balustrade-galerij tussen torentje en vleugel
		var gx: float = s * (hw + 3.0)
		Kit.box(f, "Gallery", Vector3(gx, 13.0, -3.5), Vector3(3.0, 0.4, 7.0), STONE)
		for k in range(6):
			Kit.box(f, "Gallery baluster", Vector3(gx + s * 1.4, 13.5, -6.6 + float(k) * 1.2), Vector3(0.18, 0.8, 0.18), STONE)
		Kit.box(f, "Gallery rail", Vector3(gx + s * 1.4, 13.95, -3.5), Vector3(0.25, 0.15, 7.0), STONE)
		var arch := Kit.beam(f, "Flying arch", Vector3(tx, 15.5, -0.6), Vector3(s * (hw + 5.8), 13.2, -4.0), 0.5, Color("8e5444"))
		arch.name = "Flying arch"
		Kit.box(f, "Gallery pier", Vector3(s * (hw + 5.8), 14.0, -4.0), Vector3(0.9, 2.0, 0.9), Color.WHITE, false, brick)
		Kit.pyramid(f, "Gallery pinnacle", Vector3(s * (hw + 5.8), 15.0, -4.0), 0.4, 1.8, STONE)
	# zijkanten (alleen het deel achter de vleugels is te zien): steunberen en vensters
	for s in [-1.0, 1.0]:
		var sf := Kit.face(self, Vector3(s * hw, 0, 0), 90.0 * s)
		for k in range(5):
			var z: float = -WING_D - 3.0 - float(k) * 4.6
			var fx: float = -z * s
			_pointed(sf, "Chapel lancet", fx, 2.0, 1.3, 3.2, GLASS, 0.05)
			_pointed(sf, "Chapel lancet high", fx, 7.0, 1.6, 6.0, GLASS, 0.05)
			var bx: float = -(z + 2.3) * s
			Kit.box(sf, "Buttress", Vector3(bx, 6.5, 0.6), Vector3(1.0, 13.0, 1.2), Color.WHITE, false, brick)
			Kit.pyramid(sf, "Buttress pinnacle", Vector3(bx, 13.0, 0.6), 0.45, 2.2, STONE)
	# dakruiter op de nok, achter de vleugels
	var rt := Vector3(0, CH_H + rise - 0.6, -WING_D - 2.0)
	Kit.cyl(self, "Ridge turret", rt + Vector3(0, 1.8, 0), 1.0, 1.0, 3.6, SLATE, 8)
	for k in range(4):
		var a: float = float(k) * PI * 0.5
		Kit.box(self, "Turret louvre", rt + Vector3(cos(a) * 1.0, 2.2, sin(a) * 1.0), Vector3(0.5, 1.4, 0.5), Color("2c2e33"))
	Kit.cyl(self, "Ridge spire", rt + Vector3(0, 10.6, 0), 1.05, 0.0, 14.0, SLATE, 8)
	Kit.cyl(self, "Spire cross", rt + Vector3(0, 18.4, 0), 0.05, 0.05, 1.6, Color("b8962e"), 6)
	Kit.box(self, "Spire cross arm", rt + Vector3(0, 18.6, 0), Vector3(0.7, 0.08, 0.08), Color("b8962e"))

# ---------------------------------------------------------------- hek
func _fence() -> void:
	var fz := 8.0
	Kit.box(self, "Lawn", Vector3(0, 0.03, fz * 0.5), Vector3(WING_X1 * 2.0, 0.06, fz), Color("5f8a45"))
	Kit.box(self, "Forecourt", Vector3(0, 0.05, fz * 0.5 + 1.0), Vector3(9.0, 0.1, fz + 2.0), Color("a49a8a"))
	for side in [-1.0, 1.0]:
		var x0: float = 5.0 * side
		var x1: float = (WING_X1 + 1.0) * side
		var cx: float = (x0 + x1) * 0.5
		var ln: float = absf(x1 - x0)
		Kit.box(self, "Fence wall", Vector3(cx, 0.35, fz), Vector3(ln, 0.7, 0.5), Color.WHITE, true, brick)
		Kit.box(self, "Fence wall cap", Vector3(cx, 0.74, fz), Vector3(ln, 0.08, 0.6), STONE)
		Kit.box(self, "Fence rail", Vector3(cx, 1.0, fz), Vector3(ln, 0.05, 0.05), IRON)
		Kit.box(self, "Fence rail", Vector3(cx, 2.1, fz), Vector3(ln, 0.05, 0.05), IRON)
		# spijlen als multimesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var bar := BoxMesh.new()
		bar.size = Vector3(0.04, 1.6, 0.04)
		mm.mesh = bar
		var n: int = int(ln / 0.16)
		mm.instance_count = n
		for k in range(n):
			mm.set_instance_transform(k, Transform3D(Basis(), Vector3(lerpf(x0, x1, float(k) / float(n)), 1.58, fz)))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Fence bars"
		mmi.multimesh = mm
		mmi.material_override = Kit.mat(IRON)
		add_child(mmi)
		var posts: int = int(ln / 4.0)
		for k in range(posts + 1):
			Kit.box(self, "Fence post", Vector3(lerpf(x0, x1, float(k) / float(posts)), 1.3, fz), Vector3(0.12, 1.2, 0.12), IRON)
		# poortpijlers met witte kap
		Kit.box(self, "Gate pier", Vector3(x0, 1.2, fz), Vector3(0.9, 2.4, 0.9), Color.WHITE, true, brick)
		Kit.box(self, "Gate pier cap", Vector3(x0, 2.5, fz), Vector3(1.1, 0.25, 1.1), STONE)
