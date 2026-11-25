extends Node3D
# Heilige Gregoriuskerk, Brunssum (Gottfried Böhm, 1963). Naar jouw Street View-foto's
# (20-11):
# - losse, heel slanke betonnen klokkentoren die iets taps toeloopt, bovenin een
#   onregelmatig raster van kleine vierkante gaten, een spitse piramidekap met kruis
# - hoge kerkzaal: onderin grijs beton, daarboven rode baksteen tot het platte dak;
#   een rij achthoekige vensters hoog in de baksteen, aan de voorkant een betonnen band
#   met hoge glas-in-loodramen tussen pilasters
# - een rond betonnen erkertorentje op één kolom met hoge ramen en een witte kegelkap
# - een gesloten betonnen blok naast de kerkzaal met een klein uitgebouwd nisje
# - de doopkapel: betonnen blok met een witte vierkante piramide erop
# - plein van rode klinkers met een ronde vijver en de stenen beeldengroep, treden naar
#   de kerk, heggen en bomen
# Lokale ruimte: z=0 is de pleinrand aan de straat, de kerk ligt aan -Z.
const Kit = preload("res://scripts/build_kit.gd")

const HALL_W := 44.0
const HALL_D := 30.0
const HALL_H := 17.0
const PLINTH_H := 4.5
const HALL_Z := -38.0   # midden van de kerkzaal
const FRONT_Z := HALL_Z + HALL_D * 0.5

var concrete := Color("857e71")
var brick: StandardMaterial3D

func _ready() -> void:
	name = "Gregoriuskerk"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("b2735e"), 3.0)
	Kit.box(self, "Plaza", Vector3(0, 0.05, -11.0), Vector3(84.0, 0.1, 24.0), Color("9b5a4a"))
	_hall()
	_side_block()
	_oriel(Vector3(0.0, 0, FRONT_Z))
	_tower(Vector3(HALL_W * 0.5 + 1.5, 0, -9.0))   # op de hoogte van de vijver
	_baptistery(Vector3(-HALL_W * 0.5 - 7.0, 0, FRONT_Z - 4.0))
	_fountain(Vector3(-7.0, 0, -9.0))
	_steps_and_green()

# ---------------------------------------------------------------- kerkzaal
func _hall() -> void:
	Kit.box(self, "Hall plinth", Vector3(0, PLINTH_H * 0.5, HALL_Z), Vector3(HALL_W, PLINTH_H, HALL_D), concrete, true)
	var bh: float = HALL_H - PLINTH_H
	Kit.box(self, "Hall brick", Vector3(0, PLINTH_H + bh * 0.5, HALL_Z), Vector3(HALL_W, bh, HALL_D), Color.WHITE, true, brick)
	Kit.box(self, "Roof edge", Vector3(0, HALL_H + 0.12, HALL_Z), Vector3(HALL_W + 0.3, 0.24, HALL_D + 0.3), Color("d9d6cf"))
	# Indeling naar jouw foto's: voorkant (+Z, plein) zonder achthoeken, met de raamband en
	# het erkertorentje in het midden; rechterzijgevel (+X) drie verspringende rijen
	# achthoeken en een ingang met witte omlijsting; linkerzijgevel (-X) twee rijen
	# achthoeken op het voorste deel, achteraan het betonblok.
	var oct := Color("1e2a3d")
	var right := Kit.face(self, Vector3(HALL_W * 0.5, 0, HALL_Z), 90.0)
	for row in range(3):
		var y: float = 7.6 + float(row) * 2.9
		var shift: float = 1.6 if row % 2 == 1 else 0.0
		for k in range(9):
			var x: float = -HALL_D * 0.5 + 1.9 + shift + float(k) * 3.2
			if x > HALL_D * 0.5 - 1.6 or (row == 0 and x < -HALL_D * 0.5 + 7.5):
				continue
			_octagon(right, Vector3(x, y, 0.0), 1.15, oct)
	# ingang rechts: hoge deur met witte, afgeschuinde omlijsting
	var ex: float = -HALL_D * 0.5 + 4.5
	Kit.box(right, "Side door frame", Vector3(ex, 3.4, 0.08), Vector3(3.0, 6.8, 0.16), Color("eceae4"))
	for sx in [-1.0, 1.0]:
		var ch := Kit.box(right, "Side door chamfer", Vector3(ex + sx * 1.1, 6.95, 0.08), Vector3(1.2, 0.6, 0.16), Color("eceae4"))
		ch.rotation.z = -sx * 0.6
	Kit.box(right, "Side door glass", Vector3(ex, 3.1, 0.18), Vector3(2.0, 5.8, 0.06), Color("2f3842"))
	Kit.box(right, "Side door ramp", Vector3(ex - 1.0, 0.4, 2.0), Vector3(7.0, 0.8, 3.6), concrete, true)
	var left := Kit.face(self, Vector3(-HALL_W * 0.5, 0, HALL_Z), -90.0)
	for row in range(2):
		var y: float = 9.8 + float(row) * 3.0
		var shift: float = 1.6 if row % 2 == 1 else 0.0
		for k in range(5):
			var x: float = 1.5 + shift + float(k) * 3.2
			if x > HALL_D * 0.5 - 1.6:
				continue
			_octagon(left, Vector3(x, y, 0.0), 1.0, oct)
	# voorgevel: betonnen band met hoge glas-in-loodramen tussen pilasters
	var ff := Kit.face(self, Vector3(0, 0, FRONT_Z), 0.0)
	Kit.box(ff, "Window band", Vector3(0, PLINTH_H + 2.0, 0.08), Vector3(28.0, 4.6, 0.16), concrete)
	for k in range(8):
		var x: float = -12.6 + float(k) * 3.6
		if absf(x) < 2.5:
			continue
		Kit.box(ff, "Leaded window", Vector3(x, PLINTH_H + 2.0, 0.18), Vector3(2.6, 3.4, 0.06), Color("3b4048"))
		for gy in [-0.8, 0.0, 0.8]:
			Kit.box(ff, "Lead line", Vector3(x, PLINTH_H + 2.0 + gy, 0.22), Vector3(2.6, 0.05, 0.02), Color("55595e"))
		Kit.box(ff, "Lead line", Vector3(x, PLINTH_H + 2.0, 0.22), Vector3(0.05, 3.4, 0.02), Color("55595e"))
		Kit.box(ff, "Pilaster", Vector3(x + 1.8, PLINTH_H + 2.0, 0.24), Vector3(0.45, 4.6, 0.2), Color("b6ae9e"))
	Kit.box(ff, "Entrance", Vector3(-16.0, 1.4, 0.06), Vector3(3.0, 2.8, 0.08), Color("2a2c2f"))
	# lage bakstenen aanbouw rechtsachter
	Kit.box(self, "Back annex", Vector3(HALL_W * 0.5 + 4.0, 2.2, HALL_Z - 8.0), Vector3(8.0, 4.4, 12.0), Color.WHITE, true, brick)
	Kit.box(self, "Back annex roof", Vector3(HALL_W * 0.5 + 4.0, 4.5, HALL_Z - 8.0), Vector3(8.4, 0.2, 12.4), Color("d9d6cf"))

func _octagon(f: Node3D, p: Vector3, r: float, color: Color) -> void:
	Kit.cyl(f, "Octagon frame", p + Vector3(0, 0, 0.02), r + 0.14, r + 0.14, 0.06, Color("2e2f33"), 8, "z")
	Kit.cyl(f, "Octagon window", p + Vector3(0, 0, 0.05), r, r, 0.08, color, 8, "z")
	# glas-in-lood: een paar lichte lijnen
	Kit.box(f, "Octagon lead", p + Vector3(0, 0, 0.1), Vector3(r * 1.8, 0.04, 0.02), Color("3e4c63"))
	Kit.box(f, "Octagon lead", p + Vector3(0, 0, 0.1), Vector3(0.04, r * 1.8, 0.02), Color("3e4c63"))

# Gesloten betonnen blok linksachter, even hoog als de kerkzaal: een klein uitgebouwd
# nisje hoog in de gevel en een raam onderin.
func _side_block() -> void:
	var depth := 15.0
	var c := Vector3(-HALL_W * 0.5 - 2.0, 0, HALL_Z - HALL_D * 0.5 + depth * 0.5)
	Kit.box(self, "Concrete block", c + Vector3(0, HALL_H * 0.5, 0), Vector3(8.0, HALL_H, depth), concrete, true)
	Kit.box(self, "Concrete block edge", c + Vector3(0, HALL_H + 0.1, 0), Vector3(8.3, 0.2, depth + 0.3), Color("d9d6cf"))
	var f := Kit.face(self, c + Vector3(-4.0, 0, 0), -90.0)
	Kit.box(f, "Niche", Vector3(-2.5, 9.5, 0.5), Vector3(1.6, 2.8, 1.0), Color("9a9283"))
	Kit.box(f, "Niche hole", Vector3(-2.5, 9.7, 1.01), Vector3(1.0, 2.0, 0.04), Color("4a4842"))
	Kit.box(f, "Niche foot", Vector3(-2.5, 7.85, 0.6), Vector3(1.2, 0.5, 0.8), Color("9a9283"))
	Kit.box(f, "Block window", Vector3(3.5, 2.0, 0.05), Vector3(3.0, 2.0, 0.08), Color("2a2c2f"))

# Rond betonnen erkertorentje op één kolom: hoge ramen tussen pijlers, witte kegelkap.
func _oriel(front: Vector3) -> void:
	var c := front + Vector3(0, 0, 1.8)
	var r := 2.2
	Kit.cyl(self, "Oriel column", c + Vector3(0, 1.6, 0), 0.45, 0.45, 3.2, concrete, 12, "y", true)
	Kit.cyl(self, "Oriel floor", c + Vector3(0, 3.5, 0), r + 0.2, r - 0.6, 0.7, concrete, 20)
	Kit.cyl(self, "Oriel body", c + Vector3(0, 5.6, 0), r - 0.15, r - 0.15, 3.6, Color("3b4048"), 20)
	for k in range(8):
		var a: float = TAU * float(k) / 8.0
		var p := Vector3(sin(a) * r, 5.6, cos(a) * r)
		var pier := Kit.box(self, "Oriel pier", c + p, Vector3(0.5, 3.6, 0.4), concrete)
		pier.rotation.y = a
	Kit.cyl(self, "Oriel parapet", c + Vector3(0, 4.25, 0), r + 0.05, r + 0.05, 0.6, concrete, 20)
	Kit.cyl(self, "Oriel crown", c + Vector3(0, 7.7, 0), r + 0.2, r + 0.2, 0.7, concrete, 20)
	Kit.cyl(self, "Oriel roof", c + Vector3(0, 10.6, 0), r + 0.1, 0.05, 5.0, Color("e8e6e0"), 20)
	Kit.cyl(self, "Oriel tip", c + Vector3(0, 13.4, 0), 0.05, 0.05, 0.6, Color("6a6a6a"), 6)

# ---------------------------------------------------------------- toren
func _tower(p: Vector3) -> void:
	var h := 50.0
	var b0 := 4.6     # breedte onderaan
	var b1 := 3.6     # breedte bovenaan
	var shaft := Kit.cyl(self, "Bell tower", p + Vector3(0, h * 0.5, 0), b0 * 0.7071, b1 * 0.7071, h, concrete, 4, "y", true)
	shaft.rotation_degrees.y = 45.0
	# lichte horizontale naden van het beton
	for k in range(1, 12):
		var y: float = float(k) * 4.0
		var w: float = lerpf(b0, b1, y / h) + 0.04
		Kit.box(self, "Tower seam", p + Vector3(0, y, 0), Vector3(w, 0.06, w), Color("948c7d"))
	# spitse piramidekap met kruis
	Kit.pyramid(self, "Tower cap", p + Vector3(0, h, 0), b1 * 0.5 + 0.05, 7.5, Color("9a9283"))
	Kit.cyl(self, "Tower cross", p + Vector3(0, h + 8.2, 0), 0.06, 0.06, 1.6, Color("3a3a3a"), 6)
	Kit.box(self, "Tower cross bar", p + Vector3(0, h + 8.5, 0), Vector3(0.8, 0.08, 0.08), Color("3a3a3a"))
	# onregelmatig raster van kleine vierkante gaten in de bovenste 15 m, op alle zijden
	var rng := RandomNumberGenerator.new()
	rng.seed = 1963
	for yaw in [0.0, 90.0, 180.0, -90.0]:
		var out := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
		for row in range(12):
			var y: float = h - 1.5 - float(row) * 1.2
			var half: float = lerpf(b0, b1, y / h) * 0.5
			var f := Kit.face(self, p + out * (half + 0.01) + Vector3(0, 0, 0), yaw)
			var cols: int = 3 if row % 2 == 0 else 2
			for col in range(cols):
				if rng.randf() < 0.18:
					continue
				var x: float = (-0.9 + float(col) * 0.9) if cols == 3 else (-0.45 + float(col) * 0.9)
				Kit.box(f, "Sound hole", Vector3(x, y, 0.0), Vector3(0.38, 0.45, 0.04), Color("1e2023"))
	# deurtje onderaan
	var df := Kit.face(self, p + Vector3(0, 0, b0 * 0.5 + 0.01), 0.0)
	Kit.box(df, "Tower door", Vector3(0, 1.2, 0), Vector3(1.2, 2.4, 0.04), Color("2a2c2f"))

# Doopkapel: betonnen blok met een witte, spitse vierkante piramide, met een laag glazen
# tussenlid vast aan de zijgevel van de kerk; ervoor een trap met een betonnen muurtje.
func _baptistery(p: Vector3) -> void:
	Kit.box(self, "Baptistery", p + Vector3(0, 2.6, 0), Vector3(6.0, 5.2, 6.0), concrete, true)
	Kit.box(self, "Baptistery edge", p + Vector3(0, 5.25, 0), Vector3(6.2, 0.1, 6.2), Color("d9d6cf"))
	Kit.pyramid(self, "Baptistery roof", p + Vector3(0, 5.3, 0), 3.0, 7.5, Color("eeede8"))
	# tussenlid naar de linkerzijgevel: laag, met glazen pui
	var link_x0: float = p.x + 3.0
	var link_x1: float = -HALL_W * 0.5
	var lc := Vector3((link_x0 + link_x1) * 0.5, 0, p.z)
	Kit.box(self, "Baptistery link", lc + Vector3(0, 1.6, 0), Vector3(link_x1 - link_x0, 3.2, 5.0), concrete, true)
	var lf := Kit.face(self, lc + Vector3(0, 0, 2.51), 0.0)
	Kit.box(lf, "Link glass", Vector3(0, 1.4, 0), Vector3(link_x1 - link_x0 - 0.4, 2.6, 0.04), Color("3b4048"))
	# aan de voorkant een uitgebouwd erkerraam met spitse onderkant (foto linksvoor),
	# aan de straatkant een klein diep raam
	var f := Kit.face(self, p + Vector3(0, 0, 3.01), 0.0)
	Kit.box(f, "Baptistery bay", Vector3(0.0, 3.2, 0.35), Vector3(1.6, 1.8, 0.7), Color("dcdcd6"))
	Kit.box(f, "Baptistery bay glass", Vector3(0.0, 3.2, 0.71), Vector3(1.2, 1.5, 0.04), Color("6d7f88"))
	var foot := Kit.cyl(f, "Baptistery bay foot", Vector3(0.0, 1.9, 0.35), 0.0, 0.8, 0.8, Color("9a9283"), 4)
	foot.rotation_degrees.y = 45.0
	var fs := Kit.face(self, p + Vector3(-3.01, 0, 0), -90.0)
	Kit.box(fs, "Baptistery window", Vector3(0.0, 2.6, 0), Vector3(1.4, 1.0, 0.04), Color("2a2c2f"))
	# trap met muurtje ervoor
	for k in range(4):
		Kit.box(self, "Baptistery step", p + Vector3(5.5, 0.1 + float(k) * 0.18, 4.4 - float(k) * 0.4), Vector3(3.0, 0.2 + float(k) * 0.36, 0.4), Color("8a8478"))
	Kit.box(self, "Stair wall", p + Vector3(3.5, 0.7, 4.6), Vector3(0.6, 1.4, 3.2), Color("4a4542"))

# ---------------------------------------------------------------- plein
func _fountain(c: Vector3) -> void:
	Kit.cyl(self, "Pool rim", c + Vector3(0, 0.3, 0), 5.0, 5.0, 0.6, Color("8a4e40"), 32, "y", true)
	Kit.cyl(self, "Pool water", c + Vector3(0, 0.52, 0), 4.6, 4.6, 0.1, Color("6a7a6e"), 32)
	# stenen beeldengroep: blokvormige figuren met ronde hoofden op een sokkel
	var stone := Color("8f8d88")
	Kit.box(self, "Sculpture base", c + Vector3(0, 0.9, 0), Vector3(2.4, 1.0, 1.6), stone)
	var figs := [[-1.6, 0.4, 2.6], [-0.9, -0.3, 3.0], [0.2, 0.5, 2.2], [0.9, -0.4, 3.4], [1.7, 0.2, 2.4], [-0.3, -0.6, 2.8]]
	for fg in figs:
		var p: Vector3 = c + Vector3(fg[0], 0, fg[1])
		var h: float = fg[2]
		Kit.box(self, "Sculpture figure", p + Vector3(0, 0.6 + h * 0.5, 0), Vector3(0.75, h, 0.6), stone)
		Kit.cyl(self, "Sculpture head", p + Vector3(0, 0.6 + h + 0.3, 0), 0.33, 0.3, 0.6, stone, 10)
	Kit.box(self, "Sculpture slab", c + Vector3(1.0, 2.8, -0.7), Vector3(1.2, 3.6, 0.4), stone)

func _steps_and_green() -> void:
	for k in range(3):
		Kit.box(self, "Church step", Vector3(4.0, 0.15 + float(k) * 0.15, FRONT_Z + 4.0 - float(k) * 0.8), Vector3(30.0, 0.3 + float(k) * 0.3, 0.8), Color("8a8478"))
	Kit.box(self, "Church forecourt", Vector3(4.0, 0.45, FRONT_Z + 1.6), Vector3(30.0, 0.9, 3.2), Color("9b5a4a"))
	# heg en bomen op de hoek bij de straat
	Kit.box(self, "Hedge", Vector3(-12.0, 0.6, -2.5), Vector3(18.0, 1.2, 1.4), Color("4f6b34"))
	Kit.box(self, "Lawn", Vector3(-12.0, 0.12, -7.0), Vector3(18.0, 0.1, 8.0), Color("6d8f4a"))
	var leaf := [Color("3f6a32"), Color("4d7a38")]
	for k in range(3):
		var p := Vector3(-18.0 + float(k) * 6.0, 0, -7.0)
		Kit.cyl(self, "Tree trunk", p + Vector3(0, 2.0, 0), 0.25, 0.2, 4.0, Color("6a5a48"), 8, "y", true)
		_blob(p + Vector3(0, 6.5, 0), Vector3(7.0, 6.0, 7.0), leaf[k % 2])

func _blob(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Tree crown"
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	mi.mesh = sm
	mi.material_override = Kit.mat(color)
	mi.scale = size
	mi.position = pos
	add_child(mi)
