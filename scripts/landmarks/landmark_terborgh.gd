extends Node3D
# Kasteel Terborgh, Schinnen (Beekdaelen). Naar jouw foto's (20-11): een gesloten
# carré van vier vleugels rond een binnenplaats van grind, rondom in de gracht.
# - voorkant: een poortgebouw met een puntgevel en een rondboogdoorgang, een brug met
#   bakstenen borstwering, banken en lantaarnpalen; links een lange lage vleugel met kleine
#   vensters en een halsgevel met schoorsteen op het uiteinde, rechts een hoger stuk met
#   witte kruiskozijnen in natuurstenen omlijsting
# - rechts het hoofdhuis: drie lagen, lange gevel met rijen kruiskozijnen en muurankers,
#   op de kop naar voren een hoge tuitgevel met gebogen hals en een natuurstenen top
# - pannendaken in donker blauwgrijs met kleine dakkapellen
# - aan de straatkant een vakwerkhuisje en bomen: vanaf de weg zie je het kasteel maar half
# Lokale ruimte: +Z = straatkant.
const Kit = preload("res://scripts/build_kit.gd")

const STONE := Color("cfc8b8")
const TILES := Color("4a4e58")
const GLASS := Color("2c3438")
const FRAME := Color("f2f0ea")
const IRON := Color("1f2021")
const FZ := -15.0          # voorgevel van de voorvleugel

var brick: Material

func _ready() -> void:
	name = "Kasteel Terborgh"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("cdb3ad"), 3.0)
	# gracht met eiland
	Kit.box(self, "Moat", Vector3(0, 0.05, -36.0), Vector3(70.0, 0.1, 62.0), Color("44584c"))
	Kit.box(self, "Island", Vector3(0.5, 0.1, -36.0), Vector3(60.0, 0.12, 52.0), Color("5f8a45"))
	Kit.box(self, "Courtyard", Vector3(-4.0, 0.18, -37.0), Vector3(36.0, 0.04, 24.0), Color("aea48e"))
	_front_left()
	_gate()
	_front_right()
	_main_wing()
	# achter- en linkervleugel (lager, eenvoudig)
	_block("Back wing", Vector3(-5.0, 0, -54.0), 42.0, 8.0, 7.0, 6.0, true)
	_block("Left wing", Vector3(-22.0, 0, -37.0), 8.0, 26.0, 7.0, 6.0, false)
	_bridge()
	_timber_house(Vector3(-46.0, 0, -12.0))
	for tp in [Vector3(-24, 0, -1.5), Vector3(-10, 0, -1.5), Vector3(17, 0, -1.5), Vector3(32, 0, -1.5), Vector3(39, 0, -24), Vector3(-38, 0, -30)]:
		_tree(tp)

# ---------------------------------------------------------------- hulpjes
func _mesh(parent: Node3D, n: String, tris: Array, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, m)
	parent.add_child(mi)
	return mi

func _roof(n: String, base: Vector3, width: float, length: float, rise: float, along_x: bool) -> void:
	var hw: float = width * 0.5
	var hl: float = length * 0.5
	var t: Array = []
	Kit._quad(t, Vector3(-hw, 0, -hl), Vector3(-hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	Kit._quad(t, Vector3(hw, 0, -hl), Vector3(hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	var mi := _mesh(self, n, t, Kit._two_sided(TILES))
	mi.position = base
	if along_x:
		mi.rotation_degrees.y = 90.0

func _gable(f: Node3D, y: float, w: float, rise: float) -> void:
	var hw: float = w * 0.5
	_mesh(f, "Gable", [Vector3(hw, y, 0), Vector3(-hw, y, 0), Vector3(0, y + rise, 0)], brick)

# Tuitgevel: bakstenen driehoek iets boven het dak uit, met een smalle hals met gebogen
# schouders en een natuurstenen top, in face-ruimte.
func _neck_gable(f: Node3D, y: float, w: float, rise: float, neck_w: float, neck_h: float) -> void:
	var hw: float = w * 0.5
	var top_y: float = y + rise
	var nw: float = neck_w * 0.5
	var t: Array = []
	# schuine flanken tot onder de hals
	var y1: float = top_y - neck_h * 0.4
	var x1: float = hw * (1.0 - (y1 - y) / rise) + 0.35
	t.append_array([Vector3(hw + 0.3, y, 0), Vector3(-hw - 0.3, y, 0), Vector3(-x1, y1, 0)])
	t.append_array([Vector3(hw + 0.3, y, 0), Vector3(-x1, y1, 0), Vector3(x1, y1, 0)])
	# hals met gebogen schouders
	var steps := 6
	for s in [-1.0, 1.0]:
		for k in range(steps):
			var a0: float = PI * 0.5 * float(k) / float(steps)
			var a1: float = PI * 0.5 * float(k + 1) / float(steps)
			var r: float = x1 - nw
			var p0 := Vector3(s * (nw + r * cos(a0)), y1 + r * 0.8 * sin(a0), 0)
			var p1 := Vector3(s * (nw + r * cos(a1)), y1 + r * 0.8 * sin(a1), 0)
			if s > 0.0:
				t.append_array([Vector3(0, y1, 0), p0, p1])
			else:
				t.append_array([Vector3(0, y1, 0), p1, p0])
	var ny0: float = y1 + (x1 - nw) * 0.8
	var neck_top: float = maxf(ny0 + 0.8, top_y + 1.2)
	Kit._quad(t, Vector3(nw, y1, 0), Vector3(-nw, y1, 0), Vector3(-nw, neck_top, 0), Vector3(nw, neck_top, 0))
	_mesh(f, "Neck gable", t, Kit._two_sided(Color("8a6a62")))
	var bf := Kit.face(f, Vector3(0, 0, 0.02), 0.0)
	_mesh(bf, "Neck gable brick", t, brick)
	Kit.box(f, "Neck cap", Vector3(0, neck_top + 0.12, 0.05), Vector3(neck_w + 0.3, 0.24, 0.5), STONE)
	Kit.cyl(f, "Neck finial", Vector3(0, neck_top + 0.55, 0.05), 0.18, 0.08, 0.6, STONE, 8)

# Kruiskozijn: wit, met roeden, in een natuurstenen omlijsting.
func _xwin(f: Node3D, x: float, y: float, w: float = 1.2, h: float = 1.9) -> void:
	Kit.box(f, "Window surround", Vector3(x, y + h * 0.5, 0.04), Vector3(w + 0.36, h + 0.36, 0.1), STONE)
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.08), Vector3(w, h, 0.05), FRAME)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.11), Vector3(w - 0.16, h - 0.16, 0.03), GLASS)
	Kit.box(f, "Mullion", Vector3(x, y + h * 0.5, 0.13), Vector3(0.08, h - 0.1, 0.03), FRAME)
	Kit.box(f, "Transom", Vector3(x, y + h * 0.66, 0.13), Vector3(w - 0.1, 0.08, 0.03), FRAME)
	for gy in [0.33, 0.85]:
		Kit.box(f, "Glazing bar", Vector3(x, y + h * gy, 0.14), Vector3(w - 0.12, 0.03, 0.02), FRAME)

func _small_win(f: Node3D, x: float, y: float) -> void:
	Kit.box(f, "Small window surround", Vector3(x, y + 0.45, 0.04), Vector3(0.75, 1.05, 0.08), STONE)
	Kit.box(f, "Small window", Vector3(x, y + 0.45, 0.08), Vector3(0.5, 0.8, 0.04), GLASS)
	Kit.box(f, "Small window bar", Vector3(x, y + 0.45, 0.1), Vector3(0.04, 0.8, 0.02), FRAME)

func _anchor(f: Node3D, x: float, y: float) -> void:
	Kit.box(f, "Wall anchor", Vector3(x, y, 0.06), Vector3(0.08, 0.6, 0.05), IRON)

func _block(n: String, c: Vector3, sx: float, sz: float, wall_h: float, rise: float, along_x: bool) -> void:
	Kit.box(self, n, c + Vector3(0, wall_h * 0.5, 0), Vector3(sx, wall_h, sz), Color.WHITE, true, brick)
	_roof(n + " roof", c + Vector3(0, wall_h - 0.1, 0), (sz if along_x else sx) + 1.0, (sx if along_x else sz) + 0.4, rise, along_x)

func _dormer(p: Vector3, facing: Vector3) -> void:
	var d := Kit.box(self, "Dormer", p, Vector3(0.8, 0.6, 0.8), FRAME)
	d.basis = Basis.looking_at(-facing, Vector3.UP)
	var r := Kit.box(self, "Dormer roof", p + Vector3(0, 0.38, 0), Vector3(1.0, 0.14, 1.0), TILES)
	r.basis = d.basis

# ---------------------------------------------------------------- voorkant
func _front_left() -> void:
	# lange lage vleugel links van de poort
	var x0 := -26.0
	var x1 := 0.0
	var wall_h := 7.0
	var cx: float = (x0 + x1) * 0.5
	_block("Front left wing", Vector3(cx, 0, FZ - 4.5), x1 - x0, 9.0, wall_h, 6.0, true)
	var f := Kit.face(self, Vector3(cx, 0, FZ), 0.0)
	for x in [-10.5, -7.0, -3.5, 0.0, 3.5, 7.0]:
		_small_win(f, x, 4.2)
		_anchor(f, x + 1.7, 5.6)
	_small_win(f, 9.5, 1.2)
	Kit.box(f, "Basement vent", Vector3(-4.0, 0.6, 0.05), Vector3(0.5, 0.3, 0.05), Color("151515"))
	# halsgevel op het linkeruiteinde, met een schoorsteen bovenop
	var ef := Kit.face(self, Vector3(x0, 0, FZ - 4.5), -90.0)
	_neck_gable(ef, wall_h - 0.1, 9.0, 6.0, 1.4, 2.0)
	_small_win(ef, 0, 7.6)
	Kit.box(self, "Gable chimney", Vector3(x0 + 0.4, wall_h + 7.6, FZ - 4.5), Vector3(0.9, 1.6, 0.9), Color("7a5a52"))

func _gate() -> void:
	var x0 := 0.0
	var x1 := 8.0
	var cx: float = (x0 + x1) * 0.5
	var fz: float = FZ + 0.8
	var depth := 10.0
	var wall_h := 9.0
	var aw := 3.0
	var spring := 3.4
	# zijdelen en bovenstuk, zodat de doorgang open blijft
	for s in [-1.0, 1.0]:
		Kit.box(self, "Gate side", Vector3(cx + s * (aw + (x1 - x0)) * 0.25, wall_h * 0.5, fz - depth * 0.5), Vector3((x1 - x0 - aw) * 0.5, wall_h, depth), Color.WHITE, true, brick)
	Kit.box(self, "Gate top", Vector3(cx, (spring + aw * 0.5 + wall_h) * 0.5, fz - depth * 0.5), Vector3(aw, wall_h - spring - aw * 0.5, depth), Color.WHITE, true, brick)
	_roof("Gate roof", Vector3(cx, wall_h - 0.1, fz - depth * 0.5), x1 - x0 + 0.8, depth + 0.4, 5.6, false)
	var f := Kit.face(self, Vector3(cx, 0, fz), 0.0)
	_gable(f, wall_h, x1 - x0, 5.6)
	Kit.box(f, "Gable coping", Vector3(0, wall_h - 0.1, 0.1), Vector3(x1 - x0 + 0.3, 0.2, 0.25), STONE)
	_small_win(f, 0, wall_h + 2.2)
	_xwin(f, 0, 5.0, 1.2, 1.8)
	# rondboog met natuurstenen omlijsting; de boog zelf als donkere halve schijf
	var fan: Array = []
	for k in range(14):
		var a0: float = PI * float(k) / 14.0
		var a1: float = PI * float(k + 1) / 14.0
		fan.append_array([Vector3(0, spring, 0.02), Vector3(cos(a1) * aw * 0.5, spring + sin(a1) * aw * 0.5, 0.02), Vector3(cos(a0) * aw * 0.5, spring + sin(a0) * aw * 0.5, 0.02)])
	_mesh(f, "Gate arch", fan, Kit._two_sided(Color("2a2522")))
	for k in range(11):
		var a: float = PI * (float(k) + 0.5) / 11.0
		var v := Kit.box(f, "Arch stone", Vector3(cos(a) * (aw * 0.5 + 0.22), spring + sin(a) * (aw * 0.5 + 0.22), 0.06), Vector3(0.44, 0.5, 0.12), STONE)
		v.rotation.z = a
	for s in [-1.0, 1.0]:
		Kit.box(f, "Gate jamb", Vector3(s * (aw * 0.5 + 0.22), spring * 0.5, 0.06), Vector3(0.44, spring, 0.12), STONE)
	Kit.box(f, "Gate lintel stone", Vector3(0, spring + aw * 0.5 + 0.6, 0.06), Vector3(2.0, 0.3, 0.12), STONE)
	Kit.box(self, "Gate passage floor", Vector3(cx, 0.2, fz - depth * 0.5), Vector3(aw, 0.04, depth), Color("8a857a"))
	Kit.box(self, "Gate passage ceiling", Vector3(cx, spring + aw * 0.5 - 0.02, fz - depth * 0.5), Vector3(aw, 0.04, depth), Color("2a2522"))

func _front_right() -> void:
	var x0 := 8.0
	var x1 := 16.0
	var cx: float = (x0 + x1) * 0.5
	var wall_h := 9.0
	_block("Front right", Vector3(cx, 0, FZ - 4.5), x1 - x0, 9.0, wall_h, 6.0, true)
	var f := Kit.face(self, Vector3(cx, 0, FZ), 0.0)
	for x in [-2.2, 2.2]:
		_xwin(f, x, 1.4)
		_xwin(f, x, 5.2)
	Kit.box(self, "Front right chimney", Vector3(x1 - 1.0, wall_h + 5.0, FZ - 4.5), Vector3(0.8, 2.0, 0.8), Color("7a5a52"))

# Hoofdhuis: drie lagen, lange gevel naar rechts, tuitgevel op de kop naar voren.
func _main_wing() -> void:
	var x0 := 16.0
	var x1 := 27.0
	var cx: float = (x0 + x1) * 0.5
	var z0 := FZ + 1.0
	var z1 := -58.0
	var zc: float = (z0 + z1) * 0.5
	var wall_h := 11.5
	var rise := 7.5
	Kit.box(self, "Main wing", Vector3(cx, wall_h * 0.5, zc), Vector3(x1 - x0, wall_h, z0 - z1), Color.WHITE, true, brick)
	_roof("Main wing roof", Vector3(cx, wall_h - 0.1, zc - 0.2), x1 - x0 + 1.0, z0 - z1 + 0.2, rise, false)
	# kop naar voren met de tuitgevel
	var ff := Kit.face(self, Vector3(cx, 0, z0), 0.0)
	_neck_gable(ff, wall_h - 0.1, x1 - x0, rise, 1.8, 2.6)
	_small_win(ff, 0, wall_h + 2.0)
	for x in [-2.6, 2.6]:
		_xwin(ff, x, 1.4)
		_xwin(ff, x, 5.0)
		_xwin(ff, x, 8.4, 1.1, 1.7)
	for y in [4.4, 7.9]:
		_anchor(ff, -4.6, y)
		_anchor(ff, 4.6, y)
	# lange gevel naar rechts
	var sf := Kit.face(self, Vector3(x1, 0, zc), 90.0)
	var ln: float = z0 - z1
	for k in range(9):
		var x: float = -ln * 0.5 + 4.0 + float(k) * (ln - 8.0) / 8.0
		_xwin(sf, x, 1.4)
		_xwin(sf, x, 5.0)
		if k % 2 == 0:
			_xwin(sf, x, 8.4, 1.1, 1.7)
		Kit.box(sf, "Basement window", Vector3(x, 0.55, 0.06), Vector3(0.45, 0.35, 0.04), GLASS)
		_anchor(sf, x + 1.6, 4.4)
		_anchor(sf, x + 1.6, 7.9)
	# kleine dakkapellen op het lange dakvlak en schoorstenen op de nok
	for k in range(7):
		var z: float = z0 - 6.0 - float(k) * (ln - 12.0) / 6.0
		_dormer(Vector3(x1 - 1.2, wall_h + 1.4, z), Vector3(1, 0, 0))
	for z in [z0 - 6.0, z0 - 26.0]:
		Kit.box(self, "Main chimney", Vector3(cx, wall_h + rise + 0.6, z), Vector3(0.9, 1.8, 0.9), Color("7a5a52"))

# Brug met bakstenen borstwering, banken en lantaarnpalen, en een grindpad naar de weg.
func _bridge() -> void:
	var bx := 4.0
	var z0: float = FZ + 0.8
	var z1 := -2.0
	var zc: float = (z0 + z1) * 0.5
	var ln: float = z1 - z0
	Kit.box(self, "Bridge", Vector3(bx, 0.25, zc), Vector3(4.2, 0.5, ln), Color("8a857a"), true)
	for s in [-1.0, 1.0]:
		Kit.box(self, "Bridge parapet", Vector3(bx + s * 2.3, 0.75, zc), Vector3(0.45, 1.0, ln), Color.WHITE, true, brick)
		Kit.box(self, "Parapet cap", Vector3(bx + s * 2.3, 1.3, zc), Vector3(0.55, 0.12, ln), Color("7a5a52"))
		Kit.box(self, "Bridge pier", Vector3(bx + s * 2.3, 0.8, z1), Vector3(0.6, 1.6, 0.6), Color("b9b2a2"), true)
		Kit.cyl(self, "Lamp post", Vector3(bx + s * 3.2, 1.4, z1 + 0.6), 0.06, 0.06, 2.8, IRON, 6)
		Kit.box(self, "Lamp", Vector3(bx + s * 3.2, 2.95, z1 + 0.6), Vector3(0.3, 0.4, 0.3), Color("e8e2ba"))
		Kit.box(self, "Bench", Vector3(bx + s * 1.5, 0.95, zc - 2.0), Vector3(0.5, 0.08, 1.6), Color("7a5a3a"))
	Kit.box(self, "Gravel path", Vector3(bx, 0.03, 3.0), Vector3(4.2, 0.06, 10.0), Color("a49c8c"))
	# hagen langs de gracht aan de voorkant
	for s in [-1.0, 1.0]:
		Kit.box(self, "Moat hedge", Vector3(bx + s * 15.0, 0.6, -2.4), Vector3(24.0, 1.2, 1.0), Color("3f5f30"))

# Vakwerkhuisje aan de straatkant (eerste foto): wit met zwarte balken, rode pannen.
func _timber_house(p: Vector3) -> void:
	var w := 10.0
	var d := 7.0
	var h := 4.2
	Kit.box(self, "Timber house", p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), Color("f0ece2"), true)
	Kit.box(self, "Timber house plinth", p + Vector3(0, 0.3, 0), Vector3(w + 0.1, 0.6, d + 0.1), Color("8a5848"))
	_roof("Timber house roof", p + Vector3(0, h - 0.1, 0), d + 1.0, w + 0.6, 3.6, true)
	var f := Kit.face(self, p + Vector3(0, 0, d * 0.5), 0.0)
	var dark := Color("2a2420")
	for x in [-4.9, -2.5, 0.0, 2.5, 4.9]:
		Kit.box(f, "Timber post", Vector3(x, h * 0.5, 0.04), Vector3(0.2, h, 0.06), dark)
	for y in [0.65, 2.1, h - 0.1]:
		Kit.box(f, "Timber rail", Vector3(0, y, 0.04), Vector3(w, 0.18, 0.06), dark)
	for x in [-3.7, 1.25]:
		var br := Kit.box(f, "Timber brace", Vector3(x, 3.1, 0.05), Vector3(0.14, 1.6, 0.05), dark)
		br.rotation.z = 0.6
	for x in [-1.25, 3.7]:
		Kit.box(f, "Timber window", Vector3(x, 1.4, 0.06), Vector3(1.0, 1.0, 0.04), GLASS)

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 3.5, 0), 0.4, 0.3, 7.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 4.0
	cm.height = 6.5
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("5d7f3c"))
	cr.position = p + Vector3(0, 9.0, 0)
	add_child(cr)
