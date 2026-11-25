extends Node3D
# Watertoren Rimburg (Landgraaf), naar jouw foto's (23-11): een achtkantige toren van
# donkere baksteen die naar boven iets smaller wordt, met witte betonnen hoekribben en
# horizontale banden, kleine smalle raampjes en een rode deur; bovenin een breder
# achtkantig reservoir op een uitkragende witte rand, met smalle ramen in rode kozijnen en
# een donker metalen tentdak. Aan de zijkanten twee cortenstalen (roestbruine) uitkijkpunten:
# links een bak die uitsteekt, rechts een schuine trap naar beneden naar een balkon en weer
# terug naar de toren. Eromheen grasland met een paar bomen en een hek.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const WHITE := Color("e8e8e2")
const CORTEN := Color("8c4a2a")
const GLASS := Color("2c3438")

var brick: Material

func _ready() -> void:
	name = "Watertoren Rimburg"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("9a6e5e"), 3.0)
	Kit.box(self, "Meadow", Vector3(0, 0.03, 0), Vector3(70.0, 0.06, 60.0), Color("7ba04f"))
	_tower()
	for p in [Vector3(-22, 0, -14), Vector3(-26, 0, 4), Vector3(20, 0, -18), Vector3(26, 0, 2), Vector3(-12, 0, -24)]:
		_tree(p)
	var x := -30.0
	while x <= 30.0:
		Kit.cyl(self, "Fence post", Vector3(x, 0.7, 24.0), 0.08, 0.08, 1.4, Color("8a7a5e"), 6)
		x += 3.0

func _oct(n: String, y: float, h: float, r0: float, r1: float, mat: Material, color := Color.WHITE, solid := false) -> void:
	var c := Kit.cyl(self, n, Vector3(0, y + h * 0.5, 0), r0, r1, h, color, 8, "y", solid, mat)
	c.rotation.y = PI / 8.0     # een vlakke zijde naar voren

# Witte ribben op de hoeken van een achtkant, van straal r0 op y0 naar r1 op y1.
func _ribs(y0: float, y1: float, r0: float, r1: float, w: float) -> void:
	for k in range(8):
		var a: float = TAU * float(k) / 8.0 + PI / 8.0     # de hoeken (de cilinder is 22,5 graden gedraaid)
		var d := Vector3(sin(a), 0, cos(a))
		Kit.beam(self, "Corner rib", d * (r0 + 0.05) + Vector3(0, y0, 0), d * (r1 + 0.05) + Vector3(0, y1, 0), w, WHITE)

func _tower() -> void:
	var h := 25.0
	var rb := 4.4
	var rt := 3.7
	_oct("Shaft", 0.0, h, rb, rt, brick, Color.WHITE, true)
	_ribs(0.0, h, rb, rt, 0.5)
	# horizontale banden
	for y in [4.6, 9.2, 13.8, 18.4, 23.0]:
		var r: float = lerpf(rb, rt, y / h) + 0.08
		_oct("Band", y - 0.18, 0.36, r, r, null, WHITE)
	# kleine smalle raampjes op een paar zijden, en een deur
	for p in [[0.0, 7.0], [0.0, 11.5], [2.0, 16.0], [5.0, 20.5], [1.0, 2.0]]:
		var a: float = TAU * float(p[0]) / 8.0
		var y: float = p[1]
		var r: float = lerpf(rb, rt, y / h) * cos(PI / 8.0) + 0.05
		var f := Kit.face(self, Vector3(sin(a), 0, cos(a)) * r, rad_to_deg(a))
		if y < 3.0:
			Kit.box(f, "Door", Vector3(0, 1.1, 0.03), Vector3(1.0, 2.2, 0.06), Color("7a3a2e"))
		else:
			Kit.box(f, "Small window", Vector3(0, y, 0.03), Vector3(0.45, 0.8, 0.06), GLASS)
	# uitkragende rand en het reservoir
	_oct("Corbel", h, 1.6, rt, 5.0, null, WHITE)
	var r0 := 5.0
	_oct("Reservoir", h + 1.6, 6.4, r0, r0, brick)
	_ribs(h + 1.6, h + 8.0, r0, r0, 0.45)
	_oct("Reservoir top band", h + 7.8, 0.5, r0 + 0.1, r0 + 0.1, null, WHITE)
	for k in [0, 1, 3, 5, 7]:
		var a: float = TAU * float(k) / 8.0
		var f := Kit.face(self, Vector3(sin(a), 0, cos(a)) * (r0 * cos(PI / 8.0) + 0.05), rad_to_deg(a))
		Kit.box(f, "Reservoir window frame", Vector3(0, h + 4.8, 0.03), Vector3(0.75, 1.9, 0.06), Color("8a2a22"))
		Kit.box(f, "Reservoir window", Vector3(0, h + 4.8, 0.06), Vector3(0.5, 1.6, 0.04), GLASS)
	# tentdak
	_oct("Roof", h + 8.3, 2.6, r0 + 0.3, 0.5, null, Color("4b3a35"))
	_oct("Roof cap", h + 10.8, 0.5, 0.6, 0.4, null, Color("4b3a35"))
	# uitkijkbak links
	var lb := Vector3(-r0 - 1.8, h + 3.2, 0.0)
	Kit.box(self, "Lookout box floor", lb + Vector3(0, -0.7, 0), Vector3(3.8, 0.2, 2.2), CORTEN)
	for z in [-1.05, 1.05]:
		Kit.box(self, "Lookout box side", lb + Vector3(0, 0, z), Vector3(3.8, 1.4, 0.1), CORTEN)
	Kit.box(self, "Lookout box end", lb + Vector3(-1.85, 0, 0), Vector3(0.1, 1.4, 2.2), CORTEN)
	# rechts: schuine trap naar een balkon en weer terug naar de toren
	var top := Vector3(r0 - 0.2, h + 3.0, 0)
	var bal := Vector3(r0 + 5.5, h - 2.0, 0)
	Kit.box(self, "Balcony", bal, Vector3(2.8, 1.4, 2.4), CORTEN)
	Kit.beam(self, "Stair down", top, bal + Vector3(-1.2, 0.3, 0), 1.2, CORTEN)
	Kit.beam(self, "Stair back", bal + Vector3(-1.2, -0.5, 0), Vector3(rt + 0.2, h - 7.0, 0), 1.2, CORTEN)

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 3.0, 0), 0.4, 0.3, 6.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 4.5
	cm.height = 7.5
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("4f7a36"))
	cr.position = p + Vector3(0, 8.0, 0)
	add_child(cr)
