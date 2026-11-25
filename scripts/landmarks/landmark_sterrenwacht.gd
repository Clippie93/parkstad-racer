extends Node3D
# Sterrenwacht op de Brunssummerheide, naar jouw foto (20-11): een laag, beige gebouw met
# een plat dak tegen de bosrand; rechts een hoger blok met de witte koepel (met de donkere
# kijkspleet) en twee ronde patrijspoorten; links een glazen uitbouw met witte en
# lichtblauwe kozijnen; ervoor twee witte vlaggenmasten, links een witte schotelantenne,
# een haag en een grasveld.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const BEIGE := Color("cbc4b2")
const FRAME := Color("e8ecf0")
const BLUE := Color("8aa3c4")
const GLASS := Color("33404e")

func _ready() -> void:
	name = "Sterrenwacht"
	Kit.box(self, "Lawn", Vector3(0, 0.02, 3.0), Vector3(26.0, 0.04, 18.0), Color("4a7436"))
	# laag hoofdgebouw met plat dak en daktrim
	Kit.box(self, "Main block", Vector3(1.0, 1.7, -3.0), Vector3(12.0, 3.4, 7.0), BEIGE, true)
	Kit.box(self, "Roof trim", Vector3(1.0, 3.45, -3.0), Vector3(12.2, 0.15, 7.2), Color("b8b19e"))
	Kit.box(self, "Roof unit", Vector3(-1.0, 3.8, -4.0), Vector3(1.4, 0.6, 1.0), Color("9a958a"))
	# koepelblok rechts, iets hoger, met patrijspoorten
	var t := Vector3(5.2, 0, -1.6)
	Kit.box(self, "Dome block", t + Vector3(0, 2.2, 0), Vector3(4.6, 4.4, 4.6), BEIGE, true)
	Kit.box(self, "Dome block trim", t + Vector3(0, 4.45, 0), Vector3(4.8, 0.12, 4.8), Color("b8b19e"))
	for x in [-1.0, 1.0]:
		Kit.cyl(self, "Porthole frame", t + Vector3(x, 2.4, 2.31), 0.55, 0.55, 0.08, FRAME, 18, "z")
		Kit.cyl(self, "Porthole", t + Vector3(x, 2.4, 2.36), 0.42, 0.42, 0.06, GLASS, 18, "z")
		Kit.box(self, "Porthole bar", t + Vector3(x, 2.4, 2.4), Vector3(0.06, 0.84, 0.03), FRAME)
	# witte koepel met donkere kijkspleet
	var dome := MeshInstance3D.new()
	dome.name = "Dome"
	var sm := SphereMesh.new()
	sm.radius = 1.9
	sm.height = 1.9
	sm.is_hemisphere = true
	sm.radial_segments = 24
	sm.rings = 8
	dome.mesh = sm
	dome.material_override = Kit.mat(Color("f2f2ee"))
	dome.position = t + Vector3(0, 4.5, 0)
	add_child(dome)
	Kit.cyl(self, "Dome ring", t + Vector3(0, 4.55, 0), 1.95, 1.95, 0.12, Color("d8d8d2"), 24)
	var slit := Kit.box(self, "Dome slit", t + Vector3(0, 5.65, 0.75), Vector3(0.55, 0.06, 2.4), Color("2a2e33"))
	slit.rotation.x = -0.6
	var slit2 := Kit.box(self, "Dome slit top", t + Vector3(0, 6.35, -0.2), Vector3(0.55, 0.06, 1.2), Color("2a2e33"))
	slit2.rotation.x = 0.0
	# glazen uitbouw links met witte en lichtblauwe kozijnen
	var g := Vector3(-3.0, 0, 2.0)
	var gw := 9.0
	var gd := 3.6
	var gh := 2.7
	Kit.box(self, "Glass room", g + Vector3(0, gh * 0.5, 0), Vector3(gw, gh, gd), GLASS, true)
	Kit.box(self, "Glass room roof", g + Vector3(0, gh + 0.08, 0), Vector3(gw + 0.2, 0.16, gd + 0.2), FRAME)
	Kit.box(self, "Glass room sill", g + Vector3(0, 0.15, 0), Vector3(gw + 0.1, 0.3, gd + 0.1), FRAME)
	var n: int = int(gw / 0.75)
	for k in range(n + 1):
		var x: float = -gw * 0.5 + float(k) * gw / float(n)
		Kit.box(self, "Glass mullion", g + Vector3(x, gh * 0.5, gd * 0.5 + 0.02), Vector3(0.09, gh, 0.06), FRAME if k % 2 == 0 else BLUE)
	for k in range(5):
		var z: float = -gd * 0.5 + float(k) * gd / 4.0
		Kit.box(self, "Glass mullion side", g + Vector3(-gw * 0.5 - 0.02, gh * 0.5, z), Vector3(0.06, gh, 0.09), FRAME)
	Kit.box(self, "Glass transom", g + Vector3(0, gh - 0.35, gd * 0.5 + 0.03), Vector3(gw, 0.08, 0.06), BLUE)
	# lager glazen portaal helemaal links
	var e := Vector3(-8.6, 0, 2.6)
	Kit.box(self, "Entrance", e + Vector3(0, 1.1, 0), Vector3(2.2, 2.2, 2.6), GLASS, true)
	Kit.box(self, "Entrance roof", e + Vector3(0, 2.25, 0), Vector3(2.4, 0.12, 2.8), FRAME)
	for x in [-1.05, 0.0, 1.05]:
		Kit.box(self, "Entrance frame", e + Vector3(x, 1.1, 1.32), Vector3(0.08, 2.2, 0.05), FRAME)
	# twee witte vlaggenmasten en een schotelantenne
	for x in [-11.0, -9.6]:
		Kit.cyl(self, "Flag pole", Vector3(x, 3.5, 5.0), 0.06, 0.04, 7.0, Color("f2f2ee"), 6)
	Kit.box(self, "Dish post", Vector3(-12.2, 0.8, 0.8), Vector3(0.18, 1.6, 0.18), Color("9a9a96"))
	var dish := Kit.cyl(self, "Dish", Vector3(-12.2, 1.9, 1.0), 1.0, 0.6, 0.25, Color("eeeeea"), 16, "z")
	dish.rotation_degrees = Vector3(70, 30, 0)
	# haag rechts en het bos erachter (bomen komen van het level)
	Kit.box(self, "Hedge", Vector3(9.6, 0.65, 2.4), Vector3(2.6, 1.3, 2.0), Color("3f5f30"))
