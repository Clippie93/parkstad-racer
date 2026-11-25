extends Node3D
# Station Simpelveld, thuisstation van de Miljoenenlijn (ZLSM). Naar jouw foto's van de
# straatkant (20-11), van links naar rechts langs de straat:
# - een blok van anderhalve laag met de topgevel naar de straat: drie grote witte ramen
#   (links een dubbel), natuurstenen lateien, een hoge granieten plint en boven in de gevel
#   een luik met een raampje; brede witte windveren
# - een lage vleugel van één laag met drie kleine dakkapellen, ramen met bloembakken en een deur
# - het hoofdgebouw van drie lagen: zadeldak met aan beide kopgevels een wit 'hoedje',
#   rechts een hoge dwarsgevel naar de straat, twee dakkapellen en een schoorsteen,
#   segmentbogen boven de ramen, een rode en een groene deur, en een Nederlandse vlag
# - aan de perronkant een overkapping, het perron en een terras
# Lokale ruimte: +Z = straatkant, -Z = perron en spoor; het gebouw ligt langs X.
const Kit = preload("res://scripts/build_kit.gd")

const SLATE := Color("4a4645")
const WHITE := Color("efede6")
const STONE := Color("aaa59c")
const GLASS := Color("2c3438")

var brick: Material

func _ready() -> void:
	name = "Station Simpelveld"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("d8c4bc"), 3.0)
	_gable_block()
	_low_wing()
	_main_building()
	_platform_side()
	# voorplein aan de straatkant (klinkers)
	Kit.box(self, "Forecourt", Vector3(1.0, 0.05, 9.0), Vector3(44.0, 0.1, 8.0), Color("7f6458"))
	for k in range(3):
		Kit.box(self, "Planter", Vector3(-4.0 + float(k) * 9.0, 0.45, 7.2), Vector3(0.9, 0.9, 0.9), Color("7a6a58"))
		var fl := Kit.box(self, "Planter flowers", Vector3(-4.0 + float(k) * 9.0, 1.15, 7.2), Vector3(1.1, 0.5, 1.1), Color("eeeeea"))
		fl.rotation.y = 0.4

# Driehoekige bakstenen geveltop, in face-ruimte (x langs de gevel, y omhoog).
func _gable_wall(parent: Node3D, n: String, pos: Vector3, yaw: float, w: float, rise: float) -> void:
	var f := Kit.face(parent, pos, yaw)
	var hw: float = w * 0.5
	var t: Array = [Vector3(hw, 0, 0), Vector3(-hw, 0, 0), Vector3(0, rise, 0)]
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(t, brick)
	f.add_child(mi)

# Zadeldak zonder dichte kopse kanten (die zijn de bakstenen geveltoppen): alleen twee
# dakvlakken. Nok langs Z, of langs X met along_x.
func _roof(n: String, base: Vector3, width: float, length: float, rise: float, along_x: bool = false) -> void:
	var hw: float = width * 0.5
	var hl: float = length * 0.5
	var t: Array = []
	Kit._quad(t, Vector3(-hw, 0, -hl), Vector3(-hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	Kit._quad(t, Vector3(hw, 0, -hl), Vector3(hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(t, Kit._two_sided(SLATE))
	mi.position = base
	if along_x:
		mi.rotation_degrees.y = 90.0
	add_child(mi)

# Witte windveren langs een gevelschuin, in face-ruimte; met een wit hoedje in de top.
func _bargeboards(f: Node3D, base_y: float, w: float, rise: float, hood: bool) -> void:
	var hw: float = w * 0.5
	var top := Vector3(0, base_y + rise, 0.25)
	for s in [-1.0, 1.0]:
		var b := Kit.beam(f, "Bargeboard", Vector3(s * hw, base_y - 0.1, 0.25), top, 0.32, WHITE)
		b.scale.x = 1.6
	if hood:
		# klein schilddakje boven in de top (een 'hoedje'), zoals op de foto's
		var hd := Kit.gable(f, "Gable hood", Vector3(0, base_y + rise - 1.6, -0.2), 2.6, 1.6, 1.4, SLATE)
		hd.rotation.y = 0.0
		Kit.box(f, "Gable hood soffit", Vector3(0, base_y + rise - 1.65, 0.3), Vector3(2.6, 0.14, 0.7), WHITE)

# Raam met witte kozijnen en roeden, in face-ruimte. y = onderkant.
func _window(f: Node3D, x: float, y: float, w: float, h: float, arch: bool = false, transom: bool = true) -> void:
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.03), Vector3(w + 0.16, h + 0.16, 0.08), WHITE)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.06), Vector3(w - 0.12, h - 0.12, 0.04), GLASS)
	Kit.box(f, "Mullion", Vector3(x, y + h * 0.5, 0.09), Vector3(0.09, h - 0.1, 0.04), WHITE)
	if transom:
		Kit.box(f, "Transom", Vector3(x, y + h * 0.72, 0.09), Vector3(w - 0.1, 0.09, 0.04), WHITE)
		for s in [-0.25, 0.25]:
			Kit.box(f, "Glazing bar", Vector3(x + s * w, y + h * 0.86, 0.1), Vector3(0.05, h * 0.26, 0.03), WHITE)
	Kit.box(f, "Sill", Vector3(x, y - 0.06, 0.1), Vector3(w + 0.35, 0.12, 0.22), STONE)
	if arch:
		# segmentboog van rollagen met natuurstenen blokjes
		Kit.box(f, "Arch", Vector3(x, y + h + 0.22, 0.05), Vector3(w + 0.4, 0.4, 0.06), Color("6e4438"))
		for s in [-0.5, 0.0, 0.5]:
			Kit.box(f, "Arch stone", Vector3(x + s * (w + 0.2), y + h + 0.22, 0.08), Vector3(0.24, 0.42, 0.06), STONE)
	else:
		Kit.box(f, "Lintel", Vector3(x, y + h + 0.2, 0.06), Vector3(w + 0.5, 0.3, 0.1), STONE)

func _door(f: Node3D, x: float, color: Color, w: float = 1.1, h: float = 2.5) -> void:
	Kit.box(f, "Door frame", Vector3(x, 0.7 + h * 0.5, 0.03), Vector3(w + 0.2, h + 0.2, 0.08), WHITE)
	Kit.box(f, "Door", Vector3(x, 0.7 + (h - 0.6) * 0.5, 0.06), Vector3(w, h - 0.6, 0.06), color)
	Kit.box(f, "Door fanlight", Vector3(x, 0.7 + h - 0.3, 0.06), Vector3(w, 0.45, 0.04), GLASS)
	Kit.box(f, "Door step", Vector3(x, 0.35, 0.35), Vector3(w + 0.5, 0.7, 0.7), STONE)
	Kit.box(f, "Door arch", Vector3(x, 0.7 + h + 0.25, 0.05), Vector3(w + 0.5, 0.4, 0.06), Color("6e4438"))

# Links: blok van anderhalve laag met de topgevel naar de straat.
func _gable_block() -> void:
	var cx := -14.0
	var w := 10.0
	var wall_h := 5.0
	var rise := 5.2
	Kit.box(self, "Gable block", Vector3(cx, wall_h * 0.5, -0.5), Vector3(w, wall_h, 11.0), Color.WHITE, true, brick)
	Kit.box(self, "Gable block plinth", Vector3(cx, 0.6, 5.05), Vector3(w + 0.1, 1.2, 0.2), Color("9c9890"))
	_roof("Gable block roof", Vector3(cx, wall_h - 0.15, -0.5), w + 0.8, 12.0, rise + 0.45)
	_gable_wall(self, "Gable top", Vector3(cx, wall_h, 5.0), 0.0, w, rise)
	_gable_wall(self, "Gable top back", Vector3(cx, wall_h, -6.0), 180.0, w, rise)
	var f := Kit.face(self, Vector3(cx, 0, 5.0), 0.0)
	_bargeboards(f, wall_h, w + 0.8, rise + 0.3, false)
	# drie grote ramen: links een dubbel raam, dan twee enkele
	_window(f, -2.7, 1.4, 1.2, 3.0)
	_window(f, -1.35, 1.4, 1.2, 3.0)
	Kit.box(f, "Double window lintel", Vector3(-2.02, 4.62, 0.07), Vector3(3.2, 0.32, 0.1), STONE)
	_window(f, 1.0, 1.5, 1.2, 2.8)
	_window(f, 3.2, 1.5, 1.2, 2.8)
	# boven in de gevel: luik met een raampje erboven, en twee blinde nissen
	Kit.box(f, "Loft hatch", Vector3(0, 6.0, 0.06), Vector3(1.1, 1.3, 0.06), Color("4f5f68"))
	_window(f, 0, 6.75, 1.1, 0.8, false, false)
	for s in [-1.0, 1.0]:
		Kit.box(f, "Blind niche", Vector3(s * 1.8, 5.9, 0.02), Vector3(0.9, 1.3, 0.04), Color("6a4438"))
		Kit.box(f, "Niche stone", Vector3(s * 1.8, 6.7, 0.05), Vector3(1.1, 0.24, 0.08), STONE)
	# zijkant links: gesloten met een regenpijp
	Kit.box(self, "Downpipe", Vector3(cx - w * 0.5 - 0.1, 2.5, 4.6), Vector3(0.14, 5.0, 0.14), Color("5a5d60"))

# Midden: lage vleugel van één laag met drie kleine dakkapellen.
func _low_wing() -> void:
	var cx := -3.5
	var ln := 11.0
	var wall_h := 4.2
	Kit.box(self, "Low wing", Vector3(cx, wall_h * 0.5, 0), Vector3(ln, wall_h, 8.0), Color.WHITE, true, brick)
	Kit.box(self, "Low wing plinth", Vector3(cx, 0.35, 4.05), Vector3(ln, 0.7, 0.14), Color("9c9890"))
	Kit.gable(self, "Low wing roof", Vector3(cx, wall_h, 0), 9.2, ln - 0.1, 3.2, SLATE, true)
	Kit.box(self, "Low wing gutter", Vector3(cx, wall_h, 4.55), Vector3(ln, 0.25, 0.3), WHITE)
	var f := Kit.face(self, Vector3(cx, 0, 4.0), 0.0)
	for x in [-4.2, -2.2, 2.0, 4.0]:
		_window(f, x, 1.2, 1.1, 2.2, true)
		# bloembak met bloemen
		Kit.box(f, "Flower box", Vector3(x, 1.0, 0.3), Vector3(1.1, 0.25, 0.35), Color("3d3a36"))
		Kit.box(f, "Flowers", Vector3(x, 1.22, 0.32), Vector3(1.0, 0.2, 0.3), Color("e8c04a") if int(x) % 2 == 0 else Color("b94a7a"))
	_door(f, 0.0, Color("27302c"), 1.0, 2.4)
	for k in range(3):
		var x: float = cx - 3.2 + float(k) * 3.2
		Kit.box(self, "Dormer", Vector3(x, wall_h + 1.0, 2.9), Vector3(1.0, 1.0, 1.2), WHITE)
		Kit.gable(self, "Dormer roof", Vector3(x, wall_h + 1.5, 2.9), 1.4, 1.3, 0.75, SLATE)
		Kit.box(self, "Dormer window", Vector3(x, wall_h + 0.95, 3.52), Vector3(0.55, 0.6, 0.04), GLASS)

# Rechts: hoofdgebouw van drie lagen.
func _main_building() -> void:
	var x0 := 2.0
	var x1 := 22.0
	var cx: float = (x0 + x1) * 0.5
	var ln: float = x1 - x0
	var wall_h := 7.8
	var rise := 5.2
	Kit.box(self, "Main block", Vector3(cx, wall_h * 0.5, 0), Vector3(ln, wall_h, 11.0), Color.WHITE, true, brick)
	Kit.box(self, "Main plinth", Vector3(cx, 0.35, 5.56), Vector3(ln + 0.1, 0.7, 0.14), Color("9c9890"))
	_roof("Main roof", Vector3(cx, wall_h - 0.1, 0), 12.0, ln + 0.6, rise + 0.4, true)
	Kit.box(self, "Main gutter", Vector3(cx, wall_h, 6.05), Vector3(ln + 0.6, 0.28, 0.3), WHITE)
	Kit.box(self, "Main gutter back", Vector3(cx, wall_h, -6.05), Vector3(ln + 0.6, 0.28, 0.3), WHITE)
	for s in [-1.0, 1.0]:
		var gx: float = x0 if s < 0.0 else x1
		_gable_wall(self, "Main end gable", Vector3(gx, wall_h, 0), 90.0 * s, 11.0, rise)
		var ef := Kit.face(self, Vector3(gx, 0, 0), 90.0 * s)
		_bargeboards(ef, wall_h, 12.0, rise + 0.3, true)
		# zolderramen in de kopgevel
		_window(ef, 0, wall_h + 0.6, 1.0, 1.4, false, false)
		if s < 0.0:
			continue    # tegen deze kopgevel staat de lage vleugel
		for wx in [-2.6, 2.6]:
			_window(ef, wx, 1.3, 1.1, 2.3, true)
			_window(ef, wx, 4.8, 1.1, 2.1)
	# natuurstenen banden tussen de lagen
	for y in [0.75, 4.25]:
		Kit.box(self, "String course", Vector3(cx, y, 5.55), Vector3(ln + 0.06, 0.16, 0.12), STONE)
	# hoge dwarsgevel naar de straat aan de rechterkant
	var gx := 18.5
	var gw := 6.6
	var g_rise := 5.0
	Kit.box(self, "Cross gable wall", Vector3(gx, wall_h * 0.5, 5.9), Vector3(gw, wall_h, 0.9), Color.WHITE, true, brick)
	_roof("Cross gable roof", Vector3(gx, wall_h - 0.1, 2.4), gw + 0.6, 8.2, g_rise + 0.4)
	_gable_wall(self, "Cross gable top", Vector3(gx, wall_h, 6.35), 0.0, gw, g_rise)
	var cf := Kit.face(self, Vector3(gx, 0, 6.35), 0.0)
	_bargeboards(cf, wall_h, gw + 0.6, g_rise + 0.3, true)
	_window(cf, -1.2, 5.0, 1.1, 2.1)
	_window(cf, 1.2, 4.8, 1.6, 2.3)
	_window(cf, -0.75, wall_h + 0.5, 0.95, 1.6, false, false)
	_window(cf, 0.75, wall_h + 0.5, 0.95, 1.6, false, false)
	_window(cf, -1.4, 1.4, 1.2, 2.3, true)
	_door(cf, 1.3, Color("26332d"), 1.2, 2.6)
	Kit.box(cf, "House number", Vector3(1.3, 3.55, 0.08), Vector3(0.25, 0.18, 0.02), WHITE)
	# Nederlandse gevelvlag aan een schuine stok uit de gevel. De korte zijde (broeking) zit
	# langs de stok en loopt dus even schuin; de vlag zelf staat er haaks op, met rood aan
	# de kant van de top van de stok.
	var pole_a := Vector3(gx - 2.6, 5.2, 6.4)
	var pole_b := pole_a + Vector3(0, 1.5, 1.9)
	Kit.beam(self, "Flag pole", pole_a, pole_b, 0.07, WHITE)
	Kit.box(self, "Flag pole holder", pole_a, Vector3(0.18, 0.18, 0.18), Color("5a5d60"))
	Kit.box(self, "Flag pole knob", pole_b, Vector3(0.12, 0.12, 0.12), Color("e08a2a"))
	var u: Vector3 = (pole_b - pole_a).normalized()
	var v := Vector3(0, -u.z, u.y)        # haaks op de stok, omlaag en van de gevel af
	var hoist_top := pole_a.lerp(pole_b, 0.92)
	var fw := 1.5
	var fh := 1.0
	var stripes := [Color("ae1c28"), Color("ffffff"), Color("21468b")]
	for k in range(3):
		var a0 := hoist_top - u * (fh * float(k) / 3.0)
		var a1 := hoist_top - u * (fh * float(k + 1) / 3.0)
		var tris: Array = []
		Kit._quad(tris, a0, a0 + v * fw, a1 + v * fw, a1)
		var mi := MeshInstance3D.new()
		mi.name = "Flag"
		mi.mesh = Kit._mesh_from(tris, Kit._two_sided(stripes[k]))
		add_child(mi)
	# straatgevel van het hoofdgebouw links van de dwarsgevel
	var f := Kit.face(self, Vector3(cx, 0, 5.5), 0.0)
	for wx in [-8.3, -6.0, -2.2, 0.2, 2.4]:
		_window(f, wx, 1.3, 1.15, 2.3, true)
		_window(f, wx, 4.85, 1.15, 2.1)
	_door(f, -4.1, Color("8e1f22"), 1.1, 2.5)
	Kit.box(f, "Downpipe", Vector3(1.3, wall_h * 0.5, 0.12), Vector3(0.14, wall_h, 0.14), Color("5a5d60"))
	Kit.box(f, "Cafe sign", Vector3(-1.0, 4.4, 0.4), Vector3(0.08, 0.6, 0.6), Color("5a3a26"))
	# twee dakkapellen en een schoorsteen
	for dx in [7.0, 11.0]:
		Kit.box(self, "Main dormer", Vector3(dx, wall_h + 1.2, 3.9), Vector3(2.0, 1.6, 1.6), Color.WHITE, false, brick)
		Kit.gable(self, "Main dormer roof", Vector3(dx, wall_h + 2.0, 3.9), 2.6, 1.8, 1.1, SLATE)
		Kit.box(self, "Main dormer window", Vector3(dx, wall_h + 1.2, 4.72), Vector3(1.3, 0.9, 0.04), GLASS)
		Kit.box(self, "Main dormer frame", Vector3(dx, wall_h + 1.2, 4.73), Vector3(0.08, 0.9, 0.04), WHITE)
	Kit.box(self, "Chimney", Vector3(9.0, wall_h + rise + 0.2, 0.9), Vector3(0.9, 2.4, 0.9), Color("6e4438"))
	Kit.box(self, "Chimney cap", Vector3(9.0, wall_h + rise + 1.45, 0.9), Vector3(1.1, 0.15, 1.1), STONE)
	Kit.box(self, "Chimney 2", Vector3(15.0, wall_h + rise - 0.6, -1.4), Vector3(0.8, 2.2, 0.8), Color("6e4438"))
	# achtergevel aan het perron: ramen en de stationsnaam
	var bf := Kit.face(self, Vector3(cx, 0, -5.5), 180.0)
	for wx in [-7.5, -4.0, -0.5, 3.0, 6.5]:
		_window(bf, wx, 1.3, 1.15, 2.3, true)
		_window(bf, wx, 4.85, 1.15, 2.1)
	Kit.box(bf, "Name board", Vector3(-0.5, 4.2, 0.1), Vector3(4.2, 0.6, 0.06), Color("1d4f9c"))
	Kit.label(bf, "Simpelveld", Vector3(-0.5, 4.2, 0.14), 0.0075, Color.WHITE, 80)

# Perronkant: overkapping op ijzeren kolommen, perron en terras met parasols.
func _platform_side() -> void:
	Kit.box(self, "Canopy", Vector3(6.5, 3.8, -7.0), Vector3(31.0, 0.25, 6.0), Color("3a3330"))
	Kit.box(self, "Canopy fascia", Vector3(6.5, 3.55, -9.95), Vector3(31.0, 0.5, 0.1), Color("6b5a4a"))
	for k in range(7):
		Kit.cyl(self, "Canopy column", Vector3(-8.0 + float(k) * 5.0, 1.85, -9.6), 0.12, 0.12, 3.7, Color("2f3a33"), 8)
	Kit.box(self, "Platform", Vector3(-6.0, 0.4, -10.0), Vector3(120.0, 0.8, 8.0), Color("8f8a80"), true)
	Kit.box(self, "Platform edge", Vector3(-6.0, 0.82, -13.85), Vector3(120.0, 0.05, 0.3), Color("e9e2c4"))
	for k in range(3):
		var p := Vector3(-16.0 + float(k) * 3.6, 0.8, -10.5)
		Kit.cyl(self, "Parasol pole", p + Vector3(0, 1.2, 0), 0.04, 0.04, 2.4, Color("dddddd"), 6)
		Kit.cyl(self, "Parasol", p + Vector3(0, 2.4, 0), 1.6, 0.05, 0.6, Color("f4f2ea"), 12)
		Kit.box(self, "Table", p + Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 0.8), Color("6b4a2f"))
	# stationsbord aan het perron
	for x in [-20.0, 26.0]:
		Kit.box(self, "Sign post", Vector3(x, 2.0, -12.8), Vector3(0.12, 2.4, 0.12), Color("2f3a33"))
		Kit.box(self, "Sign post 2", Vector3(x + 2.6, 2.0, -12.8), Vector3(0.12, 2.4, 0.12), Color("2f3a33"))
		Kit.box(self, "Platform sign", Vector3(x + 1.3, 3.0, -12.8), Vector3(3.2, 0.55, 0.06), Color("1d4f9c"))
		for s in [-1.0, 1.0]:
			var fs := Kit.face(self, Vector3(x + 1.3, 0, -12.8 + s * 0.04), 0.0 if s > 0.0 else 180.0)
			Kit.label(fs, "Simpelveld", Vector3(0, 3.0, 0.01), 0.0065, Color.WHITE, 72)
