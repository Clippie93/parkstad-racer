extends Node3D
# Nonke Buusjke (Schinveld), openluchtmuseum in de Schinveldse bossen, naar jouw foto's
# (25-11). Een binnenplaats van grind onder hoge bomen, met rondom oude vakwerkhuisjes:
# - achterin een lang huis, wit gepleisterd met zwart vakwerk, rode schuine schoren onder
#   de dakgoot, een oud pannendak met een dakkapel (rood met groen), een groene deur,
#   witte raampjes met groene luiken
# - links een wit vakwerkhuis met een strogeel dak
# - rechts een okergeel huis met een puntgevel met bruin vakwerk (grote schoren)
# - rechts een lange open schuur met een strodak waaronder de kraampjes staan
# Op het plein groene tafels met rode banken.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const WHITE := Color("f2efe6")
const OCHRE := Color("e2c886")
const BLACK := Color("26221e")
const BROWN := Color("6a4a32")
const RED := Color("a8322a")
const GREEN := Color("2f5a3e")
const TILES := Color("5a4a42")
const THATCH := Color("b89a5a")
const GLASS := Color("2c3236")

func _ready() -> void:
	name = "Nonke Buusjke"
	Kit.box(self, "Courtyard", Vector3(0, 0.03, -6), Vector3(36, 0.06, 30), Color("b49a7c"))
	_long_house(Vector3(0, 0, -18))
	_white_house(Vector3(-15, 0, -6))
	_ochre_house(Vector3(13, 0, -12))
	_stalls(Vector3(14, 0, 2))
	for p in [Vector3(-6, 0, -6), Vector3(3, 0, -2), Vector3(-2, 0, 3), Vector3(6, 0, -9)]:
		_table(p)
	for p in [Vector3(-9, 0, 2), Vector3(4, 0, -8), Vector3(-4, 0, -12), Vector3(9, 0, 6), Vector3(-17, 0, 8)]:
		_tree(p)
	# lage haag en een poortje naar de weg
	for sx in [-1.0, 1.0]:
		Kit.box(self, "Hedge", Vector3(sx * 11.0, 0.6, 9.5), Vector3(16.0, 1.2, 1.2), Color("3f5a32"))

# Vakwerk als één mesh: latten (segmenten in gevel-coördinaten) net voor de muur.
func _timbers(f: Node3D, segs: Array, width: float, color: Color, z := 0.03) -> void:
	var t: Array = []
	for sg in segs:
		var a: Vector2 = sg[0]
		var b: Vector2 = sg[1]
		var d: Vector2 = (b - a).normalized()
		var n := Vector2(-d.y, d.x) * (width * 0.5)
		Kit._quad(t, Vector3(a.x - n.x, a.y - n.y, z), Vector3(b.x - n.x, b.y - n.y, z), Vector3(b.x + n.x, b.y + n.y, z), Vector3(a.x + n.x, a.y + n.y, z))
	var mi := MeshInstance3D.new()
	mi.name = "Timber frame"
	mi.mesh = Kit._mesh_from(t, Kit._two_sided(color))
	f.add_child(mi)

# Standaard vakwerkraster voor een muur: stijlen om de `step` m, regels onder, midden, boven.
func _grid(w: float, h: float, step: float, braces := false) -> Array:
	var segs: Array = []
	var x := -w * 0.5
	while x <= w * 0.5 + 0.01:
		segs.append([Vector2(x, 0.3), Vector2(x, h)])
		x += step
	for y in [0.35, h * 0.5, h - 0.1]:
		segs.append([Vector2(-w * 0.5, y), Vector2(w * 0.5, y)])
	if braces:
		segs.append([Vector2(-w * 0.5, h * 0.5), Vector2(-w * 0.5 + step, h - 0.1)])
		segs.append([Vector2(w * 0.5, h * 0.5), Vector2(w * 0.5 - step, h - 0.1)])
	return segs

func _small_window(f: Node3D, x: float, y: float, shutters := true) -> void:
	Kit.box(f, "Window", Vector3(x, y, 0.05), Vector3(0.8, 0.95, 0.04), WHITE)
	Kit.box(f, "Glass", Vector3(x, y, 0.08), Vector3(0.62, 0.78, 0.02), GLASS)
	Kit.box(f, "Window bar", Vector3(x, y, 0.1), Vector3(0.05, 0.78, 0.02), WHITE)
	if shutters:
		for s in [-1.0, 1.0]:
			Kit.box(f, "Shutter", Vector3(x + s * 0.62, y, 0.06), Vector3(0.38, 1.0, 0.04), GREEN)

func _long_house(c: Vector3) -> void:
	var w := 20.0
	var d := 7.0
	var h := 3.2
	Kit.box(self, "Long house", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), WHITE, true)
	Kit.box(self, "Brick plinth", c + Vector3(0, 0.2, 0), Vector3(w + 0.1, 0.4, d + 0.1), Color("8a5040"))
	Kit.gable(self, "Tile roof", c + Vector3(0, h, 0), d + 2.0, w + 0.6, 3.6, TILES, true)
	Kit.box(self, "Gutter", c + Vector3(0, h - 0.05, d * 0.5 + 0.9), Vector3(w + 0.6, 0.18, 0.2), GREEN)
	var f := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	_timbers(f, _grid(w, h, 1.6), 0.18, BLACK)
	# rode schoren onder de goot
	var braces: Array = []
	var x := -w * 0.5 + 1.6
	while x < w * 0.5 - 0.5:
		braces.append([Vector2(x, h * 0.55), Vector2(x + 0.9, h - 0.05)])
		x += 3.2
	_timbers(f, braces, 0.14, RED, 0.25)
	Kit.box(f, "Green door", Vector3(-1.0, 1.05, 0.06), Vector3(1.0, 2.1, 0.05), GREEN)
	for wx in [-6.5, -4.0, 2.2, 5.0, 7.5]:
		_small_window(f, wx, 1.6, wx > 0.0)
	# dakkapel: rood met groene randen
	Kit.box(self, "Dormer", c + Vector3(1.5, h + 1.0, d * 0.5 + 0.2), Vector3(1.8, 1.3, 1.4), RED)
	Kit.gable(self, "Dormer roof", c + Vector3(1.5, h + 1.65, d * 0.5 + 0.2), 2.2, 1.8, 0.7, GREEN)
	var df := Kit.face(self, c + Vector3(1.5, 0, d * 0.5 + 0.9), 0.0)
	_small_window(df, 0.0, h + 1.0, false)
	Kit.box(self, "Chimney", c + Vector3(-7.0, h + 3.2, -1.0), Vector3(0.4, 1.8, 0.4), Color("9aa0a4"))
	# bankje en rek tegen de gevel
	Kit.box(self, "Bench", c + Vector3(-3.4, 0.45, d * 0.5 + 0.6), Vector3(2.4, 0.12, 0.5), BROWN)

func _white_house(c: Vector3) -> void:
	var w := 7.0
	var d := 10.0
	var h := 3.0
	Kit.box(self, "White house", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), WHITE, true)
	Kit.gable(self, "Thatch roof", c + Vector3(0, h, 0), w + 1.6, d + 1.0, 3.4, THATCH)
	var f := Kit.face(self, c + Vector3(w * 0.5, 0, 0), 90.0)
	_timbers(f, _grid(d, h, 1.5, true), 0.18, BLACK)
	_small_window(f, -2.5, 1.5)
	_small_window(f, 2.5, 1.5)
	Kit.box(f, "Door", Vector3(0, 1.0, 0.06), Vector3(0.95, 2.0, 0.05), BLACK)
	# voorgevel (naar de weg) met vakwerk in de top
	var gf := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	_timbers(gf, _grid(w, h, 1.4), 0.18, BLACK)
	var t: Array = [Vector3(-w * 0.5, h, 0.0), Vector3(w * 0.5, h, 0.0), Vector3(0, h + 3.4, 0.0)]
	var g := MeshInstance3D.new()
	g.mesh = Kit._mesh_from(t, Kit._two_sided(WHITE))
	gf.add_child(g)
	_timbers(gf, [[Vector2(0, h), Vector2(0, h + 3.2)], [Vector2(-w * 0.3, h + 1.2), Vector2(w * 0.3, h + 1.2)]], 0.18, BLACK)

func _ochre_house(c: Vector3) -> void:
	var w := 7.0
	var d := 8.0
	var h := 3.4
	Kit.box(self, "Ochre house", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), OCHRE, true)
	Kit.gable(self, "Ochre roof", c + Vector3(0, h, 0), w + 0.8, d + 0.8, 4.4, Color("6a5a50"))
	var gf := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	var t: Array = [Vector3(-w * 0.5, h, 0.0), Vector3(w * 0.5, h, 0.0), Vector3(0, h + 4.4, 0.0)]
	var g := MeshInstance3D.new()
	g.mesh = Kit._mesh_from(t, Kit._two_sided(OCHRE))
	gf.add_child(g)
	var segs: Array = _grid(w, h, 1.75)
	# grote gebogen schoren als een "X" over gevel en top, middenstijl tot de nok
	segs.append([Vector2(-w * 0.5, 0.4), Vector2(-0.4, h + 3.6)])
	segs.append([Vector2(w * 0.5, 0.4), Vector2(0.4, h + 3.6)])
	segs.append([Vector2(0, h), Vector2(0, h + 4.2)])
	segs.append([Vector2(-w * 0.32, h + 1.4), Vector2(w * 0.32, h + 1.4)])
	_timbers(gf, segs, 0.2, BROWN)
	_small_window(gf, -0.9, 1.6, false)
	_small_window(gf, 0.9, 1.6, false)
	_small_window(gf, -0.5, h + 0.7, false)
	_small_window(gf, 0.5, h + 0.7, false)
	Kit.box(gf, "Bargeboard", Vector3(0, h + 4.45, 0.2), Vector3(0.3, 0.3, 0.3), Color("c8c2b4"))

# Lange open schuur met strodak en kraampjes eronder.
func _stalls(c: Vector3) -> void:
	var w := 4.0
	var d := 16.0
	Kit.box(self, "Stall back wall", c + Vector3(1.6, 1.3, 0), Vector3(0.3, 2.6, d), WHITE, true)
	var f := Kit.face(self, c + Vector3(1.45, 0, 0), -90.0)
	_timbers(f, _grid(d, 2.6, 2.0), 0.16, BLACK)
	for z in [-7.5, -2.5, 2.5, 7.5]:
		Kit.box(self, "Stall post", c + Vector3(-1.6, 1.3, z), Vector3(0.2, 2.6, 0.2), BROWN)
	var roof := Kit.box(self, "Thatch stall roof", c + Vector3(0, 3.0, 0), Vector3(w + 1.4, 0.45, d + 0.6), THATCH)
	roof.rotation.z = 0.32
	for z in [-5.0, 0.0, 5.0]:
		Kit.box(self, "Stall counter", c + Vector3(0.6, 0.5, z), Vector3(1.2, 1.0, 3.6), Color("8a6a4a"))

func _table(p: Vector3) -> void:
	Kit.box(self, "Picnic table", p + Vector3(0, 0.75, 0), Vector3(2.0, 0.08, 0.9), GREEN)
	Kit.box(self, "Table leg", p + Vector3(0, 0.37, 0), Vector3(1.6, 0.74, 0.1), Color("2a3a2a"))
	for s in [-1.0, 1.0]:
		Kit.box(self, "Red bench", p + Vector3(0, 0.45, s * 0.85), Vector3(2.0, 0.08, 0.35), RED)
		Kit.box(self, "Red bench back", p + Vector3(0, 0.75, s * 1.05), Vector3(2.0, 0.5, 0.06), RED)

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 5.0, 0), 0.4, 0.3, 10.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 5.0
	cm.height = 6.0
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("4a7a36"))
	cr.position = p + Vector3(0, 12.0, 0)
	add_child(cr)
