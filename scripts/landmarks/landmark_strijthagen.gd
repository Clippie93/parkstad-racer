extends Node3D
# Kasteel Strijthagen (Landgraaf), naar jouw foto's (23-11): een groot rechthoekig huis van
# natuursteen met baksteen (warm bruingrijs) in de gracht, drie lagen, een hoog donker
# schilddak met schoorstenen; witte ramen met donkergroene luiken en kleine kelderraampjes;
# in het midden van de voorgevel een uitgebouwde traptoren met een donker tentdak; op de
# hoeken van de lage walmuur langs het water twee ronde torentjes met een leien koepeldakje
# en een spits. Links een ouder gebouw met een puntgevel en een houten loopbrug.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const SLATE := Color("3d4048")
const SHUTTER := Color("2f4a3a")
const FRAME := Color("f2f0ea")
const GLASS := Color("2c3438")
const WATER := Color("405a5e")

var stone: Material
var brick: Material

func _ready() -> void:
	name = "Kasteel Strijthagen"
	stone = Kit.tex_mat("res://assets/kerk_rubble.png", Color("c2a88a"), 3.0)
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("c49480"), 3.0)
	Kit.box(self, "Castle lawn", Vector3(0, 0.03, 0), Vector3(90.0, 0.06, 74.0), Color("6d9a4c"))
	Kit.box(self, "Moat", Vector3(0, 0.07, -6), Vector3(64.0, 0.06, 48.0), Color.WHITE, false, Kit.mat(WATER, 0.0, 0.25, 0.12))
	Kit.box(self, "Island", Vector3(0, 0.6, -10), Vector3(44.0, 1.2, 30.0), Color("6d8a4c"))
	_quay()
	_house(Vector3(2, 1.2, -12))
	_old_wing(Vector3(-24, 1.2, -18))
	_footbridge()
	for p in [Vector3(-38, 0, 20), Vector3(36, 0, 18), Vector3(38, 0, -24), Vector3(-36, 0, -30), Vector3(28, 0, -34)]:
		_tree(p)

# Lage gemetselde walmuur langs het water met de twee ronde hoektorentjes.
func _quay() -> void:
	var zf := 5.0
	Kit.box(self, "Quay wall front", Vector3(0, 0.9, zf), Vector3(44.0, 2.2, 1.0), Color.WHITE, true, stone)
	for sx in [-1.0, 1.0]:
		Kit.box(self, "Quay wall side", Vector3(sx * 22.0, 0.9, -10.0), Vector3(1.0, 2.2, 30.0), Color.WHITE, true, stone)
		var tp := Vector3(sx * 18.0, 0, zf)
		Kit.cyl(self, "Corner turret", tp + Vector3(0, 3.6, 0), 2.0, 2.0, 6.0, Color.WHITE, 16, "y", true, brick)
		Kit.cyl(self, "Turret base", tp + Vector3(0, 0.6, 0), 2.3, 2.3, 1.2, Color.WHITE, 16, "y", false, stone)
		# leien koepeldakje met een spits
		Kit.cyl(self, "Turret roof skirt", tp + Vector3(0, 6.85, 0), 2.4, 2.0, 0.5, SLATE, 16)
		Kit.cyl(self, "Turret roof", tp + Vector3(0, 7.9, 0), 2.0, 1.1, 1.6, SLATE, 16)
		Kit.cyl(self, "Turret roof top", tp + Vector3(0, 9.0, 0), 1.1, 0.25, 0.8, SLATE, 16)
		Kit.cyl(self, "Turret spire", tp + Vector3(0, 9.9, 0), 0.08, 0.04, 1.4, Color("8a8f94"), 6)
		Kit.cyl(self, "Turret ball", tp + Vector3(0, 10.7, 0), 0.18, 0.18, 0.3, Color("8a8f94"), 8)
		var f := Kit.face(self, tp + Vector3(0, 0, 2.0), 0.0)
		Kit.box(f, "Turret window", Vector3(0, 3.8, 0.03), Vector3(0.6, 0.9, 0.05), FRAME)

func _win(f: Node3D, x: float, y: float, w := 1.2, h := 1.7) -> void:
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.04), Vector3(w + 0.2, h + 0.2, 0.06), FRAME)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.07), Vector3(w - 0.1, h - 0.1, 0.04), GLASS)
	Kit.box(f, "Window cross", Vector3(x, y + h * 0.6, 0.09), Vector3(w - 0.1, 0.07, 0.02), FRAME)
	Kit.box(f, "Window bar", Vector3(x, y + h * 0.5, 0.09), Vector3(0.07, h - 0.1, 0.02), FRAME)
	for s in [-1.0, 1.0]:
		Kit.box(f, "Shutter", Vector3(x + s * (w * 0.5 + 0.38), y + h * 0.5, 0.06), Vector3(0.55, h + 0.1, 0.05), SHUTTER)

func _house(c: Vector3) -> void:
	var w := 26.0
	var d := 14.0
	var h := 11.0
	Kit.box(self, "Castle house", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), Color.WHITE, true, stone)
	# hoog schilddak
	var hx: float = w * 0.5 + 0.4
	var hz: float = d * 0.5 + 0.4
	var rise := 7.5
	var r: float = hx - hz
	var t: Array = []
	var a := Vector3(-r, rise, 0)
	var b := Vector3(r, rise, 0)
	Kit._quad(t, Vector3(-hx, 0, hz), Vector3(hx, 0, hz), b, a)
	Kit._quad(t, Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), a, b)
	t.append_array([Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), a])
	t.append_array([Vector3(hx, 0, hz), Vector3(hx, 0, -hz), b])
	var roof := MeshInstance3D.new()
	roof.name = "Castle roof"
	roof.mesh = Kit._mesh_from(t, Kit._two_sided(SLATE))
	roof.position = c + Vector3(0, h, 0)
	add_child(roof)
	for cx in [-8.0, 8.0]:
		Kit.box(self, "Chimney", c + Vector3(cx, h + 6.0, 0), Vector3(1.0, 3.0, 1.2), Color("8a5a48"))
	Kit.box(self, "Dormer", c + Vector3(6.0, h + 2.2, d * 0.5 - 0.6), Vector3(1.2, 1.2, 1.0), SLATE)
	# voorgevel: drie lagen ramen met luiken, kleine kelderraampjes
	var f := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	for x in [-10.0, -6.0, -2.0, 6.0, 10.0]:
		_win(f, x, 1.4, 1.2, 1.7)
		_win(f, x, 4.8, 1.2, 1.9)
		_win(f, x, 8.3, 1.2, 1.9)
	for x in [-10.0, -6.0, 6.0, 10.0]:
		Kit.box(f, "Cellar window", Vector3(x, 0.5, 0.04), Vector3(0.5, 0.35, 0.05), GLASS)
	# uitgebouwde traptoren in het midden met een tentdak
	var tc: Vector3 = c + Vector3(2.0, 0, d * 0.5 + 1.6)
	Kit.box(self, "Stair tower", tc + Vector3(0, 4.5, 0), Vector3(4.0, 9.0, 3.2), Color.WHITE, true, brick)
	Kit.pyramid(self, "Stair tower roof", tc + Vector3(0, 9.0, 0), 2.4, 2.6, SLATE)
	var tf := Kit.face(self, tc + Vector3(0, 0, 1.6), 0.0)
	_win(tf, 0.0, 5.0, 1.0, 1.6)
	Kit.box(tf, "Stair tower arch", Vector3(0, 1.3, 0.03), Vector3(1.6, 2.6, 0.05), Color("2a2622"))
	# zijgevels met een paar ramen
	for s in [-1.0, 1.0]:
		var sf := Kit.face(self, c + Vector3(s * w * 0.5, 0, 0), 90.0 * s)
		for x in [-3.5, 3.5]:
			_win(sf, x, 4.8, 1.2, 1.9)

# Ouder gebouw met een puntgevel links achter het huis.
func _old_wing(c: Vector3) -> void:
	Kit.box(self, "Old wing", c + Vector3(0, 4.0, 0), Vector3(10.0, 8.0, 12.0), Color.WHITE, true, stone)
	Kit.gable(self, "Old wing roof", c + Vector3(0, 8.0, 0), 10.6, 12.4, 5.0, SLATE)
	var f := Kit.face(self, c + Vector3(0, 0, 6.0), 0.0)
	var t: Array = [Vector3(-5.0, 8.0, 0.02), Vector3(5.0, 8.0, 0.02), Vector3(0, 12.8, 0.02)]
	var g := MeshInstance3D.new()
	g.mesh = Kit._mesh_from(t, Kit._two_sided(Color("b09a80")))
	f.add_child(g)
	_win(f, 0.0, 3.6, 1.0, 1.5)

# Houten loopbrug van de walmuur van het eiland (z 5) over de gracht tot op de oever.
func _footbridge() -> void:
	var x := -12.0
	var a := Vector3(x, 2.1, 5.2)
	var b := Vector3(x, 0.25, 19.5)     # gracht tot z 18
	var d: Vector3 = b - a
	var ln: float = d.length()
	var mid: Vector3 = (a + b) * 0.5
	var tilt: float = atan2(-d.y, d.z)
	var deck := Kit.box(self, "Footbridge", mid, Vector3(2.4, 0.2, ln), Color("6a5a48"), true)
	deck.rotation.x = tilt
	for s in [-1.0, 1.0]:
		var rail := Kit.box(self, "Footbridge rail", mid + Vector3(s * 1.15, 0.9, 0), Vector3(0.08, 0.08, ln), Color("4a4038"))
		rail.rotation.x = tilt
		for k in range(7):
			var f: float = float(k) / 6.0
			var p: Vector3 = a.lerp(b, f)
			Kit.box(self, "Footbridge post", p + Vector3(s * 1.15, 0.45, 0), Vector3(0.08, 0.9, 0.08), Color("4a4038"))
	# paaltjes in het water
	for f in [0.33, 0.66]:
		var p: Vector3 = a.lerp(b, f)
		Kit.box(self, "Footbridge pile", Vector3(x, p.y * 0.5, p.z), Vector3(2.0, p.y, 0.3), Color("4a4038"))
	# opening in de walmuur waar de brug aankomt
	Kit.box(self, "Quay gap", Vector3(x, 1.6, 5.0), Vector3(2.6, 1.0, 1.1), Color("6d8a4c"))

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 3.5, 0), 0.45, 0.35, 7.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 5.0
	cm.height = 9.0
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("4f7a36"))
	cr.position = p + Vector3(0, 9.5, 0)
	add_child(cr)
