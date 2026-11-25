extends Node3D
# Station Klimmen-Ransdaal (Voerendaal), naar jouw foto's (25-11). Stationsgebouw uit
# ca. 1914 in chaletstijl: de begane grond van donkerbruine baksteen op een plint van
# natuursteen (wit-grijs mozaïek), de verdieping wit gepleisterd. Een donker pannendak
# met aan de voorkant twee topgevels met overstekende witte windveren, donker vakwerk en
# houten consoles; een dakkapel ertussen, twee witte dakruitertjes met puntdakjes en een
# witte schoorsteen. Witte ramen met kleine roedes, een donkerrode en een groene deur.
# Rechts een lage bakstenen aanbouw met een schilddak en een groene dubbele deur.
# Achter het gebouw het perron en het spoor (Heuvellandlijn). Geen NS-logo.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const BRICK := Color("5e4038")
const PLASTER := Color("f2f0ea")
const TIMBER := Color("2a2c30")
const ROOF := Color("3a3634")
const FRAME := Color("f4f4f0")
const GLASS := Color("2c3438")

const W := 14.0
const D := 9.0
const H1 := 3.8        # begane grond (baksteen)
const H2 := 3.2        # verdieping (wit)

func _ready() -> void:
	name = "Station Klimmen-Ransdaal"
	Kit.box(self, "Station square", Vector3(2, 0.03, 4), Vector3(34, 0.06, 14), Color("8a7a70"))
	_main()
	_annex(Vector3(W * 0.5 + 3.2, 0, -0.6))
	_platform()

func _window(f: Node3D, x: float, y: float, w: float, h: float) -> void:
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.03), Vector3(w + 0.2, h + 0.2, 0.06), FRAME)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.06), Vector3(w, h, 0.03), GLASS)
	# roedes: bovenlicht met kleine ruitjes, onderraam met een kruis
	Kit.box(f, "Transom", Vector3(x, y + h * 0.7, 0.09), Vector3(w, 0.07, 0.02), FRAME)
	Kit.box(f, "Mullion", Vector3(x, y + h * 0.5, 0.09), Vector3(0.06, h, 0.02), FRAME)
	for k in range(1, 3):
		Kit.box(f, "Glazing bar", Vector3(x - w * 0.5 + w * float(k) / 3.0, y + h * 0.85, 0.09), Vector3(0.04, h * 0.3, 0.02), FRAME)
	Kit.box(f, "Window head", Vector3(x, y + h + 0.18, 0.05), Vector3(w + 0.4, 0.16, 0.08), Color("b8b4aa"))

func _main() -> void:
	var c := Vector3(0, 0, -D * 0.5)
	Kit.box(self, "Station brick", c + Vector3(0, H1 * 0.5, 0), Vector3(W, H1, D), BRICK, true)
	Kit.box(self, "Station plaster", c + Vector3(0, H1 + H2 * 0.5, 0), Vector3(W, H2, D), PLASTER, true)
	Kit.box(self, "Stone plinth", c + Vector3(0, 0.3, 0), Vector3(W + 0.1, 0.6, D + 0.1), Color("d4d2cc"))
	Kit.box(self, "Floor band", c + Vector3(0, H1, 0), Vector3(W + 0.1, 0.18, D + 0.1), Color("b8b4aa"))
	var top: float = H1 + H2
	Kit.gable(self, "Station roof", c + Vector3(0, top, 0), D + 1.2, W + 1.0, 4.6, ROOF, true)
	# topgevels aan de voorkant
	for g in [[-3.6, 4.6], [3.2, 4.2]]:
		_front_gable(float(g[0]), float(g[1]), top)
	# dakkapel tussen de gevels, dakruitertjes en schoorsteen
	Kit.box(self, "Dormer", Vector3(-0.3, top + 1.4, -1.6), Vector3(1.6, 1.3, 1.6), PLASTER)
	Kit.gable(self, "Dormer roof", Vector3(-0.3, top + 2.05, -1.6), 2.0, 1.9, 0.7, ROOF)
	for x in [-3.6, 3.2]:
		Kit.box(self, "Roof turret", Vector3(x, top + 4.4, -D * 0.5), Vector3(0.7, 0.9, 0.7), PLASTER)
		Kit.pyramid(self, "Turret roof", Vector3(x, top + 4.85, -D * 0.5), 0.5, 0.8, TIMBER)
	Kit.box(self, "Chimney", Vector3(5.6, top + 3.2, -D * 0.5 - 1.0), Vector3(0.8, 2.8, 0.8), PLASTER)
	Kit.box(self, "Flue", Vector3(6.4, top + 3.6, -D * 0.5 - 1.6), Vector3(0.3, 2.6, 0.3), Color("a8acb0"))
	var f := Kit.face(self, Vector3(0, 0, 0), 0.0)
	# begane grond: ramen en deuren
	for x in [-5.8, -1.6, 0.6, 2.6, 4.8]:
		_window(f, x, 0.8, 1.0, 2.2)
	Kit.box(f, "Green door", Vector3(-4.3, 1.15, 0.05), Vector3(0.95, 2.3, 0.06), Color("2f4a3e"))
	Kit.box(f, "Red door", Vector3(-0.5, 1.2, 0.05), Vector3(1.0, 2.4, 0.06), Color("7a1e24"))
	Kit.box(f, "Door light", Vector3(-0.5, 2.7, 0.05), Vector3(1.1, 0.5, 0.05), GLASS)
	# verdieping
	for x in [-4.4, -2.8, 0.3, 2.6, 3.9]:
		_window(f, x, H1 + 0.6, 0.9, 1.7)
	# stationsnaambord (blauw met witte letters)
	Kit.box(f, "Name sign", Vector3(-2.2, H1 + 0.25, 0.07), Vector3(3.6, 0.42, 0.05), Color("1d4f9c"))
	Kit.label(f, "Klimmen-Ransdaal", Vector3(-2.2, H1 + 0.25, 0.11), 0.0032, PLASTER, 64)
	# lantaarnpaal op het plein
	Kit.cyl(self, "Lamp post", Vector3(4.5, 2.6, 4.5), 0.08, 0.06, 5.2, Color("3a3c40"), 8)
	Kit.box(self, "Lamp", Vector3(4.5, 5.2, 4.5), Vector3(0.5, 0.3, 0.5), Color("3a3c40"))

# Topgevel naar voren met witte windveren, donker vakwerk en consoles.
func _front_gable(x: float, w: float, top: float) -> void:
	var rise := 3.4
	var z := 0.55
	var f := Kit.face(self, Vector3(x, 0, z), 0.0)
	var t: Array = [Vector3(-w * 0.5, top, 0.0), Vector3(w * 0.5, top, 0.0), Vector3(0, top + rise, 0.0)]
	var g := MeshInstance3D.new()
	g.mesh = Kit._mesh_from(t, Kit._two_sided(PLASTER))
	f.add_child(g)
	# overstek: kort dakje naar achteren zodat de gevel in het dak steekt
	Kit.gable(self, "Gable roof", Vector3(x, top, -1.2), w + 0.8, 3.6, rise, ROOF)
	# windveren (wit) en vakwerk (donker)
	var slope: float = atan2(rise, w * 0.5)
	var ln: float = sqrt(rise * rise + w * w * 0.25) + 0.6
	for s in [-1.0, 1.0]:
		var b := Kit.box(f, "Bargeboard", Vector3(s * w * 0.25, top + rise * 0.5, 0.3), Vector3(ln, 0.26, 0.08), FRAME)
		b.rotation.z = -s * slope
		var tb := Kit.box(f, "Gable timber", Vector3(s * w * 0.25, top + rise * 0.5 - 0.15, 0.04), Vector3(ln - 0.4, 0.16, 0.04), TIMBER)
		tb.rotation.z = -s * slope
	Kit.box(f, "Gable beam", Vector3(0, top + 0.05, 0.05), Vector3(w, 0.2, 0.06), TIMBER)
	Kit.box(f, "Gable beam", Vector3(0, top + 1.3, 0.05), Vector3(w * 0.6, 0.14, 0.05), TIMBER)
	for px in [-w * 0.32, w * 0.32]:
		Kit.box(f, "Gable post", Vector3(px, top + 0.65, 0.05), Vector3(0.14, 1.2, 0.05), TIMBER)
	Kit.box(f, "Gable window", Vector3(0, top + 0.7, 0.05), Vector3(1.6, 0.9, 0.04), FRAME)
	Kit.box(f, "Gable glass", Vector3(0, top + 0.7, 0.08), Vector3(1.4, 0.75, 0.03), GLASS)
	Kit.box(f, "Gable glass bar", Vector3(0, top + 0.7, 0.1), Vector3(0.05, 0.75, 0.02), FRAME)
	# houten consoles onder de gevel
	for px in [-w * 0.4, -w * 0.15, w * 0.15, w * 0.4]:
		Kit.box(f, "Console", Vector3(px, top - 0.2, 0.15), Vector3(0.16, 0.4, 0.3), TIMBER)

func _annex(c: Vector3) -> void:
	var w := 6.4
	var d := 7.4
	var h := 3.8
	Kit.box(self, "Annex", c + Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d), BRICK, true)
	Kit.box(self, "Annex plinth", c + Vector3(0, 0.3, -d * 0.5), Vector3(w + 0.1, 0.6, d + 0.1), Color("d4d2cc"))
	Kit.frustum(self, "Annex roof", c + Vector3(0, h, -d * 0.5), w + 0.8, d + 0.8, 2.6, 2.8, Color("5a3a30"))
	var f := Kit.face(self, c, 0.0)
	_window(f, -2.2, 0.8, 0.8, 2.2)
	_window(f, 2.2, 0.8, 0.8, 2.2)
	Kit.box(f, "Annex door", Vector3(0, 1.25, 0.05), Vector3(1.6, 2.5, 0.06), Color("2f4a3e"))
	Kit.box(f, "Annex door light", Vector3(0, 2.9, 0.05), Vector3(1.8, 0.6, 0.05), GLASS)
	Kit.box(f, "Annex band", Vector3(0, 3.35, 0.05), Vector3(w, 0.14, 0.06), Color("b8b4aa"))

# Perron met een abri en het spoor achter het gebouw.
func _platform() -> void:
	var z := -D - 3.0
	Kit.box(self, "Platform", Vector3(0, 0.4, z), Vector3(60.0, 0.8, 4.0), Color("a8a49c"), true)
	Kit.box(self, "Platform edge", Vector3(0, 0.81, z - 1.8), Vector3(60.0, 0.02, 0.3), Color("e8d24a"))
	Kit.box(self, "Shelter roof", Vector3(14, 3.2, z), Vector3(6.0, 0.12, 2.4), Color("dcdcd8"))
	for x in [11.5, 16.5]:
		Kit.box(self, "Shelter post", Vector3(x, 2.0, z + 0.9), Vector3(0.1, 2.4, 0.1), Color("3a3c40"))
	Kit.box(self, "Ballast", Vector3(0, 0.15, z - 4.6), Vector3(120.0, 0.3, 4.2), Color("7a746c"))
	for s in [-0.72, 0.72]:
		Kit.box(self, "Rail", Vector3(0, 0.38, z - 4.6 + s), Vector3(120.0, 0.12, 0.08), Color("6a6662"))
	for k in range(40):
		Kit.box(self, "Sleeper", Vector3(-58.5 + float(k) * 3.0, 0.3, z - 4.6), Vector3(0.25, 0.1, 2.4), Color("4a3e34"))
