extends "res://scripts/levels/level_base.gd"
# Level 2: Kerkrade. Start op de Nieuwstraat / Neustraße, waar de grens met Duitsland
# midden over de straat loopt, langs de poort van Abdij Rolduc, dan westwaarts naar de
# finish bij het Parkstad Limburg Stadion. Het stratenplan is verzonnen en compact.
# Nieuwstraat naar jouw Street View-foto's (20-11): gewone straat zonder middenberm, lage
# heggen met bomen langs de stoep, links (Duitse kant) wit gestucte en donkere huizen,
# de Lidl en de MediaMarkt, rechts (Nederlandse kant) rode bakstenen rijtjeshuizen met
# witte rolluiken en een flat met balkons; een blauwe Duitse bushalte.
const LmRolduc = preload("res://scripts/landmarks/landmark_rolduc.gd")
const PlsSite = preload("res://scripts/places/pls_site.gd")
const LmDiscovery = preload("res://scripts/landmarks/landmark_discovery.gd")
const LmGaia = preload("res://scripts/landmarks/landmark_gaiazoo.gd")
const LmNulland = preload("res://scripts/landmarks/landmark_nulland.gd")

const ROLDUC_POS := Vector3(-180, 0, -74)
const PLS_POS := Vector3(-360, 0, -670)
const BORDER_Z0 := 430.0   # grensstraat van z 430 tot z 40
const BORDER_Z1 := 40.0

func build() -> void:
    level_title = "KERKRADE"
    seed_value = 4613
    # rondje: langs het parkeerterrein van het stadion naar het oosten en terug naar de grensstraat
    route = Route.new([
        Vector3(0, 0, 460),
        Vector3(0, 0, 0),
        Vector3(-320, 0, 0),
        Vector3(-420, 0, -110),
        Vector3(-420, 0, -250),
        Vector3(-360, 0, -340),
        Vector3(-360, 0, -530),
        Vector3(200, 0, -530),
        Vector3(200, 0, 620),
        Vector3(0, 0, 620),
    ], [40.0, 70.0, 70.0, 70.0, 70.0, 60.0, 80.0, 80.0, 60.0], true)
    checkpoints = [
        {"at": Vector3(0, 0, 150), "name": "NIEUWSTRAAT / NEUSTRASSE"},
        {"at": Vector3(-255, 0, 0), "name": "ABDIJ ROLDUC"},
        {"at": Vector3(-420, 0, -200), "name": "KERKRADE-WEST"},
        {"at": Vector3(-360, 0, -470), "name": "PARKSTAD LIMBURG STADION"},
        {"at": Vector3(30, 0, -530), "name": "SCHACHT NULLAND"},
        {"at": Vector3(200, 0, -140), "name": "DISCOVERY MUSEUM"},
        {"at": Vector3(200, 0, 330), "name": "GAIAZOO"},
    ]

    place(LmRolduc.new(), ROLDUC_POS)
    exclude_box(ROLDUC_POS, Vector3(-61, 0, -51), Vector3(61, 0, 59), 4.0)
    place(PlsSite.new(), PLS_POS)
    exclusions.append(Rect2(PLS_POS.x - 100, PLS_POS.z - 75, 200, 190))

    # na het stadion oostwaarts: Schacht Nulland, links van de weg (de ventilatortoren
    # staat aan de achterkant)
    place_beside(LmNulland.new(), route.closest_s(Vector3(-40, 0, -530)), -1.0, 22.0, Vector2(40, 22))
    # terugweg naar het noorden, links van de weg: eerst het Discovery Museum (bij station
    # Kerkrade-Centrum), verderop de uitkijktoren van GaiaZOO
    place_beside(LmDiscovery.new(), route.closest_s(Vector3(200, 0, -250)), -1.0, 28.0, Vector2(40, 86))
    exclusions.append(Rect2(188, -420, 90, 86))       # grasveld met de mijnrelikwieën ervoor
    place_beside(LmGaia.new(), route.closest_s(Vector3(200, 0, 250)), -1.0, 30.0, Vector2(32, 36))
    exclusions.append(Rect2(188, 150, 90, 66))        # open zicht op de toren

    # Nieuwstraat: eigen bebouwing, geen standaard flatblokken
    exclusions.append(Rect2(-48.0, BORDER_Z1 + 10.0, 32.0, BORDER_Z0 - BORDER_Z1 + 20.0))
    exclusions.append(Rect2(16.0, BORDER_Z1 + 10.0, 32.0, BORDER_Z0 - BORDER_Z1 + 20.0))
    finish_line(2)   # lange ronde: 2 ronden
    build_road()
    _border_street()
    # oude mijnstad: rijtjes en mijnwerkerswoningen, een paar winkels en flats
    street_mix = {"row": 3, "mine": 3, "shop": 1, "flat": 1, "semi": 1}
    build_streetscape()
    _border_name_plates()
    town_board(60.0, 1.0, Color("e8c21e"), [["name", ["Kerkrade"]], ["limit", "50"], ["bars", 2]])   # naar jouw foto: geen dialectnaam
    street_sign("ABDIJ ROLDUC", Vector3(-60, 4.0, -11))
    street_sign("PARKSTAD LIMBURG STADION", route.pos_at(route.closest_s(Vector3(-360, 0, -400))) + Vector3(-11, 4.0, 0))

# Nieuwstraat / Neustraße: heggen met bomen achter de stoep, huizen aan beide kanten,
# de Lidl bij de start en de MediaMarkt aan het eind (Duitse kant, links = -x).
func _border_street() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 2210
    _hedges(rng)
    # Duitse kant: Lidl bij de start, MediaMarkt aan het eind, daartussen huizen
    _lidl(Vector3(-30.0, 0, 385.0))
    _mediamarkt(Vector3(-32.0, 0, 95.0))
    _houses(-1.0, 345.0, 135.0, rng)
    # Nederlandse kant: rijtjes en een flat
    _flat(Vector3(25.0, 0, 160.0))
    _houses(1.0, 420.0, 185.0, rng)
    _houses(1.0, 135.0, 60.0, rng)
    _bus_shelter_de(Vector3(-10.6, 0, 210.0))
    exclusions.append(Rect2(-13.5, 202.0, 4.0, 18.0))
    var s: float = route.closest_s(Vector3(0, 0, BORDER_Z0))
    while s < route.closest_s(Vector3(0, 0, BORDER_Z1)):
        town_s.append(s)
        s += 27.0

# Lage heggen achter het trottoir met een rij bomen erin, met onderbrekingen.
func _hedges(rng: RandomNumberGenerator) -> void:
    var hedge := Kit.mat(Color("4f6b34"))
    var leaf := [Color("3f6a32"), Color("4d7a38"), Color("5a8340")]
    for side in [-1.0, 1.0]:
        var z: float = BORDER_Z0 - 4.0
        while z > BORDER_Z1 + 12.0:
            var l: float = rng.randf_range(16.0, 26.0)
            var zc: float = z - l * 0.5
            if _hedge_gap(side, z - l, z):
                z -= l + rng.randf_range(3.0, 6.0)
                continue
            Kit.box(self, "Hedge", Vector3(side * 12.3, 0.5, zc), Vector3(1.3, 1.0, l), Color.WHITE, false, hedge)
            z -= l + rng.randf_range(3.0, 6.0)
        z = BORDER_Z0 - 12.0
        while z > BORDER_Z1 + 15.0:
            var p := Vector3(side * 12.3, 0, z)
            if _hedge_gap(side, z - 3.0, z + 3.0) or near_lamp(p, 2.0):
                z -= 8.0
                continue
            Kit.cyl(self, "Street tree trunk", p + Vector3(0, 2.2, 0), 0.2, 0.17, 4.4, Color("6a5a48"), 8, "y", true)
            var sz: float = rng.randf_range(0.85, 1.15)
            _blob(p + Vector3(0, 6.8 * sz, 0), Vector3(6.4, 5.6, 6.4) * sz, leaf[rng.randi_range(0, 2)])
            _blob(p + Vector3(0.9, 8.2 * sz, 0.6), Vector3(4.2, 3.6, 4.2) * sz, leaf[rng.randi_range(0, 2)])
            z -= rng.randf_range(16.0, 22.0)

func _blob(pos: Vector3, size: Vector3, color: Color) -> void:
    var mi := MeshInstance3D.new()
    mi.name = "Street tree crown"
    var sm := SphereMesh.new()
    sm.radius = 0.5
    sm.height = 1.0
    sm.radial_segments = 10
    sm.rings = 5
    mi.mesh = sm
    mi.material_override = Kit.mat(color)
    mi.scale = size
    mi.position = pos
    add_child(mi)

# Gaten in de heg: bij de Duitse bushalte en bij het plaatsnaambord.
const HEDGE_GAPS := [[-1.0, 198.0, 222.0]]
func _hedge_gap(side: float, z0: float, z1: float) -> bool:
    for g in HEDGE_GAPS:
        if float(g[0]) == side and z1 > float(g[1]) and z0 < float(g[2]):
            return true
    return false

# Huizen langs één kant, van z0 naar z1. side -1 = Duitse kant, +1 = Nederlandse kant.
func _houses(side: float, z0: float, z1: float, rng: RandomNumberGenerator) -> void:
    var z: float = z0
    var nl_brick := [Color("a8573c"), Color("b4654a"), Color("9a4e37")]
    var de_walls := [Color("ece8de"), Color("e2dccd"), Color("7a5545"), Color("8c6a52"), Color("d9cfbd")]
    var roofs := [Color("4a3a33"), Color("3c3d40"), Color("5a463c")]
    while z > z1:
        var w: float = rng.randf_range(7.0, 10.0) if side < 0.0 else rng.randf_range(5.5, 6.5) * float(rng.randi_range(3, 5))
        if z - w < z1:
            break
        var depth: float = rng.randf_range(9.0, 11.0)
        var front: float = rng.randf_range(15.0, 17.5)
        var c := Vector3(side * (front + depth * 0.5), 0, z - w * 0.5)
        if side < 0.0:
            _house_de(c, w, depth, de_walls[rng.randi_range(0, de_walls.size() - 1)], roofs[rng.randi_range(0, 2)], rng)
            z -= w + rng.randf_range(2.0, 6.0)
        else:
            _row_nl(c, w, depth, nl_brick[rng.randi_range(0, 2)], roofs[rng.randi_range(0, 2)], rng)
            z -= w + rng.randf_range(4.0, 9.0)

# Duits huis: twee verdiepingen, gestuct of donkere baksteen, zadeldak met de nok langs
# de straat, schoorsteen, soms een donker beklede bovenverdieping of een dakkapel.
func _house_de(c: Vector3, w: float, depth: float, wall: Color, roof: Color, rng: RandomNumberGenerator) -> void:
    var side: float = signf(c.x)
    var h := 6.0
    Kit.box(self, "DE house", c + Vector3(0, h * 0.5, 0), Vector3(depth, h, w), wall, true)
    if rng.randf() < 0.3:
        Kit.box(self, "DE upper cladding", c + Vector3(0, h * 0.75, 0), Vector3(depth + 0.04, h * 0.5, w + 0.04), Color("2f2b2a"))
    Kit.gable(self, "DE roof", c + Vector3(0, h, 0), depth + 1.0, w + 0.6, 4.2, roof)
    Kit.box(self, "Chimney", c + Vector3(0, h + 3.6, w * 0.3), Vector3(0.6, 2.2, 0.6), Color("6d625a"))
    var f := Kit.face(self, c + Vector3(-side * depth * 0.5, 0, 0), -90.0 * side)
    var n: int = maxi(2, int(w / 2.6))
    for k in range(n):
        var x: float = -w * 0.5 + w * (float(k) + 0.5) / float(n)
        Kit.box(f, "Window", Vector3(x, 4.3, 0.04), Vector3(1.1, 1.2, 0.08), Color("2f3a40"))
        Kit.box(f, "Window frame", Vector3(x, 4.3, 0.02), Vector3(1.3, 1.4, 0.04), Color("f2f2ee"))
        if k == 0:
            Kit.box(f, "Door", Vector3(x, 1.1, 0.04), Vector3(1.0, 2.2, 0.08), Color("3b3532"))
        else:
            Kit.box(f, "Window", Vector3(x, 1.5, 0.04), Vector3(1.2, 1.3, 0.08), Color("2f3a40"))
            Kit.box(f, "Window frame", Vector3(x, 1.5, 0.02), Vector3(1.4, 1.5, 0.04), Color("f2f2ee"))
    if rng.randf() < 0.4:
        Kit.box(self, "Dormer", c + Vector3(-side * (depth * 0.25), h + 1.4, 0), Vector3(1.6, 1.8, 2.4), Color("3c3d40"))
        Kit.box(self, "Dormer window", c + Vector3(-side * (depth * 0.25 + 0.82), h + 1.4, 0), Vector3(0.04, 1.0, 1.6), Color("2f3a40"))

# Nederlands rijtje: rode baksteen, twee lagen met witte rolluikkasten, wit gestucte plint,
# doorlopend zadeldak met de nok langs de straat en schoorstenen.
func _row_nl(c: Vector3, w: float, depth: float, brick: Color, roof: Color, rng: RandomNumberGenerator) -> void:
    var side: float = signf(c.x)
    var h := 6.2
    Kit.box(self, "NL row", c + Vector3(0, h * 0.5, 0), Vector3(depth, h, w), brick, true)
    Kit.gable(self, "NL roof", c + Vector3(0, h, 0), depth + 1.0, w + 0.4, 4.0, roof)
    var f := Kit.face(self, c + Vector3(-side * depth * 0.5, 0, 0), -90.0 * side)
    Kit.box(f, "Plinth", Vector3(0, 0.35, 0.03), Vector3(w, 0.7, 0.06), Color("e8e6e0"))
    var units: int = maxi(2, int(round(w / 6.0)))
    var uw: float = w / float(units)
    for u in range(units):
        var ux: float = -w * 0.5 + uw * (float(u) + 0.5)
        Kit.box(self, "Chimney", c + Vector3(0, h + 3.2, ux * side), Vector3(0.5, 1.6, 0.5), Color("7a4a38"))
        Kit.box(f, "Door", Vector3(ux - uw * 0.3, 1.1, 0.05), Vector3(1.0, 2.2, 0.08), Color("5a3a2c"))
        # raam beneden en twee ramen boven, met witte rolluikkast en lateien
        Kit.box(f, "Window", Vector3(ux + uw * 0.15, 1.6, 0.05), Vector3(2.0, 1.4, 0.08), Color("2f3a40"))
        Kit.box(f, "Shutter box", Vector3(ux + uw * 0.15, 2.45, 0.07), Vector3(2.1, 0.3, 0.12), Color("f2f2ee"))
        for wx in [ux - uw * 0.22, ux + uw * 0.22]:
            Kit.box(f, "Window", Vector3(wx, 4.4, 0.05), Vector3(1.2, 1.3, 0.08), Color("2f3a40"))
            Kit.box(f, "Roller shutter", Vector3(wx, 4.9, 0.08), Vector3(1.25, 0.45, 0.08), Color("f2f2ee"))
            Kit.box(f, "Sill", Vector3(wx, 3.7, 0.1), Vector3(1.4, 0.1, 0.18), Color("e8e6e0"))

# Flat van drie lagen in rode baksteen met witte balkons (Nederlandse kant).
func _flat(c: Vector3) -> void:
    var w := 30.0
    var depth := 12.0
    var h := 9.3
    Kit.box(self, "Flat", c + Vector3(0, h * 0.5, 0), Vector3(depth, h, w), Color("b06a4a"), true)
    Kit.gable(self, "Flat roof", c + Vector3(0, h, 0), depth + 0.8, w + 0.4, 3.0, Color("4a3a33"))
    var f := Kit.face(self, c + Vector3(-depth * 0.5, 0, 0), -90.0)
    for fl in range(3):
        var y: float = 1.0 + float(fl) * 3.1
        for k in range(5):
            var x: float = -12.0 + float(k) * 6.0
            Kit.box(f, "Flat window", Vector3(x + 1.6, y + 0.8, 0.05), Vector3(1.6, 1.4, 0.08), Color("2f3a40"))
            Kit.box(f, "Flat door", Vector3(x - 0.8, y + 1.0, 0.05), Vector3(1.0, 2.1, 0.08), Color("2f3a40"))
            Kit.box(f, "Balcony", Vector3(x - 0.8, y, 0.75), Vector3(2.6, 0.18, 1.5), Color("e4e2dc"))
            for bx in [-2.05, 0.45]:
                Kit.box(f, "Balcony rail", Vector3(x + bx * 0.5 - 0.15, y + 0.55, 1.45), Vector3(1.25, 0.9, 0.05), Color("f2f2ee"))

# Supermarkt met lage zadelkap, witte gevel, grijs dak, blauw logo en een reclamezuil.
func _lidl(c: Vector3) -> void:
    var depth := 28.0
    var w := 40.0
    var h := 5.5
    Kit.box(self, "Lidl", c + Vector3(-6.0, h * 0.5, 0), Vector3(depth, h, w), Color("eceeee"), true)
    Kit.gable(self, "Lidl roof", c + Vector3(-6.0, h, 0), depth + 1.2, w + 1.2, 2.2, Color("8f979c"))
    Kit.box(self, "Lidl band", c + Vector3(-6.0 + depth * 0.5 + 0.05, h - 0.6, 0), Vector3(0.1, 0.8, w), Color("8f979c"))
    var f := Kit.face(self, c + Vector3(-6.0 + depth * 0.5, 0, 0), 90.0)
    _lidl_logo(f, Vector3(-8.0, 3.6, 0.12), 2.6)
    Kit.box(f, "Lidl glass", Vector3(8.0, 1.4, 0.05), Vector3(10.0, 2.8, 0.08), Color("3d4f5a"))
    # parkeerterrein met klinkers tussen winkel en straat en de reclamezuil
    Kit.box(self, "Lidl parking", c + Vector3(12.5, 0.05, 0), Vector3(9.0, 0.1, w), Color("8f8a84"))
    var pole := c + Vector3(15.5, 0, -16.0)
    Kit.box(self, "Lidl pole", pole + Vector3(0, 4.0, 0), Vector3(0.35, 8.0, 0.35), Color("8f979c"), true)
    var pf := Kit.face(self, pole + Vector3(0.2, 0, 0), 90.0)
    _lidl_logo(pf, Vector3(-1.4, 6.5, 0.0), 2.6)
    Kit.box(pf, "Opening hours", Vector3(-1.4, 4.4, 0.0), Vector3(2.4, 1.2, 0.1), Color("f4f4f2"))
    Kit.label(pf, "Mo - Sa\n7 - 21 Uhr", Vector3(-1.4, 4.4, 0.06), 0.006, Color("1f4fa0"), 48)
    var pb := Kit.face(self, pole + Vector3(-0.2, 0, 0), -90.0)
    _lidl_logo(pb, Vector3(1.4, 6.5, 0.0), 2.6)

func _lidl_logo(f: Node3D, p: Vector3, size: float) -> void:
    Kit.box(f, "Logo blue", p, Vector3(size, size, 0.12), Color("1f4fa0"))
    Kit.cyl(f, "Logo yellow", p + Vector3(0, 0, 0.07), size * 0.42, size * 0.42, 0.04, Color("f2d22e"), 24, "z")
    Kit.label(f, "LIDL", p + Vector3(0, 0, 0.1), size * 0.0042, Color("1f4fa0"), 64)

# Elektronicazaak: lange grijze hal met golfplaat, een hoge trappentoren en het rode bord.
func _mediamarkt(c: Vector3) -> void:
    var depth := 26.0
    var w := 60.0
    var h := 10.0
    Kit.box(self, "MediaMarkt hall", c + Vector3(-4.0, h * 0.5, 0), Vector3(depth, h, w), Color("b6bcc0"), true)
    var f := Kit.face(self, c + Vector3(-4.0 + depth * 0.5, 0, 0), 90.0)
    for k in range(30):
        Kit.box(f, "Cladding rib", Vector3(-w * 0.5 + 1.0 + float(k) * 2.0, h * 0.5, 0.04), Vector3(0.12, h, 0.08), Color("a2a9ad"))
    # trappentoren met natuursteen en een schuine kap
    var t := c + Vector3(-4.0 + depth * 0.5 + 2.5, 0, 18.0)
    Kit.box(self, "MediaMarkt tower", t + Vector3(0, 7.5, 0), Vector3(5.0, 15.0, 5.0), Color("9a9fa2"), true)
    Kit.pyramid(self, "MediaMarkt tower roof", t + Vector3(0, 15.0, 0), 2.8, 1.6, Color("6d7275"))
    Kit.box(self, "MediaMarkt tower glass", t + Vector3(2.52, 8.0, 0), Vector3(0.05, 12.0, 1.0), Color("3d4f5a"))
    # rood bord en geel ingangsbord
    var sign := c + Vector3(13.0, 0, 6.0)
    for x in [-1.2, 1.2]:
        Kit.box(self, "MM sign post", sign + Vector3(0, 0.9, x), Vector3(0.12, 1.8, 0.12), Color("8f979c"))
    var sf := Kit.face(self, sign + Vector3(0.1, 0, 0), 90.0)
    Kit.box(sf, "MM sign", Vector3(0, 2.9, 0), Vector3(4.6, 2.2, 0.12), Color("df1f26"))
    Kit.label(sf, "MediaMarkt", Vector3(0, 3.3, 0.08), 0.0115, Color.WHITE, 64)
    Kit.label(sf, "Kostenlose Parkplätze", Vector3(0, 2.4, 0.08), 0.006, Color.WHITE, 48)
    Kit.box(f, "Entrance sign", Vector3(-10.0, 4.0, 0.12), Vector3(7.0, 1.4, 0.1), Color("f2d22e"))
    Kit.label(f, "Eingang  Selection Fitness", Vector3(-10.0, 4.0, 0.2), 0.008, Color("222222"), 48)
    Kit.box(f, "MM entrance", Vector3(-18.0, 1.4, 0.06), Vector3(3.0, 2.8, 0.08), Color("3d4f5a"))

# Duitse bushalte: blauw stalen frame met glas en een blauw bankje, haltepaal met bord.
func _bus_shelter_de(p: Vector3) -> void:
    var blue := Color("2346a0")
    var l := 6.0
    var d := 1.8
    for z in [-l * 0.5, 0.0, l * 0.5]:
        for x in [-d * 0.5, d * 0.5]:
            Kit.box(self, "DE shelter post", p + Vector3(-x - d * 0.5 - 0.4, 1.25, z), Vector3(0.1, 2.5, 0.1), blue)
    var roof := Kit.box(self, "DE shelter roof", p + Vector3(-d * 0.5 - 0.4, 2.6, 0), Vector3(d + 0.6, 0.12, l + 0.4), Color("5d86c8"))
    roof.rotation.z = 0.12
    Kit.box(self, "DE shelter glass", p + Vector3(-d - 0.4, 1.3, 0), Vector3(0.04, 2.0, l), Color("9fb8c8"))
    Kit.box(self, "DE shelter bench", p + Vector3(-d - 0.1, 0.45, 0), Vector3(0.4, 0.08, 2.6), blue)
    Kit.box(self, "DE stop pole", p + Vector3(0.3, 1.5, -l * 0.5 - 1.0), Vector3(0.1, 3.0, 0.1), Color("a9aeb1"))
    var sf := Kit.face(self, p + Vector3(0.3, 0, -l * 0.5 - 1.0), 0.0)
    Kit.box(sf, "DE stop sign", Vector3(0, 2.75, 0.06), Vector3(0.7, 0.7, 0.04), Color("f2d22e"))
    Kit.cyl(sf, "DE stop H ring", Vector3(0, 2.75, 0.09), 0.3, 0.3, 0.02, Color("2f8a3a"), 20, "z")
    Kit.label(sf, "H", Vector3(0, 2.75, 0.11), 0.007, Color("f2d22e"), 64)

# Straatnaamborden: Nederlands rechts (wit), Duits links (geel/zwart). Pas na de
# straatbebouwing plaatsen, zodat ze niet tegen een lantaarnpaal of plaatsnaambord staan.
func _border_name_plates() -> void:
    # EU-grensborden bij de start, achter het trottoir: links de Duitse kant, rechts de Nederlandse
    _eu_sign(Vector3(-12.2, 0, 432), 0.0, "Bundes-\nrepublik\nDeutschland")
    _eu_sign(Vector3(12.2, 0, 432), 0.0, "Nederland")
    for zz in [370.0, 250.0, 120.0]:
        for side in [1.0, -1.0]:
            var z: float = zz
            while near_lamp(Vector3(side * 10.6, 0, z), 2.0):
                z -= 1.5
            if side > 0.0:
                _name_plate("Nieuwstraat", Vector3(10.6, 2.6, z), Color("f4f4ee"), Color("1f4fa0"))
            else:
                _name_plate("Neustraße", Vector3(-10.6, 2.6, z), Color("f2f2f2"), Color("1a1a1a"))

# Landsgrensbord zoals in de EU: blauw vierkant met witte rand op twee palen, een
# krans van twaalf gele sterren en de landsnaam in witte letters in het midden.
func _eu_sign(pos: Vector3, yaw: float, text: String) -> void:
    var f := Node3D.new()
    f.name = "EU border sign"
    f.position = pos
    f.rotation.y = yaw
    add_child(f)
    var y := 3.0
    for x in [-0.55, 0.55]:
        Kit.cyl(f, "EU sign post", Vector3(x, y * 0.5, -0.06), 0.05, 0.05, y, Color("a9aeb1"), 10)
    Kit.box(f, "EU sign back", Vector3(0, y, -0.02), Vector3(1.7, 1.7, 0.02), Color("8d9396"))
    Kit.box(f, "EU sign border", Vector3(0, y, 0), Vector3(1.7, 1.7, 0.02), Color("f4f4ee"))
    Kit.box(f, "EU sign", Vector3(0, y, 0.012), Vector3(1.6, 1.6, 0.012), Color("1f4fa0"))
    for i in range(12):
        var a: float = TAU * float(i) / 12.0
        _star(f, Vector3(sin(a) * 0.62, y + cos(a) * 0.62, 0.022), 0.085, Color("f2c230"))
    var lines: PackedStringArray = text.split("\n")
    var longest := 0
    for l in lines:
        longest = maxi(longest, l.length())
    var font: Font = ThemeDB.fallback_font
    var w: float = 0.0
    for l in lines:
        w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x)
    # de tekst moet binnen de sterrenkrans passen
    var px: float = minf(0.0045, (0.95 if lines.size() > 1 else 1.0) / w)
    Kit.label(f, text, Vector3(0, y, 0.026), px, Color.WHITE, 64)

# Vijfpuntige ster (plat, voorkant naar +Z).
func _star(f: Node3D, pos: Vector3, rad: float, color: Color) -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var pts: Array = []
    for i in range(10):
        var a: float = PI * float(i) / 5.0
        var rr: float = rad if i % 2 == 0 else rad * 0.4
        pts.append(Vector3(sin(a) * rr, cos(a) * rr, 0))
    for i in range(10):
        st.add_vertex(Vector3.ZERO)
        st.add_vertex(pts[i])
        st.add_vertex(pts[(i + 1) % 10])
    var mi := MeshInstance3D.new()
    mi.name = "EU star"
    mi.mesh = st.commit()
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mi.material_override = m
    mi.position = pos
    f.add_child(mi)

func _name_plate(text: String, pos: Vector3, plate: Color, ink: Color) -> void:
    # de paal houdt op onder het bord (anders steekt hij door het dunne bord heen)
    var ph: float = pos.y - 0.22
    Kit.box(self, "Name plate post", Vector3(pos.x, ph * 0.5, pos.z), Vector3(0.08, ph, 0.08), Color("8a8f92"))
    Kit.box(self, "Name plate clamp", Vector3(pos.x, ph + 0.02, pos.z), Vector3(0.1, 0.05, 0.2), Color("6f7477"))
    Kit.box(self, "Name plate", pos, Vector3(0.05, 0.45, 2.2), ink)
    Kit.box(self, "Name plate face", pos, Vector3(0.07, 0.37, 2.1), plate)
    var side: float = signf(pos.x)
    var f := Kit.face(self, pos + Vector3(-side * 0.04, 0, 0), -90.0 * side)
    Kit.label(f, text, Vector3.ZERO, 0.004, ink, 64)
    var b := Kit.face(self, pos + Vector3(side * 0.04, 0, 0), 90.0 * side)
    Kit.label(b, text, Vector3.ZERO, 0.004, ink, 64)
