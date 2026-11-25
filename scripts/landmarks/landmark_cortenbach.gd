extends Node3D
# Kasteel Cortenbach, Voerendaal. Naar foto's op Wikimedia Commons:
# - hoog, blokvormig herenhuis van rode baksteen in de gracht: drie lagen met witte
#   schuiframen, natuurstenen hoekblokken en plint, leien mansardedak met dakkapellen
#   en schoorstenen; links een lagere zijvleugel
# - voorburcht naar jouw foto's (20-11): lange hoevegebouwen van geelbruine baksteen met
#   schilddaken, schoorstenen en (rechts) witte dakkapellen; in het midden het poortgebouw
#   met natuurstenen hoekblokken, een rondboog, een open rode deur, een plaquette, twee
#   vensters en een wapenschild, met een schilddak en een grote leien ui
# - rechts achteraan een vierkante hoektoren met lantaarn, links achteraan een ronde toren
#   met een slanke spits; links van de voorplaats een open karschuur met rode palen,
#   grind, een haag en oude bomen
# - gracht rondom het herenhuis, stenen brug vanaf de voorburcht
# Lokale ruimte: +Z = straatkant (voorburcht), het herenhuis ligt achteraan in het water.
const Kit = preload("res://scripts/build_kit.gd")

var slate := Color("44494f")
var marl := Color("dcd2b8")
var stone := Color("bdb6a6")

func _ready() -> void:
    name = "Kasteel Cortenbach"
    _moat()
    _house()
    _bailey()

func _moat() -> void:
    Kit.box(self, "Moat", Vector3(0, 0.06, -32.0), Vector3(64.0, 0.08, 40.0), Color("4d6a6b"))
    Kit.box(self, "Island", Vector3(-4.0, 0.12, -27.0), Vector3(32.0, 0.12, 18.0), Color("6f8f4a"))
    Kit.box(self, "Bridge", Vector3(0, 0.6, -13.5), Vector3(4.0, 0.5, 9.0), stone, true)
    for x in [-2.0, 2.0]:
        Kit.box(self, "Bridge parapet", Vector3(x, 1.2, -13.5), Vector3(0.4, 0.8, 9.0), stone)

func _house() -> void:
    var wing := Kit.tex_mat_tiles("res://assets/rolduc_wing.png", Vector2(3.2, 4.0))
    var c := Vector3(0, 0, -27.0)
    Kit.box(self, "Plinth", c + Vector3(0, 0.8, 0), Vector3(18.4, 1.6, 14.4), stone, true)
    Kit.box(self, "House", c + Vector3(0, 1.6 + 6.0, 0), Vector3(18.0, 12.0, 14.0), Color.WHITE, true, wing)
    for sx in [-1.0, 1.0]:
        for sz in [-1.0, 1.0]:
            Kit.box(self, "Quoin", c + Vector3(sx * 8.95, 7.6, sz * 6.95), Vector3(0.3, 12.0, 0.3), stone)
    Kit.box(self, "Cornice", c + Vector3(0, 13.75, 0), Vector3(18.8, 0.3, 14.8), Color("e8e4da"))
    # mansardedak: steil onderschild (afgeknotte piramide) en een plat bovendak
    Kit.frustum(self, "Mansard", c + Vector3(0, 13.9, 0), 18.6, 14.6, 1.6, 4.0, slate)
    Kit.frustum(self, "Mansard top", c + Vector3(0, 17.9, 0), 15.4, 11.4, 5.7, 1.4, Color("50555b"))
    for x in [-5.0, 0.0, 5.0]:
        Kit.box(self, "Dormer", c + Vector3(x, 15.6, 6.2), Vector3(1.5, 2.0, 1.4), Color("efede6"))
        Kit.box(self, "Dormer glass", c + Vector3(x, 15.5, 6.92), Vector3(0.9, 1.3, 0.04), Color("2c3438"))
        Kit.box(self, "Dormer cap", c + Vector3(x, 16.75, 6.2), Vector3(1.8, 0.3, 1.7), slate)
    for x in [-6.0, 6.0]:
        Kit.box(self, "Chimney", c + Vector3(x, 19.5, 0), Vector3(1.0, 3.0, 1.0), Color("8a5446"))
    # lagere zijvleugel links
    var w := c + Vector3(-15.0, 0, 1.0)
    Kit.box(self, "Side wing", w + Vector3(0, 1.6 + 3.6, 0), Vector3(12.0, 7.2, 10.0), Color.WHITE, true, wing)
    Kit.box(self, "Side wing plinth", w + Vector3(0, 0.8, 0), Vector3(12.4, 1.6, 10.4), stone)
    Kit.frustum(self, "Side wing roof", w + Vector3(0, 8.8, 0), 12.6, 10.6, 5.3, 4.2, slate)

# Hoevegebouw van geelbruine baksteen met een schilddak; ramen en dakkapellen naar de straat.
func _range(n: String, x0: float, x1: float, z_front: float, depth: float, dormers: int, windows: Array) -> void:
    var cx: float = (x0 + x1) * 0.5
    var ln: float = absf(x1 - x0)
    var zc: float = z_front - depth * 0.5
    var wall_h := 5.2
    Kit.box(self, n, Vector3(cx, wall_h * 0.5, zc), Vector3(ln, wall_h, depth), Color.WHITE, true, brick)
    Kit.box(self, n + " plinth", Vector3(cx, 0.35, z_front + 0.03), Vector3(ln, 0.7, 0.1), Color("8f8a80"))
    Kit.frustum(self, n + " roof", Vector3(cx, wall_h - 0.1, zc), ln + 0.8, depth + 0.8, (depth + 0.8) * 0.5, 5.6, tiles)
    Kit.box(self, n + " gutter", Vector3(cx, wall_h - 0.15, z_front + 0.4), Vector3(ln + 0.6, 0.18, 0.18), Color("6a6c6e"))
    var f := Kit.face(self, Vector3(cx, 0, z_front), 0.0)
    for w in windows:
        # [x, y, breedte, hoogte] met natuurstenen omlijsting
        Kit.box(f, "Window surround", Vector3(w[0], w[1] + w[3] * 0.5, 0.03), Vector3(w[2] + 0.3, w[3] + 0.3, 0.08), stone)
        Kit.box(f, "Window", Vector3(w[0], w[1] + w[3] * 0.5, 0.06), Vector3(w[2], w[3], 0.04), Color("2c3438"))
        Kit.box(f, "Window bar", Vector3(w[0], w[1] + w[3] * 0.5, 0.09), Vector3(0.06, w[3], 0.03), Color("efede6"))
    for k in range(dormers):
        var dx: float = cx - ln * 0.3 + float(k) * ln * 0.6 / maxf(1.0, float(dormers - 1))
        var dz: float = z_front - 1.4
        Kit.box(self, "Dormer", Vector3(dx, wall_h + 1.2, dz), Vector3(1.2, 1.1, 1.6), Color("efede6"))
        Kit.box(self, "Dormer glass", Vector3(dx, wall_h + 1.15, dz + 0.81), Vector3(0.7, 0.7, 0.04), Color("2c3438"))
        var dr := Kit.frustum(self, "Dormer roof", Vector3(dx, wall_h + 1.75, dz), 1.5, 1.9, 0.75, 0.6, tiles)
        dr.name = "Dormer roof"
    for k in range(int(ln / 9.0)):
        Kit.box(self, n + " chimney", Vector3(x0 + (x1 - x0) * (float(k) + 0.5) / float(int(ln / 9.0)), wall_h + 4.6, zc + 0.8), Vector3(0.8, 2.0, 0.8), Color("8a6a52"))

var brick: Material
var tiles := Color("4b4d50")

# Natuurstenen hoekblokken (om en om lang en kort) op een hoek in face-ruimte.
func _quoins(f: Node3D, x: float, h: float, side: float) -> void:
    var k := 0
    var y := 0.6
    while y < h:
        var long: bool = k % 2 == 0
        Kit.box(f, "Quoin", Vector3(x - side * (0.45 if long else 0.25), y + 0.24, 0.06), Vector3(0.9 if long else 0.5, 0.46, 0.14), stone)
        Kit.box(f, "Quoin side", Vector3(x + side * 0.06, y + 0.24, -(0.25 if long else 0.45)), Vector3(0.14, 0.46, 0.5 if long else 0.9), stone)
        y += 0.5
        k += 1

func _bailey() -> void:
    brick = Kit.tex_mat("res://assets/cortenbach_brick.png", Color(0.76, 0.86, 0.84), 3.0)
    var zf := -2.0
    # voorste vleugels links en rechts van het poortgebouw; rechts met dakkapellen en ramen
    _range("Front range L", -30.0, -3.4, zf, 9.0, 0, [[-9.0, 1.6, 0.9, 1.2]])
    _range("Front range R", 3.4, 34.0, zf, 9.0, 5, [[-12.0, 1.2, 0.6, 0.6], [-10.0, 1.2, 0.6, 0.6], [-7.5, 2.4, 0.8, 1.5],
        [-4.0, 1.2, 0.6, 0.6], [-1.5, 1.2, 0.6, 0.6], [1.5, 2.2, 0.8, 1.6], [5.0, 2.2, 0.8, 1.6], [9.0, 2.2, 0.8, 1.6], [12.5, 1.2, 0.6, 0.6]])
    _range("Side range", -39.0, -30.0, zf, 32.0, 0, [])
    # vierkante hoektoren rechts achteraan, met een leien schilddak en een lantaarn
    var ct := Vector3(37.5, 0, -6.0)
    Kit.box(self, "Corner tower", ct + Vector3(0, 5.5, 0), Vector3(6.0, 11.0, 6.0), Color.WHITE, true, brick)
    var ctf := Kit.face(self, ct + Vector3(0, 0, 3.0), 0.0)
    _quoins(ctf, -3.0, 11.0, -1.0)
    _quoins(ctf, 3.0, 11.0, 1.0)
    Kit.box(ctf, "Corner tower shutters", Vector3(0, 7.0, 0.05), Vector3(0.8, 1.1, 0.06), Color("8a2a24"))
    Kit.frustum(self, "Corner tower roof", ct + Vector3(0, 11.0, 0), 7.0, 7.0, 2.2, 2.0, tiles)
    Kit.box(self, "Corner tower lantern", ct + Vector3(0, 14.0, 0), Vector3(2.6, 2.0, 2.6), Color("5a5d62"))
    Kit.pyramid(self, "Corner tower cap", ct + Vector3(0, 15.0, 0), 1.6, 2.6, tiles)
    Kit.cyl(self, "Corner tower vane", ct + Vector3(0, 18.2, 0), 0.04, 0.04, 1.6, Color("2a2a2a"), 6)
    # poortgebouw: vierkante toren met natuurstenen hoekblokken en rondboog
    var g := Vector3(0, 0, zf - 3.2)
    var th := 12.0
    Kit.box(self, "Gate tower", g + Vector3(0, th * 0.5, 0), Vector3(6.8, th, 7.0), Color.WHITE, true, brick)
    var f := Kit.face(self, g + Vector3(0, 0, 3.5), 0.0)
    _quoins(f, -3.4, th, -1.0)
    _quoins(f, 3.4, th, 1.0)
    Kit.box(f, "Gate plinth", Vector3(0, 0.3, 0.05), Vector3(6.8, 0.6, 0.12), stone)
    # doorgang met donkere tunnel, rondboog van natuursteen en een open rode deur
    Kit.box(f, "Passage", Vector3(0, 1.8, 0.02), Vector3(3.2, 3.6, 0.04), Color("1d1d1b"))
    Kit.cyl(f, "Passage arch", Vector3(0, 3.6, 0.02), 1.6, 1.6, 0.04, Color("1d1d1b"), 18, "z")
    for sx in [-1.0, 1.0]:
        for k in range(6):
            var bw: float = 0.7 if k % 2 == 0 else 0.5
            Kit.box(f, "Jamb", Vector3(sx * (1.6 + bw * 0.5), 0.3 + float(k) * 0.55 + 0.27, 0.07), Vector3(bw, 0.52, 0.14), stone)
    for k in range(11):
        var a: float = PI * (float(k) + 0.5) / 11.0
        var v := Kit.box(f, "Voussoir", Vector3(cos(a) * 1.95, 3.6 + sin(a) * 1.95, 0.07), Vector3(0.7, 0.5, 0.14), stone)
        v.rotation.z = a
    var door := Kit.box(f, "Gate door", Vector3(1.25, 2.0, -0.9), Vector3(1.5, 4.0, 0.1), Color("8a2a24"))
    door.rotation.y = 1.2
    # natuurstenen plaquette met krullen boven de poort
    Kit.box(f, "Plaque", Vector3(0, 6.3, 0.07), Vector3(1.4, 0.9, 0.12), stone)
    for sx in [-1.0, 1.0]:
        Kit.cyl(f, "Volute", Vector3(sx * 1.05, 6.1, 0.1), 0.25, 0.25, 0.14, stone, 10, "z")
        Kit.box(f, "Console", Vector3(sx * 2.6, 5.8, 0.25), Vector3(0.35, 0.5, 0.5), stone)
    # twee vensters boven elkaar en het wapenschild (rood met een geel teken)
    for y in [7.4, 8.9]:
        Kit.box(f, "Tower window surround", Vector3(0, y + 0.55, 0.04), Vector3(1.0, 1.3, 0.08), stone)
        Kit.box(f, "Tower window", Vector3(0, y + 0.55, 0.07), Vector3(0.7, 1.0, 0.04), Color("efede6"))
        for qy in [0.33, 0.77]:
            for qx in [-0.17, 0.17]:
                Kit.box(f, "Pane", Vector3(qx, y + qy, 0.1), Vector3(0.26, 0.36, 0.02), Color("2c3438"))
    Kit.box(f, "Coat of arms", Vector3(-1.0, 7.6, 0.07), Vector3(0.6, 0.8, 0.06), Color("b8282a"))
    Kit.box(f, "Coat of arms mark", Vector3(-1.0, 7.6, 0.11), Vector3(0.26, 0.5, 0.02), Color("e8c03a"))
    # schilddak met uitlopende rand, een hals en een grote leien ui met windvaan
    Kit.frustum(self, "Gate roof eave", g + Vector3(0, th, 0), 8.2, 8.4, 0.8, 0.6, tiles)
    Kit.frustum(self, "Gate roof", g + Vector3(0, th + 0.6, 0), 6.6, 6.8, 2.6, 2.6, tiles)
    Kit.box(self, "Onion neck", g + Vector3(0, th + 3.6, 0), Vector3(1.1, 1.4, 1.1), Color("3a3d42"))
    var onion := MeshInstance3D.new()
    onion.name = "Onion"
    var sm := SphereMesh.new()
    sm.radius = 1.6
    sm.height = 3.6
    sm.radial_segments = 16
    sm.rings = 10
    onion.mesh = sm
    onion.material_override = Kit.mat(Color("2f3236"), 0.0, 0.3, 0.5)
    onion.position = g + Vector3(0, th + 6.0, 0)
    add_child(onion)
    Kit.cyl(self, "Onion tip", g + Vector3(0, th + 8.1, 0), 0.5, 0.05, 1.0, Color("2f3236"), 10)
    Kit.cyl(self, "Onion spike", g + Vector3(0, th + 9.3, 0), 0.04, 0.04, 1.8, Color("2a2a2a"), 6)
    Kit.box(self, "Vane", g + Vector3(0.3, th + 9.8, 0), Vector3(0.6, 0.25, 0.03), Color("2a2a2a"))
    # ronde toren met een slanke spits links achteraan
    var t := Vector3(-27.0, 0, -18.0)
    Kit.cyl(self, "Round tower", t + Vector3(0, 5.0, 0), 3.0, 2.9, 10.0, marl, 16, "y", true)
    Kit.cyl(self, "Round tower eave", t + Vector3(0, 10.2, 0), 3.4, 3.1, 0.4, tiles, 16)
    Kit.cyl(self, "Round tower roof", t + Vector3(0, 10.4 + 5.0, 0), 3.1, 0.0, 10.0, tiles, 16)
    Kit.cyl(self, "Round tower spike", t + Vector3(0, 21.0, 0), 0.05, 0.03, 1.6, Color("2a2a2a"), 6)
    # open karschuur links van de voorplaats, met rode houten palen
    var sx0 := -15.0
    Kit.box(self, "Shed back wall", Vector3(sx0 - 2.8, 1.3, 6.0), Vector3(0.4, 2.6, 15.0), Color.WHITE, true, brick)
    Kit.box(self, "Shed end wall", Vector3(sx0, 1.3, -1.3), Vector3(6.0, 2.6, 0.4), Color.WHITE, true, brick)
    var sr := Kit.gable(self, "Shed roof", Vector3(sx0, 2.7, 6.0), 7.0, 15.6, 1.4, Color("4a4f4a"))
    sr.name = "Shed roof"
    for k in range(6):
        Kit.box(self, "Shed post", Vector3(sx0 + 2.9, 1.35, -0.8 + float(k) * 2.95), Vector3(0.25, 2.7, 0.25), Color("7a3a2a"), true)
        Kit.beam(self, "Shed brace", Vector3(sx0 + 2.9, 2.2, -0.8 + float(k) * 2.95), Vector3(sx0 + 2.9, 2.65, -0.2 + float(k) * 2.95), 0.12, Color("7a3a2a"))
    # voorplaats van grind, haag voor de rechtervleugel en oude bomen
    Kit.box(self, "Forecourt", Vector3(6.0, 0.04, 6.0), Vector3(44.0, 0.08, 16.0), Color("857e72"))
    Kit.box(self, "Hedge", Vector3(22.0, 0.8, zf + 0.9), Vector3(22.0, 1.6, 1.2), Color("3f5f30"))
    for tp in [Vector3(-22, 0, 13), Vector3(18, 0, 13), Vector3(27, 0, 9)]:
        Kit.cyl(self, "Tree trunk", tp + Vector3(0, 4.0, 0), 0.55, 0.4, 8.0, Color("5b5148"), 8, "y", true)
        var cr := MeshInstance3D.new()
        var cm := SphereMesh.new()
        cm.radius = 5.0
        cm.height = 7.0
        cm.radial_segments = 10
        cm.rings = 5
        cr.mesh = cm
        cr.material_override = Kit.mat(Color("5d7a3e"))
        cr.position = tp + Vector3(0, 10.0, 0)
        add_child(cr)
    # binnenplaats achter de poort
    Kit.box(self, "Courtyard", Vector3(0, 0.05, -14.0), Vector3(60.0, 0.1, 6.0), Color("9e9583"))
