extends Node3D
# Steakhouse Dalmacija aan het Lindeplein (Brunssum), naar jouw foto's (24-11), een stukje
# naast de Brikke Oave. Smal pand van donkerbruine baksteen met drie lagen brede ramen in
# witte kozijnen en een pannenrandje bovenaan; op de begane grond een rode luifelband met de
# borden "Steakhouse" en "Dalmacija", ramen met matglas onderin, de deur, en ervoor een klein
# terras met grijze plantenbakken, een tafeltje en stoelen. Links ervan (richting de Brikke
# Oave) een pand van rode baksteen met een winkel achter een grijze gevel.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const DARK_BRICK := Color("4e3b33")
const RED_BRICK := Color("8a4a3a")
const RED := Color("b8202a")
const WHITE := Color("f0eee8")
const GLASS := Color("2e3a42")

func _ready() -> void:
	name = "Steakhouse Dalmacija"
	Kit.box(self, "Pavement", Vector3(-5, 0.02, 2.0), Vector3(20, 0.04, 4.0), Color("a87060"))
	_steakhouse()
	_neighbour()

func _window(f: Node3D, x: float, y: float, w: float, h: float, frame: Color) -> void:
	Kit.box(f, "Window frame", Vector3(x, y, 0.03), Vector3(w + 0.25, h + 0.25, 0.06), frame)
	Kit.box(f, "Window", Vector3(x, y, 0.07), Vector3(w, h, 0.04), GLASS)
	Kit.box(f, "Window bar", Vector3(x, y + h * 0.18, 0.1), Vector3(w, 0.08, 0.03), frame)
	Kit.box(f, "Window mullion", Vector3(x, y, 0.1), Vector3(0.08, h, 0.03), frame)

func _steakhouse() -> void:
	var c := Vector3(0, 0, -6)
	var w := 10.0
	var d := 12.0
	var h := 10.5
	Kit.box(self, "Steakhouse", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), DARK_BRICK, true)
	# pannenrandje (mansarde) bovenaan en een daklijst
	Kit.frustum(self, "Steakhouse roof", c + Vector3(0, h, 0), w + 0.4, d + 0.4, 0.8, 1.6, Color("5a3a30"))
	var f := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	# twee verdiepingen met brede witte ramen (onderste rij met een smal klapraam bovenin)
	for row in [[5.6, 1.9], [8.4, 1.7]]:
		_window(f, -2.4, row[0], 3.6, row[1], WHITE)
		_window(f, 2.4, row[0], 3.6, row[1], WHITE)
		for s in [-1.0, 1.0]:
			Kit.box(f, "Curtain", Vector3(s * 2.4, row[0] - 0.1, 0.09), Vector3(3.2, row[1] * 0.7, 0.02), Color("e8e4dc"))
	# rode luifelband met de twee borden
	Kit.box(f, "Red fascia", Vector3(0, 3.6, 0.25), Vector3(w + 0.2, 0.7, 0.5), RED)
	Kit.box(f, "Red awning", Vector3(0, 3.15, 0.55), Vector3(w + 0.2, 0.2, 1.1), Color("a01c24"))
	for b in [[-2.7, "Steakhouse"], [2.7, "Dalmacija"]]:
		Kit.box(f, "Sign board", Vector3(b[0], 4.35, 0.12), Vector3(4.0, 0.7, 0.1), RED)
		Kit.box(f, "Sign rim", Vector3(b[0], 4.35, 0.08), Vector3(4.15, 0.85, 0.06), Color("e8e4dc"))
		Kit.label(f, b[1], Vector3(b[0], 4.35, 0.2), 0.01, WHITE, 64)
	Kit.label(f, "Steakhouse", Vector3(-3.0, 3.6, 0.52), 0.005, WHITE, 64)
	Kit.label(f, "Dalmacija", Vector3(3.4, 3.6, 0.52), 0.005, WHITE, 64)
	# een verticaal reclamebord op de hoek
	Kit.box(f, "Vertical sign", Vector3(-4.7, 6.8, 0.4), Vector3(0.25, 3.0, 0.7), RED)
	# begane grond: ramen met matglas onderin en de deur
	for x in [0.8, 3.6]:
		Kit.box(f, "Shop window", Vector3(x, 1.65, 0.04), Vector3(2.4, 2.5, 0.05), GLASS)
		Kit.box(f, "Frosted glass", Vector3(x, 1.0, 0.07), Vector3(2.4, 1.0, 0.03), Color("c8ccce"))
		Kit.box(f, "Shop frame", Vector3(x, 1.65, 0.03), Vector3(2.6, 2.7, 0.04), WHITE)
	Kit.box(f, "Door frame", Vector3(-2.6, 1.3, 0.03), Vector3(1.6, 2.6, 0.05), WHITE)
	Kit.box(f, "Door", Vector3(-2.6, 1.25, 0.06), Vector3(1.2, 2.4, 0.04), Color("3a3430"))
	Kit.box(f, "Side window", Vector3(-4.3, 1.65, 0.04), Vector3(0.9, 2.4, 0.05), GLASS)
	# terras: grijze plantenbakken met groen, een tafeltje met stoelen, een stoepbord
	for x in [1.0, 2.4, 3.8]:
		Kit.box(self, "Terrace planter", Vector3(x, 0.4, 1.0), Vector3(1.3, 0.8, 0.6), Color("4a4c50"))
		Kit.box(self, "Planter green", Vector3(x, 0.9, 1.0), Vector3(1.2, 0.25, 0.5), Color("5a7a3a"))
	Kit.box(self, "Planter", Vector3(-4.0, 0.4, 1.0), Vector3(1.0, 0.8, 0.6), Color("4a4c50"))
	Kit.box(self, "Planter green", Vector3(-4.0, 0.9, 1.0), Vector3(0.9, 0.25, 0.5), Color("5a7a3a"))
	Kit.box(self, "Terrace table", Vector3(-1.2, 0.72, 1.4), Vector3(0.9, 0.06, 0.9), Color("8a6a4a"))
	Kit.box(self, "Table leg", Vector3(-1.2, 0.36, 1.4), Vector3(0.1, 0.72, 0.1), Color("3a3a3a"))
	for s in [-1.0, 1.0]:
		Kit.box(self, "Chair", Vector3(-1.2 + s * 0.8, 0.45, 1.4), Vector3(0.5, 0.9, 0.5), Color("6a4a32"))
	Kit.box(self, "Sandwich board", Vector3(-3.0, 0.5, 2.2), Vector3(0.7, 1.0, 0.25), Color("2a2a2a"))

func _neighbour() -> void:
	var c := Vector3(-10, 0, -6)
	var w := 10.0
	var d := 12.0
	var h := 9.0
	Kit.box(self, "Red brick house", c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), RED_BRICK, true)
	Kit.box(self, "Red brick roof edge", c + Vector3(0, h + 0.1, 0), Vector3(w + 0.2, 0.25, d + 0.2), Color("6a6c70"))
	var f := Kit.face(self, c + Vector3(0, 0, d * 0.5), 0.0)
	# grijze gevelplaten op de begane grond met een winkelpui
	Kit.box(f, "Grey cladding", Vector3(0, 1.6, 0.04), Vector3(w, 3.2, 0.08), Color("6e7074"))
	Kit.box(f, "Shop window", Vector3(1.0, 1.4, 0.1), Vector3(5.5, 2.4, 0.05), GLASS)
	Kit.box(f, "Shop door", Vector3(-3.0, 1.2, 0.1), Vector3(1.2, 2.3, 0.05), Color("3a3c40"))
	for y in [4.8, 7.4]:
		for x in [-2.8, 0.0, 2.8]:
			_window(f, x, y, 2.0, 1.5, Color("9a9ca0"))
