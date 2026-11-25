extends Node3D
# Brikke Oave (Brunssum), tegenover het Lindeplein, naar jouw foto (24-11). De naam betekent
# "steenoven"; nu theater en grand café. Gele baksteen in drie delen:
# - links een lager deel met hoge glazen puien tussen bakstenen penanten
# - in het midden een smalle toren met een strook glasbouwstenen en bovenop een glazen
#   lantaarn met een vlag
# - rechts een groot blok dat op de verdieping naar voren uitkraagt, met een terugliggende
#   band donkere ramen, een lichte onderkant en de naam in rode letters; eronder op kolommen
#   het terras van het café
# Ervoor een terras met grijze houten loungebanken, tafels en dichte parasols.
# Lokale ruimte: +Z = naar de weg.
const Kit = preload("res://scripts/build_kit.gd")

const BRICK := Color("d8b878")
const DARK_BRICK := Color("3a3a3e")
const GLASS := Color("2e3a42")
const WOOD := Color("a8a8a2")
const SOFFIT := Color("e6e2d8")

func _ready() -> void:
	name = "Brikke Oave"
	var brick := Kit.mat(BRICK)
	Kit.box(self, "Terrace paving", Vector3(0, 0.02, 4), Vector3(38, 0.04, 10), Color("a86e58"))
	# ---- links: lager deel met hoge glazen puien
	Kit.box(self, "Low wing", Vector3(-11, 4.75, -7), Vector3(14, 9.5, 14), Color.WHITE, true, brick)
	var lf := Kit.face(self, Vector3(-11, 0, 0), 0.0)
	for gx in [-3.6, 2.6]:
		Kit.box(lf, "Tall glass", Vector3(gx, 4.0, 0.03), Vector3(4.2, 7.0, 0.06), GLASS)
		for mx in [-1.4, 0.0, 1.4]:
			Kit.box(lf, "Mullion", Vector3(gx + mx, 4.0, 0.08), Vector3(0.1, 7.0, 0.05), Color("1e2226"))
		for my in [2.6, 5.2]:
			Kit.box(lf, "Transom", Vector3(gx, my, 0.08), Vector3(4.2, 0.1, 0.05), Color("1e2226"))
		Kit.box(lf, "Plinth", Vector3(gx, 0.25, 0.04), Vector3(4.4, 0.5, 0.08), DARK_BRICK)
	Kit.box(lf, "Cornice line", Vector3(0, 8.0, 0.05), Vector3(14, 0.12, 0.1), Color("c4a468"))
	# ---- midden: smalle toren met glasbouwstenen en een glazen lantaarn
	var tc := Vector3(-2.5, 0, -6)
	Kit.box(self, "Tower", tc + Vector3(0, 8.5, 0), Vector3(5.0, 17.0, 8.0), Color.WHITE, true, brick)
	var tf := Kit.face(self, tc + Vector3(0, 0, 4.0), 0.0)
	Kit.box(tf, "Glass blocks", Vector3(0.6, 9.5, 0.03), Vector3(0.9, 8.0, 0.06), Color("b8c8cc"))
	Kit.box(tf, "Glass blocks low", Vector3(0.6, 3.5, 0.03), Vector3(0.7, 4.0, 0.06), Color("b8c8cc"))
	Kit.box(self, "Lantern", tc + Vector3(0, 18.4, 0), Vector3(2.4, 2.8, 2.4), Color("4a5a64"))
	Kit.box(self, "Lantern roof", tc + Vector3(0, 19.9, 0), Vector3(2.7, 0.2, 2.7), Color("8a8e92"))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Kit.box(self, "Lantern post", tc + Vector3(sx * 1.15, 18.4, sz * 1.15), Vector3(0.12, 2.8, 0.12), Color("cfd3d6"))
	Kit.cyl(self, "Flag pole", tc + Vector3(0, 22.5, 0), 0.06, 0.05, 5.0, Color("d8dadc"), 6)
	Kit.box(self, "Flag", tc + Vector3(0.6, 24.2, 0), Vector3(1.2, 0.9, 0.03), Color("e8e0d4"))
	# ---- rechts: blok met uitkragende verdieping
	var rc := Vector3(9.5, 0, -6)
	# begane grond: glazen pui, iets terug
	Kit.box(self, "Cafe ground floor", rc + Vector3(0, 2.6, -1.0), Vector3(15.0, 5.2, 10.0), GLASS, true)
	var gf := Kit.face(self, rc + Vector3(0, 0, 4.0), 0.0)
	var x := -6.5
	while x <= 6.6:
		Kit.box(gf, "Cafe mullion", Vector3(x, 2.6, 0.04), Vector3(0.12, 5.2, 0.06), Color("1e2226"))
		x += 1.8
	# verdieping: uitkragend blok
	var up := rc + Vector3(0, 9.75, 2.0)
	Kit.box(self, "Upper block", up, Vector3(16.0, 9.5, 16.0), Color.WHITE, true, brick)
	Kit.box(self, "Soffit", up + Vector3(0, -4.78, 0.5), Vector3(15.6, 0.06, 15.0), SOFFIT)
	var uf := Kit.face(self, up + Vector3(0, 0, 8.0), 0.0)
	# terugliggende band donkere ramen met een lichte binnenkant
	Kit.box(uf, "Window recess", Vector3(0, 0.3, 0.02), Vector3(14.0, 5.0, 0.04), SOFFIT)
	Kit.box(uf, "Dark windows", Vector3(-0.6, 0.0, 0.05), Vector3(12.4, 4.0, 0.05), Color("26282c"))
	var wx := -6.4
	while wx <= 5.8:
		Kit.box(uf, "Window frame", Vector3(wx, 0.0, 0.09), Vector3(0.1, 4.0, 0.04), Color("6a6e72"))
		wx += 1.55
	Kit.box(uf, "Window sill", Vector3(0, -2.1, 0.12), Vector3(14.0, 0.12, 0.25), Color("8a8e92"))
	Kit.box(uf, "Light panel", Vector3(6.2, 0.0, 0.05), Vector3(1.4, 4.0, 0.05), Color("dcdcd8"))
	# de naam binnen de gevel: "Brikke" rood, "Oave" grijs
	Kit.label(uf, "Brikke", Vector3(-4.0, 3.5, 0.06), 0.024, Color("c8302c"), 64)
	Kit.label(uf, "Oave", Vector3(1.3, 3.3, 0.06), 0.024, Color("6a6c70"), 64)
	# kolommen onder de uitkraging
	for cx in [-6.0, -1.5, 3.0, 7.0]:
		Kit.box(self, "Column", rc + Vector3(cx, 2.5, 9.0), Vector3(0.9, 5.0, 0.9), Color.WHITE, true, brick)
		Kit.box(self, "Column base", rc + Vector3(cx, 0.5, 9.0), Vector3(0.95, 1.0, 0.95), DARK_BRICK)
	# ---- terras: grijze houten loungebanken links, tafels en stoelen rechts
	for p in [Vector3(-15, 0, 3), Vector3(-11, 0, 4.5), Vector3(-7, 0, 3.5), Vector3(-3, 0, 5)]:
		Kit.box(self, "Lounge seat", p + Vector3(0, 0.25, 0), Vector3(2.2, 0.5, 1.0), WOOD)
		Kit.box(self, "Lounge back", p + Vector3(0, 0.7, -0.4), Vector3(2.2, 0.5, 0.2), WOOD)
		Kit.box(self, "Lounge table", p + Vector3(0, 0.3, 1.2), Vector3(0.9, 0.6, 0.9), WOOD)
	for p in [Vector3(-13, 0, 6.5), Vector3(-5, 0, 7)]:
		Kit.cyl(self, "Parasol", p + Vector3(0, 1.6, 0), 0.25, 0.05, 3.2, Color("5e5a52"), 6)
	for i in range(3):
		for j in range(2):
			var p := rc + Vector3(-5.0 + float(i) * 4.5, 0, 11.0 + float(j) * 2.4)
			Kit.box(self, "Cafe table", p + Vector3(0, 0.38, 0), Vector3(1.6, 0.06, 0.8), Color("a07a52"))
			for s in [-1.0, 1.0]:
				Kit.box(self, "Cafe chair", p + Vector3(0, 0.45, s * 0.75), Vector3(0.5, 0.9, 0.5), Color("2c2c2e"))
	# ---- zijkant en achterkant: dichte gele baksteen
	Kit.box(self, "Back block", Vector3(0, 6.0, -15.5), Vector3(36, 12.0, 5.0), Color.WHITE, true, brick)
