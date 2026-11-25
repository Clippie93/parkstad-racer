extends Node3D
# Kasteel Hoensbroek (Heerlen), naar jouw foto's (23-11):
# - de hoofdburcht ligt in de gracht: rode baksteen met lichte natuurstenen hoekblokken en
#   vensteromlijstingen, vensters met rode luiken, grijze leien schilddaken met dakkapellen
#   en schoorstenen
# - links vooraan een hoge ronde toren met een spitse kegelvormige leien spits; rechts
#   vooraan een vierkante toren met hoekblokken en een uitlopende, spitse leien kap met een
#   lantaarntje; achterop twee torens met een uivormige koepel; vooraan in het water een
#   laag rond torentje met een kegeldak
# - links de voorburcht: lange lage vleugels met hoge grijze schilddaken, een hoekpaviljoen
#   en een poorttorentje, met een boogbrug naar de hoofdburcht
# - tussen de weg en de gracht een grasveld met grote bomen
# Lokale ruimte: +Z = naar de weg. De hoofdburcht staat rechts (+X), de voorburcht links.
const Kit = preload("res://scripts/build_kit.gd")

const STONE := Color("d9d2c2")
const SLATE := Color("6a6e77")
const SLATE_DARK := Color("4e525a")
const GLASS := Color("2c3438")
const FRAME := Color("f0ede6")
const SHUTTER := Color("a3272b")
const WATER := Color("2c4650")
const MC := Vector3(26, 0, -4)     # midden van de hoofdburcht

var brick: Material

func _ready() -> void:
	name = "Kasteel Hoensbroek"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("d8a090"), 3.0)
	# grasveld en gracht rond de hoofdburcht, met een vijver naar de weg toe
	# (naar de kant waar je vandaan komt loopt het grasveld verder door: het kasteel zie je al van ver)
	Kit.box(self, "Castle park", Vector3(38.0, 0.03, 12.0), Vector3(226.0, 0.06, 114.0), Color("6d9a4c"))
	var water := Kit.mat(WATER, 0.0, 0.25, 0.12)
	Kit.box(self, "Moat", MC + Vector3(0, 0.08, 4.0), Vector3(62.0, 0.06, 66.0), Color.WHITE, false, water)
	Kit.box(self, "Moat bank", MC + Vector3(0, 0.05, 4.0), Vector3(64.0, 0.05, 68.0), Color("55704a"))
	_main_castle()
	_forecourt()
	_bridge()
	for tp in [Vector3(-60, 0, 52), Vector3(-34, 0, 56), Vector3(-6, 0, 50), Vector3(64, 0, 50), Vector3(66, 0, 10), Vector3(-66, 0, -10)]:
		_tree(tp)

# ---------------------------------------------------------------- hulpjes
func _mesh(n: String, tris: Array, m: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, m)
	mi.position = at
	add_child(mi)
	return mi

# Schilddak over een blok van sx bij sz, nok langs de langste kant.
func _hip_roof(n: String, base: Vector3, sx: float, sz: float, rise: float, color := SLATE) -> void:
	var hx: float = sx * 0.5 + 0.4
	var hz: float = sz * 0.5 + 0.4
	var t: Array = []
	if sx >= sz:
		var r: float = hx - hz
		var a := Vector3(-r, rise, 0)
		var b := Vector3(r, rise, 0)
		Kit._quad(t, Vector3(-hx, 0, hz), Vector3(hx, 0, hz), b, a)
		Kit._quad(t, Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), a, b)
		t.append_array([Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), a])
		t.append_array([Vector3(hx, 0, hz), Vector3(hx, 0, -hz), b])
	else:
		var r: float = hz - hx
		var a := Vector3(0, rise, -r)
		var b := Vector3(0, rise, r)
		Kit._quad(t, Vector3(hx, 0, -hz), Vector3(hx, 0, hz), b, a)
		Kit._quad(t, Vector3(-hx, 0, hz), Vector3(-hx, 0, -hz), a, b)
		t.append_array([Vector3(-hx, 0, hz), Vector3(hx, 0, hz), b])
		t.append_array([Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), a])
	_mesh(n, t, Kit._two_sided(color), base)

# Bakstenen blok met natuurstenen hoekblokken en een schilddak.
func _wing(n: String, c: Vector3, sx: float, sz: float, h: float, rise: float, quoins := true) -> void:
	Kit.box(self, n, c + Vector3(0, h * 0.5, 0), Vector3(sx, h, sz), Color.WHITE, true, brick)
	Kit.box(self, n + " plinth", c + Vector3(0, 0.6, 0), Vector3(sx + 0.15, 1.2, sz + 0.15), Color("b7ac98"))
	_hip_roof(n + " roof", c + Vector3(0, h, 0), sx, sz, rise)
	if quoins:
		for sxs in [-1.0, 1.0]:
			for szs in [-1.0, 1.0]:
				_quoin(c + Vector3(sxs * sx * 0.5, 0, szs * sz * 0.5), h, -sxs, -szs)

# Hoekblokken: om en om lange en korte lichte stenen op een hoek, vrijwel vlak in de gevel
# (ix, iz: richting naar binnen).
func _quoin(p: Vector3, h: float, ix: float, iz: float) -> void:
	var y := 1.2
	var k := 0
	while y < h - 0.3:
		var l: float = 0.95 if k % 2 == 0 else 0.5
		# twee dunne platen: één op elke gevel van de hoek
		Kit.box(self, "Quoin", p + Vector3(ix * l * 0.5, y + 0.3, -iz * 0.03), Vector3(l, 0.55, 0.08), STONE)
		Kit.box(self, "Quoin", p + Vector3(-ix * 0.03, y + 0.3, iz * l * 0.5), Vector3(0.08, 0.55, l), STONE)
		y += 0.7
		k += 1

# Venster met lichte omlijsting, wit kozijn met kruis en twee open rode luiken, in face-ruimte.
func _win(f: Node3D, x: float, y: float, w := 1.1, h := 1.7, shutters := true) -> void:
	Kit.box(f, "Window surround", Vector3(x, y + h * 0.5, 0.04), Vector3(w + 0.4, h + 0.4, 0.08), STONE)
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.08), Vector3(w, h, 0.04), FRAME)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.11), Vector3(w - 0.16, h - 0.16, 0.03), GLASS)
	Kit.box(f, "Window cross", Vector3(x, y + h * 0.62, 0.13), Vector3(w - 0.1, 0.07, 0.02), FRAME)
	Kit.box(f, "Window mullion", Vector3(x, y + h * 0.5, 0.13), Vector3(0.07, h - 0.1, 0.02), FRAME)
	if shutters:
		for s in [-1.0, 1.0]:
			Kit.box(f, "Shutter", Vector3(x + s * (w * 0.5 + 0.48), y + h * 0.5, 0.09), Vector3(0.5, h, 0.05), SHUTTER)

func _win_grid(f: Node3D, xs: Array, ys: Array, w := 1.1, h := 1.7) -> void:
	for x in xs:
		for y in ys:
			_win(f, float(x), float(y), w, h)

# Spits: een kegel met een iets uitlopende voet, een bolletje en een windvaan.
func _spire(p: Vector3, r: float, h: float, color := SLATE) -> void:
	Kit.cyl(self, "Spire skirt", p + Vector3(0, 0.6, 0), r + 0.6, r - 0.1, 1.2, color, 20)
	Kit.cyl(self, "Spire", p + Vector3(0, 1.2 + h * 0.5, 0), r - 0.1, 0.12, h, color, 20)
	_finial(p + Vector3(0, 1.2 + h, 0))

func _finial(p: Vector3) -> void:
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	ball.mesh = sm
	ball.material_override = Kit.mat(Color("8a8f94"))
	ball.position = p + Vector3(0, 0.2, 0)
	add_child(ball)
	Kit.cyl(self, "Weather vane rod", p + Vector3(0, 1.2, 0), 0.04, 0.04, 2.0, Color("2a2b2d"), 6)
	Kit.box(self, "Weather vane", p + Vector3(0.3, 1.9, 0), Vector3(0.7, 0.35, 0.03), Color("2a2b2d"))

# Toren met een uivormige koepel en een lantaarntje.
func _onion_tower(p: Vector3, r: float, h: float) -> void:
	Kit.cyl(self, "Onion tower", p + Vector3(0, h * 0.5, 0), r, r, h, Color.WHITE, 16, "y", true, brick)
	Kit.cyl(self, "Onion tower cornice", p + Vector3(0, h + 0.15, 0), r + 0.25, r + 0.25, 0.3, STONE, 16)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r * 1.1
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	dome.mesh = sm
	dome.material_override = Kit.mat(SLATE_DARK)
	dome.position = p + Vector3(0, h + r * 0.85, 0)
	add_child(dome)
	Kit.cyl(self, "Onion tip", p + Vector3(0, h + r * 2.0, 0), r * 0.55, 0.2, r * 0.9, SLATE_DARK, 12)
	Kit.cyl(self, "Lantern", p + Vector3(0, h + r * 2.6, 0), 0.45, 0.45, 1.0, SLATE_DARK, 8)
	Kit.cyl(self, "Lantern cap", p + Vector3(0, h + r * 3.3, 0), 0.55, 0.08, 1.2, SLATE_DARK, 8)
	_finial(p + Vector3(0, h + r * 3.9, 0))

# ---------------------------------------------------------------- hoofdburcht
func _main_castle() -> void:
	var fz: float = MC.z + 15.0           # voorgevel (naar de weg)
	# vier vleugels rond een binnenplaats
	_wing("Front wing", MC + Vector3(0, 0, 10.0), 32.0, 10.0, 15.0, 6.5)
	_wing("Back wing", MC + Vector3(0, 0, -11.0), 32.0, 9.0, 13.0, 6.0)
	_wing("Left wing", MC + Vector3(-12.0, 0, 0), 8.0, 13.0, 13.0, 5.5, false)
	_wing("Right wing", MC + Vector3(12.0, 0, 0), 8.0, 13.0, 13.0, 5.5, false)
	# voorgevel: vier lagen vensters, de bovenste kleiner
	var f := Kit.face(self, Vector3(MC.x, 0, fz), 0.0)
	_win_grid(f, [-9.0, -5.0, -1.0, 3.0, 7.0], [1.8, 5.2, 8.6], 1.2, 2.0)
	_win_grid(f, [-9.0, -5.0, -1.0, 3.0, 7.0], [11.9], 1.0, 1.4)
	Kit.box(f, "Cornice", Vector3(0, 14.8, 0.1), Vector3(32.0, 0.35, 0.3), STONE)
	# zijgevels van de vleugels (naar links en rechts)
	for s in [-1.0, 1.0]:
		var sf := Kit.face(self, Vector3(MC.x + s * 16.0, 0, MC.z), 90.0 * s)
		_win_grid(sf, [-12.0, -7.0, -2.0, 3.0, 8.0], [1.8, 5.2, 8.6], 1.1, 1.8)
	var bf := Kit.face(self, Vector3(MC.x, 0, MC.z - 15.5), 180.0)
	_win_grid(bf, [-10.0, -5.0, 0.0, 5.0, 10.0], [1.8, 5.2, 8.6], 1.1, 1.8)
	# dakkapellen en schoorstenen
	for x in [-8.0, -2.0, 4.0]:
		_dormer(Vector3(MC.x + x, 17.3, fz - 2.0))
	for c in [Vector3(-10, 0, 9), Vector3(4, 0, 11), Vector3(-6, 0, -11), Vector3(9, 0, -12)]:
		Kit.box(self, "Chimney", MC + c + Vector3(0, 21.0, 0), Vector3(1.0, 3.0, 1.4), Color.WHITE, false, brick)
		Kit.box(self, "Chimney cap", MC + c + Vector3(0, 22.6, 0), Vector3(1.2, 0.2, 1.6), STONE)
	# ronde toren links vooraan
	var rt: Vector3 = MC + Vector3(-17.0, 0, 13.0)
	Kit.cyl(self, "Round tower", rt + Vector3(0, 11.5, 0), 5.0, 5.0, 23.0, Color.WHITE, 24, "y", true, brick)
	Kit.cyl(self, "Round tower plinth", rt + Vector3(0, 0.8, 0), 5.3, 5.3, 1.6, Color("b7ac98"), 24)
	Kit.cyl(self, "Round tower cornice", rt + Vector3(0, 23.1, 0), 5.3, 5.3, 0.3, STONE, 24)
	for a in [0.2, 0.75, 1.3]:
		for y in [4.0, 10.0, 16.0]:
			var d := Vector3(sin(a), 0, cos(a))
			var wf := Kit.face(self, rt + d * 5.0, rad_to_deg(a))
			_win(wf, 0.0, y, 0.7, 1.1, false)
	_spire(rt + Vector3(0, 23.2, 0), 5.0, 14.0)
	# vierkante toren rechts vooraan
	var st: Vector3 = MC + Vector3(17.0, 0, 13.0)
	_wing("Square tower", st, 9.0, 9.0, 25.0, 0.0)
	for side in [0.0, 90.0]:
		var d := Vector3(sin(deg_to_rad(side)), 0, cos(deg_to_rad(side)))
		var tf := Kit.face(self, st + d * 4.5, side)
		_win_grid(tf, [-1.9, 1.9], [2.2, 6.6, 11.0, 15.4, 19.8], 0.9, 1.6)
	Kit.box(self, "Tower cornice", st + Vector3(0, 25.1, 0), Vector3(9.6, 0.35, 9.6), STONE)
	Kit.pyramid(self, "Tower roof skirt", st + Vector3(0, 25.2, 0), 5.4, 2.4, SLATE)
	Kit.pyramid(self, "Tower roof", st + Vector3(0, 25.6, 0), 4.0, 9.5, SLATE)
	Kit.cyl(self, "Tower lantern", st + Vector3(0, 34.6, 0), 0.6, 0.6, 1.4, SLATE_DARK, 8)
	Kit.cyl(self, "Tower lantern cap", st + Vector3(0, 36.0, 0), 0.8, 0.1, 1.6, SLATE_DARK, 8)
	_finial(st + Vector3(0, 36.8, 0))
	# torens met uivormige koepel achterop
	_onion_tower(MC + Vector3(-6.0, 0, -4.0), 2.6, 19.0)
	_onion_tower(MC + Vector3(9.0, 0, -6.0), 2.4, 18.0)
	# laag rond torentje vooraan in het water
	var lt: Vector3 = MC + Vector3(-3.0, 0, fz - MC.z + 1.8)
	Kit.cyl(self, "Front turret", lt + Vector3(0, 4.5, 0), 2.4, 2.4, 9.0, Color.WHITE, 16, "y", true, brick)
	Kit.cyl(self, "Front turret roof", lt + Vector3(0, 11.3, 0), 2.9, 0.1, 4.6, SLATE, 16)
	var tw := Kit.face(self, lt + Vector3(0, 0, 2.4), 0.0)
	_win(tw, 0.0, 4.0, 0.7, 1.1, true)

func _dormer(p: Vector3) -> void:
	Kit.box(self, "Dormer", p, Vector3(1.4, 1.6, 1.2), Color.WHITE, false, brick)
	Kit.box(self, "Dormer window", p + Vector3(0, 0, 0.62), Vector3(0.8, 1.0, 0.04), GLASS)
	Kit.pyramid(self, "Dormer roof", p + Vector3(0, 0.8, 0), 0.9, 0.9, SLATE)

# ---------------------------------------------------------------- voorburcht
func _forecourt() -> void:
	# lange vleugel evenwijdig aan de weg en een vleugel naar achteren, met hoge schilddaken
	_wing("Forecourt front wing", Vector3(-30.0, 0, 6.0), 44.0, 9.0, 7.0, 7.5, false)
	_wing("Forecourt side wing", Vector3(-55.0, 0, -14.0), 9.0, 32.0, 7.0, 7.5, false)
	var ff := Kit.face(self, Vector3(-30.0, 0, 10.5), 0.0)
	for x in [-19.0, -15.0, -11.0, -7.0, 1.0, 5.0, 9.0, 13.0, 17.0]:
		_win(ff, x, 1.3, 1.0, 1.4, false)
		_win(ff, x, 4.3, 0.8, 1.0, false)
	# poortdoorgang met rondboog
	Kit.box(ff, "Gate arch surround", Vector3(-3.0, 1.9, 0.05), Vector3(3.6, 3.8, 0.1), STONE)
	Kit.box(ff, "Gate opening", Vector3(-3.0, 1.6, 0.1), Vector3(2.8, 3.2, 0.06), Color("2a2622"))
	# hoekpaviljoen met piramidedak en rode luiken
	var cp := Vector3(-55.0, 0, 6.0)
	_wing("Corner pavilion", cp, 10.0, 10.0, 9.0, 0.0)
	Kit.pyramid(self, "Pavilion roof", cp + Vector3(0, 9.0, 0), 5.6, 7.0, SLATE)
	var pf := Kit.face(self, cp + Vector3(0, 0, 5.0), 0.0)
	_win_grid(pf, [-2.2, 2.2], [1.4, 5.0], 0.9, 1.5)
	# poorttorentje bij het water (eerste foto): baksteen met natuursteen, piramidedak
	var gt := Vector3(-36.0, 0, 15.0)
	_wing("Gate tower", gt, 6.0, 6.0, 9.5, 0.0)
	Kit.pyramid(self, "Gate tower roof", gt + Vector3(0, 9.5, 0), 3.6, 4.5, SLATE)
	for y in [2.5, 6.0]:
		Kit.box(self, "Gate tower band", gt + Vector3(0, y, 0), Vector3(6.1, 0.35, 6.1), STONE)
	var gf := Kit.face(self, gt + Vector3(0, 0, 3.0), 0.0)
	_win(gf, 0.0, 3.2, 0.8, 1.2, true)
	_win(gf, 0.0, 6.8, 0.8, 1.2, true)

# Boogbrug van de voorburcht naar de hoofdburcht.
func _bridge() -> void:
	var x0 := -8.0
	var x1: float = MC.x - 16.0
	var z := -2.0
	var xc: float = (x0 + x1) * 0.5
	var ln: float = x1 - x0
	Kit.box(self, "Bridge deck", Vector3(xc, 2.6, z), Vector3(ln, 0.8, 4.0), Color.WHITE, true, brick)
	for s in [-1.0, 1.0]:
		Kit.box(self, "Bridge parapet", Vector3(xc, 3.4, z + s * 1.9), Vector3(ln, 0.9, 0.35), Color.WHITE, false, brick)
		Kit.box(self, "Parapet cap", Vector3(xc, 3.9, z + s * 1.9), Vector3(ln, 0.12, 0.45), STONE)
	for k in range(3):
		var x: float = x0 + ln * (float(k) + 0.5) / 3.0
		Kit.box(self, "Bridge pier", Vector3(x + ln / 6.0, 1.2, z), Vector3(1.0, 2.4, 4.0), Color.WHITE, false, brick)
		for s in [-1.0, 1.0]:
			Kit.box(self, "Bridge arch", Vector3(x - 0.3, 1.1, z + s * 2.02), Vector3(ln / 3.0 - 1.6, 1.8, 0.05), Color("26303a"))

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 4.5, 0), 0.55, 0.4, 9.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 5.5
	cm.height = 8.5
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("5d7f3c"))
	cr.position = p + Vector3(0, 11.5, 0)
	add_child(cr)
