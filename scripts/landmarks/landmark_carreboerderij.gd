extends Node3D
# Monumentale carréboerderij vlak voor de bebouwde kom van Simpelveld, naar jouw foto's
# (25-11). Een gesloten vierkant rond een binnenplaats, van gele mergel-/kalksteenblokken
# met oranjerode pannendaken:
# - links het woonhuis: hoge puntgevel naar de weg met een schoorsteen in de top, ramen in
#   brede omlijstingen van rode baksteen (ook een paar dichtgemetselde), een gedenksteen;
#   de lange zijgevel heeft twee rijen van vier ramen; daarachter een lagere stal
# - in het midden een lage poortvleugel met een rondboogpoort van baksteen en groene
#   houten deuren
# - rechts de grote schuur met een nog hogere puntgevel, een rond venstertje in de top en
#   een grote rondboogpoort met groene deuren; een geknipte haag in een boogvorm ernaast
# - achterin een dwarsvleugel die het vierkant sluit
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const ROOF := Color("c4603a")
const BRICK := Color("8a4636")
const GREEN := Color("2a4436")
const GLASS := Color("2c3236")

var stone: Material
var stone_2s: Material

func _ready() -> void:
	name = "Carreboerderij"
	stone = Kit.tex_mat("res://assets/kerk_rubble.png", Color("e8d29a"), 3.0)
	stone_2s = (stone as StandardMaterial3D).duplicate()
	stone_2s.cull_mode = BaseMaterial3D.CULL_DISABLED
	Kit.box(self, "Farm yard", Vector3(0, 0.03, -12), Vector3(44, 0.06, 40), Color("8a8078"))
	Kit.box(self, "Front paving", Vector3(2, 0.04, 3), Vector3(40, 0.06, 6), Color("9a8a7e"))
	_house(Vector3(-11, 0, 0))
	_gate_wing(Vector3(0, 0, 0))
	_barn(Vector3(12, 0, 0))
	# achtervleugel en binnenplaats
	Kit.box(self, "Back wing", Vector3(0, 2.6, -25), Vector3(14, 5.2, 7), Color.WHITE, true, stone)
	Kit.gable(self, "Back wing roof", Vector3(0, 5.2, -25), 7.6, 14.4, 3.0, ROOF, true)
	Kit.box(self, "Courtyard", Vector3(0, 0.06, -14), Vector3(12, 0.04, 14), Color("a8a49a"))
	# haag langs de weg voor het woonhuis, geknipte boog naast de schuur
	Kit.box(self, "Hedge", Vector3(-22, 0.9, -8), Vector3(1.4, 1.8, 26), Color("3f6a32"))
	for sx in [-1.0, 1.0]:
		Kit.box(self, "Topiary leg", Vector3(20.5 + sx * 1.2, 1.2, 1.0), Vector3(0.9, 2.4, 1.6), Color("3f6a32"))
	Kit.box(self, "Topiary arch", Vector3(20.5, 2.7, 1.0), Vector3(3.3, 0.9, 1.6), Color("3f6a32"))

func _gable_end(f: Node3D, w: float, y0: float, rise: float) -> void:
	var t: Array = [Vector3(-w * 0.5, y0, 0.0), Vector3(w * 0.5, y0, 0.0), Vector3(0, y0 + rise, 0.0)]
	var g := MeshInstance3D.new()
	g.mesh = Kit._mesh_from(t, stone_2s)
	f.add_child(g)

# Raam in een brede omlijsting van rode baksteen (blind = dichtgemetseld).
func _window(f: Node3D, x: float, y: float, w := 0.9, h := 1.3, blind := false) -> void:
	Kit.box(f, "Brick surround", Vector3(x, y + h * 0.5, 0.03), Vector3(w + 0.55, h + 0.5, 0.06), BRICK)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5, 0.07), Vector3(w, h, 0.03), Color("d8c69a") if blind else Color("f0f0ea"))
	if not blind:
		Kit.box(f, "Glass", Vector3(x, y + h * 0.5, 0.09), Vector3(w - 0.14, h - 0.14, 0.02), GLASS)
		Kit.box(f, "Window bar", Vector3(x, y + h * 0.6, 0.11), Vector3(w - 0.14, 0.05, 0.02), Color("f0f0ea"))
	Kit.box(f, "Sill", Vector3(x, y - 0.05, 0.1), Vector3(w + 0.4, 0.1, 0.15), Color("b8b0a0"))

# Rondboogpoort met bakstenen boog en groene deuren.
func _arch_gate(f: Node3D, x: float, w: float, h: float) -> void:
	var r: float = w * 0.5
	Kit.cyl(f, "Brick arch", Vector3(x, h - r, 0.02), r + 0.35, r + 0.35, 0.05, BRICK, 18, "z")
	Kit.box(f, "Gate", Vector3(x, (h - r) * 0.5, 0.05), Vector3(w, h - r, 0.05), GREEN)
	Kit.cyl(f, "Gate top", Vector3(x, h - r, 0.05), r, r, 0.05, GREEN, 18, "z")
	Kit.box(f, "Gate seam", Vector3(x, (h - r) * 0.5 + 0.3, 0.09), Vector3(0.05, h - 0.4, 0.02), Color("1e3028"))

func _house(c: Vector3) -> void:
	var w := 10.0
	var front_d := 13.0
	var h := 7.6
	Kit.box(self, "Farmhouse", c + Vector3(0, h * 0.5, -front_d * 0.5), Vector3(w, h, front_d), Color.WHITE, true, stone)
	Kit.gable(self, "Farmhouse roof", c + Vector3(0, h, -front_d * 0.5), w + 0.8, front_d + 0.6, 5.0, ROOF)
	var f := Kit.face(self, c, 0.0)
	_gable_end(f, w, h, 5.0)
	Kit.box(f, "Chimney", Vector3(0, h + 5.2, -0.3), Vector3(0.9, 1.0, 0.7), BRICK)
	_window(f, -2.6, 1.2, 1.1, 1.6, true)
	_window(f, 1.2, 1.0, 0.9, 1.4)
	_window(f, -2.6, 4.2, 1.1, 1.4, true)
	_window(f, 1.2, 4.0, 0.9, 1.4)
	_window(f, 0.0, 7.6, 0.6, 1.0)
	Kit.box(f, "Memorial stone", Vector3(-0.8, 2.6, 0.05), Vector3(0.8, 0.5, 0.05), Color("dcd8cc"))
	# lange zijgevel naar links (zichtbaar vanaf de weg): twee rijen van vier ramen
	var sf := Kit.face(self, c + Vector3(-w * 0.5, 0, -front_d * 0.5), -90.0)
	for x in [-4.5, -1.5, 1.5, 4.5]:
		_window(sf, x, 1.0)
		_window(sf, x, 4.0)
	# lagere stal erachter
	var sc: Vector3 = c + Vector3(0, 0, -front_d - 7.5)
	Kit.box(self, "Stable", sc + Vector3(0, 2.6, 0), Vector3(w - 1.0, 5.2, 15.0), Color.WHITE, true, stone)
	Kit.gable(self, "Stable roof", sc + Vector3(0, 5.2, 0), w - 0.2, 15.4, 3.2, ROOF)

func _gate_wing(c: Vector3) -> void:
	var w := 14.0
	var d := 7.0
	var h := 4.4
	Kit.box(self, "Gate wing", c + Vector3(0, h * 0.5, -d * 0.5 - 0.3), Vector3(w, h, d), Color.WHITE, true, stone)
	Kit.gable(self, "Gate wing roof", c + Vector3(0, h, -d * 0.5 - 0.3), d + 1.2, w + 0.4, 3.0, ROOF, true)
	var f := Kit.face(self, c + Vector3(0, 0, -0.3), 0.0)
	_arch_gate(f, -3.6, 3.0, 3.6)
	Kit.box(f, "Name stone", Vector3(3.5, 1.8, 0.05), Vector3(0.9, 0.5, 0.05), Color("dcd8cc"))
	for x in [-1.5, 1.5]:
		Kit.box(self, "Roof light", c + Vector3(x, h + 1.4, -0.5), Vector3(0.5, 0.05, 0.4), Color("cfd6da"))

func _barn(c: Vector3) -> void:
	var w := 10.0
	var d := 28.0
	var h := 7.2
	Kit.box(self, "Barn", c + Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, d), Color.WHITE, true, stone)
	Kit.gable(self, "Barn roof", c + Vector3(0, h, -d * 0.5), w + 0.8, d + 0.6, 6.4, ROOF)
	var f := Kit.face(self, c, 0.0)
	_gable_end(f, w, h, 6.4)
	_arch_gate(f, 0.0, 3.8, 5.0)
	Kit.cyl(f, "Oculus rim", Vector3(0, h + 3.6, 0.03), 0.42, 0.42, 0.06, BRICK, 14, "z")
	Kit.cyl(f, "Oculus", Vector3(0, h + 3.6, 0.07), 0.28, 0.28, 0.04, GLASS, 14, "z")
	var sf := Kit.face(self, c + Vector3(w * 0.5, 0, -d * 0.5), 90.0)
	for x in [-8.0, -2.0, 4.0]:
		_window(sf, x, 1.6, 0.7, 0.9)
	for x in [-6.0, 2.0, 9.0]:
		Kit.box(self, "Roof light", c + Vector3(w * 0.25, h + 2.6, -d * 0.5 + x), Vector3(0.05, 0.4, 0.5), Color("cfd6da"))
