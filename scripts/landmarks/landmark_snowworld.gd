extends Node3D
# SnowWorld op de Wilhelminaberg, Landgraaf. Naar jouw foto's (20-11):
# - de skihal: een lange hal die tegen de beboste berg op loopt. Wit dak met twee lange
#   stroken zonnepanelen, grijsgroene zijwanden en een witte kop op de top van de berg.
# - onderaan de entree: een rij puntgeveltjes met leien daken naar het parkeerterrein, aan
#   het westelijke eind een houten gebouwtje met SNOWWORLD (gevel naar het terras), de grote
#   glazen ingang met houten schoren, het rode S-logo en een rood-wit gestreepte band (kijkt
#   ook naar het terras, iets terugliggend), terras met tafels en parasols, rechts het hoteltorentje
#   (houten gevel met oranje kozijnen, glazen bovenste verdieping).
# - de lange trap tegen de Wilhelminaberg op, met bovenop het kunstwerk: een kring van
#   hoge, donkere stalen kolommen.
# Lokale ruimte: +Z = ingang en parkeerterrein; de hal loopt omhoog richting -Z.
# Afmetingen geschat en ingekort (de echte hal is ruim 500 m lang).
const Kit = preload("res://scripts/build_kit.gd")

const HALL_W := 56.0
const HALL_L := 280.0
const LOW := 16.0
const HIGH := 116.0         # de hal loopt door tot op de top, naast het kunstwerk
const KNEE_Z := 120.0       # knik in het dak: daarachter loopt de hal steiler met de berg mee
const KNEE_Y := 26.0
const HILL_Z := -320.0      # midden van de berg; de top ligt aan het eind van de hal
const HILL_R := 200.0       # straal aan de voet
const HILL_TOP_R := 48.0
const HILL_H := 110.0
const STAIR_DIR := Vector3(-0.85, 0.0, 0.527)    # trap: vanaf het kunstwerk naar links omlaag
const MONUMENT_R := 38.0    # kunstwerk op de top, links naast de kop van de hal

const WOOD := Color("8a5c38")
const WOOD_DARK := Color("6b5546")
const SLATE := Color("3d4044")
const GLASS := Color("4f6772")
const WHITE := Color("efeee9")

func _ready() -> void:
	name = "SnowWorld"
	_hill()
	_stairs()
	_monument()
	_hall()
	_front()
	_hotel()

# ---------------------------------------------------------------- berg
func _hill_y(r: float) -> float:
	return clampf((HILL_R - r) / (HILL_R - HILL_TOP_R), 0.0, 1.0) * HILL_H

func _hill() -> void:
	var hill := MeshInstance3D.new()
	hill.name = "Wilhelminaberg"
	var cm := CylinderMesh.new()
	cm.bottom_radius = HILL_R
	cm.top_radius = HILL_TOP_R
	cm.height = HILL_H
	cm.radial_segments = 64
	cm.rings = 1
	hill.mesh = cm
	hill.material_override = Kit.mat(Color("4a6a3a"))
	var body := StaticBody3D.new()
	body.name = "Wilhelminaberg body"
	var cs := CollisionShape3D.new()
	cs.shape = cm.create_convex_shape()
	body.add_child(cs)
	body.add_child(hill)
	body.position = Vector3(0, HILL_H * 0.5, HILL_Z)
	add_child(body)
	# bos over de flanken (loofbomen), niet op de hal, de trap en het gras ernaast
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var greens := [Color("37502e"), Color("466238"), Color("2f4528"), Color("53703f"), Color("5d7a40")]
	var tree := SphereMesh.new()
	tree.radius = 1.0
	tree.height = 1.7
	tree.radial_segments = 8
	tree.rings = 4
	var xf: Array = []
	var cols: Array = []
	var top := Vector3(0, 0, HILL_Z)
	for i in range(900):
		var a: float = rng.randf() * TAU
		var r: float = lerpf(HILL_TOP_R + 4.0, HILL_R - 3.0, sqrt(rng.randf()))
		var p := Vector3(sin(a) * r, _hill_y(r), HILL_Z + cos(a) * r)
		if absf(p.x) < HALL_W * 0.5 + 8.0 and p.z > -HALL_L - 12.0:
			continue
		# trap met gemaaid gras ernaast vrijhouden
		var rel: Vector3 = p - top
		var along: float = rel.dot(STAIR_DIR)
		var side: float = absf(rel.dot(Vector3(STAIR_DIR.z, 0, -STAIR_DIR.x)))
		if along > 0.0 and side < 9.0:
			continue
		var s: float = rng.randf_range(5.0, 9.5)
		xf.append(Transform3D(Basis().scaled(Vector3(s, s * 0.85, s)), p + Vector3(0, s * 0.5, 0)))
		cols.append(greens[rng.randi_range(0, greens.size() - 1)])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = tree
	mm.instance_count = xf.size()
	for i in range(xf.size()):
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Hill trees"
	mmi.multimesh = mm
	var tm := StandardMaterial3D.new()
	tm.vertex_color_use_as_albedo = true
	tm.roughness = 1.0
	mmi.material_override = tm
	add_child(mmi)

# Rechte trap van de voet naar de top, met leuningen aan beide kanten.
func _stairs() -> void:
	var bottom := Vector3(0, 0, HILL_Z) + STAIR_DIR * (HILL_R - 2.0)
	bottom.y = _hill_y(HILL_R - 2.0)
	var top := Vector3(0, 0, HILL_Z) + STAIR_DIR * (HILL_TOP_R + 1.0)
	top.y = _hill_y(HILL_TOP_R + 1.0)
	var along: Vector3 = (top - bottom).normalized()
	var length: float = (top - bottom).length()
	var side := Vector3(STAIR_DIR.z, 0, -STAIR_DIR.x)
	var normal: Vector3 = side.cross(along).normalized()
	if normal.y < 0.0:
		normal = -normal
	var pivot := Node3D.new()
	pivot.name = "Wilhelminaberg stairs"
	# lokale assen: x = dwars, y = loodrecht op de helling, -z = omhoog langs de trap
	pivot.transform = Transform3D(Basis(side, normal, -along), (bottom + top) * 0.5 + normal * 0.3)
	add_child(pivot)
	var w := 3.6
	Kit.box(pivot, "Stair body", Vector3.ZERO, Vector3(w, 0.5, length), Color("8a8c8a"))
	# treden: lichte neuzen met schaduwlijn
	var z := -length * 0.5 + 1.0
	while z < length * 0.5 - 0.5:
		Kit.box(pivot, "Step", Vector3(0, 0.27, z), Vector3(w, 0.06, 0.45), Color("a9aba8"))
		Kit.box(pivot, "Step shade", Vector3(0, 0.26, z + 0.6), Vector3(w, 0.05, 0.35), Color("6c6e6d"))
		z += 2.2
	# leuningen
	for sx in [-1.0, 1.0]:
		var x: float = sx * (w * 0.5 + 0.15)
		Kit.box(pivot, "Stair rail", Vector3(x, 1.25, 0), Vector3(0.08, 0.08, length), Color("9aa0a4"))
		Kit.box(pivot, "Stair rail low", Vector3(x, 0.75, 0), Vector3(0.05, 0.05, length), Color("9aa0a4"))
		var pz := -length * 0.5 + 0.5
		while pz < length * 0.5:
			Kit.box(pivot, "Stair post", Vector3(x, 0.75, pz), Vector3(0.08, 1.0, 0.08), Color("9aa0a4"))
			pz += 6.0
	# betonnen opstapje onderaan
	Kit.box(self, "Stair foot", bottom + Vector3(0, 0.1, 0) + STAIR_DIR * 3.0, Vector3(6.0, 0.2, 6.0), Color("8a8c8a"))

# Kunstwerk op de top: een kring van hoge, donkere stalen kolommen met schuin
# afgeknipte, omgezette koppen, op een donkere rand.
func _monument() -> void:
	var c := Vector3(0, HILL_H, HILL_Z) + STAIR_DIR * MONUMENT_R
	var steel := Color("34393f")
	var ring_r := 7.5
	# donkere rand en een pad van de trap naar de kring
	for k in range(36):
		var a: float = TAU * float(k) / 36.0
		var p: Vector3 = c + Vector3(sin(a), 0, cos(a)) * ring_r
		var b := Kit.box(self, "Monument edge", p + Vector3(0, 0.1, 0), Vector3(1.75, 0.2, 0.35), Color("2b2e31"))
		b.rotation.y = a
	Kit.box(self, "Monument path", c + STAIR_DIR * 9.0 + Vector3(0, 0.03, 0), Vector3(2.2, 0.06, 2.2), Color("8f7f68"))
	var heights := [19.0, 11.0, 16.0, 8.0, 21.0, 13.0, 9.0, 18.0, 12.0, 17.0, 10.0]
	for k in range(heights.size()):
		var a: float = TAU * (float(k) + 0.3) / float(heights.size())
		var p: Vector3 = c + Vector3(sin(a), 0, cos(a)) * ring_r
		var h: float = heights[k]
		var col := Node3D.new()
		col.name = "Monument column"
		col.position = p
		col.rotation.y = a
		add_child(col)
		# U-profiel: twee flenzen en een lijf, licht naar buiten hellend
		col.rotation.x = 0.0
		Kit.box(col, "Column web", Vector3(0, h * 0.5, 0), Vector3(0.9, h, 0.15), steel)
		for fx in [-0.33, 0.33]:
			Kit.box(col, "Column flange", Vector3(fx * 1.3, h * 0.5, -0.28), Vector3(0.14, h, 0.55), steel)
		# schuin afgeknipte, omgezette kop
		var head := Kit.box(col, "Column head", Vector3(0, h + 0.5, 0.18), Vector3(0.72, 1.4, 0.14), Color("2a2e33"))
		head.rotation.x = -0.45
		Kit.box(col, "Column foot", Vector3(0, 0.25, 0), Vector3(0.9, 0.5, 0.6), Color("50565c"))

# ---------------------------------------------------------------- hal
func _hall() -> void:
	var roof_c := Color("e9ecec")
	var wall_c := Color("a9b3ad")
	# twee delen: flauw tot de voet van de berg, dan steiler tot op de top
	Kit.wedge(self, "Ski hall low", Vector3(0, 0, -KNEE_Z * 0.5), HALL_W, KNEE_Z, KNEE_Y, LOW, roof_c, wall_c)
	var up_l: float = HALL_L - KNEE_Z
	Kit.wedge(self, "Ski hall high", Vector3(0, 0, -KNEE_Z - up_l * 0.5), HALL_W, up_l, HIGH, KNEE_Y, roof_c, wall_c)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALL_W, LOW, HALL_L)
	cs.shape = shape
	body.add_child(cs)
	body.position = Vector3(0, LOW * 0.5, -HALL_L * 0.5)
	add_child(body)
	var panel := Kit.mat(Color("2a3c63"), 0.0, 0.3, 0.45)
	var panel_light := Kit.mat(Color("3d5486"), 0.0, 0.3, 0.45)
	_roof(0.0, KNEE_Z, LOW, KNEE_Y, panel, panel_light, 16.0)
	_roof(KNEE_Z, HALL_L, KNEE_Y, HIGH, panel, panel_light, 4.0)
	# witte kop bovenaan
	Kit.box(self, "Hall head", Vector3(0, HIGH - 2.0, -HALL_L + 7.0), Vector3(HALL_W + 1.0, 10.0, 14.0), Color("eef0f0"))
	Kit.box(self, "Hall head panels", Vector3(-10.0, HIGH + 3.1, -HALL_L + 7.0), Vector3(14.0, 0.15, 10.0), Color.WHITE, false, panel)
	Kit.box(self, "Hall head panels", Vector3(10.0, HIGH + 3.1, -HALL_L + 7.0), Vector3(14.0, 0.15, 10.0), Color.WHITE, false, panel)
	# zijwanden: lichte horizontale naden in de beplating
	for sx in [-1.0, 1.0]:
		for k in range(1, 4):
			Kit.box(self, "Side seam", Vector3(sx * (HALL_W * 0.5 + 0.05), float(k) * 4.0, -HALL_L * 0.5 + 30.0), Vector3(0.1, 0.2, HALL_L - 60.0), Color("95a09a"))
	# grijze aanbouw rechts naast de hal, met panelen op het platte dak
	Kit.box(self, "Side annex", Vector3(HALL_W * 0.5 + 11.0, 8.0, -22.0), Vector3(22.0, 16.0, 56.0), Color("a3ada9"), true)
	Kit.box(self, "Annex panels", Vector3(HALL_W * 0.5 + 11.0, 16.15, -22.0), Vector3(16.0, 0.2, 46.0), Color.WHITE, false, panel)

# Dakvlak van z0 tot z1 (afstand achter de voorkant, hoogtes y0 en y1): randen, nok en
# twee lange stroken zonnepanelen, met de helling mee.
func _roof(z0: float, z1: float, y0: float, y1: float, panel: Material, panel_light: Material, front_gap: float) -> void:
	var l: float = z1 - z0
	var slope: float = atan((y1 - y0) / l)
	var pivot := Node3D.new()
	pivot.name = "Hall roof"
	pivot.position = Vector3(0, (y0 + y1) * 0.5, -(z0 + z1) * 0.5)
	pivot.rotation.x = slope
	add_child(pivot)
	var slen: float = l / cos(slope)
	for sx in [-1.0, 1.0]:
		Kit.box(pivot, "Roof edge", Vector3(sx * (HALL_W * 0.5 - 0.4), 0.45, 0), Vector3(0.8, 0.9, slen), Color("d8dcdc"))
	Kit.box(pivot, "Roof ridge", Vector3(-1.0, 0.35, 0), Vector3(2.0, 0.7, slen), Color("dde1e1"))
	for strip in [[-14.0, 18.0], [11.0, 14.0]]:
		var z := -slen * 0.5 + 3.0
		var k := 0
		while z < slen * 0.5 - front_gap:
			var seg: float = minf(7.5 if k % 5 != 4 else 3.5, slen * 0.5 - front_gap - z)
			if seg > 1.0:
				Kit.box(pivot, "Solar panels", Vector3(strip[0], 0.2, z + seg * 0.5), Vector3(strip[1], 0.12, seg),
					Color.WHITE, false, panel if k % 3 != 1 else panel_light)
			z += seg + 1.8
			k += 1

# ---------------------------------------------------------------- entree
func _front() -> void:
	# platte middenbouw met donkere houten gevel tussen hal en chalets
	Kit.box(self, "Base building", Vector3(4.0, 6.0, 10.0), Vector3(HALL_W + 8.0, 12.0, 20.0), WOOD_DARK, true)
	Kit.box(self, "Base roof", Vector3(4.0, 12.15, 10.0), Vector3(HALL_W + 8.4, 0.3, 20.4), Color("a2a8aa"))
	for k in range(4):
		Kit.box(self, "Roof unit", Vector3(-2.0 + float(k) * 7.0, 13.2, 6.0), Vector3(4.0, 1.8, 3.0), Color("b9bec0"))
	var bf := Kit.face(self, Vector3(4.0, 0, 20.0), 0)
	for k in range(5):
		Kit.box(bf, "Base window", Vector3(-16.0 + float(k) * 8.0, 8.3, 0.05), Vector3(5.0, 2.2, 0.1), GLASS)
	# Indeling naar jouw foto's en de luchtfoto (25-11): een rij puntgeveltjes naar het
	# parkeerterrein onder één groot leien dak; aan het westelijke eind (-X) het houten
	# gebouwtje met SNOWWORLD, haaks op de puntgevels, met de gevel naar het terras; de grote
	# glazen ingang kijkt ook naar het terras en ligt iets terug, achter het hout.
	Kit.box(self, "Chalet block", Vector3(-20.0, 3.5, 27.0), Vector3(28.0, 7.0, 14.0), WHITE, true)
	Kit.gable(self, "Chalet block roof", Vector3(-20.0, 7.0, 26.0), 18.0, 28.6, 5.5, SLATE, true)
	for k in range(4):
		_chalet(Vector3(-30.5 + float(k) * 7.0, 0, 30.0), 6.6, 7.0, 4.6, "")
	_name_wall(Vector3(-35.5, 0, 28.5), 19.0)
	var ent := Node3D.new()
	ent.name = "Entrance"
	ent.position = Vector3(-27.0, 0, 9.5)
	ent.rotation_degrees.y = -90.0      # glasgevel kijkt naar -X (het terras)
	add_child(ent)
	_entrance(ent, Vector3.ZERO)
	# terras aan de westkant en plein voor de puntgevels, met rode klinkers en paaltjes
	Kit.box(self, "Terrace", Vector3(-50.0, 0.05, 20.0), Vector3(28.0, 0.1, 44.0), Color("9a7766"))
	Kit.box(self, "Plaza", Vector3(-1.0, 0.05, 40.0), Vector3(70.0, 0.1, 8.0), Color("9a7766"))
	# voorplein tussen de puntgevels en het hotel (waar vroeger de ingang stond)
	Kit.box(self, "Forecourt", Vector3(4.0, 0.05, 28.0), Vector3(20.0, 0.1, 16.0), Color("9a7766"))
	for k in range(13):
		Kit.cyl(self, "Bollard", Vector3(-62.0 + float(k) * 5.5, 0.45, 43.5), 0.12, 0.12, 0.9, Color("8e9396"), 8)
	_terrace_furniture()
	# vlaggen
	var flags := [Color("d23c3c"), Color("e8ecee"), Color("d23c3c"), Color("1f2a36")]
	for k in range(4):
		var p := Vector3(12.0 + float(k) * 3.0, 0, 40.0)
		Kit.cyl(self, "Flagpole", p + Vector3(0, 4.5, 0), 0.07, 0.05, 9.0, Color("eeeeee"), 6)
		Kit.box(self, "Flag", p + Vector3(0, 7.7, 0.7), Vector3(0.03, 2.4, 1.3), flags[k])

# Driehoekig vlak (geveltop) in face-ruimte van f.
func _tri(f: Node3D, n: String, y0: float, w: float, rise: float, z: float, color: Color) -> void:
	var t: Array = [Vector3(-w * 0.5, y0, z), Vector3(w * 0.5, y0, z), Vector3(0, y0 + rise, z)]
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(t, Kit._two_sided(color))
	f.add_child(mi)

# Chaletgevel: witte penanten, houten borstwering en top, leien zadeldak met windveren.
func _chalet(c: Vector3, w: float, wall_h: float, rise: float, text: String) -> void:
	var depth := 16.0
	Kit.box(self, "Chalet", c + Vector3(0, wall_h * 0.5, 0), Vector3(w, wall_h, depth), WHITE, true)
	Kit.gable(self, "Chalet roof", c + Vector3(0, wall_h, -0.6), w + 1.6, depth + 1.4, rise, SLATE)
	var f := Kit.face(self, c + Vector3(0, 0, depth * 0.5), 0)
	# houten top en band met de naam
	_tri(f, "Chalet gable wood", wall_h, w + 1.2, rise + 0.35, 0.2, WOOD)
	Kit.box(f, "Chalet band", Vector3(0, wall_h - 1.0, 0.06), Vector3(w - 1.2, 2.0, 0.12), WOOD)
	if text != "":
		Kit.label(f, text, Vector3(0, wall_h - 1.0, 0.14), 0.0125, Color("f4f1ea"), 96)
	# ramen: onder een glazen pui, boven twee vensters
	Kit.box(f, "Chalet glass", Vector3(0, 1.6, 0.05), Vector3(w - 1.6, 3.2, 0.1), GLASS)
	for x in [-1.6, 1.6]:
		Kit.box(f, "Chalet window", Vector3(x, wall_h + 1.3, 0.26), Vector3(1.5, 1.6, 0.08), GLASS)
	# windveren en makelaar
	var edge := Color("7a3b22")
	Kit.beam(f, "Barge board", Vector3(-w * 0.5 - 0.8, wall_h - 0.1, 0.3), Vector3(0, wall_h + rise + 0.25, 0.3), 0.35, edge)
	Kit.beam(f, "Barge board", Vector3(w * 0.5 + 0.8, wall_h - 0.1, 0.3), Vector3(0, wall_h + rise + 0.25, 0.3), 0.35, edge)
	Kit.box(f, "Tie beam", Vector3(0, wall_h + 0.05, 0.22), Vector3(w + 0.4, 0.3, 0.3), Color("9a6b42"))

# Houten gebouwtje aan het westelijke eind van de puntgevels, met de gevel naar het terras
# (-X): lichte houten delen, SNOWWORLD in witte letters, glazen pui met deuren onderaan.
# c = midden van de gevel op de grond, w = breedte van de gevel (langs Z).
func _name_wall(c: Vector3, w: float) -> void:
	var h := 10.0
	var depth := 5.0
	var light_wood := Color("c08a55")
	Kit.box(self, "Name wall", c + Vector3(depth * 0.5, h * 0.5, 0), Vector3(depth, h, w), light_wood, true)
	# leien dak met de goot langs de terrasgevel (nok evenwijdig aan de gevel)
	Kit.gable(self, "Name wall roof", c + Vector3(depth * 0.5 + 3.0, h, 0), depth + 6.8, w + 0.8, 4.5, SLATE)
	var f := Kit.face(self, c, -90.0)     # gevel naar -X
	var y := 0.4
	while y < h - 0.2:
		Kit.box(f, "Cladding seam", Vector3(0, y, 0.02), Vector3(w, 0.04, 0.04), Color("a87a4a"))
		y += 0.55
	Kit.box(f, "Name wall glass", Vector3(-w * 0.5 + 4.0, 1.5, 0.06), Vector3(5.0, 3.0, 0.1), GLASS)
	Kit.box(f, "Name wall pier", Vector3(-w * 0.5 + 0.4, h * 0.5, 0.15), Vector3(0.8, h, 0.3), WHITE)
	Kit.label(f, "SNOWWORLD", Vector3(1.0, 6.2, 0.08), 0.013, Color("f6f6f2"), 96)

# Terrasmeubels: picknicktafels, statafels van tonnen en grijze parasols.
func _terrace_furniture() -> void:
	var wood := Color("8a6a48")
	for t in [Vector3(-46, 0, 30), Vector3(-52, 0, 24), Vector3(-46, 0, 18), Vector3(-54, 0, 12), Vector3(-47, 0, 6)]:
		Kit.box(self, "Picnic table", t + Vector3(0, 0.75, 0), Vector3(1.0, 0.06, 2.2), wood)
		for sx in [-0.75, 0.75]:
			Kit.box(self, "Picnic bench", t + Vector3(sx, 0.45, 0), Vector3(0.35, 0.05, 2.2), wood)
		for sz in [-0.9, 0.9]:
			Kit.box(self, "Picnic leg", t + Vector3(0, 0.37, sz), Vector3(1.8, 0.74, 0.08), wood)
	for t in [Vector3(-41, 0, 36), Vector3(-43, 0, 38.5), Vector3(-39.5, 0, 39)]:
		Kit.cyl(self, "Barrel", t + Vector3(0, 0.5, 0), 0.38, 0.38, 1.0, Color("7a5434"), 10)
		Kit.cyl(self, "Barrel top", t + Vector3(0, 1.03, 0), 0.55, 0.55, 0.06, Color("2e2b28"), 12)
	for u in [Vector3(-49, 0, 27), Vector3(-50, 0, 15), Vector3(-44, 0, 36)]:
		Kit.cyl(self, "Parasol pole", u + Vector3(0, 1.4, 0), 0.05, 0.05, 2.8, Color("5a5550"), 6)
		Kit.cyl(self, "Parasol", u + Vector3(0, 2.75, 0), 2.0, 0.1, 0.55, Color("8e9091"), 4)

# Grote ingang: hoge glazen gevel onder een steil leien dak, houten schoren, rood S-logo,
# en een rood-witte band onderaan. De naam staat op de houten gevel ernaast (_name_wall).
func _entrance(p: Node3D, c: Vector3) -> void:
	var w := 17.0
	var wall_h := 9.0
	var rise := 11.0
	var depth := 18.0
	Kit.box(p, "Entrance hall", c + Vector3(0, wall_h * 0.5, -1.0), Vector3(w, wall_h, depth), WHITE, true)
	Kit.gable(p, "Entrance roof", c + Vector3(0, wall_h, -1.0), w + 2.0, depth + 0.2, rise, SLATE)
	var f := Kit.face(p, c + Vector3(0, 0, depth * 0.5 - 1.0), 0)
	# glazen pui en glazen top, met stijlen
	var glass := Kit.glass_mat(Color("5d7c8a"))
	Kit.box(f, "Entrance glass", Vector3(0, wall_h * 0.5, 0.05), Vector3(w - 1.0, wall_h, 0.1), Color.WHITE, false, glass)
	var t: Array = [Vector3(-w * 0.5 - 0.5, wall_h, 0.18), Vector3(w * 0.5 + 0.5, wall_h, 0.18), Vector3(0, wall_h + rise + 0.2, 0.18)]
	var top := MeshInstance3D.new()
	top.name = "Entrance glass top"
	top.mesh = Kit._mesh_from(t, Kit.glass_two_sided(Color("5d7c8a")))
	f.add_child(top)
	for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		var hgt: float = wall_h + rise * (1.0 - absf(x) / (w * 0.5)) - 0.8
		Kit.box(f, "Mullion", Vector3(x, hgt * 0.5, 0.26), Vector3(0.12, hgt, 0.1), Color("2e3338"))
	for y in [3.2, 6.4, 9.6, 12.8]:
		var hw: float = minf(w * 0.5 - 0.5, (w * 0.5) * (1.0 - (y - wall_h) / rise)) if y > wall_h else w * 0.5 - 0.5
		Kit.box(f, "Transom", Vector3(0, y, 0.26), Vector3(hw * 2.0, 0.1, 0.1), Color("2e3338"))
	# houten windveren en schoren (grote V in de gevel)
	var wood := Color("9a6b42")
	Kit.beam(f, "Barge board", Vector3(-w * 0.5 - 1.0, wall_h - 0.2, 0.5), Vector3(0, wall_h + rise + 0.3, 0.5), 0.5, Color("7a3b22"))
	Kit.beam(f, "Barge board", Vector3(w * 0.5 + 1.0, wall_h - 0.2, 0.5), Vector3(0, wall_h + rise + 0.3, 0.5), 0.5, Color("7a3b22"))
	Kit.beam(f, "Brace", Vector3(-w * 0.5 + 0.4, 0.5, 0.6), Vector3(0, wall_h + 2.5, 0.6), 0.45, wood)
	Kit.beam(f, "Brace", Vector3(w * 0.5 - 0.4, 0.5, 0.6), Vector3(0, wall_h + 2.5, 0.6), 0.45, wood)
	Kit.box(f, "Tie beam", Vector3(0, wall_h, 0.6), Vector3(w + 1.0, 0.45, 0.45), wood)
	Kit.beam(f, "Brace", Vector3(-3.5, wall_h, 0.62), Vector3(0, wall_h + rise - 1.5, 0.62), 0.35, wood)
	Kit.beam(f, "Brace", Vector3(3.5, wall_h, 0.62), Vector3(0, wall_h + rise - 1.5, 0.62), 0.35, wood)
	# rood S-logo achter het glas
	Kit.label(f, "S", Vector3(1.6, wall_h + 3.0, 0.32), 0.04, Color("e2433b"), 128)
	# rood-witte band onderaan
	Kit.box(f, "Stripe band", Vector3(0, 2.6, 0.18), Vector3(w - 1.4, 0.9, 0.04), Color("f2f2f0"))
	var x := -w * 0.5 + 1.4
	while x < w * 0.5 - 1.2:
		var s := Kit.box(f, "Stripe", Vector3(x, 2.6, 0.21), Vector3(0.45, 1.2, 0.03), Color("d63a32"))
		s.rotation.z = 0.7
		x += 1.1
	Kit.box(f, "Stripe band mask", Vector3(0, 3.3, 0.22), Vector3(w - 1.2, 0.5, 0.05), Color("3a4a52"))
	Kit.box(f, "Stripe band mask", Vector3(0, 1.9, 0.22), Vector3(w - 1.2, 0.5, 0.05), Color("3a4a52"))
	# deuren
	Kit.box(f, "Doors", Vector3(-2.0, 1.15, 0.2), Vector3(4.0, 2.3, 0.06), Color("2a3236"))

# ---------------------------------------------------------------- hotel
func _hotel() -> void:
	var c := Vector3(24.0, 0, 22.0)
	var size := Vector3(18.0, 0, 14.0)
	var floors := 8
	var fh := 3.2
	var h: float = float(floors) * fh
	Kit.box(self, "Hotel", c + Vector3(0, h * 0.5, 0), Vector3(size.x, h, size.z), Color("6f655c"), true)
	# houten gevelbeplating: donkere en lichte banen
	for k in range(6):
		Kit.box(self, "Hotel cladding", c + Vector3(-size.x * 0.5 + 1.5 + float(k) * 3.0, h * 0.5, size.z * 0.5 + 0.03), Vector3(1.2, h, 0.04), Color("5f564e"))
	var orange := Color("e07a2c")
	var glass := Color("33424a")
	# voorgevel (+Z) en zijgevel (-X): ramen met oranje kozijnen
	var front := Kit.face(self, c + Vector3(0, 0, size.z * 0.5), 0)
	var side := Kit.face(self, c + Vector3(-size.x * 0.5, 0, 0), -90)
	for fl in range(1, floors):
		var y: float = float(fl) * fh + 0.9
		for k in range(5):
			var x: float = -6.4 + float(k) * 3.2
			Kit.box(front, "Hotel frame", Vector3(x, y + 0.75, 0.06), Vector3(1.5, 1.9, 0.08), orange)
			Kit.box(front, "Hotel window", Vector3(x, y + 0.75, 0.11), Vector3(1.1, 1.5, 0.05), glass)
		for k in range(4):
			var x: float = -4.8 + float(k) * 3.2
			Kit.box(side, "Hotel frame", Vector3(x, y + 0.75, 0.06), Vector3(1.5, 1.9, 0.08), orange)
			Kit.box(side, "Hotel window", Vector3(x, y + 0.75, 0.11), Vector3(1.1, 1.5, 0.05), glass)
	# begane grond: glazen pui met terras
	Kit.box(front, "Hotel lobby", Vector3(0, 1.4, 0.06), Vector3(size.x - 2.0, 2.6, 0.08), GLASS)
	Kit.box(self, "Hotel terrace", c + Vector3(0, 0.25, size.z * 0.5 + 3.0), Vector3(size.x + 2.0, 0.5, 6.0), Color("c9c2b4"), true)
	# glazen bovenste verdieping met balkons en een schuin overstekend dak met oranje rand
	Kit.box(self, "Hotel top", c + Vector3(0, h + 1.5, -0.5), Vector3(size.x - 1.0, 3.0, size.z - 1.0), Color.WHITE, false, Kit.glass_mat(Color("8fb4c2")))
	for k in range(6):
		Kit.box(self, "Balcony divider", c + Vector3(-7.5 + float(k) * 3.0, h + 0.6, size.z * 0.5 - 0.4), Vector3(0.1, 1.2, 1.4), Color("e8e8e4"))
	Kit.box(self, "Balcony rail", c + Vector3(0, h + 0.55, size.z * 0.5 + 0.25), Vector3(size.x, 1.1, 0.06), Color.WHITE, false, Kit.glass_mat(Color("a9c6d0")))
	var roof := Kit.box(self, "Hotel roof", c + Vector3(0, h + 3.4, 0.4), Vector3(size.x + 1.6, 0.5, size.z + 2.4), Color("e9e7e2"))
	roof.rotation.x = -0.06
	Kit.box(self, "Hotel roof edge", c + Vector3(0, h + 3.45, size.z * 0.5 + 1.65), Vector3(size.x + 1.7, 0.7, 0.2), Color("c4552a"))
