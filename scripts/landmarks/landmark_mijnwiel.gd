extends Node3D
# Schachtwiel: herdenkingsmonument voor de verongelukte mijnwerkers in Brunssum. Naar jouw
# foto's (20-11):
# - groot lichtgrijs schachtwiel (ongeveer 7 m) met een vlakke velg, twaalf spaken en een
#   naaf, iets boven de grond
# - de naaf rust op een stalen arm die naar rechts loopt naar een staande stalen plaat
#   met een ovaal gat, op een betonnen voet
# - een kabel loopt vanaf de bovenkant van het wiel schuin omlaag naar een driehoekig
#   betonnen anker op de grond
# - tegelpad, een bloemenperkje tussen anker en wiel en een gedenksteen in het gras
# Lokale ruimte: het wiel staat in het XY-vlak, de kijkkant is +Z.
const Kit = preload("res://scripts/build_kit.gd")

const R := 3.5
const HUB := Vector3(0, R + 0.55, 0)
const STEEL := Color("c4ccd0")
const STEEL_DARK := Color("a9b3b8")
const CONCRETE := Color("8f9294")

func _ready() -> void:
	name = "Schachtwiel"
	Kit.box(self, "Paving", Vector3(-2.5, 0.04, 0), Vector3(16.0, 0.08, 5.0), Color("b4b1aa"))
	_wheel()
	_bracket()
	_cable()
	Kit.box(self, "Flower bed", Vector3(-5.2, 0.15, 0.2), Vector3(3.0, 0.22, 1.2), Color("6a5a48"))
	var flowers := [Color("e8c33a"), Color("d8483a"), Color("f2f2ee"), Color("b44fa0")]
	for k in range(14):
		Kit.box(self, "Flower", Vector3(-6.5 + float(k % 7) * 0.42, 0.33, -0.1 + float(k / 7) * 0.55), Vector3(0.25, 0.18, 0.25), flowers[k % flowers.size()])
	# gedenksteen plat in het gras, voor rechts
	var st := Kit.box(self, "Memorial stone", Vector3(3.5, 0.15, 5.0), Vector3(1.4, 0.3, 0.9), Color("b9b7b2"))
	st.rotation.x = -0.15
	var f := Kit.face(self, Vector3(3.5, 0.32, 5.0), 0.0)
	var lab := Kit.label(f, "Glück auf", Vector3.ZERO, 0.004, Color("4a4a48"), 48)
	lab.rotation.x = -PI * 0.5 + 0.15

func _wheel() -> void:
	# vlakke velg: korte, brede segmenten
	var segs := 36
	for k in range(segs):
		var a0: float = float(k) * TAU / float(segs)
		var a1: float = float(k + 1) * TAU / float(segs)
		var p0 := HUB + Vector3(cos(a0) * R, sin(a0) * R, 0)
		var p1 := HUB + Vector3(cos(a1) * R, sin(a1) * R, 0)
		var seg := Kit.box(self, "Rim", (p0 + p1) * 0.5, Vector3((p1 - p0).length() + 0.04, 0.26, 0.38), STEEL, true)
		seg.rotation.z = (a0 + a1) * 0.5 + PI * 0.5
	# binnenrand van de velg
	for k in range(segs):
		var a0: float = float(k) * TAU / float(segs)
		var a1: float = float(k + 1) * TAU / float(segs)
		var r2: float = R - 0.2
		var p0 := HUB + Vector3(cos(a0) * r2, sin(a0) * r2, 0)
		var p1 := HUB + Vector3(cos(a1) * r2, sin(a1) * r2, 0)
		var seg := Kit.box(self, "Rim lip", (p0 + p1) * 0.5, Vector3((p1 - p0).length() + 0.03, 0.12, 0.2), STEEL_DARK)
		seg.rotation.z = (a0 + a1) * 0.5 + PI * 0.5
	# twaalf spaken, plat en taps
	for k in range(12):
		var a: float = float(k) * TAU / 12.0 + PI / 12.0
		var dir := Vector3(cos(a), sin(a), 0)
		var sp := Kit.box(self, "Spoke", HUB + dir * (R * 0.5), Vector3(R - 0.3, 0.2, 0.14), STEEL)
		sp.rotation.z = a
	Kit.cyl(self, "Hub", HUB, 0.55, 0.55, 0.7, STEEL_DARK, 16, "z")
	Kit.cyl(self, "Hub cap", HUB + Vector3(0, 0, 0.4), 0.3, 0.3, 0.12, STEEL, 12, "z")
	Kit.box(self, "Hub block", HUB + Vector3(0, 0.5, 0.2), Vector3(0.9, 0.5, 0.5), STEEL_DARK)

# Stalen arm van de naaf naar rechts, naar een staande plaat met een ovaal gat, op beton.
func _bracket() -> void:
	var px := R + 1.6       # midden van de staande plaat
	Kit.box(self, "Bracket base", Vector3(px, 0.4, 0), Vector3(2.8, 0.8, 1.8), CONCRETE, true)
	Kit.box(self, "Bracket plate", Vector3(px, 2.5, 0.0), Vector3(1.9, 3.4, 0.5), STEEL, true)
	Kit.box(self, "Bracket arm", Vector3(px * 0.5 + 0.2, HUB.y - 0.1, 0.45), Vector3(px + 0.4, 0.7, 0.55), STEEL)
	Kit.box(self, "Bracket arm flange", Vector3(px * 0.5 + 0.2, HUB.y - 0.48, 0.45), Vector3(px + 0.4, 0.08, 0.8), STEEL_DARK)
	Kit.box(self, "Bracket top", Vector3(px, HUB.y - 0.1, 0.0), Vector3(1.9, 0.7, 0.55), STEEL)
	# schuine schoor van de arm naar de plaat
	Kit.beam(self, "Bracket strut", Vector3(px - 1.6, HUB.y - 0.4, 0.45), Vector3(px - 0.9, 1.4, 0.3), 0.3, STEEL_DARK)
	# ovaal gat in de plaat
	var f := Kit.face(self, Vector3(px, 0, 0.26), 0.0)
	var hole := Kit.cyl(f, "Bracket hole", Vector3(0.1, 2.3, 0.01), 0.42, 0.42, 0.04, Color("3a4a3a"), 18, "z")
	hole.scale = Vector3(1.0, 1.0, 1.7)
	var rim := Kit.cyl(f, "Bracket hole rim", Vector3(0.1, 2.3, 0.0), 0.52, 0.52, 0.03, STEEL_DARK, 18, "z")
	rim.scale = Vector3(1.0, 1.0, 1.6)

# Kabel van een driehoekig betonnen anker naar het raakpunt bovenlinks op het wiel.
func _cable() -> void:
	var anchor := Vector3(-9.0, 0.0, 0.0)
	Kit.gable(self, "Cable anchor", anchor, 1.4, 1.0, 0.9, CONCRETE)
	var eye := anchor + Vector3(0.5, 0.75, 0)
	Kit.cyl(self, "Cable eye", eye, 0.12, 0.12, 0.5, STEEL, 8, "x")
	var d := Vector3(eye.x - HUB.x, eye.y - HUB.y, 0)
	var dist: float = d.length()
	var a: float = atan2(d.y, d.x) - acos(R / dist)
	var touch := HUB + Vector3(cos(a), sin(a), 0) * R
	Kit.beam(self, "Cable", eye, touch, 0.07, Color("6a6e70"))
