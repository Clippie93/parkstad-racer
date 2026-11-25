extends Node3D
# Kasteel Puth, Voerendaal (Klimmen). Naar jouw foto's (20-11):
# - langs de weg een lange poortschuur van rode baksteen met een pannendak; in het midden
#   een poortpaviljoen met een puntgevel (natuurstenen afdekking, rond venster met
#   stenen omlijsting) boven een grote korfboog op natuurstenen pilasters; in de
#   doorgang een smeedijzeren hek
# - rechts van de poort schietgaten in mergelstenen blokken en muurankers, links kleine
#   rondboogvensters en ovale gaten, aan beide uiteinden een lager bijgebouw (links met
#   rondbogen, rechts met garagedeuren)
# - achter de binnenplaats het herenhuis in de gracht: twee lagen rode baksteen tussen
#   brede natuurstenen pilasters, vijf traveeën met getoogde witte vensters, een witte
#   voordeur met trap, een leien mansardedak met vijf dakkapellen; een natuurstenen
#   voet in het water en een bakstenen brug met borstwering
# Lokale ruimte: +Z = weg.
const Kit = preload("res://scripts/build_kit.gd")

const STONE := Color("c9c3b4")
const MARL := Color("d8cca4")
const TILES := Color("53554d")
const SLATE := Color("4d5058")
const GLASS := Color("2c3438")
const FRAME := Color("f0eee8")
const IRON := Color("1f2021")

var brick: Material

func _ready() -> void:
	name = "Kasteel Puth"
	brick = Kit.tex_mat("res://assets/on_brick.png", Color("dcc0b4"), 3.0)
	_gate_barn()
	_manor()
	# binnenplaats met grind en gras
	Kit.box(self, "Courtyard", Vector3(0, 0.04, -16.0), Vector3(50.0, 0.08, 14.0), Color("8f887a"))

# ---------------------------------------------------------------- hulpjes
func _mesh(parent: Node3D, n: String, tris: Array, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = Kit._mesh_from(tris, m)
	parent.add_child(mi)
	return mi

# Zadeldak zonder kopse driehoeken. Nok langs Z, of langs X met along_x.
func _roof(n: String, base: Vector3, width: float, length: float, rise: float, along_x: bool, color: Color) -> void:
	var hw: float = width * 0.5
	var hl: float = length * 0.5
	var t: Array = []
	Kit._quad(t, Vector3(-hw, 0, -hl), Vector3(-hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	Kit._quad(t, Vector3(hw, 0, -hl), Vector3(hw, 0, hl), Vector3(0, rise, hl), Vector3(0, rise, -hl))
	var mi := _mesh(self, n, t, Kit._two_sided(color))
	mi.position = base
	if along_x:
		mi.rotation_degrees.y = 90.0

# Bakstenen geveltop met natuurstenen afdekking, in face-ruimte.
func _gable(f: Node3D, y: float, w: float, rise: float) -> void:
	var hw: float = w * 0.5
	_mesh(f, "Gable", [Vector3(hw, y, 0), Vector3(-hw, y, 0), Vector3(0, y + rise, 0)], brick)
	for s in [-1.0, 1.0]:
		Kit.beam(f, "Gable coping", Vector3(s * (hw + 0.1), y - 0.1, 0.2), Vector3(0, y + rise + 0.15, 0.2), 0.4, STONE)
		Kit.box(f, "Gable kneeler", Vector3(s * (hw - 0.1), y + 0.1, 0.2), Vector3(0.7, 0.4, 0.5), STONE)

# Schietgat: mergelstenen blok met een zwarte sleutelgatvormige spleet.
func _loophole(f: Node3D, x: float, y: float) -> void:
	Kit.box(f, "Loophole stone", Vector3(x, y, 0.04), Vector3(0.8, 1.0, 0.1), MARL)
	Kit.box(f, "Loophole slit", Vector3(x, y - 0.05, 0.1), Vector3(0.12, 0.65, 0.03), Color("151515"))
	Kit.box(f, "Loophole cross", Vector3(x, y + 0.08, 0.1), Vector3(0.32, 0.1, 0.03), Color("151515"))
	Kit.cyl(f, "Loophole hole", Vector3(x, y - 0.35, 0.1), 0.1, 0.1, 0.03, Color("151515"), 8, "z")

# ---------------------------------------------------------------- poortschuur
func _gate_barn() -> void:
	var wall_h := 6.0
	var depth := 10.0
	var zc: float = -depth * 0.5
	# hoofdschuur links en rechts van de poort
	# links en rechts van het poortpaviljoen (de doorgang blijft open)
	for s in [-1.0, 1.0]:
		var cx: float = s * (26.0 + 4.5) * 0.5
		Kit.box(self, "Gate barn", Vector3(cx, wall_h * 0.5, zc), Vector3(21.5, wall_h, depth), Color.WHITE, true, brick)
		Kit.box(self, "Gutter", Vector3(cx + s * 0.2, wall_h - 0.15, 0.6), Vector3(21.9, 0.18, 0.2), Color("6a6c6e"))
		Kit.box(self, "Eaves stone", Vector3(cx, wall_h - 0.35, 0.06), Vector3(21.5, 0.3, 0.14), STONE)
	_roof("Gate barn roof", Vector3(0, wall_h - 0.1, zc), depth + 1.2, 52.4, 5.0, true, TILES)
	for s in [-1.0, 1.0]:
		var ef := Kit.face(self, Vector3(s * 26.0, 0, zc), 90.0 * s)
		_gable(ef, wall_h, depth, 5.0)
		Kit.box(self, "Downpipe", Vector3(s * 4.9, wall_h * 0.5, 0.15), Vector3(0.14, wall_h, 0.14), Color("6a6c6e"))
	var f := Kit.face(self, Vector3(0, 0, 0), 0.0)
	# rechts: schietgaten en muurankers
	for x in [7.5, 10.5, 13.5, 16.5, 19.0, 21.0, 23.0]:
		_loophole(f, x, 1.6)
	for x in [8.5, 13.0, 18.0, 22.0]:
		Kit.box(f, "Wall anchor", Vector3(x, 3.6, 0.06), Vector3(0.08, 0.7, 0.05), IRON)
	# links: kleine rondboogvensters en ovale gaten
	for k in range(9):
		var x: float = -6.5 - float(k) * 2.1
		if k % 3 == 1:
			Kit.box(f, "Low window", Vector3(x, 1.65, 0.05), Vector3(1.1, 0.5, 0.06), GLASS)
			Kit.cyl(f, "Low window arch", Vector3(x, 1.9, 0.05), 0.55, 0.55, 0.06, GLASS, 12, "z")
			Kit.box(f, "Low window plug", Vector3(x, 1.65, 0.0), Vector3(1.3, 0.5, 0.02), Color("8a5848"))
			Kit.box(f, "Low window sill", Vector3(x, 1.3, 0.08), Vector3(1.3, 0.12, 0.16), STONE)
		else:
			var ov := Kit.cyl(f, "Oval vent stone", Vector3(x, 1.8, 0.05), 0.35, 0.35, 0.06, MARL, 10, "z")
			ov.scale = Vector3(1.0, 1.0, 1.4)
			var oh := Kit.cyl(f, "Oval vent", Vector3(x, 1.8, 0.08), 0.18, 0.18, 0.04, Color("151515"), 10, "z")
			oh.scale = Vector3(1.0, 1.0, 1.6)
	for x in [-9.0, -14.0]:
		Kit.box(f, "Wall anchor", Vector3(x, 3.6, 0.06), Vector3(0.08, 0.7, 0.05), IRON)
	# poortpaviljoen: iets naar voren, hogere puntgevel, grote korfboog
	var pw := 9.0
	var aw := 5.0
	var spring := 3.8
	var ph: float = wall_h + 0.6
	for s in [-1.0, 1.0]:
		Kit.box(self, "Gate pier", Vector3(s * (aw + pw) * 0.25, ph * 0.5, -depth * 0.5 + 0.2), Vector3((pw - aw) * 0.5, ph, depth + 0.4), Color.WHITE, true, brick)
	Kit.box(self, "Gate top", Vector3(0, (spring + ph) * 0.5, -depth * 0.5 + 0.2), Vector3(aw, ph - spring, depth + 0.4), Color.WHITE, true, brick)
	Kit.box(self, "Passage ceiling", Vector3(0, spring - 0.02, -depth * 0.5 + 0.2), Vector3(aw, 0.04, depth + 0.3), Color("2a2522"))
	_roof("Gate pavilion roof", Vector3(0, wall_h + 0.5, -depth * 0.5 + 0.2), pw + 0.8, depth + 0.6, 5.2, false, TILES)
	var pf := Kit.face(self, Vector3(0, 0, 0.4), 0.0)
	_gable(pf, wall_h + 0.6, pw, 5.0)
	Kit.cyl(pf, "Oculus frame", Vector3(0, wall_h + 2.6, 0.05), 0.85, 0.85, 0.1, STONE, 18, "z")
	Kit.cyl(pf, "Oculus", Vector3(0, wall_h + 2.6, 0.1), 0.6, 0.6, 0.06, GLASS, 18, "z")
	for k in range(4):
		var bar := Kit.box(pf, "Oculus bar", Vector3(0, wall_h + 2.6, 0.14), Vector3(1.2, 0.06, 0.03), IRON)
		bar.rotation.z = float(k) * PI * 0.25
	Kit.box(pf, "Gable cornice", Vector3(0, wall_h + 0.5, 0.15), Vector3(pw + 0.3, 0.3, 0.3), STONE)
	# korfboog: donkere doorgang, natuurstenen boog en pilasters met kapiteel
	# donkere halve ellips van de boog boven de doorgang
	var fan: Array = []
	for k in range(16):
		var a0: float = PI * float(k) / 16.0
		var a1: float = PI * float(k + 1) / 16.0
		fan.append_array([Vector3(0, spring, 0.02), Vector3(cos(a1) * aw * 0.5, spring + sin(a1) * aw * 0.31, 0.02), Vector3(cos(a0) * aw * 0.5, spring + sin(a0) * aw * 0.31, 0.02)])
	_mesh(pf, "Passage arch", fan, Kit._two_sided(Color("2a2522")))
	for k in range(13):
		var a: float = PI * (float(k) + 0.5) / 13.0
		var p := Vector3(cos(a) * (aw * 0.5 + 0.3), spring + sin(a) * (aw * 0.5 + 0.3) * 0.62, 0.08)
		var v := Kit.box(pf, "Arch stone", p, Vector3(0.6, 0.62, 0.16), STONE)
		v.rotation.z = atan2(sin(a) * 0.62, cos(a) * 1.0)
	for s in [-1.0, 1.0]:
		Kit.box(pf, "Pilaster", Vector3(s * (aw * 0.5 + 0.45), spring * 0.5, 0.1), Vector3(0.9, spring, 0.25), STONE)
		Kit.box(pf, "Capital", Vector3(s * (aw * 0.5 + 0.45), spring + 0.15, 0.15), Vector3(1.15, 0.3, 0.35), STONE)
		Kit.box(pf, "Bollard", Vector3(s * (aw * 0.5 + 0.2), 0.3, 0.5), Vector3(0.45, 0.6, 0.45), Color("9a958c"))
	# doorgang met kasseien en het smeedijzeren hek halverwege
	Kit.box(self, "Passage floor", Vector3(0, 0.05, -depth * 0.5 + 0.5), Vector3(aw, 0.1, depth + 2.0), Color("7a756c"))
	for s in [-1.0, 1.0]:
		Kit.box(self, "Passage wall", Vector3(s * aw * 0.5, spring * 0.5, -depth * 0.5), Vector3(0.05, spring, depth), Color("6a4438"))
	var gz: float = -4.0
	Kit.box(self, "Gate rail", Vector3(0, 0.3, gz), Vector3(aw, 0.06, 0.06), IRON)
	Kit.box(self, "Gate rail", Vector3(0, 2.2, gz), Vector3(aw, 0.06, 0.06), IRON)
	for k in range(26):
		var x: float = -aw * 0.5 + 0.1 + float(k) * (aw - 0.2) / 25.0
		var h: float = 2.6 + absf(x) * 0.12
		Kit.box(self, "Gate bar", Vector3(x, h * 0.5, gz), Vector3(0.04, h, 0.04), IRON)
		Kit.box(self, "Gate spike", Vector3(x, h + 0.08, gz), Vector3(0.09, 0.16, 0.09), IRON)
	Kit.box(self, "Gate lantern", Vector3(0, spring + 0.7, -1.5), Vector3(0.4, 0.6, 0.4), IRON)
	# lagere bijgebouwen aan beide uiteinden
	var lw := 9.0
	Kit.box(self, "Annex L", Vector3(-26.0 - lw * 0.5, 1.8, -4.0), Vector3(lw, 3.6, 8.0), Color.WHITE, true, brick)
	_roof("Annex L roof", Vector3(-26.0 - lw * 0.5, 3.5, -4.0), 9.0, lw + 0.4, 2.6, true, Color("5b6150"))
	var al := Kit.face(self, Vector3(-26.0 - lw * 0.5, 0, 0.0), 0.0)
	for k in range(4):
		var x: float = -3.2 + float(k) * 2.1
		Kit.box(al, "Annex arch", Vector3(x, 1.2, 0.04), Vector3(0.8, 1.2, 0.05), Color("2a2522"))
		Kit.cyl(al, "Annex arch top", Vector3(x, 1.8, 0.04), 0.4, 0.4, 0.05, Color("2a2522"), 10, "z")
	Kit.box(self, "Annex R", Vector3(26.0 + lw * 0.5, 1.8, -4.0), Vector3(lw, 3.6, 8.0), Color.WHITE, true, brick)
	_roof("Annex R roof", Vector3(26.0 + lw * 0.5, 3.5, -4.0), 9.0, lw + 0.4, 2.6, true, Color("5b6150"))
	var ar := Kit.face(self, Vector3(26.0 + lw * 0.5, 0, 0.0), 0.0)
	for k in range(3):
		Kit.box(ar, "Garage door", Vector3(-2.6 + float(k) * 2.6, 1.2, 0.05), Vector3(1.6, 2.4, 0.06), Color("4a4a48"))
		Kit.box(ar, "Garage pier", Vector3(-3.9 + float(k) * 2.6, 1.6, 0.1), Vector3(0.6, 3.2, 0.2), MARL)
	# haag en tuinmuur verder rechts
	Kit.box(self, "Hedge", Vector3(36.5 + 4.0, 0.9, -1.0), Vector3(8.0, 1.8, 1.2), Color("3f5f30"))

# ---------------------------------------------------------------- herenhuis
func _manor() -> void:
	var c := Vector3(0, 0, -42.0)
	var w := 20.0
	var d := 12.0
	var base := 1.6          # natuurstenen voet in de gracht
	var wall_h := 8.6
	# gracht rondom en natuurstenen voet
	Kit.box(self, "Moat", c + Vector3(0, 0.05, -2.0), Vector3(40.0, 0.1, 30.0), Color("3f5650"))
	Kit.box(self, "Manor base", c + Vector3(0, base * 0.5 - 0.3, 0), Vector3(w + 2.0, base + 0.6, d + 2.0), STONE, true)
	Kit.box(self, "Terrace", c + Vector3(0, base + 0.02, d * 0.5 + 0.6), Vector3(w + 2.0, 0.08, 1.4), Color("9f978a"))
	Kit.box(self, "Manor", c + Vector3(0, base + wall_h * 0.5, 0), Vector3(w, wall_h, d), Color.WHITE, true, brick)
	Kit.box(self, "Manor cornice", c + Vector3(0, base + wall_h + 0.15, 0), Vector3(w + 0.6, 0.35, d + 0.6), STONE)
	# mansardedak: steil onderschild met dakkapellen, flauw bovenschild
	Kit.frustum(self, "Mansard", c + Vector3(0, base + wall_h + 0.3, 0), w + 0.4, d + 0.4, 1.2, 3.4, SLATE)
	Kit.frustum(self, "Mansard top", c + Vector3(0, base + wall_h + 3.7, 0), w - 2.0, d - 2.0, (d - 2.0) * 0.5, 1.6, Color("5a5d64"))
	Kit.box(self, "Chimney", c + Vector3(w * 0.5 - 1.2, base + wall_h + 5.0, -2.0), Vector3(0.9, 2.2, 0.9), Color("6e4a40"))
	for s in [-1.0, 1.0]:
		var f := Kit.face(self, c + Vector3(0, base, s * d * 0.5), 0.0 if s > 0.0 else 180.0)
		# brede natuurstenen pilasters op de hoeken en naast de middentravee
		for px in [-w * 0.5 + 0.6, -2.6, 2.6, w * 0.5 - 0.6]:
			Kit.box(f, "Pilaster", Vector3(px, wall_h * 0.5, 0.08), Vector3(1.2 if absf(px) > 5.0 else 0.8, wall_h, 0.16), STONE)
			for k in range(int(wall_h / 0.9)):
				Kit.box(f, "Pilaster joint", Vector3(px, 0.9 * float(k + 1), 0.17), Vector3(1.22 if absf(px) > 5.0 else 0.82, 0.04, 0.02), Color("a9a395"))
		Kit.box(f, "Band", Vector3(0, 4.3, 0.06), Vector3(w, 0.2, 0.12), STONE)
		for wx in [-7.0, -4.3, 0.0, 4.3, 7.0]:
			for wy in [0.9, 5.0]:
				if s > 0.0 and absf(wx) < 0.1 and wy < 1.0:
					continue
				_manor_window(f, wx, wy)
		if s > 0.0:
			# voordeur met bovenlicht, stenen omlijsting en kroonlijst, trap met leuning
			Kit.box(f, "Door surround", Vector3(0, 1.6, 0.08), Vector3(1.9, 3.2, 0.14), STONE)
			Kit.box(f, "Door", Vector3(0, 1.2, 0.14), Vector3(1.3, 2.4, 0.05), FRAME)
			Kit.box(f, "Door fanlight", Vector3(0, 2.75, 0.14), Vector3(1.3, 0.6, 0.04), GLASS)
			Kit.box(f, "Door cornice", Vector3(0, 3.35, 0.2), Vector3(2.2, 0.25, 0.35), STONE)
			for k in range(3):
				Kit.box(f, "Door step", Vector3(0, -0.15 - float(k) * 0.3, 0.5 + float(k) * 0.35), Vector3(2.4 + float(k) * 0.3, 0.3, 0.7), STONE)
	# dakkapellen (vijf voor, vijf achter)
	for s in [-1.0, 1.0]:
		for wx in [-7.0, -4.3, 0.0, 4.3, 7.0]:
			var dp := c + Vector3(wx, base + wall_h + 1.6, s * (d * 0.5 - 0.5))
			Kit.box(self, "Dormer", dp, Vector3(1.2, 1.6, 1.0), FRAME)
			Kit.box(self, "Dormer glass", dp + Vector3(0, -0.1, s * 0.51), Vector3(0.75, 1.0, 0.03), GLASS)
			Kit.cyl(self, "Dormer arch", dp + Vector3(0, 0.75, 0), 0.6, 0.6, 1.0, SLATE, 12, "z")
	# bakstenen brug met borstwering van de binnenplaats naar de voordeur
	var bz: float = c.z + d * 0.5 + 6.0
	Kit.box(self, "Bridge", Vector3(0, base * 0.5, bz), Vector3(4.0, base, 9.0), STONE, true)
	Kit.box(self, "Bridge deck", Vector3(0, base + 0.02, bz), Vector3(3.6, 0.06, 9.0), Color("9f978a"))
	for s in [-1.0, 1.0]:
		Kit.box(self, "Bridge parapet", Vector3(s * 2.0, base + 0.45, bz), Vector3(0.4, 0.9, 9.0), Color.WHITE, true, brick)
		Kit.box(self, "Parapet cap", Vector3(s * 2.0, base + 0.95, bz), Vector3(0.5, 0.12, 9.0), Color("7a4a3c"))

# Getoogd raam met een stenen omlijsting en een sluitsteen, in face-ruimte.
func _manor_window(f: Node3D, x: float, y: float) -> void:
	var w := 1.3
	var h := 2.4
	Kit.box(f, "Window surround", Vector3(x, y + h * 0.5, 0.06), Vector3(w + 0.4, h + 0.3, 0.1), STONE)
	Kit.box(f, "Window frame", Vector3(x, y + h * 0.5, 0.1), Vector3(w, h, 0.06), FRAME)
	Kit.box(f, "Window", Vector3(x, y + h * 0.5 - 0.05, 0.13), Vector3(w - 0.2, h - 0.25, 0.03), GLASS)
	Kit.box(f, "Window bar", Vector3(x, y + h * 0.5, 0.15), Vector3(0.06, h - 0.2, 0.02), FRAME)
	Kit.box(f, "Window bar", Vector3(x, y + h * 0.66, 0.15), Vector3(w - 0.2, 0.06, 0.02), FRAME)
	Kit.box(f, "Keystone", Vector3(x, y + h + 0.1, 0.14), Vector3(0.3, 0.4, 0.12), STONE)
