extends Node3D
# Sint-Remigiuskerk (Simpelveld), naar jouw foto's (25-11). Lichtgrijze breuksteen
# (kalksteen in onregelmatige blokken), donkere leien daken.
# - hoge vierkante toren midden voor, met een slanke leien naaldspits met gouden bol en
#   kruis; bovenin aan elke kant een uurwerk (donkere wijzerplaat, gouden cijfers) met
#   daaronder drie rondboogvormige galmgaten; lager een klein rondboogvenster
# - onderin een diepe rondboogportaal met getrapte stenen boog en een groene bronzen deur,
#   met een bordes met trapje ervoor
# - lager deel links en rechts van de toren met schuine dakjes (de zijbeuken)
# - schip met een leien zadeldak, kleine dakkapellen en een dakruitertje met spitsje;
#   langs de zijkant een rij lage kapellen met elk een eigen puntdakje en rondboogvensters
# - achterin een dwarspand en een halfronde apsis
# - een lage muur van breuksteen met pijlers en een zwart hekwerk langs de stoep
# Lokale ruimte: oorsprong = midden voor de toren, +Z = naar de weg, de kerk loopt in -Z.
const Kit = preload("res://scripts/build_kit.gd")

const SLATE := Color("3b4047")
const TRIM := Color("c9c0aa")
const GLASS := Color("2f3438")
const BRONZE := Color("4e8a78")
const GOLD := Color("d4ac3c")

var stone: Material
var stone_2s: Material

const TW := 7.4          # torenbreedte
const TH := 29.0         # torenhoogte tot de dakrand
const NAVE_HW := 6.5
const NAVE_EAVE := 12.0
const NAVE_Z0 := -6.0
const NAVE_Z1 := -36.0
const AISLE_HW := 10.5
const AISLE_EAVE := 5.5

func _ready() -> void:
	name = "Sint-Remigiuskerk"
	stone = Kit.tex_mat("res://assets/kerk_rubble.png", Color("d6d8d6"), 3.0)
	stone_2s = (stone as StandardMaterial3D).duplicate()
	stone_2s.cull_mode = BaseMaterial3D.CULL_DISABLED
	Kit.box(self, "Church yard", Vector3(0, 0.03, -21.5), Vector3(30.0, 0.06, 49.0), Color("8f8a7c"))   # tot aan de muur, niet over de weg
	_tower()
	_nave()
	_chapels()
	_transept_and_apse()
	_wall_and_fence()

func _arch(parent: Node3D, n: String, x: float, yb: float, w: float, h: float, z: float, thick: float, color: Color) -> void:
	var r: float = w * 0.5
	var straight: float = maxf(h - r, 0.1)
	Kit.box(parent, n, Vector3(x, yb + straight * 0.5, z), Vector3(w, straight, thick), color)
	Kit.cyl(parent, n + " top", Vector3(x, yb + straight, z), r, r, thick, color, 16, "z")

func _arch_window(f: Node3D, x: float, yb: float, w: float, h: float) -> void:
	_arch(f, "Window reveal", x, yb - 0.08, w + 0.3, h + 0.15, 0.03, 0.06, Color("a8a292"))
	_arch(f, "Window", x, yb, w, h, 0.07, 0.04, GLASS)

func _gable_end(f: Node3D, w: float, y0: float, rise: float) -> void:
	var t: Array = [Vector3(-w * 0.5, y0, 0.0), Vector3(w * 0.5, y0, 0.0), Vector3(0, y0 + rise, 0.0)]
	var g := MeshInstance3D.new()
	g.name = "Gable end"
	g.mesh = Kit._mesh_from(t, stone_2s)
	f.add_child(g)

func _tower() -> void:
	var c := Vector3(0, 0, -TW * 0.5)
	Kit.box(self, "Tower", c + Vector3(0, TH * 0.5, 0), Vector3(TW, TH, TW), Color.WHITE, true, stone)
	Kit.box(self, "Tower cornice", c + Vector3(0, TH + 0.12, 0), Vector3(TW + 0.5, 0.25, TW + 0.5), Color("5a5d62"))
	# naaldspits (vierkant grondvlak, heel steil) met bol en kruis
	Kit.pyramid(self, "Spire", c + Vector3(0, TH + 0.2, 0), TW * 0.42, 15.5, SLATE)
	Kit.cyl(self, "Spire ball", c + Vector3(0, TH + 15.9, 0), 0.32, 0.32, 0.6, GOLD, 10)
	Kit.box(self, "Cross", c + Vector3(0, TH + 17.2, 0), Vector3(0.1, 2.0, 0.1), Color("2a2a2a"))
	Kit.box(self, "Cross arm", c + Vector3(0, TH + 17.5, 0), Vector3(1.0, 0.1, 0.1), Color("2a2a2a"))
	for k in range(4):
		var a: float = float(k) * 90.0
		var dir := Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
		var f := Kit.face(self, c + dir * (TW * 0.5), a)
		# uurwerk
		Kit.cyl(f, "Clock rim", Vector3(0, TH - 3.2, 0.05), 1.25, 1.25, 0.1, Color("8a8478"), 24, "z")
		Kit.cyl(f, "Clock face", Vector3(0, TH - 3.2, 0.1), 1.05, 1.05, 0.06, Color("1f2226"), 24, "z")
		for m in range(12):
			var ang: float = float(m) * TAU / 12.0
			Kit.box(f, "Clock mark", Vector3(sin(ang) * 0.85, TH - 3.2 + cos(ang) * 0.85, 0.15), Vector3(0.08, 0.2, 0.02), GOLD).rotation.z = -ang
		var hh := Kit.box(f, "Clock hand", Vector3(0.2, TH - 3.0, 0.17), Vector3(0.07, 0.55, 0.02), GOLD)
		hh.rotation.z = -0.8
		Kit.box(f, "Clock hand long", Vector3(0, TH - 2.85, 0.18), Vector3(0.05, 0.8, 0.02), GOLD)
		# drie galmgaten
		for x in [-1.6, 0.0, 1.6]:
			Kit.box(f, "Sound hole sill", Vector3(x, TH - 7.2, 0.08), Vector3(1.2, 0.16, 0.16), Color("a8a292"))
			_arch(f, "Sound hole", x, TH - 7.1, 0.9, 2.0, 0.06, 0.06, Color("1e2022"))
		if k != 0:
			_arch_window(f, 0.0, TH - 13.5, 0.55, 1.4)
	# portaal naar de weg: getrapte rondboog en groene bronzen deur
	var pf := Kit.face(self, Vector3(0, 0, 0), 0.0)
	_arch(pf, "Portal outer", 0, 0.0, 4.4, 5.6, 0.08, 0.16, Color("b8ab8a"))
	_arch(pf, "Portal inner", 0, 0.0, 3.5, 5.0, 0.14, 0.14, Color("a59878"))
	_arch(pf, "Bronze door", 0, 0.0, 2.6, 4.3, 0.2, 0.08, BRONZE)
	Kit.box(pf, "Door seam", Vector3(0, 1.8, 0.25), Vector3(0.06, 3.6, 0.02), Color("3a6a5c"))
	_arch_window(pf, 0.0, TH - 13.5, 0.55, 1.4)
	_arch_window(pf, 0.0, 9.5, 0.35, 0.9)
	# bordes met trapje
	Kit.box(self, "Steps", Vector3(0, 0.15, 1.2), Vector3(5.0, 0.3, 2.4), Color("b4aea0"))
	Kit.box(self, "Steps top", Vector3(0, 0.38, 0.6), Vector3(4.2, 0.2, 1.2), Color("bcb6a8"))

func _nave() -> void:
	var len: float = NAVE_Z0 - NAVE_Z1
	var mid: float = (NAVE_Z0 + NAVE_Z1) * 0.5
	Kit.box(self, "Nave", Vector3(0, NAVE_EAVE * 0.5, mid), Vector3(NAVE_HW * 2.0, NAVE_EAVE, len), Color.WHITE, true, stone)
	Kit.gable(self, "Nave roof", Vector3(0, NAVE_EAVE, mid - 0.4), NAVE_HW * 2.0 + 0.8, len + 0.8, 7.0, SLATE)
	# lage delen naast de toren (eind van de zijbeuken) met schuine dakjes
	for sx in [-1.0, 1.0]:
		var x: float = sx * (TW * 0.5 + (AISLE_HW - TW * 0.5) * 0.5)
		var w: float = AISLE_HW - TW * 0.5
		Kit.box(self, "Front aisle", Vector3(x, 3.8, -3.6), Vector3(w, 7.6, 7.2), Color.WHITE, true, stone)
		# lessenaarsdak: hoog tegen de toren, laag aan de buitenkant
		var rise := 3.0
		var slope: float = atan2(rise, w)
		var roof := Kit.box(self, "Front aisle roof", Vector3(x, 7.6 + rise * 0.5 + 0.1, -3.6), Vector3(w / cos(slope) + 0.5, 0.2, 7.8), SLATE)
		roof.rotation.z = -slope * sx
		var f := Kit.face(self, Vector3(x, 0, 0.02), 0.0)
		var t: Array = [Vector3(-sx * w * 0.5, 7.6, 0.0), Vector3(sx * w * 0.5, 7.6, 0.0), Vector3(-sx * w * 0.5, 7.6 + rise, 0.0)]
		var tri := MeshInstance3D.new()
		tri.mesh = Kit._mesh_from(t, stone_2s)
		f.add_child(tri)
		_arch_window(f, 0.0, 2.2, 0.8, 2.0)
	# dakkapellen en dakruiter
	for z in [-12.0, -20.0, -28.0]:
		for sx in [-1.0, 1.0]:
			var d := Kit.box(self, "Dormer", Vector3(sx * 3.6, NAVE_EAVE + 2.4, z), Vector3(1.0, 1.0, 1.1), SLATE)
			d.rotation_degrees.y = 90.0
	var rt := Vector3(0, NAVE_EAVE + 7.0, -24.0)
	Kit.box(self, "Ridge turret", rt + Vector3(0, 0.8, 0), Vector3(1.0, 1.6, 1.0), Color("2e3238"))
	Kit.pyramid(self, "Ridge turret spire", rt + Vector3(0, 1.6, 0), 0.65, 3.2, SLATE)
	Kit.box(self, "Ridge cross", rt + Vector3(0, 5.3, 0), Vector3(0.06, 0.8, 0.06), Color("2a2a2a"))
	# lichtbeuk: rondboogvenstertjes boven de kapellen
	for sx in [-1.0, 1.0]:
		var f := Kit.face(self, Vector3(sx * NAVE_HW, 0, 0), 90.0 * sx)
		var z := NAVE_Z0 - 3.0
		while z > NAVE_Z1 + 2.0:
			_arch_window(f, -z * sx, 8.4, 0.7, 1.8)
			z -= 3.0

# Rij lage kapellen langs beide zijkanten, elk met een eigen puntdakje dwars op het schip.
func _chapels() -> void:
	var w := 5.0
	for sx in [-1.0, 1.0]:
		var z := NAVE_Z0 - 4.0
		while z > NAVE_Z1 + 2.5:
			var x: float = sx * (NAVE_HW + (AISLE_HW - NAVE_HW) * 0.5)
			var dw: float = AISLE_HW - NAVE_HW
			Kit.box(self, "Chapel", Vector3(x, AISLE_EAVE * 0.5, z), Vector3(dw, AISLE_EAVE, w - 0.4), Color.WHITE, true, stone)
			Kit.gable(self, "Chapel roof", Vector3(x, AISLE_EAVE, z), w + 0.2, dw + 0.6, 2.6, SLATE, true)
			var f := Kit.face(self, Vector3(sx * AISLE_HW, 0, z), 90.0 * sx)
			_gable_end(f, w - 0.4, AISLE_EAVE, 2.3)
			_arch_window(f, -0.9, 1.6, 0.5, 1.6)
			_arch_window(f, 0.9, 1.6, 0.5, 1.6)
			z -= w

func _transept_and_apse() -> void:
	var tz: float = NAVE_Z1 - 4.0
	var tw := 26.0
	var td := 8.0
	var th := 12.0
	Kit.box(self, "Transept", Vector3(0, th * 0.5, tz), Vector3(tw, th, td), Color.WHITE, true, stone)
	Kit.gable(self, "Transept roof", Vector3(0, th, tz), td + 0.8, tw + 0.8, 5.5, SLATE, true)
	for sx in [-1.0, 1.0]:
		var f := Kit.face(self, Vector3(sx * tw * 0.5, 0, tz), 90.0 * sx)
		_gable_end(f, td, th, 5.2)
		_arch_window(f, 0.0, 4.0, 1.4, 4.2)
		Kit.box(self, "Transept vent", Vector3(sx * (tw * 0.5 + 0.1), th + 2.4, tz), Vector3(0.1, 0.9, 0.7), Color("2e3238"))
	# halfronde apsis met kleine vensters
	var ac := Vector3(0, 0, tz - td * 0.5)
	Kit.cyl(self, "Apse", ac + Vector3(0, 4.5, 0), 5.0, 5.0, 9.0, Color.WHITE, 20, "y", true, stone)
	Kit.cyl(self, "Apse roof", ac + Vector3(0, 10.2, 0), 5.4, 0.6, 2.4, SLATE, 20)
	for a in [150.0, 180.0, 210.0]:
		var dir := Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
		var f := Kit.face(self, ac + dir * 5.0, a)
		_arch_window(f, 0.0, 4.0, 0.6, 1.8)

# Lage muur van breuksteen met pijlers en een zwart hek langs de stoep (voor de toren
# met een opening naar het bordes).
func _wall_and_fence() -> void:
	var z := 3.4
	for seg in [[-14.0, -3.0], [3.0, 14.0]]:
		var a: float = seg[0]
		var b: float = seg[1]
		Kit.box(self, "Church wall", Vector3((a + b) * 0.5, 0.45, z), Vector3(b - a, 0.9, 0.5), Color.WHITE, true, stone)
		var x := a
		while x <= b + 0.01:
			Kit.box(self, "Wall pier", Vector3(x, 0.9, z), Vector3(0.7, 1.8, 0.7), Color.WHITE, false, stone)
			Kit.box(self, "Pier cap", Vector3(x, 1.85, z), Vector3(0.8, 0.12, 0.8), Color("a8a292"))
			x += 3.6
		Kit.box(self, "Railing top", Vector3((a + b) * 0.5, 1.75, z), Vector3(b - a, 0.05, 0.05), Color("1e1e20"))
		var r := a + 0.2
		while r < b:
			Kit.box(self, "Railing bar", Vector3(r, 1.3, z), Vector3(0.03, 0.9, 0.03), Color("1e1e20"))
			r += 0.25
	# struiken en een rode esdoorn bij de ingang
	for x in [-6.5, 6.5]:
		Kit.box(self, "Shrubs", Vector3(x, 0.7, 1.8), Vector3(5.0, 1.4, 2.0), Color("4a6e36"))
	var maple := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 2.6
	sm.radial_segments = 10
	sm.rings = 5
	maple.mesh = sm
	maple.material_override = Kit.mat(Color("7a2a2a"))
	maple.position = Vector3(-3.4, 2.6, 2.2)
	add_child(maple)
	Kit.cyl(self, "Maple trunk", Vector3(-3.4, 0.8, 2.2), 0.12, 0.1, 1.6, Color("4a3a2e"), 6)
