extends Node3D
# Schacht Nulland (Kerkrade), naar jouw foto's (23-11). Wegkant:
# - een groot zandkleurig gepleisterd blok op een donkere stenen voet, onderaan een rij
#   grote rondbogen met diepe loggia's en balustrades, verspreid kleine vierkante raampjes,
#   rechts een donkere plaquette (het wapen)
# - in het midden de ronde toren: onderaan een halfronde uitbouw met een rand van kleine
#   boogjes, daarboven de hoge ronde toren met smalle sleuven, een kroonlijst en een
#   vlaggenmast met een rood-witte vlag
# - links een schuine muur van het lagere deel omhoog naar de toren, met boogopeningen
# - links daarvan een lage vleugel met hoge boogramen met blauwe kozijnen en een terras
# Achterkant (niet de wegkant): de grijze geklonken ventilatortoren en het halfronde
# ventilatorhuis. Ervoor een paar mijnkarretjes.
# Lokale ruimte: +Z = naar de weg; +X = rechts gezien vanaf de weg. Voorgevel op z = 0.
const Kit = preload("res://scripts/build_kit.gd")

const SAND := Color("e6cf9f")
const SAND_DARK := Color("cdb584")
const SHADOW := Color("b59f72")       # diepte in de loggia's
const BASE := Color("45474b")
const SLOT := Color("2a2c30")
const BLUE := Color("2d5a9a")
const STEEL := Color("8c959c")
const RAIL := Color("9aa0a5")

func _ready() -> void:
	name = "Schacht Nulland"
	Kit.box(self, "Nulland grounds", Vector3(-4, 0.03, -12), Vector3(76.0, 0.06, 34.0), Color("aaa59a"))
	Kit.box(self, "Stone base", Vector3(-4, 0.75, 0.9), Vector3(62.0, 1.5, 1.6), BASE, true)
	_main_block()
	_tower()
	_slope_wall()
	_low_wing()
	_back()
	_locomotive(Vector3(-26.0, 0, 5.5))
	for x in [-14.0, -11.5]:
		_mine_cart(Vector3(x, 0, 4.0))
	_mine_cart(Vector3(18.0, 0, 4.2), Color("d9a520"))

func _mesh(n: String, tris: Array, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, Kit._two_sided(color))
	add_child(mi)

func _square_window(f: Node3D, x: float, y: float, s := 0.7) -> void:
	Kit.box(f, "Small window", Vector3(x, y, 0.04), Vector3(s, s, 0.06), SLOT)

# ---------------------------------------------------------------- hoofdblok
func _main_block() -> void:
	var x0 := -3.0
	var x1 := 23.0
	var d := 13.0
	# linkerdeel lager (daar begint de schuine muur), rechterdeel tot 22 m
	Kit.box(self, "Main block left", Vector3((x0 + 7.0) * 0.5, 9.0, -d * 0.5), Vector3(7.0 - x0, 18.0, d), SAND, true)
	Kit.box(self, "Main block right", Vector3((7.0 + x1) * 0.5, 11.0, -d * 0.5), Vector3(x1 - 7.0, 22.0, d), SAND, true)
	Kit.box(self, "Main cornice", Vector3((7.0 + x1) * 0.5, 22.1, -d * 0.5), Vector3(x1 - 7.0 + 0.3, 0.25, d + 0.3), SAND_DARK)
	var f := Kit.face(self, Vector3(0, 0, 0), 0.0)
	# rij grote rondbogen met loggia's en balustrades
	for ax in [-0.5, 4.0, 9.0, 14.0, 19.0]:
		var w := 3.8
		Kit.box(f, "Loggia", Vector3(ax, 4.8, 0.03), Vector3(w, 6.6, 0.06), SHADOW)
		Kit.cyl(f, "Loggia arch", Vector3(ax, 8.1, 0.03), w * 0.5, w * 0.5, 0.06, SHADOW, 20, "z")
		Kit.box(f, "Loggia back", Vector3(ax, 4.6, 0.05), Vector3(w - 1.2, 5.6, 0.04), Color("9f8a60"))
		Kit.box(f, "Balustrade rail", Vector3(ax, 2.6, 0.2), Vector3(w - 0.2, 0.08, 0.08), RAIL)
		for k in range(5):
			Kit.box(f, "Balustrade bar", Vector3(ax - w * 0.4 + float(k) * w * 0.2, 2.1, 0.2), Vector3(0.05, 1.0, 0.05), RAIL)
		Kit.box(f, "Balcony slab", Vector3(ax, 1.55, 0.3), Vector3(w + 0.2, 0.15, 0.6), SAND_DARK)
	# pijlers tussen de bogen iets naar voren
	for px in [-2.7, 1.75, 6.5, 11.5, 16.5, 21.5]:
		Kit.box(f, "Pier", Vector3(px, 5.0, 0.12), Vector3(0.7, 10.0, 0.25), SAND)
	# verspreide kleine vierkante raampjes
	for p in [Vector3(-1.5, 0.7, 0), Vector3(1.5, 0.7, 0), Vector3(5.0, 0.7, 0), Vector3(8.0, 0.7, 0), Vector3(12.5, 0.7, 0), Vector3(16.0, 0.7, 0), Vector3(20.0, 0.7, 0),
			Vector3(14.0, 12.5, 0), Vector3(19.5, 12.0, 0), Vector3(21.5, 16.0, 0), Vector3(21.5, 19.5, 0), Vector3(15.5, 18.5, 0)]:
		_square_window(f, p.x, p.y)
	# het wapen rechtsboven: twee staande leeuwen met een schild en een kroon, op een balk
	# met de naam (vereenvoudigd reliëf)
	_coat_of_arms(f, Vector3(17.5, 14.6, 0.1))
	# deur rechts
	Kit.box(f, "Door", Vector3(21.8, 1.1, 0.05), Vector3(1.1, 2.2, 0.06), BLUE)

func _coat_of_arms(f: Node3D, p: Vector3, sc := 1.0) -> void:
	var ink := Color("2a2c2e")
	var g := Node3D.new()
	g.position = p
	g.scale = Vector3(sc, sc, 1.0)
	f.add_child(g)
	# naambalk
	Kit.box(g, "Arms plaque", Vector3(0, -0.15, 0), Vector3(3.8, 0.5, 0.14), ink)
	Kit.label(g, "SCHACHT NULLAND", Vector3(0, -0.15, 0.09), 0.009, Color("c9cbc6"), 40)
	# schild met een klimmende leeuw erin
	Kit.box(g, "Arms shield", Vector3(0, 1.15, 0), Vector3(1.1, 1.3, 0.18), ink)
	Kit.cyl(g, "Arms shield point", Vector3(0, 0.55, 0), 0.55, 0.55, 0.18, ink, 14, "z")
	Kit.box(g, "Shield edge", Vector3(0, 1.15, 0.1), Vector3(0.95, 1.15, 0.03), Color("3a3c3f"))
	var sl := Kit.box(g, "Shield lion", Vector3(0, 1.1, 0.13), Vector3(0.32, 0.75, 0.03), ink)
	sl.rotation.z = -0.35
	Kit.cyl(g, "Shield lion head", Vector3(0.12, 1.5, 0.13), 0.12, 0.12, 0.03, ink, 8, "z")
	# grote kroon met bogen, rijksappel en kruis
	Kit.box(g, "Crown band", Vector3(0, 1.95, 0), Vector3(1.3, 0.25, 0.18), ink)
	for cx in [-0.55, -0.27, 0.0, 0.27, 0.55]:
		Kit.cyl(g, "Crown pearl", Vector3(cx, 2.15, 0), 0.08, 0.08, 0.18, ink, 8, "z")
	for sx in [-1.0, 1.0]:
		var arc := Kit.box(g, "Crown arch", Vector3(sx * 0.33, 2.35, 0), Vector3(0.12, 0.55, 0.18), ink)
		arc.rotation.z = sx * 0.6
	Kit.cyl(g, "Crown orb", Vector3(0, 2.62, 0), 0.13, 0.13, 0.18, ink, 10, "z")
	Kit.box(g, "Crown cross", Vector3(0, 2.92, 0), Vector3(0.07, 0.38, 0.18), ink)
	Kit.box(g, "Crown cross bar", Vector3(0, 2.98, 0), Vector3(0.24, 0.07, 0.18), ink)
	# twee steigerende leeuwen met gekroonde kop, opgeheven klauwen en gekrulde staart
	for sx in [-1.0, 1.0]:
		var lp := Vector3(sx * 1.2, 0, 0)
		var body := Kit.box(g, "Lion body", lp + Vector3(sx * 0.05, 1.0, 0), Vector3(0.45, 1.05, 0.16), ink)
		body.rotation.z = -sx * 0.35
		var chest := Kit.cyl(g, "Lion chest", lp + Vector3(-sx * 0.1, 1.38, 0), 0.3, 0.3, 0.16, ink, 10, "z")
		Kit.cyl(g, "Lion mane", lp + Vector3(-sx * 0.2, 1.78, 0), 0.34, 0.34, 0.15, ink, 10, "z")
		Kit.cyl(g, "Lion head", lp + Vector3(-sx * 0.3, 1.86, 0.02), 0.21, 0.21, 0.16, ink, 12, "z")
		Kit.box(g, "Lion snout", lp + Vector3(-sx * 0.5, 1.8, 0.02), Vector3(0.2, 0.14, 0.16), ink)
		Kit.box(g, "Lion crown", lp + Vector3(-sx * 0.27, 2.16, 0), Vector3(0.32, 0.16, 0.16), ink)
		for cx in [-0.12, 0.0, 0.12]:
			Kit.box(g, "Lion crown point", lp + Vector3(-sx * 0.27 + cx, 2.28, 0), Vector3(0.06, 0.12, 0.16), ink)
		# klauwen tegen het schild
		for k in range(2):
			var paw := Kit.box(g, "Lion paw", lp + Vector3(-sx * 0.42, 1.25 + float(k) * 0.32, 0), Vector3(0.45, 0.12, 0.16), ink)
			paw.rotation.z = sx * (0.5 - float(k) * 0.3)
		# achterpoten
		for lx in [-0.15, 0.2]:
			var leg := Kit.box(g, "Lion hind leg", lp + Vector3(sx * lx, 0.32, 0), Vector3(0.16, 0.62, 0.16), ink)
			leg.rotation.z = sx * 0.2
			Kit.box(g, "Lion foot", lp + Vector3(sx * lx - sx * 0.05, 0.04, 0), Vector3(0.26, 0.09, 0.16), ink)
		# gekrulde staart met kwast
		var t1 := Kit.box(g, "Lion tail", lp + Vector3(sx * 0.42, 0.95, 0), Vector3(0.09, 0.6, 0.12), ink)
		t1.rotation.z = sx * 0.6
		var t2 := Kit.box(g, "Lion tail", lp + Vector3(sx * 0.6, 1.35, 0), Vector3(0.09, 0.45, 0.12), ink)
		t2.rotation.z = -sx * 0.3
		Kit.cyl(g, "Lion tail tuft", lp + Vector3(sx * 0.55, 1.62, 0), 0.13, 0.13, 0.12, ink, 8, "z")

# ---------------------------------------------------------------- toren
func _tower() -> void:
	var c := Vector3(9.0, 0, -3.5)
	# halfronde uitbouw voor de gevel
	Kit.cyl(self, "Tower bay", c + Vector3(0, 15.0, 0), 4.4, 4.4, 10.0, SAND, 24, "y", true)
	for a in [-0.9, -0.3, 0.3, 0.9]:
		for y in [12.0, 15.5, 18.5]:
			var d := Vector3(sin(a), 0, cos(a))
			var wf := Kit.face(self, c + d * 4.42 + Vector3(0, 0, 0), rad_to_deg(a))
			_square_window(wf, 0.0, y, 0.6)
	# rand met kleine boogjes bovenop de uitbouw
	Kit.cyl(self, "Bay ring", c + Vector3(0, 20.6, 0), 4.7, 4.7, 1.2, SAND_DARK, 28)
	for i in range(14):
		var a: float = -PI * 0.5 + PI * float(i) / 13.0
		var d := Vector3(sin(a), 0, cos(a))
		var wf := Kit.face(self, c + d * 4.72, rad_to_deg(a))
		Kit.box(wf, "Ring arch", Vector3(0, 20.5, 0.03), Vector3(0.35, 0.7, 0.04), SHADOW)
	# hoge ronde toren met kroonlijst
	var t := Vector3(c.x, 0, -6.0)
	Kit.cyl(self, "Round tower", t + Vector3(0, 28.0, 0), 3.4, 3.4, 16.0, SAND, 24, "y", true)
	Kit.cyl(self, "Tower cornice", t + Vector3(0, 36.1, 0), 3.6, 3.6, 0.3, SAND_DARK, 24)
	Kit.cyl(self, "Tower cornice 2", t + Vector3(0, 35.5, 0), 3.5, 3.5, 0.15, SAND_DARK, 24)
	var tf := Kit.face(self, t + Vector3(0, 0, 3.42), 0.0)
	_square_window(tf, 0.0, 24.5, 0.5)
	_square_window(tf, 1.6, 26.0, 0.5)
	# ladderkooi aan de zijkant
	Kit.box(self, "Ladder cage", t + Vector3(3.6, 26.5, 0.8), Vector3(0.7, 9.0, 0.7), Color("55595e"))
	# twee sleuven met de donkere kabelwielen erin, naar de kant van de lage vleugel. Uit
	# elke sleuf loopt een staalkabel in een rechte lijn schuin naar beneden: over de
	# schuine muur het voorgebouw in, door een vierkante opening in de zijgevel van het
	# voorgebouw weer naar buiten en verder het dak van de lage vleugel in.
	var ya: float = deg_to_rad(-60.0)
	var d := Vector3(sin(ya), 0, cos(ya))
	var tan := Vector3(cos(ya), 0, -sin(ya))
	var sf := Kit.face(self, t + d * 3.42, -60.0)
	var side_x := -3.0          # zijgevel van het voorgebouw (naar de lage vleugel)
	for k in range(2):
		var sx: float = -1.2 if k == 0 else 1.2
		Kit.box(sf, "Tower slit", Vector3(sx, 32.0, 0.03), Vector3(0.45, 3.4, 0.05), SLOT)
		Kit.cyl(sf, "Slit sheave", Vector3(sx, 32.4, 0.06), 1.1, 1.1, 0.06, Color("1a1b1d"), 16, "z")
		var top: Vector3 = t + d * 3.5 + tan * sx + Vector3(0, 31.5, 0)
		var end := Vector3(-7.5, 6.6, top.z)
		Kit.beam(self, "Steel cable", top, end, 0.07, Color("2a2c30"))
		# vierkante opening waar de kabel door de zijgevel gaat
		var f: float = (top.x - side_x) / (top.x - end.x)
		var y: float = lerpf(top.y, end.y, f)
		Kit.box(self, "Cable opening", Vector3(side_x - 0.03, y, top.z), Vector3(0.08, 1.5, 1.5), SLOT)
		Kit.box(self, "Cable opening sill", Vector3(side_x - 0.1, y - 0.8, top.z), Vector3(0.2, 0.12, 1.7), SAND_DARK)
	# vlaggenmast met rood-witte vlag
	Kit.cyl(self, "Flag pole", t + Vector3(1.8, 40.0, 0), 0.07, 0.05, 8.0, Color("d8dadc"), 6)
	Kit.box(self, "Flag white", t + Vector3(2.9, 43.4, 0), Vector3(2.2, 0.7, 0.04), Color("f2f2ee"))
	Kit.box(self, "Flag red", t + Vector3(2.9, 42.7, 0), Vector3(2.2, 0.7, 0.04), Color("c8202a"))

# ---------------------------------------------------------------- schuine muur
# Van de bovenkant van het linkerdeel schuin omhoog naar de toren, met open bogen:
# pijlers onder een schuine balk.
func _slope_wall() -> void:
	var xa := -3.0
	var ya := 18.0
	var xb := 6.2
	var yb := 31.0
	var z0 := -2.2      # iets terug van de voorgevel: de kabels hangen ervoor
	var z1 := -4.8
	var th := 1.4
	var t: Array = []
	var a0 := Vector3(xa, ya, z0)
	var b0 := Vector3(xb, yb, z0)
	var a1 := Vector3(xa, ya, z1)
	var b1 := Vector3(xb, yb, z1)
	var dn := Vector3(0, -th, 0)
	Kit._quad(t, a0, b0, b1, a1)
	Kit._quad(t, a0 + dn, b0 + dn, b0, a0)
	Kit._quad(t, a1, b1, b1 + dn, a1 + dn)
	Kit._quad(t, a0 + dn, a1 + dn, b1 + dn, b0 + dn)
	_mesh("Slope band", t, SAND)
	# pijlers van het dak van het linkerdeel tot onder de schuine balk
	for k in range(4):
		var x: float = xa + (xb - xa) * float(k) / 3.0
		var top: float = ya + (yb - ya) * (x - xa) / (xb - xa) - th
		if top - ya > 0.3:
			Kit.box(self, "Slope pier", Vector3(x, (ya + top) * 0.5, (z0 + z1) * 0.5), Vector3(0.9, top - ya, z0 - z1), SAND)
	# boogvormige afronding in elke opening (iets donkerder: de binnenkant van de boog)
	for k in range(3):
		var xm: float = xa + (xb - xa) * (float(k) + 0.5) / 3.0
		var top: float = ya + (yb - ya) * (xm - xa) / (xb - xa) - th
		var r: float = (xb - xa) / 6.0 - 0.45
		Kit.cyl(self, "Slope arch", Vector3(xm, top - r * 0.2, (z0 + z1) * 0.5), r, r, 0.25, SAND_DARK, 16, "z")

# ---------------------------------------------------------------- lage vleugel
func _low_wing() -> void:
	var x0 := -33.0
	var x1 := -3.0
	var h := 6.5
	Kit.box(self, "Low wing", Vector3((x0 + x1) * 0.5, h * 0.5, -6.0), Vector3(x1 - x0, h, 12.0), SAND, true)
	Kit.box(self, "Low wing cornice", Vector3((x0 + x1) * 0.5, h + 0.1, -6.0), Vector3(x1 - x0 + 0.3, 0.25, 12.3), SAND_DARK)
	var f := Kit.face(self, Vector3(0, 0, 0), 0.0)
	for x in [-28.0, -21.0, -14.0]:
		Kit.box(f, "Arch window frame", Vector3(x, 2.6, 0.04), Vector3(2.6, 3.6, 0.06), BLUE)
		Kit.cyl(f, "Arch window frame top", Vector3(x, 4.4, 0.04), 1.3, 1.3, 0.06, BLUE, 16, "z")
		Kit.box(f, "Arch window glass", Vector3(x, 2.6, 0.08), Vector3(2.2, 3.4, 0.04), Color("2c3a4a"))
		Kit.cyl(f, "Arch window glass top", Vector3(x, 4.4, 0.08), 1.1, 1.1, 0.04, Color("2c3a4a"), 16, "z")
		Kit.box(f, "Arch window bar", Vector3(x, 3.0, 0.11), Vector3(0.08, 4.4, 0.03), BLUE)
	Kit.box(f, "Wing door", Vector3(-8.0, 1.2, 0.05), Vector3(1.1, 2.4, 0.06), BLUE)
	_coat_of_arms(f, Vector3(-24.5, 3.4, 0.08), 0.75)
	# terras met reling op het dak, tegen het hoofdgebouw
	Kit.box(self, "Terrace rail", Vector3(-6.5, h + 1.0, -0.3), Vector3(7.0, 0.08, 0.08), RAIL)
	for k in range(8):
		Kit.box(self, "Terrace bar", Vector3(-10.0 + float(k), h + 0.55, -0.3), Vector3(0.05, 0.9, 0.05), RAIL)

# ---------------------------------------------------------------- achterkant
func _back() -> void:
	# ventilatorhuis: een groot rechtopstaand halfrond, met de geribde kant naar achteren
	# (achter het hoofdgebouw), een kleiner halfrond ervoor en de motor ernaast
	var fh := Vector3(1.0, 0, -19.5)
	var rib := Color("6f777d")
	_half_disc("Fan housing", fh, 6.0, 3.0, STEEL)
	_half_disc("Fan inner", fh + Vector3(0, 0, -1.6), 2.8, 1.0, STEEL)
	for i in range(19):
		var a: float = PI * float(i) / 18.0
		var dir := Vector3(cos(a), sin(a), 0)
		Kit.beam(self, "Fan rib", fh + dir * 3.0 + Vector3(0, 0, -1.55), fh + dir * 5.95 + Vector3(0, 0, -1.55), 0.12, rib)
	Kit.cyl(self, "Fan motor", fh + Vector3(4.5, 1.1, -3.0), 1.0, 1.0, 2.2, STEEL, 16, "z")
	Kit.box(self, "Fan motor base", fh + Vector3(4.5, 0.25, -3.0), Vector3(2.4, 0.5, 2.6), Color("3a3c40"))
	# ventilatortoren ernaast (kant van de lage vleugel): gestapelde, naar boven uitlopende
	# geklonken ringen
	var vt := Vector3(-10.0, 0, -20.5)
	var r := 3.0
	var y := 0.0
	for k in range(7):
		var h := 2.4
		Kit.cyl(self, "Diffusor section", vt + Vector3(0, y + h * 0.5, 0), r, r + 0.3, h, STEEL, 24, "y", k == 0)
		Kit.cyl(self, "Diffusor lip", vt + Vector3(0, y + h - 0.08, 0), r + 0.42, r + 0.42, 0.16, rib, 24)
		y += h
		r += 0.16
	Kit.cyl(self, "Diffusor foot", vt + Vector3(0, 0.25, 0), 3.6, 3.6, 0.5, Color("b9b2a6"), 24)
	# lager paviljoen achter, ver genoeg opzij dat het ventilatorhuis vrij staat
	Kit.box(self, "Back pavilion", Vector3(21.0, 3.0, -20.0), Vector3(12.0, 6.0, 8.0), SAND, true)

# Rechtopstaand halfrond (onderkant op de grond), vlak in het XY-vlak, dikte langs Z.
func _half_disc(n: String, c: Vector3, r: float, th: float, color: Color) -> void:
	var t: Array = []
	var segs := 20
	for i in range(segs):
		var a0: float = PI * float(i) / float(segs)
		var a1: float = PI * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0) * r, sin(a0) * r, 0)
		var p1 := Vector3(cos(a1) * r, sin(a1) * r, 0)
		var zf := Vector3(0, 0, th * 0.5)
		t.append_array([c + zf, c + p0 + zf, c + p1 + zf])
		t.append_array([c - zf, c + p1 - zf, c + p0 - zf])
		Kit._quad(t, c + p0 + zf, c + p0 - zf, c + p1 - zf, c + p1 + zf)
	Kit._quad(t, c + Vector3(-r, 0, th * 0.5), c + Vector3(r, 0, th * 0.5), c + Vector3(r, 0, -th * 0.5), c + Vector3(-r, 0, -th * 0.5))
	_mesh(n, t, color)

# Klein diesellocomotiefje op een stukje spoor met dwarsliggers, op een donkere sokkel.
func _locomotive(p: Vector3) -> void:
	var black := Color("1d1e20")
	var red := Color("b3262a")
	Kit.box(self, "Loco plinth", p + Vector3(0, 0.4, 0), Vector3(12.0, 0.8, 3.4), Color("3f4145"), true)
	for k in range(10):
		Kit.box(self, "Sleeper", p + Vector3(-5.4 + float(k) * 1.2, 0.95, 0), Vector3(0.5, 0.3, 2.6), Color("c9c6be"))
	for z in [-0.72, 0.72]:
		Kit.box(self, "Rail", p + Vector3(0, 1.18, z), Vector3(12.0, 0.16, 0.12), Color("5a5d61"))
	var q: Vector3 = p + Vector3(0, 1.26, 0)
	Kit.box(self, "Loco frame", q + Vector3(0, 0.75, 0), Vector3(5.6, 0.7, 2.2), red)
	for x in [-1.4, 1.4]:
		for z in [-0.95, 0.95]:
			Kit.cyl(self, "Loco wheel", q + Vector3(x, 0.5, z), 0.5, 0.5, 0.15, red, 14, "z")
	Kit.box(self, "Loco hood", q + Vector3(0.9, 1.8, 0), Vector3(3.2, 1.4, 1.8), black)
	Kit.box(self, "Loco cab", q + Vector3(-1.7, 2.4, 0), Vector3(2.0, 2.6, 2.2), black)
	Kit.box(self, "Loco cab roof", q + Vector3(-1.7, 3.75, 0), Vector3(2.3, 0.15, 2.4), black)
	for z in [-1.11, 1.11]:
		Kit.box(self, "Cab window", q + Vector3(-1.7, 2.9, z), Vector3(1.3, 0.9, 0.04), Color("6c7a86"))
	Kit.box(self, "Cab front window", q + Vector3(-0.69, 2.9, 0), Vector3(0.04, 0.8, 1.6), Color("6c7a86"))
	for sx in [-1.0, 1.0]:
		Kit.box(self, "Buffer beam", q + Vector3(sx * 2.9, 0.75, 0), Vector3(0.2, 0.5, 2.3), red)
		for z in [-0.7, 0.7]:
			Kit.cyl(self, "Buffer", q + Vector3(sx * 3.2, 0.8, z), 0.18, 0.18, 0.5, black, 10, "x")
	Kit.cyl(self, "Loco lamp", q + Vector3(2.55, 2.1, 0.55), 0.18, 0.18, 0.2, Color("e8e2c8"), 10, "x")
	Kit.cyl(self, "Loco exhaust", q + Vector3(1.6, 2.8, 0.5), 0.12, 0.12, 0.6, black, 8)

func _mine_cart(p: Vector3, color := Color("2b2c2e")) -> void:
	Kit.box(self, "Mine cart", p + Vector3(0, 0.75, 0), Vector3(1.6, 0.8, 1.0), color)
	for x in [-0.5, 0.5]:
		for z in [-0.45, 0.45]:
			Kit.cyl(self, "Cart wheel", p + Vector3(x, 0.25, z), 0.25, 0.25, 0.1, Color("1c1c1e"), 10, "z")
