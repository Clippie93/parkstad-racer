extends Node3D
# GaiaZOO (Kerkrade): vanaf de weg zie je vooral de uitkijktoren, naar jouw foto (23-11):
# een zwarte stalen toren van staanders met ringvormige platforms en een wenteltrap erin,
# bovenaan een rond platform met reling en een vlaggenmast met vlag. Ervoor een hek met
# struiken en bomen (het park zelf ligt erachter).
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const STEEL := Color("22262a")

func _ready() -> void:
	name = "GaiaZOO"
	Kit.box(self, "Zoo grounds", Vector3(0, 0.03, -14), Vector3(70.0, 0.06, 46.0), Color("5f8a45"))
	_tower(Vector3(4, 0, -10))
	_fence()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(22):
		var p := Vector3(rng.randf_range(-33, 33), 0, rng.randf_range(-36, -2))
		if p.distance_to(Vector3(4, 0, -10)) < 7.0:
			continue
		_tree(p, rng.randf_range(3.0, 5.0))
	for i in range(18):
		var p := Vector3(rng.randf_range(-33, 33), 0, rng.randf_range(4.0, 6.5))
		_bush(p, rng.randf_range(1.2, 2.0))

func _ring(c: Vector3, r: float, thick: float, segs := 16) -> void:
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		Kit.beam(self, "Tower ring", c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r, thick, STEEL)

func _tower(c: Vector3) -> void:
	var h := 24.0
	var posts := 6
	for i in range(posts):
		var a: float = TAU * float(i) / float(posts)
		var d := Vector3(cos(a), 0, sin(a))
		Kit.beam(self, "Tower post", c + d * 3.3, c + d * 2.9 + Vector3(0, h, 0), 0.35, STEEL)
	# platforms om de paar meter, met reling
	for y in [5.0, 10.0, 15.0, 19.5, h]:
		var r: float = 3.3 - 0.4 * y / h
		_ring(c + Vector3(0, y, 0), r + 0.3, 0.3)
		_ring(c + Vector3(0, y + 1.0, 0), r + 0.3, 0.06)
	# bovenste platform iets breder, als een kraag
	_ring(c + Vector3(0, h + 0.4, 0), 3.4, 0.25)
	_ring(c + Vector3(0, h + 1.3, 0), 3.4, 0.08)
	# wenteltrap binnenin: schuine treden rond een spil
	Kit.cyl(self, "Stair core", c + Vector3(0, h * 0.5, 0), 0.15, 0.15, h, STEEL, 6)
	var steps := 56
	for i in range(steps):
		var a: float = float(i) * 0.55
		var y: float = 0.4 + h * float(i) / float(steps)
		Kit.beam(self, "Stair step", c + Vector3(0, y, 0), c + Vector3(cos(a), 0, sin(a)) * 2.2 + Vector3(0, y, 0), 0.15, STEEL)
	# vlaggenmast met vlag
	Kit.cyl(self, "Flag pole", c + Vector3(0.6, h + 4.0, 0), 0.06, 0.05, 8.0, Color("c9ccd0"), 6)
	var flag := Kit.box(self, "Flag", c + Vector3(2.1, h + 6.6, 0), Vector3(3.0, 2.0, 0.05), Color("3c7a4c"))
	flag.rotation.y = 0.3
	var band := Kit.box(self, "Flag band", c + Vector3(2.1, h + 6.0, 0.03), Vector3(3.0, 0.5, 0.03), Color("2f6aa6"))
	band.rotation.y = 0.3

func _fence() -> void:
	var x := -34.0
	while x <= 34.0:
		Kit.cyl(self, "Fence post", Vector3(x, 1.0, 3.0), 0.05, 0.05, 2.0, Color("1f3a2a"), 6)
		x += 2.5
	var mesh_mat := StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.12, 0.22, 0.16, 0.45)
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	Kit.box(self, "Fence mesh", Vector3(0, 1.0, 3.0), Vector3(68.0, 1.9, 0.03), Color.WHITE, false, mesh_mat)

func _tree(p: Vector3, r: float) -> void:
	Kit.cyl(self, "Tree trunk", p + Vector3(0, r * 0.8, 0), 0.3, 0.22, r * 1.6, Color("5b5148"), 6)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = r
	cm.height = r * 1.7
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("4f7a36") if int(p.x) % 2 == 0 else Color("6a9445"))
	cr.position = p + Vector3(0, r * 2.0, 0)
	add_child(cr)

func _bush(p: Vector3, r: float) -> void:
	var b := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = r
	bm.height = r * 1.4
	bm.radial_segments = 8
	bm.rings = 4
	b.mesh = bm
	b.material_override = Kit.mat(Color("5c8a3c"))
	b.position = p + Vector3(0, r * 0.55, 0)
	add_child(b)
