extends RefCounted
# Straatbebouwing: een vaste set Parkstad-huistypes. Elk type wordt één keer opgebouwd uit
# blokjes en samengevoegd tot één mesh (een paar oppervlakken: muur, dak, glas, kozijnen,
# groen, bestrating, schoorsteen). Langs de weg staan daar honderden kopieën van via
# MultiMesh, elk met een eigen gevelkleur (instance color) en dakkleur (custom data). Zo
# laadt een level snel en tekent de grafische chip per vak maar een handvol keer.
#
# Lokale ruimte van een type: X langs de straat (midden = 0), +Z naar de weg, Y omhoog.
# De voorgevel staat op z = 0; tuin of stoep ervoor loopt tot z = +front; het huis zelf
# ligt achter z = 0 (negatieve z).

const Kit = preload("res://scripts/build_kit.gd")

const GLASS := Color("2b343a")
const TRIM := Color("efeee8")
const HEDGE := Color("3f6b35")
const LAWN := Color("6d9a4c")
const PAVE := Color("a7a397")
const CHIM := Color("6e4a3c")
const STONE := Color("5b5a57")

# Gevelkleuren per soort
const BRICK := [Color("a8573c"), Color("b4654a"), Color("9a4e37"), Color("8e5a45"), Color("b97b5c")]
const PLASTER := [Color("f1ede3"), Color("e9e2d2"), Color("f4f1ea"), Color("e6dcc6")]
const MIXED := [Color("a8573c"), Color("b4654a"), Color("ede8dc"), Color("d8c6a8"), Color("8e5a45"), Color("c9b9a0")]
const SHOPWALL := [Color("e8dfcc"), Color("b4654a"), Color("cfc7b8"), Color("9a4e37"), Color("e2d3b5")]
const FLATWALL := [Color("b06a4a"), Color("c8b9a0"), Color("9a5a44"), Color("d6cdbd")]
const ROOFS := [Color("3a3b3f"), Color("4a3a33"), Color("5d3f33"), Color("2f3033"), Color("6a4536")]
const AWNINGS := [Color("b3302a"), Color("2d6a4a"), Color("27508a"), Color("7a2a3a"), Color("c78a1c")]

static var _protos := {}
static var _mats := {}

# Gegevens per type: breedte langs de straat, diepte van het huis, voortuin/stoep ervoor,
# hoogte voor de botsvorm, en welke kleuren.
static func info(kind: String) -> Dictionary:
	match kind:
		"row":
			return {"w": 21.6, "d": 9.0, "front": 3.4, "h": 9.6, "walls": BRICK, "roofs": ROOFS}
		"semi":
			return {"w": 14.6, "d": 9.5, "front": 3.4, "h": 9.6, "walls": MIXED, "roofs": ROOFS}
		"detached":
			return {"w": 13.0, "d": 10.0, "front": 3.6, "h": 10.0, "walls": MIXED, "roofs": ROOFS}
		"mine":
			return {"w": 20.0, "d": 8.0, "front": 3.4, "h": 8.6, "walls": BRICK, "roofs": ROOFS}
		"farm":
			return {"w": 20.0, "d": 12.0, "front": 0.6, "h": 11.0, "walls": PLASTER, "roofs": ROOFS}
		"flat":
			return {"w": 24.0, "d": 12.0, "front": 4.4, "h": 12.4, "walls": FLATWALL, "roofs": ROOFS}
		"shop":
			return {"w": 22.5, "d": 12.0, "front": 0.6, "h": 10.2, "walls": SHOPWALL, "roofs": AWNINGS}
	return info("row")

static func mesh(kind: String) -> ArrayMesh:
	if not _protos.has(kind):
		var root := Node3D.new()
		match kind:
			"row": _row(root)
			"semi": _semi(root)
			"detached": _detached(root)
			"mine": _mine(root)
			"farm": _farm(root)
			"flat": _flat(root)
			"shop": _shop(root)
		_protos[kind] = _bake(root)
		root.free()
	return _protos[kind]

# ---------------------------------------------------------------- materiaal

# Kleuren van de vaste onderdelen; muur en dak krijgen hun kleur per huis.
const SLOT_COLORS := {"glass": GLASS, "trim": TRIM, "hedge": HEDGE, "lawn": LAWN, "pave": PAVE, "chim": CHIM, "stone": STONE}

# Eén materiaal voor alle huizen (zo is elk type één tekenopdracht per vak). De vaste kleuren
# zitten in de vertexkleur; alpha zegt wat het is: 0,25 = muur (kleur uit INSTANCE_CUSTOM.rgb),
# 0,75 = dak (kleur nummer INSTANCE_CUSTOM.a uit de dakkleuren), 1 = vaste kleur.
static func material() -> Material:
	if _mats.has("all"):
		return _mats["all"]
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec3 roofs[10];
varying vec3 col;
void vertex() {
	// kleuren zoals bij albedo_color in deze renderer: rechtstreeks de sRGB-waarden
	if (COLOR.a < 0.5) {
		col = INSTANCE_CUSTOM.rgb;
	} else if (COLOR.a < 0.9) {
		col = roofs[clamp(int(INSTANCE_CUSTOM.a + 0.5), 0, 9)];
	} else {
		col = COLOR.rgb;
	}
}
void fragment() {
	ALBEDO = col;
	ROUGHNESS = 0.95;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var pal := PackedVector3Array()
	for c in roof_palette():
		pal.append(Vector3(c.r, c.g, c.b))
	m.set_shader_parameter("roofs", pal)
	_mats["all"] = m
	return m

static func roof_palette() -> Array:
	return ROOFS + AWNINGS

# ---------------------------------------------------------------- bouwstenen

static func _b(root: Node3D, slot: String, pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.set_meta("slot", slot)
	root.add_child(mi)

static func _tri(root: Node3D, slot: String, tris: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in tris:
		st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.set_meta("slot", slot)
	root.add_child(mi)

# Zadeldak: twee dakvlakken (zonder dichte kopse kanten). across = breedte dwars op de nok
# (incl. overstek), along = lengte langs de nok, base = midden van de onderkant.
static func _roof(root: Node3D, slot: String, base: Vector3, across: float, along: float, rise: float, ridge_along_x: bool) -> void:
	var hw: float = across * 0.5
	var hl: float = along * 0.5
	var m := func(a: float, y: float, c: float) -> Vector3:
		return base + (Vector3(a, y, c) if ridge_along_x else Vector3(c, y, a))
	var t: Array = []
	for sgn in [-1.0, 1.0]:
		var e0: Vector3 = m.call(-hl, 0.0, sgn * hw)
		var e1: Vector3 = m.call(hl, 0.0, sgn * hw)
		var r0: Vector3 = m.call(-hl, rise, 0.0)
		var r1: Vector3 = m.call(hl, rise, 0.0)
		t.append_array([e0, e1, r1, e0, r1, r0])
	_tri(root, slot, t)

# Topgevels in muurkleur onder het dak, aan beide uiteinden van de nok: tot precies tegen
# de dakvlakken (across = muurbreedte, roof_across = dakbreedte incl. overstek).
static func _gable_walls(root: Node3D, base: Vector3, across: float, roof_across: float, along: float, rise: float, ridge_along_x: bool) -> void:
	var hw: float = across * 0.5
	var e: float = rise * (1.0 - across / roof_across)
	var t: Array = []
	for a in [-along * 0.5, along * 0.5]:
		var p := func(c: float, y: float) -> Vector3:
			return base + (Vector3(a, y, c) if ridge_along_x else Vector3(c, y, a))
		t.append_array([p.call(-hw, 0.0), p.call(hw, 0.0), p.call(hw, e)])
		t.append_array([p.call(-hw, 0.0), p.call(hw, e), p.call(-hw, e)])
		t.append_array([p.call(-hw, e), p.call(hw, e), p.call(0.0, rise - 0.03)])
	_tri(root, "wall", t)

# Zadeldak met de nok langs de straat over een huis van breedte w en diepte d (voorgevel
# op z = 0), met de topgevels op de zijkanten.
static func _street_roof(root: Node3D, w: float, d: float, h: float, rise: float) -> void:
	var base := Vector3(0, h, -d * 0.5)
	_roof(root, "roof", base, d + 0.8, w + 0.4, rise, true)
	_gable_walls(root, base, d, d + 0.8, w, rise, true)

static func _window(root: Node3D, x: float, y: float, w: float, h: float) -> void:
	_b(root, "trim", Vector3(x, y, 0.03), Vector3(w + 0.2, h + 0.2, 0.06))
	_b(root, "glass", Vector3(x, y, 0.06), Vector3(w, h, 0.06))

static func _garden(root: Node3D, w: float, depth: float, gaps: Array = [], cx := 0.0) -> void:
	_b(root, "lawn", Vector3(cx, 0.04, depth * 0.5), Vector3(w, 0.08, depth))
	# heg langs de stoep, met openingen voor de tuinpaden
	var xs: Array = [cx - w * 0.5]
	for g in gaps:
		xs.append(float(g) - 0.6)
		xs.append(float(g) + 0.6)
	xs.append(cx + w * 0.5)
	for i in range(0, xs.size(), 2):
		var a: float = xs[i]
		var b: float = xs[i + 1]
		if b - a > 0.3:
			_b(root, "hedge", Vector3((a + b) * 0.5, 0.45, depth - 0.35), Vector3(b - a, 0.9, 0.6))
	for g in gaps:
		_b(root, "pave", Vector3(float(g), 0.06, depth * 0.5), Vector3(1.2, 0.1, depth))

# ---------------------------------------------------------------- types

# Rijtje van vier: baksteen, twee lagen, witte rolluikkasten, doorlopend dak, schoorstenen.
static func _row(root: Node3D) -> void:
	var w := 21.6
	var d := 9.0
	var h := 5.8
	_b(root, "wall", Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	_street_roof(root, w, d, h, 3.8)
	_b(root, "trim", Vector3(0, 0.3, 0.02), Vector3(w, 0.6, 0.06))
	var uw: float = w / 4.0
	var gaps: Array = []
	for u in range(4):
		var ux: float = -w * 0.5 + uw * (float(u) + 0.5)
		var dx: float = ux - uw * 0.3 if u % 2 == 0 else ux + uw * 0.3
		var wx: float = ux + uw * 0.12 if u % 2 == 0 else ux - uw * 0.12
		_b(root, "chim", Vector3(dx, h + 3.9, -d * 0.5), Vector3(0.5, 1.8, 0.5))
		_b(root, "glass", Vector3(dx, 1.1, 0.05), Vector3(1.0, 2.2, 0.08))
		_window(root, wx, 1.6, 2.2, 1.4)
		_b(root, "trim", Vector3(wx, 2.45, 0.1), Vector3(2.4, 0.3, 0.16))
		for k in [-1.0, 1.0]:
			_window(root, ux + k * uw * 0.22, 4.3, 1.1, 1.2)
		# dakkapel op elk tweede huis
		if u % 2 == 1:
			_b(root, "wall", Vector3(ux, h + 1.0, -1.6), Vector3(2.2, 1.6, 1.8))
			_b(root, "roof", Vector3(ux, h + 1.85, -1.5), Vector3(2.5, 0.12, 2.1))
			_window(root, ux, h + 1.0, 1.6, 0.9)
		gaps.append(dx)
	_garden(root, w, 3.4, gaps)

# Twee-onder-een-kap (jaren dertig): erker beneden, topgeveltje boven de voordeur.
static func _semi(root: Node3D) -> void:
	var hw := 6.8
	var d := 9.5
	var h := 5.6
	var w: float = hw * 2.0
	_b(root, "wall", Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	_roof(root, "roof", Vector3(0, h, -d * 0.5), d + 0.8, w + 0.6, 4.4, true)
	_gable_walls(root, Vector3(0, h, -d * 0.5), d, d + 0.8, w, 4.4, true)
	_b(root, "chim", Vector3(0, h + 4.5, -d * 0.5), Vector3(0.7, 1.6, 0.7))
	var gaps: Array = []
	for side in [-1.0, 1.0]:
		var c: float = side * hw * 0.5
		# erker met plat dakje
		var ex: float = c + side * 1.2
		_b(root, "wall", Vector3(ex, 1.4, 0.45), Vector3(3.0, 2.8, 0.9))
		_b(root, "trim", Vector3(ex, 2.9, 0.5), Vector3(3.3, 0.2, 1.1))
		_b(root, "glass", Vector3(ex, 1.5, 0.92), Vector3(2.4, 1.5, 0.06))
		_b(root, "trim", Vector3(ex, 1.5, 0.9), Vector3(2.6, 1.7, 0.04))
		# voordeur aan de binnenkant, met een topgeveltje erboven
		var dx: float = c - side * 1.9
		_b(root, "glass", Vector3(dx, 1.1, 0.05), Vector3(1.0, 2.2, 0.08))
		_b(root, "trim", Vector3(dx, 2.35, 0.08), Vector3(1.4, 0.15, 0.3))
		# topgeveltje boven de voordeur: een stukje dak met de punt naar de straat
		_roof(root, "roof", Vector3(c - side * 1.0, h - 0.6, -0.4), 3.4, 2.6, 2.4, false)
		_gable_walls(root, Vector3(c - side * 1.0, h - 0.6, -0.4), 2.8, 3.4, 1.2, 2.4, false)
		_window(root, c - side * 1.0, h + 0.5, 0.9, 0.9)
		_window(root, c + side * 1.3, 4.2, 1.6, 1.2)
		gaps.append(dx)
	_garden(root, w, 3.4, gaps)

# Vrijstaand huis met de topgevel naar de straat, een garage opzij.
static func _detached(root: Node3D) -> void:
	var w := 8.6
	var d := 10.0
	var h := 5.4
	var x0 := -1.8
	_b(root, "wall", Vector3(x0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	_roof(root, "roof", Vector3(x0, h, -d * 0.5), w + 0.8, d + 0.4, 4.6, false)
	_gable_walls(root, Vector3(x0, h, -d * 0.5), w, w + 0.8, d, 4.6, false)
	_b(root, "chim", Vector3(x0 + 2.2, h + 3.4, -d * 0.7), Vector3(0.6, 2.0, 0.6))
	_window(root, x0 - 1.8, 1.6, 2.6, 1.5)
	_b(root, "glass", Vector3(x0 + 2.4, 1.1, 0.05), Vector3(1.0, 2.2, 0.08))
	_b(root, "trim", Vector3(x0 + 2.4, 2.35, 0.08), Vector3(1.5, 0.15, 0.5))
	_window(root, x0 - 1.6, 4.2, 1.4, 1.2)
	_window(root, x0 + 1.6, 4.2, 1.4, 1.2)
	_window(root, x0, h + 1.6, 1.0, 1.0)
	# garage met plat dak en een kanteldeur
	var gx: float = x0 + w * 0.5 + 1.9
	_b(root, "wall", Vector3(gx, 1.5, -d * 0.5 - 0.5), Vector3(3.6, 3.0, d - 1.0))
	_b(root, "trim", Vector3(gx, 3.05, -d * 0.5 - 0.5), Vector3(3.9, 0.2, d - 0.7))
	_b(root, "trim", Vector3(gx, 1.2, -0.95), Vector3(2.6, 2.3, 0.06))
	_b(root, "pave", Vector3(gx, 0.06, 1.8), Vector3(3.2, 0.1, 3.6))
	_garden(root, 9.8, 3.6, [x0 + 2.4 + 1.6], -1.6)
	# boom in de voortuin
	_b(root, "chim", Vector3(x0 - 2.6, 1.4, 1.6), Vector3(0.3, 2.8, 0.3))
	var crown := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.0
	sm.radial_segments = 8
	sm.rings = 4
	crown.mesh = sm
	crown.position = Vector3(x0 - 2.6, 3.9, 1.6)
	crown.set_meta("slot", "hedge")
	root.add_child(crown)

# Mijnwerkerswoningen (koloniehuizen): laag, met een steil dak en een dakkapel per woning.
static func _mine(root: Node3D) -> void:
	var w := 20.0
	var d := 8.0
	var h := 3.4
	_b(root, "wall", Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	_street_roof(root, w, d, h, 4.8)
	_b(root, "stone", Vector3(0, 0.25, 0.02), Vector3(w, 0.5, 0.06))
	var uw: float = w / 4.0
	var gaps: Array = []
	for u in range(4):
		var ux: float = -w * 0.5 + uw * (float(u) + 0.5)
		var dx: float = ux - uw * 0.28 if u % 2 == 0 else ux + uw * 0.28
		var wx: float = ux + uw * 0.15 if u % 2 == 0 else ux - uw * 0.15
		_b(root, "glass", Vector3(dx, 1.05, 0.05), Vector3(0.95, 2.1, 0.08))
		_b(root, "trim", Vector3(dx, 2.25, 0.06), Vector3(1.2, 0.18, 0.1))
		_window(root, wx, 1.6, 1.4, 1.4)
		# dakkapel met lessenaarsdak
		_b(root, "wall", Vector3(wx, h + 1.1, -1.4), Vector3(1.9, 1.8, 1.6))
		_b(root, "roof", Vector3(wx, h + 2.05, -1.3), Vector3(2.2, 0.12, 1.9))
		_window(root, wx, h + 1.1, 1.3, 0.9)
		_b(root, "chim", Vector3(dx, h + 4.9, -d * 0.5), Vector3(0.5, 1.6, 0.5))
		gaps.append(dx)
	_garden(root, w, 3.4, gaps)

# Limburgse hoeve: witte gevel op een donkere plint, een grote poort in het midden,
# kleine vensters met luiken en vakwerk in de topgevels; staat direct aan de stoep.
static func _farm(root: Node3D) -> void:
	var w := 20.0
	var d := 12.0
	var h := 5.4
	_b(root, "wall", Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	_street_roof(root, w, d, h, 5.0)
	_b(root, "stone", Vector3(0, 0.4, 0.02), Vector3(w, 0.8, 0.06))
	# poort: rondboog benaderd met een donkere opening en een stenen omlijsting
	_b(root, "stone", Vector3(0, 2.0, 0.03), Vector3(4.6, 4.0, 0.06))
	_b(root, "glass", Vector3(0, 1.75, 0.06), Vector3(3.8, 3.5, 0.06))
	_b(root, "chim", Vector3(0, 1.75, 0.08), Vector3(3.6, 3.3, 0.04))
	for x in [-7.5, -4.5, 4.5, 7.5]:
		_window(root, x, 1.8, 1.1, 1.3)
		for k in [-1.0, 1.0]:
			_b(root, "roof", Vector3(x + k * 0.9, 1.8, 0.07), Vector3(0.5, 1.4, 0.05))
		_window(root, x, 4.3, 0.9, 0.9)
	# vakwerk op de kopgevels
	for side in [-1.0, 1.0]:
		var gx: float = side * (w * 0.5 + 0.03)
		for z in [-2.0, -6.0, -10.0]:
			_b(root, "chim", Vector3(gx, h * 0.5 + 0.5, z), Vector3(0.06, h - 1.0, 0.22))
		_b(root, "chim", Vector3(gx, h - 0.4, -d * 0.5), Vector3(0.06, 0.22, d))
	_b(root, "pave", Vector3(0, 0.05, 0.3), Vector3(w, 0.1, 0.6))

# Flat van vier lagen met galerij-balkons, plat dak met een witte dakrand.
static func _flat(root: Node3D) -> void:
	var w := 24.0
	var d := 12.0
	var h := 11.6
	_b(root, "wall", Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d))
	_b(root, "trim", Vector3(0, h + 0.25, -d * 0.5), Vector3(w + 0.3, 0.5, d + 0.3))
	_b(root, "stone", Vector3(0, h + 0.02, -d * 0.5), Vector3(w - 0.4, 0.06, d - 0.4))
	for fl in range(4):
		var y: float = 0.9 + float(fl) * 2.9
		for k in range(4):
			var x: float = -9.0 + float(k) * 6.0
			_window(root, x + 1.5, y + 0.8, 1.8, 1.4)
			_b(root, "glass", Vector3(x - 1.0, y + 1.0, 0.05), Vector3(1.0, 2.1, 0.08))
			if fl > 0:
				_b(root, "trim", Vector3(x - 0.6, y - 0.05, 0.8), Vector3(3.0, 0.18, 1.6))
				_b(root, "trim", Vector3(x - 0.6, y + 0.5, 1.58), Vector3(3.0, 0.9, 0.05))
				# zijwanden van het balkon
				for sx in [-1.0, 1.0]:
					_b(root, "trim", Vector3(x - 0.6 + sx * 1.475, y + 0.5, 0.8), Vector3(0.05, 0.9, 1.6))
	_b(root, "lawn", Vector3(0, 0.04, 2.2), Vector3(w, 0.08, 4.4))
	_b(root, "pave", Vector3(-9.0, 0.06, 2.2), Vector3(2.0, 0.1, 4.4))

# Winkelpanden: drie panden met etalages, een gekleurde luifel (dakkleur) en
# twee woonlagen erboven; plat dak met een dakrand.
static func _shop(root: Node3D) -> void:
	var w := 22.5
	var d := 12.0
	var uw: float = w / 3.0
	for u in range(3):
		var ux: float = -w * 0.5 + uw * (float(u) + 0.5)
		var h: float = [9.4, 8.6, 10.0][u]
		_b(root, "wall", Vector3(ux, h * 0.5, -d * 0.5), Vector3(uw - 0.05, h, d))
		_b(root, "trim", Vector3(ux, h + 0.2, -d * 0.5), Vector3(uw, 0.4, d + 0.2))
		# etalage, deur, naambord en luifel
		_b(root, "glass", Vector3(ux - 0.7, 1.7, 0.05), Vector3(uw - 2.8, 2.6, 0.08))
		_b(root, "trim", Vector3(ux - 0.7, 1.7, 0.02), Vector3(uw - 2.6, 2.8, 0.04))
		_b(root, "glass", Vector3(ux + uw * 0.5 - 1.1, 1.2, 0.05), Vector3(1.1, 2.4, 0.08))
		_b(root, "trim", Vector3(ux, 3.5, 0.08), Vector3(uw - 0.6, 0.6, 0.1))
		var aw := Kit.box(root, "Awning", Vector3(ux, 3.0, 0.75), Vector3(uw - 0.8, 0.12, 1.5), Color.WHITE)
		aw.rotation_degrees.x = -12.0
		aw.set_meta("slot", "roof")
		for fl in range(2):
			var y: float = 4.9 + float(fl) * 2.6
			for k in [-1.0, 0.0, 1.0]:
				_window(root, ux + k * uw * 0.3, y + 0.5, 1.2, 1.4)
	_b(root, "pave", Vector3(0, 0.05, 0.3), Vector3(w, 0.1, 0.6))

# ---------------------------------------------------------------- samenvoegen

static func _bake(root: Node3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if not mi.has_meta("slot"):
			continue
		var slot: String = mi.get_meta("slot")
		var vc: Color
		if slot == "wall":
			vc = Color(1, 1, 1, 0.25)
		elif slot == "roof":
			vc = Color(1, 1, 1, 0.75)
		else:
			vc = SLOT_COLORS[slot]
			vc.a = 1.0
		# zelf overnemen (alleen positie en normaal): blokjes en losse dakvlakken hebben
		# verschillende vertexformaten
		var xf: Transform3D = _local_xform(mi, root)
		var nb: Basis = xf.basis.inverse().transposed()
		var m: Mesh = mi.mesh
		for i in m.get_surface_count():
			var a: Array = m.surface_get_arrays(i)
			var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			var ids = a[Mesh.ARRAY_INDEX]
			var order: Array = []
			if ids == null or (ids as PackedInt32Array).is_empty():
				order = range(vs.size())
			else:
				order = Array(ids)
			for k in order:
				st.set_color(vc)
				st.set_normal((nb * ns[k]).normalized())
				st.add_vertex(xf * vs[k])
	var out := st.commit()
	out.surface_set_material(0, material())
	return out

static func _local_xform(n: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf
