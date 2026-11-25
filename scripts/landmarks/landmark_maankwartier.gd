extends Node3D
# Maankwartier (Heerlen, bij het station), naar jouw foto's en de luchtfoto (23-11):
# - langs de weg een gevelwand van verschillende gebouwen: links een lang wit gebouw met
#   een schuin aflopend dak, dan het brugdeel met twee grote bogen (in het echt over het
#   spoor) en grote rode letters HEERLEN, een rood bakstenen blok en een wit blok met
#   groen glas
# - aan het eind (de kant waar je aan komt rijden) een gebogen vleugel om de hoek: lichte
#   natuursteen, donkere plint met boogetalages (zonder winkelnamen of logo's) en de grote
#   poort met een trap naar het binnenplein
# - daarachter het binnenplein, omsloten door gebouwen met verschillende gevels (wit
#   stucwerk met boogramen, grijze en donkere baksteen)
# - op het binnenplein de maantoren: een roze ronde zuilengalerij, daarboven een zwarte
#   stalen toren met uitstekende ringen (loopbruggen), bovenaan een ring met gouden
#   Romeinse cijfers en een halve maan met kraters, en een windvaan
# Lokale ruimte: +Z = naar de weg. Voorgevels op z = FRONT.
const Kit = preload("res://scripts/build_kit.gd")

const STONE := Color("e7dfcf")
const WHITE := Color("f1efe9")
const GREY_BRICK := Color("b9b4aa")
const DARK_BRICK := Color("4e4440")
const RED_BRICK := Color("9b4a3c")
const PLINTH := Color("4c4a4a")
const GLASS := Color("2a3238")
const GREEN_GLASS := Color("3e6b5c")
const FRAME := Color("d8d2c6")
const STEEL := Color("1c1e21")
const GOLD := Color("d9a93a")
const PINK := Color("cf8a82")
const LETTERS := Color("c0282c")

const FRONT := 3.0
const DEPTH := 14.0
const CC := Vector3(40, 0, -45)       # middelpunt van de gebogen vleugel
const R_OUT := 48.0
const R_IN := 35.0
const TOWER := Vector3(8, 0, -30)     # maantoren op het binnenplein

func _ready() -> void:
	name = "Maankwartier"
	Kit.box(self, "Courtyard", Vector3(10, 0.04, -32), Vector3(70.0, 0.06, 30.0), Color("c8b28a"))
	Kit.box(self, "Forecourt", Vector3(0, 0.03, FRONT + 6.0), Vector3(170.0, 0.06, 12.0), Color("a49f95"))
	_wedge_building()
	_bridge_building()
	_red_block()
	_glass_block()
	_curved_wing()
	_courtyard_blocks()
	_moon_tower()
	# stationsplein aan de kant waar je aan komt rijden, met bomen: zo zie je de gebogen
	# vleugel en de maan al van ver
	Kit.box(self, "Station square", Vector3(126.0, 0.03, -10.0), Vector3(70.0, 0.06, 90.0), Color("aaa59a"))
	for p in [Vector3(104, 0, 20), Vector3(124, 0, 24), Vector3(144, 0, 20), Vector3(152, 0, -6), Vector3(152, 0, -32)]:
		_tree(p)

# ---------------------------------------------------------------- hulpjes
func _mesh(n: String, tris: Array, color: Color, solid := true) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, Kit._two_sided(color))
	add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = mi.mesh.create_trimesh_shape()
		body.add_child(cs)
		add_child(body)

# Vensterraster op een gevel (face-ruimte).
func _windows(f: Node3D, x0: float, x1: float, y0: float, y1: float, dx: float, dy: float, w: float, h: float, glass := GLASS, frame := FRAME) -> void:
	var x: float = x0
	while x <= x1 + 0.01:
		var y: float = y0
		while y + h <= y1 + 0.01:
			Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.04), Vector3(w + 0.3, h + 0.3, 0.08), frame)
			Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.08), Vector3(w, h, 0.05), glass)
			y += dy
		x += dx

func _block(n: String, x0: float, x1: float, z0: float, z1: float, h: float, color: Color) -> void:
	Kit.box(self, n, Vector3((x0 + x1) * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h, z1 - z0), color, true)
	Kit.box(self, n + " parapet", Vector3((x0 + x1) * 0.5, h + 0.4, (z0 + z1) * 0.5), Vector3(x1 - x0 + 0.3, 0.8, z1 - z0 + 0.3), color.darkened(0.08))

# ---------------------------------------------------------------- gevelwand langs de weg
# Lang wit gebouw met een schuin aflopend dak (laag aan de linkerkant).
func _wedge_building() -> void:
	var x0 := -80.0
	var x1 := -22.0
	var h0 := 6.0
	var h1 := 23.0
	var zf: float = FRONT
	var zb: float = FRONT - DEPTH
	var t: Array = []
	Kit._quad(t, Vector3(x0, 0, zf), Vector3(x1, 0, zf), Vector3(x1, h1, zf), Vector3(x0, h0, zf))
	Kit._quad(t, Vector3(x1, 0, zb), Vector3(x0, 0, zb), Vector3(x0, h0, zb), Vector3(x1, h1, zb))
	Kit._quad(t, Vector3(x0, h0, zf), Vector3(x1, h1, zf), Vector3(x1, h1, zb), Vector3(x0, h0, zb))
	Kit._quad(t, Vector3(x0, 0, zb), Vector3(x0, 0, zf), Vector3(x0, h0, zf), Vector3(x0, h0, zb))
	Kit._quad(t, Vector3(x1, 0, zf), Vector3(x1, 0, zb), Vector3(x1, h1, zb), Vector3(x1, h1, zf))
	_mesh("Wedge building", t, WHITE)
	var f := Kit.face(self, Vector3(0, 0, zf), 0.0)
	Kit.box(f, "Wedge plinth", Vector3((x0 + x1) * 0.5, 1.6, 0.03), Vector3(x1 - x0, 3.2, 0.06), PLINTH)
	# vensters alleen onder de schuine daklijn; een paar boogvensters onderin
	var x: float = x0 + 3.0
	var k := 0
	while x < x1 - 1.5:
		var roof: float = h0 + (h1 - h0) * (x - x0) / (x1 - x0)
		var y := 4.6
		while y + 1.6 < roof - 1.0:
			Kit.box(f, "Window frame", Vector3(x, y + 0.8, 0.04), Vector3(1.5, 1.9, 0.08), FRAME)
			Kit.box(f, "Window", Vector3(x, y + 0.8, 0.08), Vector3(1.2, 1.6, 0.05), GLASS)
			y += 3.0
		if k % 2 == 0:
			Kit.arch_window(f, x, 0.3, 2.4, 2.8, 0.06, GLASS, Color("3a3838"))
		x += 3.6
		k += 1
	# donkere verticale glasstrook
	Kit.box(f, "Wedge glass band", Vector3(-30.0, 12.0, 0.1), Vector3(3.0, 17.0, 0.06), GLASS)

# Brugdeel met twee grote bogen en de rode letters HEERLEN.
func _bridge_building() -> void:
	var x0 := -22.0
	var x1 := 14.0
	var h := 21.0
	_block("Bridge building", x0, x1, FRONT - DEPTH, FRONT, h, WHITE)
	var f := Kit.face(self, Vector3(0, 0, FRONT), 0.0)
	for cx in [-12.0, 6.0]:
		Kit.box(f, "Rail arch", Vector3(cx, 3.5, 0.06), Vector3(13.0, 7.0, 0.1), Color("1f2226"))
		Kit.cyl(f, "Rail arch top", Vector3(cx, 7.0, 0.06), 6.5, 6.5, 0.1, Color("1f2226"), 28, "z")
	_windows(f, -20.0, 12.0, 16.4, 20.0, 2.6, 3.0, 1.1, 1.4)
	Kit.label(f, "HEERLEN", Vector3(-4.0, 13.4, 0.12), 0.032, LETTERS, 128)

func _red_block() -> void:
	_block("Red block", 14.0, 22.0, FRONT - DEPTH, FRONT + 1.0, 25.0, RED_BRICK)
	var f := Kit.face(self, Vector3(18.0, 0, FRONT + 1.0), 0.0)
	_windows(f, -2.0, 2.0, 7.0, 24.0, 4.0, 3.1, 1.0, 1.8)
	Kit.box(f, "Red block arch", Vector3(0, 2.8, 0.06), Vector3(3.2, 5.6, 0.08), Color("3a2422"))

func _glass_block() -> void:
	_block("Glass block", 22.0, 40.0, FRONT - DEPTH, FRONT, 20.0, WHITE)
	var f := Kit.face(self, Vector3(31.0, 0, FRONT), 0.0)
	_windows(f, -7.0, 7.0, 1.0, 19.0, 3.5, 3.2, 2.2, 2.4, GREEN_GLASS, Color("e9e7e1"))

# ---------------------------------------------------------------- gebogen vleugel
func _dir(deg: float) -> Vector3:
	var a: float = deg_to_rad(deg)
	return Vector3(sin(a), 0, cos(a))

func _sector(n: String, r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, color: Color, segs: int, solid: bool) -> void:
	var t: Array = []
	for i in range(segs):
		var b0: float = a0 + (a1 - a0) * float(i) / float(segs)
		var b1: float = a0 + (a1 - a0) * float(i + 1) / float(segs)
		var o0: Vector3 = CC + _dir(b0) * r1
		var o1: Vector3 = CC + _dir(b1) * r1
		var i0: Vector3 = CC + _dir(b0) * r0
		var i1: Vector3 = CC + _dir(b1) * r0
		var u0 := Vector3(0, y0, 0)
		var u1 := Vector3(0, y1, 0)
		Kit._quad(t, o0 + u0, o1 + u0, o1 + u1, o0 + u1)
		Kit._quad(t, i1 + u0, i0 + u0, i0 + u1, i1 + u1)
		Kit._quad(t, o0 + u1, o1 + u1, i1 + u1, i0 + u1)
	for b in [a0, a1]:
		var d: Vector3 = _dir(b)
		Kit._quad(t, CC + d * r0 + Vector3(0, y0, 0), CC + d * r1 + Vector3(0, y0, 0), CC + d * r1 + Vector3(0, y1, 0), CC + d * r0 + Vector3(0, y1, 0))
	_mesh(n, t, color, solid)

func _cface(deg: float, r: float) -> Node3D:
	return Kit.face(self, CC + _dir(deg) * r, deg)

func _curved_wing() -> void:
	var a0 := 0.0
	var a1 := 92.0
	_sector("Curved wing", R_IN, R_OUT, a0, a1, 0.0, 22.0, STONE, 30, true)
	_sector("Curved wing edge", R_OUT - 0.6, R_OUT + 0.25, a0, a1, 22.0, 22.6, Color("d6cdbb"), 30, false)
	_sector("Curved plinth", R_OUT - 0.2, R_OUT + 0.15, a0, a1, 0.0, 4.4, PLINTH, 30, false)
	var gate := 52.0
	var a: float = a0 + 4.0
	while a < a1 - 3.0:
		if absf(a - gate) > 7.0:
			var f := _cface(a, R_OUT + 0.18)
			Kit.arch_window(f, 0.0, 0.4, 3.4, 3.8, 0.0, GLASS, Color("3a2f2d"))
		a += 6.5
	a = a0 + 2.0
	while a < a1 - 1.5:
		var f := _cface(a, R_OUT + 0.05)
		for k in range(6):
			var y: float = 5.4 + float(k) * 2.75
			if absf(a - gate) < 6.0 and y < 12.5:
				continue
			Kit.box(f, "Window frame", Vector3(0, y + 0.75, 0.04), Vector3(1.4, 1.7, 0.08), FRAME)
			Kit.box(f, "Window", Vector3(0, y + 0.75, 0.08), Vector3(1.1, 1.4, 0.05), GLASS)
		a += 3.6
	# grote poort met trap naar het binnenplein
	var g := _cface(gate, R_OUT + 0.2)
	Kit.box(g, "Gate frame", Vector3(0, 4.0, 0.0), Vector3(10.4, 8.0, 0.2), Color("cfc6b4"))
	Kit.cyl(g, "Gate frame arch", Vector3(0, 8.0, 0.0), 5.2, 5.2, 0.2, Color("cfc6b4"), 24, "z")
	Kit.box(g, "Gate opening", Vector3(0, 4.0, 0.12), Vector3(9.0, 8.0, 0.1), PINK)
	Kit.cyl(g, "Gate opening arch", Vector3(0, 8.0, 0.12), 4.5, 4.5, 0.1, PINK, 24, "z")
	Kit.box(g, "Gate depth", Vector3(0, 5.0, 0.16), Vector3(5.0, 7.0, 0.06), Color("8e5a52"))
	for k in range(7):
		Kit.box(g, "Gate step", Vector3(0, 0.15 + float(k) * 0.3, 0.6 - float(k) * 0.25), Vector3(8.6, 0.3, 0.5), Color("b9b2a6"))

# ---------------------------------------------------------------- binnenplein
# Gebouwen rond het binnenplein, elk met een eigen gevel (zie de foto's van binnen).
func _courtyard_blocks() -> void:
	_block("Court white", -20.0, 2.0, -62.0, -47.0, 19.0, WHITE)
	var f := Kit.face(self, Vector3(-9.0, 0, -47.0), 0.0)
	for x in [-7.0, -2.5, 2.0, 6.5]:
		Kit.arch_window(f, x, 4.6, 2.6, 3.6, 0.06, GLASS, Color("e4e0d6"))
	_windows(f, -7.0, 6.5, 9.5, 18.0, 4.5, 3.2, 2.2, 2.0)
	_windows(f, -7.0, 6.5, 0.4, 4.0, 4.5, 3.2, 2.6, 3.4)
	_block("Court dark brick", 2.0, 12.0, -60.0, -44.0, 22.0, DARK_BRICK)
	var d := Kit.face(self, Vector3(7.0, 0, -44.0), 0.0)
	_windows(d, -2.5, 2.5, 1.0, 21.0, 5.0, 3.2, 1.6, 2.2)
	_block("Court grey brick", 12.0, 30.0, -58.0, -44.0, 18.0, GREY_BRICK)
	var gb := Kit.face(self, Vector3(21.0, 0, -44.0), 0.0)
	_windows(gb, -7.0, 7.0, 0.8, 17.0, 3.5, 3.2, 1.5, 2.2)
	_block("Court west", -30.0, -20.0, -58.0, -12.0, 20.0, GREY_BRICK)
	var w := Kit.face(self, Vector3(-20.0, 0, -35.0), 90.0)
	_windows(w, -18.0, 18.0, 1.0, 19.0, 4.0, 3.2, 1.4, 2.0)

# ---------------------------------------------------------------- maantoren
func _steel_ring(c: Vector3, r: float, thick: float, segs := 20) -> void:
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		Kit.beam(self, "Steel ring", c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r, thick, STEEL)

func _moon_tower() -> void:
	var t: Vector3 = TOWER
	# roze ronde zuilengalerij met bogen
	var base_h := 10.0
	Kit.cyl(self, "Pink colonnade", t + Vector3(0, base_h * 0.5, 0), 5.4, 5.4, base_h, PINK, 24, "y", true)
	Kit.cyl(self, "Pink cornice", t + Vector3(0, base_h + 0.3, 0), 5.8, 5.8, 0.6, PINK.darkened(0.1), 24)
	for i in range(8):
		var a: float = TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(sin(a), 0, cos(a))
		var f := Kit.face(self, t + d * 5.42, rad_to_deg(a))
		Kit.box(f, "Colonnade opening", Vector3(0, 3.5, 0.02), Vector3(2.4, 7.0, 0.05), Color("2a2f34"))
		Kit.cyl(f, "Colonnade arch", Vector3(0, 7.0, 0.02), 1.2, 1.2, 0.05, Color("2a2f34"), 14, "z")
	# stalen toren: staanders en uitstekende ringen (loopbruggen), in het midden het breedst
	var top_y := 38.0
	var posts := 10
	for i in range(posts):
		var a: float = TAU * float(i) / float(posts)
		var d := Vector3(cos(a), 0, sin(a))
		Kit.beam(self, "Tower post", t + Vector3(0, base_h, 0) + d * 4.4, t + Vector3(0, top_y, 0) + d * 4.0, 0.35, STEEL)
	var levels := [[base_h + 0.6, 5.6], [16.0, 6.4], [21.5, 7.0], [27.0, 6.8], [32.5, 5.8], [top_y, 4.8]]
	for lv in levels:
		var y: float = lv[0]
		var r: float = lv[1]
		_steel_ring(t + Vector3(0, y, 0), r, 0.4)
		_steel_ring(t + Vector3(0, y + 1.1, 0), r, 0.08)
		_steel_ring(t + Vector3(0, y, 0), 4.2, 0.2, 14)
	# gouden Romeinse cijfers rond de bovenste ring (de klok)
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var g := Kit.box(self, "Clock numeral", t + Vector3(0, top_y - 1.0, 0) + d * 4.95, Vector3(0.9, 1.1, 0.08), GOLD)
		g.rotation.y = atan2(d.x, d.z)
	# de halve maan: een koepel met kraters
	var moon_c: Vector3 = t + Vector3(0, top_y + 0.4, 0)
	var moon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 4.4
	sm.height = 4.4
	sm.is_hemisphere = true
	sm.radial_segments = 28
	sm.rings = 10
	moon.mesh = sm
	moon.material_override = Kit.mat(Color("dcdad4"))
	moon.position = moon_c
	moon.add_to_group("keep_far")
	add_child(moon)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1969
	for i in range(12):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.15, 1), rng.randf_range(-1, 1)).normalized()
		var cr := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var rr: float = rng.randf_range(0.5, 1.2)
		cm.top_radius = rr
		cm.bottom_radius = rr
		cm.height = 0.12
		cm.radial_segments = 14
		cr.mesh = cm
		cr.material_override = Kit.mat(Color("a9a7a2") if i % 2 == 0 else Color("bdbbb5"))
		cr.position = moon_c + d * 4.35
		cr.basis = Basis(Quaternion(Vector3.UP, d))
		cr.add_to_group("keep_far")
		add_child(cr)
	# arm en windvaan met bol naast de maan
	Kit.beam(self, "Moon arm", t + Vector3(-3.5, top_y + 0.5, 1.0), t + Vector3(-2.2, top_y + 5.2, 0.6), 0.25, STEEL)
	var mp: Vector3 = t + Vector3(3.6, top_y, 1.8)
	Kit.cyl(self, "Vane mast", mp + Vector3(0, 4.5, 0), 0.08, 0.06, 9.0, STEEL, 6)
	var ball := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.45
	bm.height = 0.9
	ball.mesh = bm
	ball.material_override = Kit.mat(Color("c9c9c4"))
	ball.position = mp + Vector3(0, 9.2, 0)
	add_child(ball)
	Kit.box(self, "Wind vane", mp + Vector3(0.5, 8.4, 0), Vector3(1.0, 0.2, 0.05), STEEL)

func _tree(p: Vector3) -> void:
	Kit.cyl(self, "Square tree trunk", p + Vector3(0, 2.5, 0), 0.25, 0.2, 5.0, Color("5b5148"), 8, "y", true)
	var cr := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 2.6
	cm.height = 4.4
	cm.radial_segments = 10
	cm.rings = 5
	cr.mesh = cm
	cr.material_override = Kit.mat(Color("6a8d45"))
	cr.position = p + Vector3(0, 6.2, 0)
	add_child(cr)
