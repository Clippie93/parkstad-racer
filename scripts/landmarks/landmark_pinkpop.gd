extends Node3D
# Megaland, Landgraaf: de ovale renbaan met het Pinkpop-festival erop. Naar jouw foto's
# (20-11):
# - ovale baan van grijs asfalt (twee rechte stukken en twee bochten) met gras binnen en
#   buiten, lichtmasten langs de buitenrand en het witte hoofdgebouw met glazen pui aan
#   het rechte stuk achter het podium
# - het hoofdpodium binnen de baan: zwarte truss-constructie met dak, een kop met een
#   bonte roze-blauw-groene pixelband en een rond embleem in het midden, ledschermen met
#   PINKPOP links en rechts, line-arrays, lichtbalken
# - twee hoge zwarte delaytorens met speakers en lampen in het veld, een mixtoren,
#   dranghekken en witte tentjes langs de rand
# Het echte Pinkpop-logo (het babygezicht) is bewust niet nagemaakt: in het embleem staat
# alleen een roze cirkel.
# Lokale ruimte: podiumrand op z=0, het publieksveld ligt aan +Z (naar de weg).
const Kit = preload("res://scripts/build_kit.gd")

const PINK := Color("e8418f")
const MAGENTA := Color("c2186b")
const TRUSS := Color("222428")
const TRACK := Color("6e7276")

const OVAL_C := Vector3(0, 0, 8.0)  # midden van de baan
const OVAL_HALF := 42.0             # halve lengte van de rechte stukken (langs x)
const OVAL_R := 40.0                # buitenstraal van de bochten
const TRACK_W := 9.0

func _ready() -> void:
	name = "Megaland Pinkpop"
	_track()
	_grandstand()
	_stage()
	_field()

# ---------------------------------------------------------------- baan
func _ring(n: String, r0: float, r1: float, y: float, color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var steps := 160
	for k in range(steps):
		# zelfde parameter op binnen- en buitenrand: per stuk apart samplen
		var p0a := _oval_at(k, steps, r0)
		var p0b := _oval_at(k, steps, r1)
		var p1a := _oval_at(k + 1, steps, r0)
		var p1b := _oval_at(k + 1, steps, r1)
		for v in [p0a, p1a, p1b, p0a, p1b, p0b]:
			st.add_vertex(v + Vector3(0, y, 0))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = st.commit()
	mi.material_override = Kit.two_sided_mat(color)
	add_child(mi)

# Punt k van steps langs de ovaal op straal r; de rechte stukken en bochten krijgen
# vaste delen van de stappen, zodat binnen- en buitenrand netjes gelijk lopen.
func _oval_at(k: int, steps: int, r: float) -> Vector3:
	var q: int = steps / 4
	var seg: int = (k % steps) / q
	var f: float = float(k % steps - seg * q) / float(q)
	if k == steps:
		seg = 0
		f = 0.0
	match seg:
		0:
			return OVAL_C + Vector3(lerpf(-OVAL_HALF, OVAL_HALF, f), 0, r)
		1:
			var a: float = f * PI
			return OVAL_C + Vector3(OVAL_HALF + sin(a) * r, 0, cos(a) * r)
		2:
			return OVAL_C + Vector3(lerpf(OVAL_HALF, -OVAL_HALF, f), 0, -r)
		_:
			var a: float = f * PI
			return OVAL_C + Vector3(-OVAL_HALF - sin(a) * r, 0, -cos(a) * r)

func _track() -> void:
	_ring("Outer grass", OVAL_R, OVAL_R + 8.0, 0.04, Color("6f9150"))
	_ring("Track", OVAL_R - TRACK_W, OVAL_R, 0.06, TRACK)
	_ring("Track line outer", OVAL_R - 0.6, OVAL_R - 0.4, 0.075, Color("e8e8e2"))
	_ring("Track line inner", OVAL_R - TRACK_W + 0.4, OVAL_R - TRACK_W + 0.6, 0.075, Color("e8e8e2"))
	# grasveld binnen de baan
	var inner: float = OVAL_R - TRACK_W
	Kit.box(self, "Infield", OVAL_C + Vector3(0, 0.05, 0), Vector3(OVAL_HALF * 2.0, 0.06, inner * 2.0), Color("78994f"))
	for sx in [-1.0, 1.0]:
		Kit.cyl(self, "Infield end", OVAL_C + Vector3(sx * OVAL_HALF, 0.05, 0), inner, inner, 0.06, Color("78994f"), 32)
	# witte hekjes en lichtmasten langs de buitenrand
	for k in range(14):
		var p := _oval_at(k * 160 / 14, 160, OVAL_R + 3.0)
		Kit.cyl(self, "Track light", p + Vector3(0, 6.0, 0), 0.12, 0.08, 12.0, Color("c9cdcf"), 8, "y", true)
		Kit.box(self, "Track light head", p + Vector3(0, 12.1, 0), Vector3(0.8, 0.25, 0.4), Color("5a5e61"))
	for k in range(80):
		var p := _oval_at(k * 2, 160, OVAL_R + 0.6)
		Kit.box(self, "Rail post", p + Vector3(0, 0.45, 0), Vector3(0.08, 0.9, 0.08), Color("f2f2ee"))

# Wit hoofdgebouw met glazen pui en blauwe band aan het rechte stuk achter het podium.
func _grandstand() -> void:
	var c := OVAL_C + Vector3(-18.0, 0, -OVAL_R - 9.0)
	var w := 34.0
	var d := 10.0
	var h := 8.0
	Kit.box(self, "Grandstand", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), Color("eceeee"), true)
	Kit.box(self, "Grandstand roof", c + Vector3(0, h + 0.2, 0), Vector3(w + 1.0, 0.4, d + 1.0), Color("3c4a6b"))
	var f := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0)
	Kit.box(f, "Grandstand glass", Vector3(0, 5.6, 0.05), Vector3(w - 2.0, 2.6, 0.08), Color("4d6a86"))
	Kit.box(f, "Grandstand band", Vector3(0, 1.4, 0.05), Vector3(w - 2.0, 1.6, 0.08), Color("3d5aa0"))
	for k in range(9):
		Kit.box(f, "Mullion", Vector3(-w * 0.5 + 1.0 + float(k) * (w - 2.0) / 8.0, 5.6, 0.1), Vector3(0.15, 2.6, 0.06), Color("dcdfe0"))
	Kit.cyl(self, "Mast", c + Vector3(w * 0.5 + 6.0, 9.0, 0), 0.3, 0.15, 18.0, Color("b7bbbd"), 8, "y", true)

# ---------------------------------------------------------------- podium
func _stage() -> void:
	# podiumvloer, achterwand en zijvleugels
	Kit.box(self, "Stage deck", Vector3(0, 1.1, -9.0), Vector3(34.0, 2.2, 18.0), TRUSS, true)
	Kit.box(self, "Back wall", Vector3(0, 9.0, -17.8), Vector3(36.0, 14.0, 0.4), Color("151619"), true)
	Kit.box(self, "Stage backdrop", Vector3(0, 7.5, -17.5), Vector3(14.0, 9.0, 0.1), Color("6d6f73"))
	for x in [-18.0, 18.0]:
		for z in [-1.0, -17.0]:
			Kit.box(self, "Truss column", Vector3(x, 10.0, z), Vector3(1.2, 20.0, 1.2), TRUSS)
	Kit.box(self, "Roof", Vector3(0, 20.6, -9.0), Vector3(40.0, 1.0, 21.0), Color("dcdcd8"))
	Kit.box(self, "Front truss", Vector3(0, 19.3, -0.6), Vector3(38.0, 1.4, 1.0), Color("3a3d42"))
	# kop: bonte pixelband met een rond embleem in het midden
	Kit.box(self, "Header", Vector3(0, 17.4, -0.3), Vector3(34.0, 3.4, 0.3), PINK)
	var cols := [Color("e8418f"), Color("2e3fa6"), Color("4fc39a"), Color("f07fb6"), Color("6e2bb0"), Color("e8418f")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1970
	for k in range(56):
		var x: float = -16.4 + float(k % 28) * 1.2
		if absf(x) < 3.0:
			continue
		var y: float = 16.6 + float(k / 28) * 1.5
		Kit.box(self, "Header pixel", Vector3(x, y, -0.12), Vector3(1.1, 1.3, 0.05), cols[rng.randi_range(0, cols.size() - 1)])
	Kit.cyl(self, "Emblem ring", Vector3(0, 17.6, -0.05), 2.6, 2.6, 0.2, Color("f2f2ee"), 28, "z")
	Kit.cyl(self, "Emblem", Vector3(0, 17.6, 0.08), 2.2, 2.2, 0.1, Color("1d2a5a"), 28, "z")
	Kit.cyl(self, "Emblem dot", Vector3(0, 17.6, 0.16), 1.3, 1.3, 0.06, PINK, 24, "z")
	# lichtbalken
	var lamp := Kit.mat(Color("f6d9ff"), 2.0)
	for k in range(14):
		Kit.cyl(self, "Spot", Vector3(-16.0 + float(k) * 2.45, 15.3, -0.6), 0.3, 0.3, 0.5, Color.WHITE, 8, "y", false, lamp)
	# ledschermen naast het podium: boven PINKPOP, onder het beeld
	for side in [-1.0, 1.0]:
		var sx: float = side * 26.0
		Kit.box(self, "Screen tower", Vector3(sx, 9.0, -3.5), Vector3(11.0, 18.0, 1.0), TRUSS, true)
		Kit.box(self, "Screen top", Vector3(sx, 13.8, -2.95), Vector3(10.0, 3.6, 0.1), Color("2a0d1f"))
		var f := Kit.face(self, Vector3(sx, 13.8, -2.85), 0)
		Kit.label(f, "PINKPOP", Vector3.ZERO, 0.02, Color("ff5fb0"), 100)
		Kit.box(self, "Screen", Vector3(sx, 7.6, -2.95), Vector3(10.0, 6.4, 0.1), Color.WHITE, false, Kit.mat(Color("5b6fc0"), 0.5))
		Kit.cyl(self, "Screen emblem", Vector3(sx, 3.2, -2.9), 1.1, 1.1, 0.1, MAGENTA, 20, "z")
		# line-array naast het podium
		for k in range(8):
			Kit.box(self, "PA box", Vector3(side * 19.8, 17.0 - float(k) * 1.0, 0.2), Vector3(1.4, 0.9, 1.3), Color("101113"))
		# hoge truss-vleugel met lampen
		Kit.box(self, "Wing truss", Vector3(side * 33.0, 11.0, -3.0), Vector3(1.2, 22.0, 1.2), TRUSS)
		Kit.box(self, "Wing truss top", Vector3(side * 30.0, 21.8, -3.0), Vector3(7.0, 0.8, 1.2), TRUSS)

func _field() -> void:
	# dranghek voor het podium
	Kit.box(self, "Crowd barrier", Vector3(0, 0.6, 2.5), Vector3(34.0, 1.2, 0.3), Color("9aa1a6"))
	# mixtoren (FOH) midden in het veld
	Kit.box(self, "FOH tower", Vector3(0, 3.5, 22.0), Vector3(6.0, 7.0, 5.0), TRUSS, true)
	Kit.box(self, "FOH roof", Vector3(0, 7.3, 22.0), Vector3(7.0, 0.4, 6.0), PINK)
	# twee delaytorens met speakers en lampen
	for side in [-1.0, 1.0]:
		var p := Vector3(side * 24.0, 0, 24.0)
		Kit.box(self, "Delay tower", p + Vector3(0, 10.0, 0), Vector3(1.0, 20.0, 1.0), TRUSS, true)
		Kit.box(self, "Delay tower top", p + Vector3(0, 19.6, 0), Vector3(4.0, 0.4, 1.2), TRUSS)
		Kit.box(self, "Delay tower bar", p + Vector3(0, 18.4, 0), Vector3(3.0, 0.3, 1.0), TRUSS)
		for k in range(5):
			Kit.box(self, "Delay speaker", p + Vector3(0.9, 14.5 - float(k) * 1.0, -0.3), Vector3(1.0, 0.9, 1.0), Color("101113"))
		for k in range(4):
			Kit.cyl(self, "Delay lamp", p + Vector3(-1.5 + float(k), 19.2, -0.6), 0.22, 0.22, 0.4, Color.WHITE, 8, "z", false, Kit.mat(Color("fff2b0"), 1.5))
	# witte tentjes langs de rand van het veld
	for k in range(5):
		var p := Vector3(-40.0 + float(k) * 4.5, 0, 30.0)
		Kit.box(self, "Tent", p + Vector3(0, 1.2, 0), Vector3(4.0, 2.4, 4.0), Color("f2f2ee"))
		Kit.pyramid(self, "Tent roof", p + Vector3(0, 2.4, 0), 2.2, 1.6, Color("f8f8f6"))
	# roze vlaggen langs het veld
	for k in range(6):
		var p := Vector3(-22.5 + float(k) * 9.0, 0, 34.0)
		Kit.cyl(self, "Flag pole", p + Vector3(0, 3.5, 0), 0.06, 0.05, 7.0, Color("dddddd"), 6)
		Kit.box(self, "Flag", p + Vector3(0.6, 6.0, 0), Vector3(1.2, 1.8, 0.03), PINK if k % 2 == 0 else Color("f4f4f4"))
