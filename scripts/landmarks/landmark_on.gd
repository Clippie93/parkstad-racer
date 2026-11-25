extends Node3D
# Mijnmonument Oranje-Nassau I (Nederlands Mijnmuseum), Heerlen. Naar foto's:
#  - vierkant schachtgebouw van donkerrode baksteen: witte natuurstenen banden, drie lagen
#    rondboogvensters (onder blinde bogen, midden paren, boven hoge vensters in een nis),
#    rondboogfries onder de kroonlijst, kantelen op de vier hoektorentjes, plat dak
#  - groengrijze vakwerk-schachtbok die uit het dak opsteekt: smalle schacht, bordes,
#    bredere kop met overstekend dak en twee schijven, schuine schoorbok naar de grond
#  - oranje letters ON bovenop de kop (de O staat iets scheef)
#  - bakstenen machinehal waar de kabels heen lopen, grijs betonnen museumgebouw ernaast,
#    oude stoomlocomotief met kolenwagens op een stukje spoor ervoor
# Maten zijn geschat. Lokale ruimte: +Z is de voorkant (naar de weg), schoorbok wijst naar +X.
const Kit = preload("res://scripts/build_kit.gd")

const HOUSE_W := 16.0     # breedte (X)
const HOUSE_D := 13.0     # diepte (Z)
const HOUSE_H := 19.0
const SHAFT_TOP := 29.0   # bovenkant smalle schacht = eerste bordes
const HEAD_LOW := 34.5
const HEAD_TOP := 39.5
const HALL_X0 := 30.0
const HALL_X1 := 50.0
const HALL_D := 14.0
const HALL_H := 12.0

var brick_mat: StandardMaterial3D
var brick := Color("8a5444")
var dark_brick := Color("5e3a30")
var stone := Color("ddd8cc")
var steel := Color("8a9a7c")
var glass := Color("343d43")
var frame := Color("a3a8a4")
var tower := Vector3(0.0, 0.0, -0.5)

func _ready() -> void:
    name = "OranjeNassauI"
    brick_mat = Kit.tex_mat("res://assets/on_brick.png", Color("c7a69c"), 3.0)
    Kit.box(self, "Forecourt", Vector3(16.0, 0.1, 5.0), Vector3(74.0, 0.2, 32.0), Color("9b9a90"))
    _shaft_house()
    _headframe()
    _strut()
    _on_letters()
    _machine_hall()
    _museum_block()
    _train(Vector3(-4.0, 0.0, 15.0))
    for p in [Vector3(-9.5, 0, 9.0), Vector3(10.0, 0, 9.0), Vector3(28.0, 0, 9.0), Vector3(46.0, 0, 9.0)]:
        _globe_lamp(p)

# ---------------------------------------------------------------- hulpvormen

func _arch(parent: Node3D, n: String, x: float, yb: float, w: float, h: float, z: float, thick: float, color: Color) -> void:
    # rondboogvorm: rechthoek met een halve cirkel erop (onderste helft valt in de rechthoek)
    var r: float = w * 0.5
    var straight: float = maxf(h - r, 0.1)
    Kit.box(parent, n, Vector3(x, yb + straight * 0.5, z), Vector3(w, straight, thick), color)
    Kit.cyl(parent, n + " top", Vector3(x, yb + straight, z), r, r, thick, color, 16, "z")

func _window(f: Node3D, x: float, yb: float, w: float, h: float) -> void:
    # rondboogvenster met bakstenen boog, roedeverdeling en witte stenen dorpel
    # lagen steeds 5-10 cm uit elkaar: nis 0-0,08, boog 0,09-0,15, glas 0,17-0,23, roeden 0,26
    _arch(f, "Window arch", x, yb - 0.05, w + 0.5, h + 0.3, 0.12, 0.06, dark_brick)
    _arch(f, "Window glass", x, yb, w, h, 0.2, 0.06, glass)
    var straight: float = h - w * 0.5
    Kit.box(f, "Mullion", Vector3(x, yb + h * 0.5, 0.26), Vector3(0.07, h - 0.1, 0.05), frame)
    for k in range(1, 4):
        Kit.box(f, "Transom", Vector3(x, yb + straight * float(k) / 4.0, 0.26), Vector3(w - 0.05, 0.07, 0.05), frame)
    Kit.box(f, "Sill", Vector3(x, yb - 0.12, 0.25), Vector3(w + 0.4, 0.2, 0.3), stone)

func _blind_arch(f: Node3D, x: float, yb: float, w: float, h: float) -> void:
    _arch(f, "Blind arch", x, yb, w, h, 0.04, 0.08, dark_brick)

func _face(pos: Vector3, yaw: float) -> Node3D:
    return Kit.face(self, pos, yaw)

# ---------------------------------------------------------------- schachtgebouw

func _shaft_house() -> void:
    Kit.box(self, "Shaft house", Vector3(0, HOUSE_H * 0.5, 0), Vector3(HOUSE_W, HOUSE_H, HOUSE_D), brick, true, brick_mat)
    Kit.box(self, "Shaft house roof", Vector3(0, HOUSE_H + 0.05, 0), Vector3(HOUSE_W - 0.6, 0.1, HOUSE_D - 0.6), Color("6c6f6a"))
    for entry in [[Vector3(0, 0, HOUSE_D * 0.5), 0.0, HOUSE_W, 3], [Vector3(0, 0, -HOUSE_D * 0.5), 180.0, HOUSE_W, 3],
            [Vector3(HOUSE_W * 0.5, 0, 0), 90.0, HOUSE_D, 2], [Vector3(-HOUSE_W * 0.5, 0, 0), -90.0, HOUSE_D, 2]]:
        _house_face(_face(entry[0], entry[1]), entry[2], entry[3], entry[1] == 0.0)
    # hoektorentjes met kantelen
    for sx in [-1.0, 1.0]:
        for sz in [-1.0, 1.0]:
            var c := Vector3(sx * (HOUSE_W * 0.5 - 0.5), 0, sz * (HOUSE_D * 0.5 - 0.5))
            var th: float = HOUSE_H + 1.6
            Kit.box(self, "Corner turret", c + Vector3(0, th * 0.5, 0), Vector3(2.0, th, 2.0), brick, false, brick_mat)
            Kit.box(self, "Turret band", c + Vector3(0, 6.6, 0), Vector3(2.12, 0.35, 2.12), stone)
            Kit.box(self, "Turret band", c + Vector3(0, 12.4, 0), Vector3(2.12, 0.35, 2.12), stone)
            for mx in [-0.75, 0.0, 0.75]:
                for mz in [-0.75, 0.0, 0.75]:
                    if mx == 0.0 and mz == 0.0:
                        continue
                    if absf(mx) < 0.1 or absf(mz) < 0.1:
                        continue
                    Kit.box(self, "Merlon", c + Vector3(mx, th + 0.35, mz), Vector3(0.5, 0.7, 0.5), brick, false, brick_mat)
            Kit.box(self, "Merlon", c + Vector3(0, th + 0.35, sz * 0.75), Vector3(0.5, 0.7, 0.5), brick, false, brick_mat)
            Kit.box(self, "Merlon", c + Vector3(sx * 0.75, th + 0.35, 0), Vector3(0.5, 0.7, 0.5), brick, false, brick_mat)
    # lage dakrand met witte deklijst tussen de torentjes
    for sz in [-1.0, 1.0]:
        Kit.box(self, "Parapet", Vector3(0, HOUSE_H + 0.45, sz * (HOUSE_D * 0.5 - 0.2)), Vector3(HOUSE_W - 3.0, 0.9, 0.4), brick, false, brick_mat)
        Kit.box(self, "Parapet coping", Vector3(0, HOUSE_H + 0.95, sz * (HOUSE_D * 0.5 - 0.2)), Vector3(HOUSE_W - 3.0, 0.12, 0.6), stone)
    for sx in [-1.0, 1.0]:
        Kit.box(self, "Parapet", Vector3(sx * (HOUSE_W * 0.5 - 0.2), HOUSE_H + 0.45, 0), Vector3(0.4, 0.9, HOUSE_D - 3.0), brick, false, brick_mat)
        Kit.box(self, "Parapet coping", Vector3(sx * (HOUSE_W * 0.5 - 0.2), HOUSE_H + 0.95, 0), Vector3(0.6, 0.12, HOUSE_D - 3.0), stone)

func _house_face(f: Node3D, fw: float, bays: int, has_door: bool) -> void:
    var inner: float = fw - 3.0          # tussen de hoektorentjes
    var bw: float = inner / float(bays)
    # witte stenen banden: plint, twee dorpelbanden, kroonlijst
    for b in [[0.25, 0.5], [6.6, 0.35], [12.4, 0.35], [HOUSE_H - 0.3, 0.45]]:
        Kit.box(f, "Stone band", Vector3(0, b[0], 0.12), Vector3(inner + 0.2, b[1], 0.25), stone)
    Kit.box(f, "Brick band", Vector3(0, 7.25, 0.06), Vector3(inner, 0.3, 0.12), dark_brick)
    # lisenen tussen de traveeën
    for i in range(1, bays):
        var x: float = -inner * 0.5 + float(i) * bw
        Kit.box(f, "Pilaster", Vector3(x, 9.5, 0.1), Vector3(0.7, 18.0, 0.2), brick, false, brick_mat)
    for i in range(bays):
        var xc: float = -inner * 0.5 + (float(i) + 0.5) * bw
        # onderste laag: blinde bogen (of de deur in het midden van de voorgevel)
        if has_door and i == int(bays / 2.0):
            _arch(f, "Door surround", xc, 0.5, 2.9, 5.0, 0.12, 0.06, dark_brick)
            _arch(f, "Door", xc, 0.5, 2.3, 4.6, 0.2, 0.06, Color("2f4a3a"))
        else:
            for dx in [-1.0, 1.0]:
                _blind_arch(f, xc + dx * bw * 0.24, 1.2, bw * 0.32, 4.6)
        # middelste laag: paren rondboogvensters
        for dx in [-1.0, 1.0]:
            _window(f, xc + dx * bw * 0.22, 8.0, minf(1.3, bw * 0.3), 3.4)
        # bovenste laag: hoog venster in een blinde nis
        _blind_arch(f, xc, 12.8, minf(3.0, bw * 0.7), 4.9)
        _window(f, xc, 13.2, minf(1.8, bw * 0.42), 3.9)
    # rondboogfries en uitkragende band onder de kroonlijst
    var n: int = int(inner / 0.85)
    for k in range(n):
        var x: float = -inner * 0.5 + (float(k) + 0.5) * inner / float(n)
        _arch(f, "Frieze arch", x, HOUSE_H - 2.1, 0.5, 0.75, 0.05, 0.1, dark_brick)
    Kit.box(f, "Corbel band", Vector3(0, HOUSE_H - 1.1, 0.15), Vector3(inner, 0.35, 0.3), brick, false, brick_mat)

# ---------------------------------------------------------------- schachtbok

func _lattice(y0: float, y1: float, hx: float, hz: float, steps: int, chord: float) -> void:
    var corners := [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
    for c: Vector2 in corners:
        Kit.beam(self, "Column", tower + Vector3(c.x, y0, c.y), tower + Vector3(c.x, y1, c.y), chord, steel)
    for s in range(steps + 1):
        var y: float = lerpf(y0, y1, float(s) / float(steps))
        for k in range(4):
            var a: Vector2 = corners[k]
            var b: Vector2 = corners[(k + 1) % 4]
            Kit.beam(self, "Girt", tower + Vector3(a.x, y, a.y), tower + Vector3(b.x, y, b.y), 0.28, steel)
        if s == steps:
            continue
        var y2: float = lerpf(y0, y1, float(s + 1) / float(steps))
        for k in range(4):
            var a: Vector2 = corners[k]
            var b: Vector2 = corners[(k + 1) % 4]
            Kit.beam(self, "Brace", tower + Vector3(a.x, y, a.y), tower + Vector3(b.x, y2, b.y), 0.16, steel)
            Kit.beam(self, "Brace", tower + Vector3(b.x, y, b.y), tower + Vector3(a.x, y2, a.y), 0.16, steel)

func _deck(y: float, hx: float, hz: float, rail: bool) -> void:
    Kit.box(self, "Deck", tower + Vector3(0, y, 0), Vector3(hx * 2.0, 0.25, hz * 2.0), Color("6d7468"))
    if not rail:
        return
    for sz in [-1.0, 1.0]:
        Kit.box(self, "Railing", tower + Vector3(0, y + 1.1, sz * hz), Vector3(hx * 2.0, 0.08, 0.08), steel)
        Kit.box(self, "Railing", tower + Vector3(0, y + 0.55, sz * hz), Vector3(hx * 2.0, 0.06, 0.06), steel)
    for sx in [-1.0, 1.0]:
        Kit.box(self, "Railing", tower + Vector3(sx * hx, y + 1.1, 0), Vector3(0.08, 0.08, hz * 2.0), steel)
        Kit.box(self, "Railing", tower + Vector3(sx * hx, y + 0.55, 0), Vector3(0.06, 0.06, hz * 2.0), steel)
    var n: int = int(hx * 2.0 / 1.2)
    for i in range(n + 1):
        var x: float = -hx + float(i) * hx * 2.0 / float(n)
        for sz in [-1.0, 1.0]:
            Kit.box(self, "Rail post", tower + Vector3(x, y + 0.55, sz * hz), Vector3(0.07, 1.1, 0.07), steel)

func _headframe() -> void:
    # smalle schacht: staat binnen in het gebouw en steekt door het dak
    _lattice(HOUSE_H - 2.0, SHAFT_TOP, 2.6, 2.3, 3, 0.45)
    _deck(SHAFT_TOP, 3.9, 3.5, true)
    # bredere bovenbouw met bordes en de kop
    _lattice(SHAFT_TOP, HEAD_LOW, 3.1, 2.8, 2, 0.4)
    _deck(HEAD_LOW, 3.9, 3.5, true)
    _lattice(HEAD_LOW, HEAD_TOP, 3.1, 2.8, 2, 0.4)
    var roof := Kit.box(self, "Head roof", tower + Vector3(0, HEAD_TOP + 0.3, 0), Vector3(8.2, 0.3, 7.6), Color("4d524c"))
    roof.rotation_degrees.x = 3.0
    Kit.box(self, "Head roof edge", tower + Vector3(0, HEAD_TOP + 0.05, 0), Vector3(8.0, 0.35, 7.4), steel)
    # ladderkooi aan de -X kant
    Kit.box(self, "Ladder cage", tower + Vector3(-4.4, (SHAFT_TOP + HEAD_TOP) * 0.5, 1.6), Vector3(0.9, HEAD_TOP - SHAFT_TOP, 0.9),
        steel, false, Kit.two_sided_mat(Color(0.54, 0.6, 0.49)))
    # twee schijven in de kop, vlak in de richting van de kabels (X)
    for z in [-1.2, 1.2]:
        var wheel := Node3D.new()
        wheel.name = "Sheave wheel"
        wheel.position = tower + Vector3(0, HEAD_LOW + 2.6, z)
        add_child(wheel)
        Kit.cyl(wheel, "Rim", Vector3.ZERO, 2.0, 2.0, 0.35, Color("3a3f3a"), 24, "z")
        Kit.cyl(wheel, "Rim inner", Vector3.ZERO, 1.75, 1.75, 0.37, Color("8a9a7c"), 24, "z")
        Kit.cyl(wheel, "Hub", Vector3.ZERO, 0.35, 0.35, 0.6, Color("3a3f3a"), 12, "z")
        for k in range(4):
            var spoke := Kit.box(wheel, "Spoke", Vector3.ZERO, Vector3(0.14, 3.6, 0.38), Color("3a3f3a"))
            spoke.rotation_degrees.z = float(k) * 45.0
        Kit.beam(self, "Hoist rope", wheel.position + Vector3(2.0, 0, 0), Vector3(HALL_X0, 10.0, z), 0.07, Color("2a2c2a"))

func _strut() -> void:
    # schuine schoorbok: twee vakwerkpoten van de kop naar betonnen poeren op de grond
    var legs: Array = []
    for sz in [-1.0, 1.0]:
        var top := tower + Vector3(3.1, HEAD_LOW, sz * 1.9)
        var foot := Vector3(24.0, 0.6, tower.z + sz * 3.4)
        Kit.box(self, "Strut footing", foot + Vector3(0, -0.1, 0), Vector3(2.2, 1.4, 2.2), Color("a3a29a"), true)
        var d: Vector3 = (top - foot).normalized()
        var n: Vector3 = d.cross(Vector3(0, 0, 1)).normalized()
        var a: Vector3 = foot + n * 0.45
        var b: Vector3 = foot - n * 0.45
        Kit.beam(self, "Strut chord", a, top + n * 0.45, 0.32, steel)
        Kit.beam(self, "Strut chord", b, top - n * 0.45, 0.32, steel)
        var steps := 16
        for k in range(steps):
            var p0: Vector3 = foot.lerp(top, float(k) / float(steps))
            var p1: Vector3 = foot.lerp(top, float(k + 1) / float(steps))
            var s0: float = 1.0 if k % 2 == 0 else -1.0
            Kit.beam(self, "Strut lacing", p0 + n * 0.45 * s0, p1 - n * 0.45 * s0, 0.12, steel)
        legs.append([foot, top])
    # verband tussen de twee poten
    var panels := 6
    for k in range(panels + 1):
        var t: float = float(k) / float(panels)
        var pa: Vector3 = legs[0][0].lerp(legs[0][1], t)
        var pb: Vector3 = legs[1][0].lerp(legs[1][1], t)
        Kit.beam(self, "Strut tie", pa, pb, 0.24, steel)
        if k < panels:
            var t2: float = float(k + 1) / float(panels)
            Kit.beam(self, "Strut brace", pa, legs[1][0].lerp(legs[1][1], t2), 0.14, steel)
            Kit.beam(self, "Strut brace", pb, legs[0][0].lerp(legs[0][1], t2), 0.14, steel)
    # ladder langs de schoorbok
    var la: Vector3 = (legs[0][0] + legs[1][0]) * 0.5 + Vector3(0, 0.5, 0)
    var lb: Vector3 = (legs[0][1] + legs[1][1]) * 0.5
    Kit.beam(self, "Strut ladder", la + Vector3(0, 0, -0.3), lb + Vector3(0, 0, -0.3), 0.08, steel)
    Kit.beam(self, "Strut ladder", la + Vector3(0, 0, 0.3), lb + Vector3(0, 0, 0.3), 0.08, steel)

func _on_letters() -> void:
    # oranje letters op een klein frame bovenop de kop; voor- en achterkant leesbaar
    var base: Vector3 = tower + Vector3(0, HEAD_TOP + 0.5, 0)
    for x in [-2.0, 2.0]:
        Kit.beam(self, "Letter post", base + Vector3(x, 0, 0), base + Vector3(x * 0.5, 2.0, 0), 0.15, steel)
    Kit.box(self, "Letter rail", base + Vector3(0, 1.0, 0), Vector3(4.4, 0.12, 0.12), steel)
    var orange := Color("f2601f")
    for side in [0.0, 180.0]:
        var f := Kit.face(self, base + Vector3(0, 2.6, 0), side)
        for layer in range(3):
            var z: float = 0.06 + float(layer) * 0.07
            var col: Color = orange if layer == 2 else orange.darkened(0.25)
            var o := Kit.label(f, "O", Vector3(-1.3, 0.3, z), 0.03, col, 140)
            o.rotation_degrees.z = 14.0
            var nl := Kit.label(f, "N", Vector3(1.3, -0.1, z), 0.03, col, 140)
            for l: Label3D in [o, nl]:
                l.alpha_cut = Label3D.ALPHA_CUT_DISCARD

# ---------------------------------------------------------------- machinehal

func _machine_hall() -> void:
    var w: float = HALL_X1 - HALL_X0
    var cx: float = (HALL_X0 + HALL_X1) * 0.5
    Kit.box(self, "Machine hall", Vector3(cx, HALL_H * 0.5, 0), Vector3(w, HALL_H, HALL_D), brick, true, brick_mat)
    Kit.box(self, "Hall roof", Vector3(cx, HALL_H + 0.05, 0), Vector3(w - 0.4, 0.1, HALL_D - 0.4), Color("6c6f6a"))
    for entry in [[Vector3(cx, 0, HALL_D * 0.5), 0.0, w, 5], [Vector3(cx, 0, -HALL_D * 0.5), 180.0, w, 5],
            [Vector3(HALL_X1, 0, 0), 90.0, HALL_D, 2], [Vector3(HALL_X0, 0, 0), -90.0, HALL_D, 2]]:
        var f := _face(entry[0], entry[1])
        var fw: float = entry[2]
        var bays: int = entry[3]
        var bw: float = (fw - 1.0) / float(bays)
        Kit.box(f, "Plinth band", Vector3(0, 0.25, 0.08), Vector3(fw + 0.2, 0.5, 0.16), stone)
        Kit.box(f, "Sill band", Vector3(0, 3.6, 0.08), Vector3(fw + 0.2, 0.3, 0.16), stone)
        Kit.box(f, "Coping", Vector3(0, HALL_H - 0.15, 0.15), Vector3(fw + 0.3, 0.35, 0.3), stone)
        for i in range(bays + 1):
            var x: float = -(fw - 1.0) * 0.5 + float(i) * bw
            Kit.box(f, "Pilaster", Vector3(x, HALL_H * 0.5, 0.11), Vector3(0.6, HALL_H - 0.4, 0.22), brick, false, brick_mat)
        for i in range(bays):
            var xc: float = -(fw - 1.0) * 0.5 + (float(i) + 0.5) * bw
            _window(f, xc, 4.2, minf(2.2, bw * 0.55), 5.6)
            # lage halfronde vensters onder de dorpelband
            _arch(f, "Low window arch", xc, 0.9, 1.8, 2.2, 0.12, 0.06, dark_brick)
            _arch(f, "Low window", xc, 1.1, 1.4, 1.8, 0.2, 0.06, glass)
        var n: int = int((fw - 1.0) / 0.85)
        for k in range(n):
            var x: float = -(fw - 1.0) * 0.5 + (float(k) + 0.5) * (fw - 1.0) / float(n)
            _arch(f, "Frieze arch", x, HALL_H - 1.6, 0.5, 0.7, 0.05, 0.1, dark_brick)
        Kit.box(f, "Corbel band", Vector3(0, HALL_H - 0.7, 0.14), Vector3(fw, 0.3, 0.28), brick, false, brick_mat)

# ---------------------------------------------------------------- omgeving

func _museum_block() -> void:
    # grijs betonnen museumgebouw tegen de -X kant
    var concrete := Color("9e9b92")
    # achterkant op z -6,2: niet in hetzelfde vlak als het hoektorentje (z -7), anders flikkert het
    Kit.box(self, "Museum block", Vector3(-14.5, 10.5, -0.6), Vector3(13.0, 21.0, 11.2), concrete, true)
    Kit.box(self, "Museum stair tower", Vector3(-12.0, 12.0, 5.8), Vector3(4.0, 24.0, 2.6), Color("94918a"), true)
    for x in [-19.0, -16.5]:
        Kit.box(self, "Museum slit window", Vector3(x, 12.0, 5.06), Vector3(0.6, 14.0, 0.15), glass)
    for y in [4.0, 8.5, 13.0, 17.5]:
        Kit.box(self, "Museum window band", Vector3(-21.06, y, -1.0), Vector3(0.15, 1.6, 9.0), glass)

func _train(at: Vector3) -> void:
    # stukje spoor met een zwart/rode stoomlocomotief en twee kolenwagens
    Kit.box(self, "Track bed", at + Vector3(-6.0, 0.3, 0), Vector3(26.0, 0.2, 3.2), Color("7a746a"))
    for z in [-0.72, 0.72]:
        Kit.box(self, "Rail", at + Vector3(-6.0, 0.48, z), Vector3(26.0, 0.14, 0.1), Color("5b5550"))
    var black := Color("1f2022")
    var red := Color("b3261e")
    Kit.box(self, "Loco frame", at + Vector3(0, 1.25, 0), Vector3(7.4, 0.5, 2.3), red, true)
    for x in [-2.0, 0.0, 2.0]:
        for z in [-1.05, 1.05]:
            Kit.cyl(self, "Loco wheel", at + Vector3(x, 0.95, z), 0.55, 0.55, 0.18, red, 14, "z")
    Kit.cyl(self, "Boiler", at + Vector3(-1.0, 2.45, 0), 0.95, 0.95, 4.6, black, 16, "x")
    Kit.box(self, "Side tanks", at + Vector3(-0.6, 2.05, 0), Vector3(3.6, 1.2, 2.3), black)
    Kit.box(self, "Cab", at + Vector3(2.5, 2.75, 0), Vector3(2.3, 2.5, 2.4), black)
    Kit.box(self, "Cab roof", at + Vector3(2.5, 4.05, 0), Vector3(2.6, 0.15, 2.6), black)
    Kit.cyl(self, "Chimney", at + Vector3(-2.9, 3.75, 0), 0.28, 0.32, 1.0, black, 12)
    Kit.cyl(self, "Dome", at + Vector3(-0.8, 3.45, 0), 0.4, 0.45, 0.5, black, 12)
    for z in [-0.7, 0.7]:
        Kit.cyl(self, "Buffer", at + Vector3(-3.9, 1.3, z), 0.2, 0.2, 0.5, red, 10, "x")
    for k in range(2):
        var wx: float = -8.0 - float(k) * 6.0
        Kit.box(self, "Wagon frame", at + Vector3(wx, 1.05, 0), Vector3(5.2, 0.35, 2.2), Color("2a2523"), true)
        Kit.box(self, "Wagon body", at + Vector3(wx, 1.95, 0), Vector3(5.0, 1.45, 2.3), Color("4a4540"))
        Kit.box(self, "Coal", at + Vector3(wx, 2.55, 0), Vector3(4.8, 0.3, 2.1), Color("161616"))
        for x in [-1.6, 1.6]:
            for z in [-1.0, 1.0]:
                Kit.cyl(self, "Wagon wheel", at + Vector3(wx + x, 0.85, z), 0.45, 0.45, 0.16, Color("2a2523"), 12, "z")

func _globe_lamp(p: Vector3) -> void:
    Kit.box(self, "Lamp post", p + Vector3(0, 2.0, 0), Vector3(0.14, 4.0, 0.14), Color("d4d4d0"))
    var mi := MeshInstance3D.new()
    mi.name = "Lamp globe"
    var s := SphereMesh.new()
    s.radius = 0.38
    s.height = 0.76
    mi.mesh = s
    mi.material_override = Kit.mat(Color("f4f2ea"), 0.3)
    mi.position = p + Vector3(0, 4.3, 0)
    add_child(mi)
