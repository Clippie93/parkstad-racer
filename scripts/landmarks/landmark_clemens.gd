extends Node3D
# Clemensdomein (Oude Clemenskerk, Brunssum), naar jouw foto's (23-11):
# - een wit gekalkt kerkje met een donkergrijze plint op een begraste heuvel
# - een vierkante toren met een steile donkere leien naaldspits met kruis, bovenin smalle
#   galmgaten, smeedijzeren muurankers als jaartal 1746 en een donkere deur
# - een schip met een donker zadeldak en rondboogramen, achteraan een koor met een hoog
#   schilddak en een lagere aanbouw met een eigen puntgevel
# - langs de straat een keermuur van baksteen met bakstenen pijlers en daartussen het
#   gouden geometrische hekwerk
# - ernaast een brok ruïne van natuursteen, een paar grafkruizen, een taxus en grote bomen
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const WHITE := Color("f2f1ec")
const PLINTH := Color("4a4c50")
const SLATE := Color("3e4146")
const GOLD := Color("d9bc6a")
const IRON := Color("1f2022")
const GRASS := Color("6d9a4c")
const HILL_H := 4.0

var brick: Material

func _ready() -> void:
	name = "Clemensdomein"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("c98c74"), 3.0)
	Kit.box(self, "Church grounds", Vector3(0, 0.03, 0), Vector3(80.0, 0.06, 56.0), GRASS)
	_hill()
	_front_wall()
	_church(Vector3(2, HILL_H, -4))
	_ruin(Vector3(-22, HILL_H, -6))
	for p in [Vector3(-14, HILL_H, 4), Vector3(-10, HILL_H, 6)]:
		_grave_cross(p)
	_yew(Vector3(-27, 0, 12))
	for p in [Vector3(20, HILL_H, -14), Vector3(-6, HILL_H, -16), Vector3(30, 0, 10)]:
		_tree(p)

# Begraste heuvel: een afgeknotte piramide.
func _hill() -> void:
	var tw := 54.0
	var td := 30.0
	var bw := 64.0
	var bd := 40.0
	var c := Vector3(0, 0, -4)
	var t: Array = []
	var top := [Vector3(-tw * 0.5, HILL_H, -td * 0.5), Vector3(tw * 0.5, HILL_H, -td * 0.5), Vector3(tw * 0.5, HILL_H, td * 0.5), Vector3(-tw * 0.5, HILL_H, td * 0.5)]
	var bot := [Vector3(-bw * 0.5, 0, -bd * 0.5), Vector3(bw * 0.5, 0, -bd * 0.5), Vector3(bw * 0.5, 0, bd * 0.5), Vector3(-bw * 0.5, 0, bd * 0.5)]
	Kit._quad(t, c + top[0], c + top[1], c + top[2], c + top[3])
	for k in range(4):
		var n: int = (k + 1) % 4
		Kit._quad(t, c + bot[k], c + bot[n], c + top[n], c + top[k])
	var mi := MeshInstance3D.new()
	mi.name = "Church hill"
	mi.mesh = Kit._mesh_from(t, Kit._two_sided(GRASS))
	add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = mi.mesh.create_trimesh_shape()
	body.add_child(cs)
	add_child(body)

# Keermuur langs de straat met bakstenen pijlers en gouden geometrisch hekwerk.
func _front_wall() -> void:
	var z := 17.5
	var x0 := -30.0
	var x1 := 30.0
	Kit.box(self, "Retaining wall", Vector3(0, 0.8, z), Vector3(x1 - x0, 1.6, 1.0), Color.WHITE, true, brick)
	Kit.box(self, "Wall cap", Vector3(0, 1.65, z), Vector3(x1 - x0 + 0.2, 0.12, 1.2), Color("c9c6be"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1746
	var x: float = x0 + 2.0
	var prev := -INF
	while x <= x1 - 1.0:
		var ph: float = rng.randf_range(4.0, 5.5)
		var p := Kit.box(self, "Brick pillar", Vector3(x, 1.6 + ph * 0.5, z), Vector3(1.0, ph, 1.0), Color.WHITE, true, brick)
		p.rotation.z = rng.randf_range(-0.08, 0.08)
		Kit.box(self, "Pillar cap", Vector3(x, 1.6 + ph + 0.06, z), Vector3(1.15, 0.14, 1.15), Color("c9c6be"))
		# gouden geometrisch frame naar de vorige pijler
		if prev > -INF:
			var y0 := 1.8
			var pts: Array = []
			for k in range(6):
				pts.append(Vector3(rng.randf_range(prev + 0.5, x - 0.5), rng.randf_range(y0, y0 + 4.5), z))
			pts.sort_custom(func(a, b): return a.x < b.x)
			pts.push_front(Vector3(prev + 0.5, y0, z))
			pts.push_back(Vector3(x - 0.5, y0 + 3.5, z))
			for k in range(pts.size() - 1):
				Kit.beam(self, "Gold frame", pts[k], pts[k + 1], 0.12, GOLD)
			for k in range(0, pts.size() - 2, 2):
				Kit.beam(self, "Gold frame", pts[k], pts[k + 2], 0.12, GOLD)
			Kit.beam(self, "Gold frame", Vector3(prev + 0.5, y0, z), Vector3(x - 0.5, y0, z), 0.12, GOLD)
		prev = x
		x += 6.0

func _arch_win(f: Node3D, x: float, y: float, w := 1.1, h := 2.0) -> void:
	Kit.arch_window(f, x, y, w, h, 0.03, Color("5a6470"), Color("dedcd4"))

func _church(c: Vector3) -> void:
	# schip
	var nl := 18.0
	var nw := 9.0
	var nh := 7.0
	var nc: Vector3 = c + Vector3(2.0, 0, 0)
	Kit.box(self, "Nave", nc + Vector3(0, nh * 0.5, 0), Vector3(nl, nh, nw), WHITE, true)
	Kit.box(self, "Nave plinth", nc + Vector3(0, 0.4, 0), Vector3(nl + 0.1, 0.8, nw + 0.1), PLINTH)
	Kit.gable(self, "Nave roof", nc + Vector3(0, nh, 0), nw + 0.8, nl + 0.4, 4.6, SLATE, true)
	for s in [-1.0, 1.0]:
		var f := Kit.face(self, nc + Vector3(0, 0, s * nw * 0.5), 0.0 if s > 0.0 else 180.0)
		for x in [-6.0, -2.0, 2.0, 6.0]:
			_arch_win(f, x, 2.4, 1.1, 2.4)
	# koor met een hoog schilddak
	var cc: Vector3 = nc + Vector3(nl * 0.5 + 3.5, 0, 0)
	Kit.box(self, "Choir", cc + Vector3(0, nh * 0.5, 0), Vector3(7.0, nh, nw - 1.0), WHITE, true)
	Kit.box(self, "Choir plinth", cc + Vector3(0, 0.4, 0), Vector3(7.1, 0.8, nw - 0.9), PLINTH)
	Kit.pyramid(self, "Choir roof", cc + Vector3(0, nh, 0), 4.6, 5.2, SLATE)
	var cf := Kit.face(self, cc + Vector3(0, 0, (nw - 1.0) * 0.5), 0.0)
	_arch_win(cf, 0.0, 2.6, 1.0, 2.2)
	# lagere aanbouw met een eigen puntgevel naar voren
	var ac: Vector3 = nc + Vector3(nl * 0.5 - 2.5, 0, nw * 0.5 + 2.5)
	Kit.box(self, "Side annex", ac + Vector3(0, 2.6, 0), Vector3(5.0, 5.2, 5.0), WHITE, true)
	Kit.box(self, "Annex plinth", ac + Vector3(0, 0.4, 0), Vector3(5.1, 0.8, 5.1), PLINTH)
	Kit.gable(self, "Annex roof", ac + Vector3(0, 5.2, 0), 5.6, 5.4, 3.0, SLATE, false)
	var af := Kit.face(self, ac + Vector3(0, 0, 2.5), 0.0)
	var tri: Array = [Vector3(-2.5, 5.2, 0.02), Vector3(2.5, 5.2, 0.02), Vector3(0, 8.1, 0.02)]
	var g := MeshInstance3D.new()
	g.mesh = Kit._mesh_from(tri, Kit._two_sided(WHITE))
	af.add_child(g)
	Kit.box(af, "Annex window", Vector3(0, 2.6, 0.03), Vector3(0.8, 1.2, 0.05), Color("5a6470"))
	# toren aan de westkant
	var tc: Vector3 = nc + Vector3(-nl * 0.5 - 3.0, 0, 0)
	var th := 14.0
	Kit.box(self, "Tower", tc + Vector3(0, th * 0.5, 0), Vector3(6.0, th, 6.0), WHITE, true)
	Kit.box(self, "Tower plinth", tc + Vector3(0, 0.45, 0), Vector3(6.1, 0.9, 6.1), PLINTH)
	Kit.box(self, "Tower eaves", tc + Vector3(0, th + 0.1, 0), Vector3(6.5, 0.2, 6.5), SLATE)
	var sp := Kit.cyl(self, "Spire", tc + Vector3(0, th + 5.6, 0), 4.2, 0.12, 11.0, SLATE, 8)
	sp.rotation.y = PI / 8.0
	Kit.cyl(self, "Spire ball", tc + Vector3(0, th + 11.3, 0), 0.2, 0.2, 0.3, Color("8a8f94"), 8)
	Kit.box(self, "Cross", tc + Vector3(0, th + 12.4, 0), Vector3(0.1, 1.8, 0.1), IRON)
	Kit.box(self, "Cross bar", tc + Vector3(0, th + 12.8, 0), Vector3(0.9, 0.1, 0.1), IRON)
	# voorkant (naar de straat) en westkant: galmgaten, raampje, deur, muurankers 1746
	for side in [[Vector3(0, 0, 3.0), 0.0], [Vector3(-3.0, 0, 0), -90.0]]:
		var f := Kit.face(self, tc + side[0], side[1])
		for gx in [-0.5, 0.5]:
			_arch_win(f, gx, th - 3.0, 0.35, 1.4)
		_arch_win(f, 0.0, th * 0.5, 0.4, 1.1)
		if side[1] < 0.0:
			Kit.box(f, "Tower door", Vector3(0, 1.4, 0.03), Vector3(1.3, 2.8, 0.06), Color("4a4f55"))
			var l := Kit.label(f, "1      7\n\n4      6", Vector3(0, th * 0.5 + 0.5, 0.05), 0.02, IRON, 96)
			l.outline_size = 0

# Brok ruïne van natuursteen naast de kerk.
func _ruin(p: Vector3) -> void:
	var stone := Color("a39a86")
	Kit.box(self, "Ruin block", p + Vector3(0, 2.0, 0), Vector3(6.0, 4.0, 5.0), stone, true)
	Kit.box(self, "Ruin block top", p + Vector3(-0.8, 4.6, 0.3), Vector3(3.6, 1.4, 3.6), stone)
	Kit.box(self, "Ruin block peak", p + Vector3(-1.2, 5.8, 0.0), Vector3(1.8, 1.2, 2.0), stone)
	for k in range(4):
		var r := Kit.box(self, "Ruin rubble", p + Vector3(2.8 + float(k) * 0.4, 0.4, -2.0 + float(k) * 1.3), Vector3(1.1, 0.8, 1.0), stone)
		r.rotation.y = float(k) * 0.6

func _grave_cross(p: Vector3) -> void:
	Kit.box(self, "Grave cross", p + Vector3(0, 1.1, 0), Vector3(0.12, 2.2, 0.12), IRON)
	Kit.box(self, "Grave cross bar", p + Vector3(0, 1.7, 0), Vector3(0.7, 0.1, 0.1), IRON)
	Kit.box(self, "Grave stone", p + Vector3(0.6, 0.45, 0.2), Vector3(0.3, 0.9, 0.5), Color("c9c3b4"))

func _yew(p: Vector3) -> void:
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 4.0
	cm.height = 10.0
	cm.radial_segments = 10
	cm.rings = 6
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("2f4a2e"))
	cr.position = p + Vector3(0, 5.0, 0)
	add_child(cr)

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, 4.0, 0), 0.5, 0.35, 8.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 5.5
	cm.height = 9.0
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("4f7a36"))
	cr.position = p + Vector3(0, 11.0, 0)
	add_child(cr)
