extends Node3D
# Molen op de Vrouweheide (Ransdaal, Voerendaal), naar jouw foto's (25-11). Ronde
# stenen grondzeiler-romp op een heuvel, naar boven smaller, helemaal bekleed met
# donkere leien (glimmend zwartblauw) met kleine witte raampjes; een witte band onder de
# kap, een donkergroene kap met een wit randje en een lantaarnvenster aan de voorkant;
# een rode as-kop met een witte ster; vier zwarte wieken met een tralie-hekwerk (de
# wieken draaien langzaam rond); witte schoren en een staart naar achteren. Om de voet
# een halfronde bakstenen ring (het molenhuis) met een rondboogpui met groene ramen, kleine
# witte raampjes en een oude molensteen tegen de muur.
# Lokale ruimte: +Z = naar de weg (de wieken kijken naar de weg).
const Kit = preload("res://scripts/build_kit.gd")

const SLATE := Color("2b3038")
const SAIL := Color("1c1e22")
const WHITE := Color("f0efe8")
const BRICK := Color("9a6a52")
const RED := Color("c22a26")
const CAP := Color("3c4a44")

const HILL := 2.6          # hoogte van de heuvel onder de molen
const BODY_H := 15.0
var rotor: Node3D

func _ready() -> void:
	name = "Molen op de Vrouweheide"
	# heuvel (afgeknotte kegel) met gras
	Kit.cyl(self, "Mill hill", Vector3(0, HILL * 0.5, -2), 19.0, 14.0, HILL, Color("6d9a4c"), 24, "y", true)   # blijft van de stoep af
	var base := Vector3(0, HILL, -2)
	_base_ring(base)
	_tower(base)
	_struts(base)
	# terras en hagen voor het molenhuis
	Kit.box(self, "Mill terrace", base + Vector3(0, 0.03, 9.6), Vector3(9.0, 0.06, 3.2), Color("a07060"))
	Kit.box(self, "Hedge", base + Vector3(-7.5, 0.6, 9.0), Vector3(6.0, 1.2, 1.4), Color("4a6e36"))
	Kit.box(self, "Hedge", base + Vector3(7.5, 0.6, 9.0), Vector3(6.0, 1.2, 1.4), Color("4a6e36"))
	# trap van de weg de heuvel op
	for k in range(6):
		Kit.box(self, "Hill step", Vector3(0, 0.22 * float(k) + 0.11, 16.5 - float(k) * 0.9), Vector3(3.0, 0.22, 1.4), Color("a8a49a"))

# Halfronde bakstenen ring om de voet van de molen.
func _base_ring(c: Vector3) -> void:
	var r := 8.6
	var h := 3.4
	var t: Array = []
	var n := 20
	for i in range(n):
		var a0: float = lerpf(-PI * 0.62, PI * 0.62, float(i) / float(n))
		var a1: float = lerpf(-PI * 0.62, PI * 0.62, float(i + 1) / float(n))
		var p0 := Vector3(sin(a0) * r, 0, cos(a0) * r)
		var p1 := Vector3(sin(a1) * r, 0, cos(a1) * r)
		Kit._quad(t, p0, p1, p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0))
		# dak van de ring (plat, naar de toren toe)
		var q0 := Vector3(sin(a0) * 4.2, h, cos(a0) * 4.2)
		var q1 := Vector3(sin(a1) * 4.2, h, cos(a1) * 4.2)
		Kit._quad(t, p0 + Vector3(0, h, 0), p1 + Vector3(0, h, 0), q1, q0)
	var ring := MeshInstance3D.new()
	ring.name = "Mill house"
	ring.mesh = Kit._mesh_from(t, Kit._two_sided(BRICK))
	ring.position = c
	add_child(ring)
	# botsblok voor de ring (benadering)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	body.add_child(cs)
	body.position = c + Vector3(0, h * 0.5, 0)
	add_child(body)
	Kit.cyl(self, "Ring coping", c + Vector3(0, h + 0.05, 0), r + 0.1, r + 0.1, 0.12, Color("8a7a6a"), 24)
	# voorkant: rondboogpui met groene roeden, raampjes, lampje, molensteen
	var f := Kit.face(self, c + Vector3(0, 0, r), 0.0)
	Kit.box(f, "Arch window", Vector3(0, 1.2, 0.03), Vector3(2.2, 2.4, 0.06), Color("3a5048"))
	Kit.cyl(f, "Arch window top", Vector3(0, 2.4, 0.03), 1.1, 1.1, 0.06, Color("3a5048"), 16, "z")
	Kit.box(f, "Arch glass", Vector3(0, 1.25, 0.07), Vector3(1.9, 2.3, 0.03), Color("8aa4b0"))
	for x in [-0.48, 0.48]:
		Kit.box(f, "Arch bar", Vector3(x, 1.6, 0.1), Vector3(0.07, 3.0, 0.03), Color("2f5a4a"))
	for y in [0.8, 1.6, 2.4]:
		Kit.box(f, "Arch bar", Vector3(0, y, 0.1), Vector3(2.0, 0.07, 0.03), Color("2f5a4a"))
	Kit.cyl(f, "Brick arch", Vector3(0, 2.4, 0.01), 1.4, 1.4, 0.05, Color("7a4a3a"), 16, "z")
	for a in [-32.0, 30.0, 45.0]:
		var d := Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
		var wf := Kit.face(self, c + d * (r + 0.01), a)
		Kit.box(wf, "Small window", Vector3(0, 1.6, 0.03), Vector3(0.7, 0.9, 0.05), WHITE)
		Kit.box(wf, "Small glass", Vector3(0, 1.6, 0.06), Vector3(0.5, 0.7, 0.03), Color("2c3236"))
	var sf := Kit.face(self, c + Vector3(sin(deg_to_rad(18.0)), 0, cos(deg_to_rad(18.0))) * (r + 0.4), 18.0)
	Kit.cyl(sf, "Millstone", Vector3(0, 0.75, 0), 0.75, 0.75, 0.22, Color("8a857c"), 18, "z")

func _tower(c: Vector3) -> void:
	var rb := 4.4
	var rt := 2.9
	Kit.cyl(self, "Mill body", c + Vector3(0, BODY_H * 0.5, 0), rb, rt, BODY_H, SLATE, 24, "y", true)
	# kleine witte raampjes, verspreid
	for e in [[0.0, 5.5], [0.0, 9.5], [30.0, 12.5], [-40.0, 7.0], [150.0, 6.0], [-160.0, 11.0], [80.0, 13.6], [-80.0, 13.6]]:
		var a: float = deg_to_rad(float(e[0]))
		var y: float = float(e[1])
		var rr: float = lerpf(rb, rt, y / BODY_H) + 0.02
		var wf := Kit.face(self, c + Vector3(sin(a) * rr, 0, cos(a) * rr), float(e[0]))
		Kit.box(wf, "Mill window", Vector3(0, y, 0.02), Vector3(0.36, 0.42, 0.04), WHITE)
	# witte band en kap
	var top: Vector3 = c + Vector3(0, BODY_H, 0)
	Kit.cyl(self, "White band", top + Vector3(0, 0.25, 0), rt + 0.15, rt + 0.15, 0.5, WHITE, 24)
	Kit.cyl(self, "Cap rim", top + Vector3(0, 0.62, 0), rt + 0.45, rt + 0.3, 0.25, Color("dcdcd2"), 24)
	Kit.cyl(self, "Cap", top + Vector3(0, 1.9, 0), rt + 0.25, 1.1, 2.4, CAP, 16)
	# lantaarn/voorschild van de kap aan de voorkant
	Kit.box(self, "Cap front", top + Vector3(0, 1.9, rt - 0.2), Vector3(2.6, 2.4, 1.2), CAP)
	for x in [-0.8, 0.0, 0.8]:
		Kit.box(self, "Cap window", top + Vector3(x, 2.1, rt + 0.42), Vector3(0.12, 1.4, 0.04), WHITE)
	Kit.box(self, "Name board", top + Vector3(0, 0.9, rt + 0.5), Vector3(3.4, 0.4, 0.06), Color("1e2226"))
	Kit.label(self, "OP DE VROUWEHEIDE", top + Vector3(0, 0.9, rt + 0.54), 0.0034, WHITE, 64)
	# rotor op de as, iets schuin omhoog
	rotor = Node3D.new()
	rotor.name = "Sails"
	rotor.position = top + Vector3(0, 2.0, rt + 1.3)
	rotor.rotation_degrees.x = -8.0
	add_child(rotor)
	Kit.cyl(rotor, "Hub", Vector3(0, 0, 0.1), 0.55, 0.55, 0.7, RED, 10, "z")
	Kit.cyl(rotor, "Hub star", Vector3(0, 0, 0.47), 0.34, 0.34, 0.04, WHITE, 8, "z")
	var t: Array = []
	for k in range(4):
		var ang: float = float(k) * PI * 0.5
		_sail(t, ang)
	var sails := MeshInstance3D.new()
	sails.name = "Sail lattice"
	sails.mesh = Kit._mesh_from(t, Kit._two_sided(SAIL))
	rotor.add_child(sails)

# Eén wiek: roede (balk) van de as naar buiten, met aan één kant een hekwerk van latten.
func _sail(t: Array, ang: float) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	var L := 12.0
	var z := 0.5
	var bar := func(a: Vector2, b: Vector2, w: float, zz: float) -> void:
		var d: Vector2 = (b - a).normalized()
		var n := Vector2(-d.y, d.x) * (w * 0.5)
		Kit._quad(t, Vector3(a.x - n.x, a.y - n.y, zz), Vector3(b.x - n.x, b.y - n.y, zz), Vector3(b.x + n.x, b.y + n.y, zz), Vector3(a.x + n.x, a.y + n.y, zz))
	bar.call(Vector2.ZERO, dir * L, 0.32, z)
	# hekwerk: van 2,5 m tot het eind, 2,1 m breed aan één kant
	var r0 := 2.5
	var wdt := 2.1
	for j in range(4):
		var off: float = 0.35 + float(j) * (wdt - 0.35) / 3.0
		bar.call(dir * r0 + nrm * off, dir * L + nrm * off, 0.07, z + 0.03)
	var r := r0
	while r <= L + 0.01:
		bar.call(dir * r + nrm * 0.1, dir * r + nrm * wdt, 0.07, z + 0.05)
		r += 0.5

# Witte schoren van de kap naar beneden aan de achterkant, en de staart.
func _struts(c: Vector3) -> void:
	var top: Vector3 = c + Vector3(0, BODY_H + 0.6, -2.9)
	for sx in [-1.0, 1.0]:
		Kit.beam(self, "Brace", top + Vector3(sx * 1.4, 0, 0), c + Vector3(sx * 4.8, 3.5, -9.0), 0.28, WHITE)
	Kit.beam(self, "Tail", top + Vector3(0, -0.4, 0), c + Vector3(0, 3.5, -10.5), 0.34, WHITE)
	Kit.box(self, "Tail end", c + Vector3(0, 3.5, -10.5), Vector3(0.5, 0.4, 0.5), RED)

func _process(delta: float) -> void:
	if rotor != null:
		rotor.rotate_object_local(Vector3(0, 0, 1), -delta * 0.6)
