extends Node3D
# Het grappige huis in de Stationsstraat van Simpelveld, naar jouw foto (20-11):
# - rood bakstenen huis van twee lagen met een plat dak en een overstekende goot
# - rondboogramen met gestreepte bogen (rood en geel) en beige luiken
# - een bewerkte houten deur en een winkelpui onder een zwart luifeltje (het naambord
#   is weggelaten: de naam is mogelijk een merknaam)
# - grote donkerblauwe theepotten met witte hartjes, staand op consoles op beide hoeken
# - een voortuintje met wit grind, een zwart smeedijzeren hekje, een bankje, struiken,
#   een paaltje met een lantaarn en een oude fiets met een mand
# - rechts een crèmekleurig buurhuis
# Lokale ruimte: +Z = straatkant, de gevel ligt langs X.
const Kit = preload("res://scripts/build_kit.gd")

const W := 9.6
const D := 9.0
const H := 7.0
const SHUTTER := Color("c9bba3")
const GLASS := Color("2f3a3e")
const WOOD := Color("c4a77e")
const IRON := Color("1e1f20")
const ARCH_A := Color("b8543c")
const ARCH_B := Color("e3b56a")

func _ready() -> void:
	name = "Theepottenhuis"
	var brick := Kit.tex_mat("res://assets/on_brick.png", Color("ffe2d6"), 2.6)
	var fz: float = D * 0.5
	Kit.box(self, "House", Vector3(0, H * 0.5, 0), Vector3(W, H, D), Color.WHITE, true, brick)
	Kit.box(self, "Plinth", Vector3(0, 0.25, fz + 0.03), Vector3(W, 0.5, 0.1), Color("b9b3a8"))
	# plat dak met een brede, overstekende goot
	Kit.box(self, "Roof", Vector3(0, H + 0.12, 0), Vector3(W + 0.2, 0.24, D + 0.2), Color("5b5550"))
	Kit.box(self, "Eaves", Vector3(0, H + 0.1, fz + 0.4), Vector3(W + 0.8, 0.32, 0.8), Color("6d6862"))
	Kit.box(self, "Gutter", Vector3(0, H - 0.02, fz + 0.78), Vector3(W + 0.8, 0.2, 0.12), Color("8b8780"))
	for k in range(3):
		Kit.box(self, "Eaves bracket", Vector3(-3.6 + float(k) * 3.6, H - 0.15, fz + 0.15), Vector3(0.18, 0.3, 0.3), Color("6d6862"))
	Kit.box(self, "Chimney", Vector3(-1.2, H + 0.7, 1.0), Vector3(0.7, 1.4, 0.7), Color("8d4a3a"))
	Kit.box(self, "Chimney 2", Vector3(3.4, H + 0.6, -2.0), Vector3(0.6, 1.2, 0.6), Color("8d4a3a"))
	var f := Kit.face(self, Vector3(0, 0, fz), 0.0)
	# boven: drie rondboogramen met luiken
	for x in [-2.9, 0.2, 3.2]:
		_arch_window(f, x, 4.3, 1.0, 1.2, true)
	# beneden: links een raam met luiken, midden de deur, rechts de winkelpui
	_arch_window(f, -2.5, 0.8, 1.4, 1.9, true)
	_arch_window(f, 0.6, 0.55, 1.15, 2.25, false)
	Kit.box(f, "Door", Vector3(0.6, 0.55 + 1.125, 0.07), Vector3(1.05, 2.25, 0.06), WOOD)
	for s in [-1.0, 1.0]:
		Kit.box(f, "Door pane", Vector3(0.6 + s * 0.25, 1.95, 0.11), Vector3(0.32, 1.2, 0.03), Color("3b3a36"))
		Kit.box(f, "Door panel", Vector3(0.6 + s * 0.25, 0.95, 0.11), Vector3(0.32, 0.5, 0.03), Color("a88b62"))
	Kit.box(f, "House number", Vector3(-0.2, 2.6, 0.06), Vector3(0.2, 0.14, 0.02), Color("eeeeea"))
	# winkelpui met dubbele glazen deur onder een zwart luifeltje
	Kit.box(f, "Shop frame", Vector3(3.4, 1.55, 0.05), Vector3(1.9, 2.6, 0.08), WOOD)
	Kit.box(f, "Shop glass", Vector3(3.4, 1.65, 0.09), Vector3(1.55, 2.2, 0.04), GLASS)
	Kit.box(f, "Shop mullion", Vector3(3.4, 1.55, 0.12), Vector3(0.1, 2.5, 0.04), WOOD)
	Kit.box(f, "Shop transom", Vector3(3.4, 2.35, 0.12), Vector3(1.6, 0.08, 0.04), WOOD)
	var aw := Kit.box(f, "Awning", Vector3(3.4, 3.1, 0.45), Vector3(2.2, 0.08, 0.9), Color("1c1c1c"))
	aw.rotation.x = 0.35
	Kit.box(f, "Awning valance", Vector3(3.4, 2.92, 0.88), Vector3(2.2, 0.28, 0.04), Color("1c1c1c"))
	# klein wit bordje bij de winkel
	Kit.box(f, "Shop plaque", Vector3(2.2, 2.0, 0.06), Vector3(0.4, 0.5, 0.03), Color("f2f2ee"))
	Kit.box(f, "Shop plaque mark", Vector3(2.2, 2.0, 0.08), Vector3(0.18, 0.3, 0.02), Color("1f2a44"))
	# theepotten op de hoeken
	_teapot(Vector3(-W * 0.5 + 0.45, 4.25, fz + 0.75), -1.0)
	_teapot(Vector3(W * 0.5 - 0.3, 4.0, fz + 0.75), 1.0)
	_front_garden(fz)
	_neighbour()

# Rondboograam met gestreepte boog (rood/geel) en beige luiken, in face-ruimte.
func _arch_window(f: Node3D, x: float, y: float, w: float, h: float, shutters: bool) -> void:
	var r: float = w * 0.5
	var top: float = y + h
	if shutters:
		Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.03), Vector3(w + 0.1, h, 0.08), Color("e9e6dc"))
		Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.06), Vector3(w - 0.12, h - 0.1, 0.04), GLASS)
		Kit.box(f, "Window bar", Vector3(x, y + h * 0.5, 0.09), Vector3(0.06, h - 0.1, 0.03), Color("e9e6dc"))
		Kit.box(f, "Window bar", Vector3(x, y + h * 0.55, 0.09), Vector3(w - 0.1, 0.06, 0.03), Color("e9e6dc"))
		Kit.cyl(f, "Window fan", Vector3(x, top, 0.06), r - 0.04, r - 0.04, 0.04, GLASS, 16, "z")
		Kit.box(f, "Sill", Vector3(x, y - 0.06, 0.1), Vector3(w + 0.3, 0.1, 0.2), Color("a8a39a"))
		for s in [-1.0, 1.0]:
			var sh := Kit.box(f, "Shutter", Vector3(x + s * (r + 0.42), y + h * 0.5 + 0.15, 0.1), Vector3(0.7, h + 0.4, 0.06), SHUTTER)
			sh.rotation.y = -s * 0.12
			for k in range(4):
				Kit.box(f, "Shutter rail", Vector3(x + s * (r + 0.42), y + 0.15 + float(k) * (h + 0.3) / 3.0, 0.14), Vector3(0.62, 0.05, 0.02), Color("b6a78d"))
	else:
		Kit.cyl(f, "Door fan", Vector3(x, top, 0.06), r - 0.04, r - 0.04, 0.04, Color("3b3a36"), 16, "z")
		Kit.box(f, "Door fan bar", Vector3(x, top + r * 0.4, 0.09), Vector3(0.05, r * 0.8, 0.02), WOOD)
	# gestreepte boog: rollaag van afwisselend rode en gele stenen
	var n := 11
	for k in range(n):
		var a: float = PI * (float(k) + 0.5) / float(n)
		var p := Vector3(x + cos(a) * (r + 0.2), top + sin(a) * (r + 0.2), 0.05)
		var st := Kit.box(f, "Arch brick", p, Vector3(0.36, PI * (r + 0.2) / float(n) + 0.01, 0.08), ARCH_A if k % 2 == 0 else ARCH_B)
		st.rotation.z = a
	for s in [-1.0, 1.0]:
		Kit.box(f, "Arch foot", Vector3(x + s * (r + 0.2), top - 0.08, 0.05), Vector3(0.36, 0.16, 0.08), ARCH_B)

# Donkerblauwe theepot met rijen witte hartjes (Pools aardewerk), staand op een houten
# plankje op een sierlijke smeedijzeren console aan de gevel. p = midden van de buik.
func _teapot(p: Vector3, side: float) -> void:
	var navy := Color("1c2350")
	var pot := StandardMaterial3D.new()
	pot.albedo_texture = load("res://assets/teapot_pattern.png")
	pot.uv1_scale = Vector3(4.0, 2.0, 1.0)
	pot.roughness = 0.35
	var plain := Kit.mat(navy, 0.0, 0.0, 0.35)
	var base_y: float = p.y - 0.34
	# console: plankje, arm naar de gevel, schoor en een krul
	Kit.box(self, "Teapot shelf", Vector3(p.x, base_y - 0.04, p.z - 0.15), Vector3(0.95, 0.07, 1.1), Color("9a9284"))
	Kit.box(self, "Teapot bracket arm", Vector3(p.x, base_y - 0.12, p.z - 0.4), Vector3(0.06, 0.08, 1.0), IRON)
	Kit.beam(self, "Teapot bracket brace", Vector3(p.x, base_y - 0.85, p.z - 0.9), Vector3(p.x, base_y - 0.12, p.z + 0.05), 0.06, IRON)
	Kit.box(self, "Teapot bracket post", Vector3(p.x, base_y - 0.5, p.z - 0.88), Vector3(0.06, 0.8, 0.06), IRON)
	Kit.cyl(self, "Teapot bracket curl", Vector3(p.x, base_y - 0.4, p.z - 0.55), 0.17, 0.17, 0.04, IRON, 12, "x")
	Kit.cyl(self, "Teapot bracket curl hole", Vector3(p.x, base_y - 0.4, p.z - 0.55), 0.11, 0.11, 0.05, Color("8d4a3a"), 12, "x")
	# buik: bol en iets afgeplat, met een voetje
	var body := MeshInstance3D.new()
	body.name = "Teapot"
	var sm := SphereMesh.new()
	sm.radius = 0.4
	sm.height = 0.66
	sm.radial_segments = 20
	sm.rings = 10
	body.mesh = sm
	body.material_override = pot
	body.position = p
	add_child(body)
	Kit.cyl(self, "Teapot foot", Vector3(p.x, base_y + 0.03, p.z), 0.26, 0.28, 0.06, navy, 16)
	# deksel met knop
	var lid := Kit.cyl(self, "Teapot lid", p + Vector3(0, 0.33, 0), 0.24, 0.3, 0.08, navy, 16)
	(lid as MeshInstance3D).material_override = pot
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.24
	dm.height = 0.24
	dm.is_hemisphere = true
	dm.radial_segments = 16
	dm.rings = 5
	dome.mesh = dm
	dome.material_override = pot
	dome.position = p + Vector3(0, 0.37, 0)
	add_child(dome)
	var knob := MeshInstance3D.new()
	var km := SphereMesh.new()
	km.radius = 0.07
	km.height = 0.13
	knob.mesh = km
	knob.material_override = plain
	knob.position = p + Vector3(0, 0.52, 0)
	add_child(knob)
	# tuit schuin omhoog naar buiten (langs de gevel), oor als lus aan de andere kant
	Kit.beam(self, "Teapot spout", p + Vector3(side * 0.3, -0.05, 0), p + Vector3(side * 0.5, 0.12, 0), 0.13, navy)
	Kit.beam(self, "Teapot spout tip", p + Vector3(side * 0.5, 0.12, 0), p + Vector3(side * 0.66, 0.24, 0), 0.08, navy)
	var pts := [Vector3(-side * 0.33, 0.2, 0), Vector3(-side * 0.5, 0.22, 0), Vector3(-side * 0.6, 0.08, 0),
		Vector3(-side * 0.55, -0.1, 0), Vector3(-side * 0.36, -0.2, 0)]
	for k in range(pts.size() - 1):
		Kit.beam(self, "Teapot handle", p + pts[k], p + pts[k + 1], 0.07, navy)

func _front_garden(fz: float) -> void:
	var gz: float = fz + 1.3
	Kit.box(self, "Gravel", Vector3(0, 0.06, gz), Vector3(W, 0.12, 2.6), Color("e6e3dc"))
	Kit.box(self, "Garden path", Vector3(0.6, 0.08, gz), Vector3(1.3, 0.14, 2.6), Color("8c4a3c"))
	# smeedijzeren hekje met speerpunten, open bij het pad
	var hz: float = fz + 2.6
	for s in [-1.0, 1.0]:
		var x0: float = 0.6 + s * 0.65
		var x1: float = W * 0.5 * s
		var cx: float = (x0 + x1) * 0.5
		var ln: float = absf(x1 - x0)
		Kit.box(self, "Fence rail", Vector3(cx, 0.25, hz), Vector3(ln, 0.05, 0.05), IRON)
		Kit.box(self, "Fence rail", Vector3(cx, 0.95, hz), Vector3(ln, 0.05, 0.05), IRON)
		var n: int = int(ln / 0.22)
		for k in range(n + 1):
			var x: float = lerpf(x0, x1, float(k) / float(n))
			Kit.box(self, "Fence bar", Vector3(x, 0.55, hz), Vector3(0.03, 1.1, 0.03), IRON)
			Kit.box(self, "Fence spike", Vector3(x, 1.12, hz), Vector3(0.07, 0.07, 0.07), IRON)
		Kit.box(self, "Fence post", Vector3(x0, 0.65, hz), Vector3(0.1, 1.3, 0.1), IRON)
		Kit.box(self, "Fence side", Vector3(x1, 0.55, (fz + hz) * 0.5), Vector3(0.04, 1.0, hz - fz), IRON)
	# bankje met twee bolle struiken, een paaltje met lantaarn en een spiraalboompje in een pot
	Kit.box(self, "Bench seat", Vector3(-2.3, 0.5, fz + 0.6), Vector3(1.6, 0.08, 0.45), Color("b5b2aa"))
	Kit.box(self, "Bench back", Vector3(-2.3, 0.85, fz + 0.38), Vector3(1.6, 0.4, 0.06), Color("b5b2aa"))
	for s in [-1.0, 1.0]:
		Kit.box(self, "Bench leg", Vector3(-2.3 + s * 0.7, 0.25, fz + 0.6), Vector3(0.08, 0.5, 0.4), Color("9a978f"))
	_bush(Vector3(-3.9, 0.55, fz + 1.2), Vector3(1.2, 1.1, 1.2), Color("3f6a32"))
	_bush(Vector3(-0.9, 0.5, fz + 1.4), Vector3(0.9, 0.9, 0.9), Color("4a7a3a"))
	Kit.box(self, "Lantern post", Vector3(-0.2, 0.55, fz + 1.4), Vector3(0.28, 1.1, 0.28), IRON)
	Kit.box(self, "Lantern top", Vector3(-0.2, 1.2, fz + 1.4), Vector3(0.36, 0.2, 0.36), IRON)
	Kit.cyl(self, "Planter pot", Vector3(2.1, 0.4, fz + 0.6), 0.32, 0.26, 0.8, Color("2b4b9b"), 12)
	for k in range(4):
		_bush(Vector3(2.1, 1.0 + float(k) * 0.42, fz + 0.6), Vector3(0.55, 0.42, 0.55) * (1.0 - float(k) * 0.18), Color("3c6230"))
	_bush(Vector3(2.1, 0.8, fz + 0.9), Vector3(0.6, 0.35, 0.5), Color("f1f0ea"))   # witte bloemen
	_bicycle(Vector3(3.9, 0, fz + 1.6))

func _bush(p: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Bush"
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	mi.mesh = sm
	mi.material_override = Kit.mat(color)
	mi.scale = size
	mi.position = p
	add_child(mi)

# Oude damesfiets met een rieten mand, langs het hek.
func _bicycle(p: Vector3) -> void:
	var frame := Color("7a3a2a")
	for x in [-0.55, 0.55]:
		Kit.cyl(self, "Bike wheel", p + Vector3(x, 0.36, 0), 0.36, 0.36, 0.04, Color("2a2a2a"), 16, "z")
		Kit.cyl(self, "Bike hub", p + Vector3(x, 0.36, 0), 0.08, 0.08, 0.06, Color("9a9a9a"), 8, "z")
	Kit.beam(self, "Bike frame", p + Vector3(-0.55, 0.36, 0), p + Vector3(-0.1, 0.85, 0), 0.04, frame)
	Kit.beam(self, "Bike frame", p + Vector3(-0.1, 0.85, 0), p + Vector3(0.45, 0.8, 0), 0.04, frame)
	Kit.beam(self, "Bike frame", p + Vector3(0.0, 0.4, 0), p + Vector3(0.45, 0.8, 0), 0.04, frame)
	Kit.beam(self, "Bike frame", p + Vector3(0.45, 0.8, 0), p + Vector3(0.55, 0.36, 0), 0.04, frame)
	Kit.beam(self, "Bike frame", p + Vector3(-0.55, 0.36, 0), p + Vector3(0.0, 0.4, 0), 0.04, frame)
	Kit.box(self, "Bike saddle", p + Vector3(-0.12, 0.92, 0), Vector3(0.24, 0.06, 0.12), Color("3a2a20"))
	Kit.box(self, "Bike handlebar", p + Vector3(0.45, 1.0, 0), Vector3(0.06, 0.04, 0.5), Color("3a3a3a"))
	Kit.box(self, "Bike basket", p + Vector3(0.68, 0.9, 0), Vector3(0.35, 0.25, 0.35), Color("a8875a"))

# Crèmekleurig buurhuis rechts, met een rode daklijst.
func _neighbour() -> void:
	var nx: float = W * 0.5 + 3.6
	Kit.box(self, "Neighbour", Vector3(nx, 4.0, -0.8), Vector3(7.2, 8.0, D - 1.6), Color("e8e0c9"), true)
	Kit.box(self, "Neighbour cornice", Vector3(nx, 8.05, D * 0.5 - 1.2), Vector3(7.4, 0.3, 0.5), Color("9c3b2e"))
	Kit.box(self, "Neighbour roof", Vector3(nx, 8.1, -0.8), Vector3(7.2, 0.2, D - 1.6), Color("5b5550"))
	var f := Kit.face(self, Vector3(nx, 0, D * 0.5 - 1.6), 0.0)
	for x in [-1.8, 1.8]:
		for y in [1.2, 4.6]:
			Kit.box(f, "Neighbour window frame", Vector3(x, y + 0.9, 0.03), Vector3(1.2, 1.9, 0.06), Color("f6f4ee"))
			Kit.box(f, "Neighbour window", Vector3(x, y + 0.9, 0.06), Vector3(0.95, 1.65, 0.04), GLASS)
	# heg ervoor
	Kit.box(self, "Neighbour hedge", Vector3(nx, 0.6, D * 0.5 + 0.6), Vector3(6.0, 1.2, 1.2), Color("3f6a32"))
