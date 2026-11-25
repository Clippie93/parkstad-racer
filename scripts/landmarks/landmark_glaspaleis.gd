extends Node3D
# SCHUNCK Glaspaleis, Heerlen (Frits Peutz, 1933-35), met de latere uitbreiding.
# Naar Street View-foto's (0.8.2):
# - glazen doos: begane grond terugliggend onder een doorlopende luifel met rode SCHUNCK-letters,
#   daarboven vier verdiepingen glasvlies met dunne stijlen voor uitkragende vloeren,
#   paddenstoelkolommen, gordijnen en ronde plafondlampen achter het glas;
#   op het dak een terugliggende glazen bouwlaag, een rond trappenhuis en twee vlaggen
# - de kubus links: geschubde zilverblauwe gevel die over een glazen terrasverdieping
#   en een grijze natuurstenen plint uitkraagt, donkere onderzijde, kleine vensters naar de kerk
# - wit gestuct trappenhuisblok tussen kubus en glaspaleis met groot hoekvenster
# - beige achterbouw met hoog SCHUNCK-venster, palmen bij de ingang, stalen dakframe
# - bronzen beeld voor de plint, bakstenen torentje met leien tentdak bij de kerk
# Lokale ruimte: +Z is de voorkant (richting plein), +X de lange zijgevel met luifel.
const Kit = preload("res://scripts/build_kit.gd")

const HW := 12.0          # halve breedte glaspaleis (x)
const HD := 11.0          # halve diepte (z)
const GF_H := 4.6         # begane grond
const FL_H := 4.0         # verdiepingen
const UPPER := 4
const SLAB := 0.4
const RECESS := 1.5       # begane grond ligt terug onder de luifel
const ROOF_Y := GF_H + FL_H * UPPER   # 20.6

var glass_clear: StandardMaterial3D
var frame_col := Color("b9bfc0")
var slab_col := Color("eeece6")
var red := Color("e2363c")

func _ready() -> void:
    name = "Glaspaleis"
    glass_clear = StandardMaterial3D.new()
    glass_clear.albedo_color = Color(0.60, 0.73, 0.80, 0.30)
    glass_clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass_clear.metallic = 0.5
    glass_clear.roughness = 0.06
    _glass_box()
    _rooftop()
    _annex()
    _link_block()
    _cube()
    _statue(Vector3(-20.5, 0, 11.2))
    _brick_tower(Vector3(-25.0, 0, -24.0))

func _collider(n: String, pos: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = n
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    cs.shape = shape
    body.add_child(cs)
    body.position = pos
    add_child(body)

func _red_label(parent: Node3D, pos: Vector3, pixel: float) -> void:
    # dikke rode blokletters: een rode omlijning maakt de letters vetter
    var l := Kit.label(parent, "SCHUNCK", pos, pixel, red, 100, 14)
    l.outline_modulate = red

func _slab_y(k: int) -> float:
    # bovenkant van vloer k (1 = eerste verdieping, UPPER+1 = dak)
    return GF_H + FL_H * float(k - 1)

# ---------------------------------------------------------------- glazen doos
func _glass_box() -> void:
    _collider("Glaspaleis body", Vector3(-RECESS * 0.5, ROOF_Y * 0.5, -RECESS * 0.5),
        Vector3(HW * 2.0 - RECESS, ROOF_Y, HD * 2.0 - RECESS))

    # Vloerplaten: de witte banden in de gevel.
    Kit.box(self, "Ground floor", Vector3(-RECESS * 0.5, 0.06, -RECESS * 0.5),
        Vector3(HW * 2.0 - RECESS, 0.12, HD * 2.0 - RECESS), Color("cfcac0"))
    for k in range(1, UPPER + 2):
        var y: float = _slab_y(k)
        Kit.box(self, "Slab %d" % k, Vector3(0, y - SLAB * 0.5, 0), Vector3(HW * 2.0, SLAB, HD * 2.0), slab_col)

    # Paddenstoelkolommen (Peutz): ronde schacht met verbrede kop onder elke vloer.
    for cx in [-6.0, 0.0, 6.0]:
        for cz in [-5.5, 0.0, 5.5]:
            Kit.cyl(self, "Column", Vector3(cx, ROOF_Y * 0.5, cz), 0.32, 0.32, ROOF_Y, slab_col, 10)
            for k in range(1, UPPER + 2):
                Kit.cyl(self, "Column head", Vector3(cx, _slab_y(k) - SLAB - 0.35, cz), 0.32, 1.2, 0.7, slab_col, 10)

    # Glasvlies op de vier verdiepingen: voor, +X, -X (voorste deel) en achter (rechts van de achterbouw).
    for k in range(1, UPPER + 1):
        var y0: float = _slab_y(k)
        var h: float = FL_H - SLAB
        var yc: float = y0 + h * 0.5
        Kit.box(self, "Glass front %d" % k, Vector3(0, yc, HD - 0.08), Vector3(HW * 2.0, h, 0.04), Color.WHITE, false, glass_clear)
        Kit.box(self, "Glass right %d" % k, Vector3(HW - 0.08, yc, 0), Vector3(0.04, h, HD * 2.0 - 0.2), Color.WHITE, false, glass_clear)
        Kit.box(self, "Glass left %d" % k, Vector3(-HW + 0.08, yc, 2.5), Vector3(0.04, h, 16.8), Color.WHITE, false, glass_clear)
        Kit.box(self, "Glass back %d" % k, Vector3(10.0, yc, -HD + 0.08), Vector3(3.8, h, 0.04), Color.WHITE, false, glass_clear)
        # Borstweringsregel op 1 m en dunne regel net onder de vloer.
        for ty in [y0 + 1.0, y0 + h - 0.1]:
            Kit.box(self, "Transom F", Vector3(0, ty, HD + 0.01), Vector3(HW * 2.0, 0.07, 0.1), frame_col)
            Kit.box(self, "Transom R", Vector3(HW + 0.01, ty, 0), Vector3(0.1, 0.07, HD * 2.0), frame_col)
            Kit.box(self, "Transom L", Vector3(-HW - 0.01, ty, 2.5), Vector3(0.1, 0.07, 17.0), frame_col)

    # Stijlen over de volle hoogte van het glasvlies.
    var mh: float = ROOF_Y - GF_H + SLAB
    var my: float = GF_H - SLAB + mh * 0.5
    for i in range(16):
        var x: float = -HW + float(i) * 1.6
        Kit.box(self, "Mullion F", Vector3(x, my, HD + 0.02), Vector3(0.08, mh, 0.12), frame_col)
    for i in range(15):
        var z: float = -HD + float(i) * (HD * 2.0 / 14.0)
        Kit.box(self, "Mullion R", Vector3(HW + 0.02, my, z), Vector3(0.12, mh, 0.08), frame_col)
        if z > -6.0:
            Kit.box(self, "Mullion L", Vector3(-HW - 0.02, my, z), Vector3(0.12, mh, 0.08), frame_col)

    # Gordijnen en lampen achter het glas (vaste willekeur).
    var rng := RandomNumberGenerator.new()
    rng.seed = 1935
    var curtain := Color("e9e1cf")
    var lamp := Kit.mat(Color("fff1c8"), 1.6)
    for k in range(1, UPPER + 1):
        var y0: float = _slab_y(k)
        var ch: float = FL_H - SLAB - 0.3
        for i in range(15):
            if rng.randf() < 0.3:
                Kit.box(self, "Curtain F", Vector3(-HW + 0.8 + float(i) * 1.6, y0 + ch * 0.5 + 0.1, HD - 0.5),
                    Vector3(1.0 + rng.randf() * 0.5, ch, 0.06), curtain)
        for i in range(13):
            if rng.randf() < 0.3:
                Kit.box(self, "Curtain R", Vector3(HW - 0.5, y0 + ch * 0.5 + 0.1, -HD + 0.8 + float(i) * 1.57),
                    Vector3(0.06, ch, 1.0 + rng.randf() * 0.5), curtain)
        var ly: float = y0 + FL_H - SLAB - 0.04
        for lx in [-9.0, -5.0, -1.0, 3.0, 7.0, 10.0]:
            Kit.cyl(self, "Ceiling lamp", Vector3(lx, ly, HD - 2.0), 0.35, 0.35, 0.06, Color.WHITE, 10, "y", false, lamp)
        for lz in [-8.0, -4.0, 0.0, 4.0, 8.0]:
            Kit.cyl(self, "Ceiling lamp", Vector3(HW - 2.0, ly, lz), 0.35, 0.35, 0.06, Color.WHITE, 10, "y", false, lamp)

    # Begane grond: terugliggende winkelpui met affiches, ronde kolommen aan de rand.
    var gh: float = GF_H - SLAB
    Kit.box(self, "Shop glass front", Vector3(-RECESS * 0.5, gh * 0.5, HD - RECESS), Vector3(HW * 2.0 - RECESS, gh, 0.05), Color.WHITE, false, glass_clear)
    Kit.box(self, "Shop glass right", Vector3(HW - RECESS, gh * 0.5, -RECESS * 0.5), Vector3(0.05, gh, HD * 2.0 - RECESS), Color.WHITE, false, glass_clear)
    Kit.box(self, "Shop glass left", Vector3(-HW + 0.08, gh * 0.5, 2.0), Vector3(0.05, gh, 15.0), Color.WHITE, false, glass_clear)
    var posters := [Color("d8463f"), Color("f1d36b"), Color("3f7fb5"), Color("f2efe8"), Color("5a9d6c"), Color("2b2b30")]
    for i in range(12):
        var px: float = -HW + 1.4 + float(i) * 1.8
        Kit.box(self, "Poster", Vector3(px, 1.9, HD - RECESS - 0.5), Vector3(1.4, 2.2, 0.04), posters[i % posters.size()])
    for i in range(9):
        Kit.box(self, "Poster", Vector3(HW - RECESS - 0.5, 1.9, -HD + 2.0 + float(i) * 2.2), Vector3(0.04, 2.2, 1.5), posters[(i + 3) % posters.size()])
    Kit.box(self, "Entrance doors", Vector3(4.0, 1.4, HD - RECESS - 0.06), Vector3(3.2, 2.8, 0.06), Color("2c3a40"))
    for i in range(5):
        Kit.cyl(self, "Edge column", Vector3(-HW + 3.0 + float(i) * 4.8, gh * 0.5, HD - 0.5), 0.28, 0.28, gh, slab_col, 10)
    for i in range(4):
        Kit.cyl(self, "Edge column", Vector3(HW - 0.5, gh * 0.5, -HD + 3.0 + float(i) * 5.0), 0.28, 0.28, gh, slab_col, 10)

    # Doorlopende luifel langs voorgevel en zijgevel, met glazen panelen en rode letters erop.
    var cy: float = GF_H - SLAB - 0.35
    var deep := 2.6
    Kit.box(self, "Canopy front", Vector3(1.3, cy, HD + deep * 0.5), Vector3(HW * 2.0 + deep, 0.22, deep), Color("8d9496"))
    Kit.box(self, "Canopy side", Vector3(HW + deep * 0.5, cy, 0), Vector3(deep, 0.22, HD * 2.0), Color("8d9496"))
    Kit.box(self, "Canopy glass F", Vector3(1.3, cy + 0.14, HD + deep * 0.5), Vector3(HW * 2.0 + deep - 0.3, 0.05, deep - 0.3), Color("d6e2e6"))
    Kit.box(self, "Canopy glass S", Vector3(HW + deep * 0.5, cy + 0.14, 0), Vector3(deep - 0.3, 0.05, HD * 2.0 - 0.3), Color("d6e2e6"))
    for i in range(7):
        var hx: float = -HW + 1.0 + float(i) * 4.2
        Kit.beam(self, "Canopy hanger", Vector3(hx, cy, HD + deep - 0.2), Vector3(hx, GF_H + 1.2, HD + 0.1), 0.06, frame_col)
    var lf := Kit.face(self, Vector3(-1.0, cy + 0.85, HD + deep - 0.05), 0)
    _red_label(lf, Vector3.ZERO, 0.021)
    var ls := Kit.face(self, Vector3(HW + deep - 0.05, cy + 0.85, 3.0), 90)
    _red_label(ls, Vector3.ZERO, 0.021)

# ---------------------------------------------------------------- dak
func _rooftop() -> void:
    var base: float = ROOF_Y
    # Dakrand-reling rondom.
    for side in [[Vector3(0, base + 1.05, HD - 0.1), Vector3(HW * 2.0, 0.06, 0.06)],
            [Vector3(HW - 0.1, base + 1.05, 0), Vector3(0.06, 0.06, HD * 2.0)],
            [Vector3(-HW + 0.1, base + 1.05, 2.5), Vector3(0.06, 0.06, 17.0)]]:
        Kit.box(self, "Roof rail", side[0], side[1], frame_col)
    for i in range(13):
        Kit.box(self, "Rail post", Vector3(-HW + 0.1 + float(i) * 2.0, base + 0.53, HD - 0.1), Vector3(0.06, 1.05, 0.06), frame_col)
        Kit.box(self, "Rail post", Vector3(HW - 0.1, base + 0.53, -HD + 0.1 + float(i) * 1.82), Vector3(0.06, 1.05, 0.06), frame_col)

    # Terugliggende glazen dakverdieping.
    var x0 := -7.0
    var x1 := HW - 1.4
    var z0 := -HD + 1.0
    var z1 := HD - 1.4
    var h := 3.6
    var cxm: float = (x0 + x1) * 0.5
    var czm: float = (z0 + z1) * 0.5
    Kit.box(self, "Top storey core", Vector3(cxm, base + h * 0.5, czm - 1.5), Vector3(x1 - x0 - 3.0, h, z1 - z0 - 6.0), Color("dedbd2"))
    Kit.box(self, "Top glass F", Vector3(cxm, base + h * 0.5, z1), Vector3(x1 - x0, h, 0.04), Color.WHITE, false, glass_clear)
    Kit.box(self, "Top glass R", Vector3(x1, base + h * 0.5, czm), Vector3(0.04, h, z1 - z0), Color.WHITE, false, glass_clear)
    Kit.box(self, "Top glass L", Vector3(x0, base + h * 0.5, czm), Vector3(0.04, h, z1 - z0), Color.WHITE, false, glass_clear)
    Kit.box(self, "Top roof", Vector3(cxm, base + h + 0.15, czm), Vector3(x1 - x0 + 0.4, 0.3, z1 - z0 + 0.4), slab_col)
    for i in range(11):
        var x: float = x0 + float(i) * (x1 - x0) / 10.0
        Kit.box(self, "Top mullion", Vector3(x, base + h * 0.5, z1 + 0.04), Vector3(0.08, h, 0.08), frame_col)
    for i in range(11):
        var z: float = z0 + float(i) * (z1 - z0) / 10.0
        Kit.box(self, "Top mullion", Vector3(x1 + 0.04, base + h * 0.5, z), Vector3(0.08, h, 0.08), frame_col)
    # Open stalen kooi boven de dakverdieping (het 'raster' op de foto's).
    var ft: float = base + h + 0.3
    var fh := 2.4
    for corner in [Vector3(x0 + 0.2, 0, z1 - 0.2), Vector3(x1 - 0.2, 0, z1 - 0.2), Vector3(x1 - 0.2, 0, z0 + 3.0), Vector3(x0 + 0.2, 0, z0 + 3.0)]:
        Kit.box(self, "Cage post", Vector3(corner.x, ft + fh * 0.5, corner.z), Vector3(0.12, fh, 0.12), frame_col)
    for yy in [ft + fh * 0.5, ft + fh]:
        Kit.box(self, "Cage rail F", Vector3(cxm, yy, z1 - 0.2), Vector3(x1 - x0 - 0.4, 0.1, 0.1), frame_col)
        Kit.box(self, "Cage rail R", Vector3(x1 - 0.2, yy, (z1 + z0 + 2.8) * 0.5), Vector3(0.1, 0.1, z1 - z0 - 3.2), frame_col)
    # Rond trappenhuis linksvoor op het dak.
    Kit.cyl(self, "Round stair", Vector3(-9.0, base + 1.8, 3.0), 2.1, 2.1, 3.6, Color("efede6"), 20)
    Kit.cyl(self, "Round stair glass", Vector3(-9.0, base + 2.4, 3.0), 2.14, 2.14, 1.2, Color("8fb0bb"), 20, "y", false, Kit.glass_mat(Color("8fb0bb")))
    Kit.cyl(self, "Round stair roof", Vector3(-9.0, base + 3.7, 3.0), 2.3, 2.3, 0.2, slab_col, 20)
    # Vlaggen.
    for f in [[Vector3(6.0, ft, 7.0), 5.5, Color("c8323c")], [Vector3(-3.0, ft, 7.0), 4.5, Color("3a72b8")]]:
        var p: Vector3 = f[0]
        var ph: float = f[1]
        Kit.cyl(self, "Flagpole", p + Vector3(0, ph * 0.5, 0), 0.05, 0.04, ph, Color("f2f2f2"), 6)
        Kit.box(self, "Flag", p + Vector3(0.75, ph - 0.55, 0), Vector3(1.5, 1.0, 0.03), f[2])

# ---------------------------------------------------------------- achterbouw
func _annex() -> void:
    var beige := Color("e7e5df")   # licht gestuct, bijna wit (jouw foto van het terras)
    var x0 := -14.0
    var x1 := 8.0
    var z0 := -20.0
    var z1 := -HD
    var h: float = ROOF_Y + 0.8
    Kit.box(self, "Annex", Vector3((x0 + x1) * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h, z1 - z0), beige, true)
    Kit.box(self, "Annex coping", Vector3((x0 + x1) * 0.5, h + 0.1, (z0 + z1) * 0.5), Vector3(x1 - x0 + 0.2, 0.2, z1 - z0 + 0.2), Color("d4d1ca"))
    Kit.box(self, "Annex top room", Vector3(-1.0, h + 1.6, -16.0), Vector3(10.0, 3.2, 6.0), beige)
    var back := Kit.face(self, Vector3(0, 0, z0), 180)   # lokaal +X = wereld -X
    var dark := Color("3e4a50")
    # kleine vierkante vensters
    for w in [[9.0, 15.0], [11.5, 15.0], [9.0, 11.0], [11.5, 11.0], [11.0, 6.0]]:
        Kit.box(back, "Annex window", Vector3(w[0], w[1], 0.04), Vector3(1.2, 1.3, 0.1), dark)
        Kit.box(back, "Annex sill", Vector3(w[0], w[1] - 0.72, 0.1), Vector3(1.4, 0.1, 0.2), Color("d2c8b2"))
    # hoge sleuf van donkergroen glas met witte letters (rechts op de foto)
    Kit.box(back, "Tall slot", Vector3(4.0, 13.0, 0.03), Vector3(4.2, 9.0, 0.08), Color("2c4a40"), false, Kit.glass_mat(Color("2c4a40")))
    Kit.label(back, "SCHUNCK", Vector3(4.0, 16.4, 0.09), 0.0085, Color("f2f2ee"), 100)
    for i in range(3):
        Kit.box(back, "Slot mullion", Vector3(1.9 + float(i) * 2.1, 13.0, 0.09), Vector3(0.08, 9.0, 0.06), frame_col)
    # terras naar jouw foto (25-11): verhoogd plateau over de hele achtergevel, brede trap
    # naar het plein (rechts), glazen balustrade (links), palmen in witte bakken en parasols
    var stone := Color("d6d3cc")
    var tz := 4.5          # diepte van het terras
    var th := 1.4          # hoogte van het terras
    Kit.box(back, "Terrace", Vector3(0.25, th * 0.5, tz * 0.5), Vector3(16.5, th, tz), stone)
    _collider("Terrace body", Vector3(-0.25, th * 0.5, z0 - tz * 0.5), Vector3(16.5, th, tz))
    for k in range(5):
        var sh: float = th * float(5 - k) / 5.0
        Kit.box(back, "Terrace step", Vector3(3.25, sh * 0.5, tz + 0.3 + float(k) * 0.6), Vector3(10.5, sh, 0.6), stone)
        Kit.box(back, "Step nose", Vector3(3.25, sh + 0.005, tz + 0.02 + float(k) * 0.6), Vector3(10.5, 0.01, 0.06), Color("a9a59c"))
    # balustrade: glas tussen stalen staanders langs de voorkant links en de zijkant
    var rail_glass := Kit.glass_mat(Color("a9c3cc"))
    Kit.box(back, "Terrace glass rail", Vector3(-5.0, th + 0.5, tz - 0.05), Vector3(6.0, 1.0, 0.05), Color.WHITE, false, rail_glass)
    Kit.box(back, "Terrace glass rail", Vector3(-8.0, th + 0.5, tz * 0.5), Vector3(0.05, 1.0, tz), Color.WHITE, false, rail_glass)
    Kit.box(back, "Terrace handrail", Vector3(-5.0, th + 1.02, tz - 0.05), Vector3(6.0, 0.06, 0.08), frame_col)
    Kit.box(back, "Terrace handrail", Vector3(-8.0, th + 1.02, tz * 0.5), Vector3(0.08, 0.06, tz), frame_col)
    for rx in [-8.0, -5.0, -2.0]:
        Kit.box(back, "Rail post", Vector3(rx, th + 0.5, tz - 0.05), Vector3(0.07, 1.05, 0.07), frame_col)
    # brede donkere glaspui achter het terras
    Kit.box(back, "Terrace glass front", Vector3(-1.5, th + 1.8, 0.04), Vector3(11.0, 3.6, 0.08), dark, false, Kit.glass_mat(dark))
    # palmen in witte bakken op de voorrand, parasols met tafeltjes erachter
    for px in [-6.5, -2.6, 1.0, 5.0, 8.0]:
        _palm(back, Vector3(px, th, tz - 0.8), 1.45)
    for ux in [-5.0, -0.8, 3.4]:
        Kit.cyl(back, "Parasol pole", Vector3(ux, th + 1.25, 2.0), 0.04, 0.04, 2.5, Color("5a524a"), 6)
        Kit.cyl(back, "Parasol", Vector3(ux, th + 2.45, 2.0), 1.7, 0.08, 0.5, Color("7d6e5c"), 10)
        Kit.cyl(back, "Table", Vector3(ux, th + 0.72, 2.0), 0.45, 0.45, 0.05, Color("2e2b28"), 10)
    # glazen toren met pictogrammen aan de linkerkant (muziek, film, dans, museum, boeken)
    var tower_glass := Kit.glass_mat(Color("6f8f99"))
    Kit.box(back, "Pictogram tower", Vector3(-9.6, ROOF_Y * 0.5 + 0.6, 0.6), Vector3(3.0, ROOF_Y + 1.2, 3.0), Color.WHITE, false, tower_glass)
    for i in range(6):
        var py: float = 5.0 + float(i) * 2.4
        Kit.box(back, "Pictogram", Vector3(-9.6, py, 2.12), Vector3(1.7, 1.7, 0.04), Color("eef0ee"))
        Kit.box(back, "Pictogram icon", Vector3(-9.6, py, 2.15), Vector3(0.5 + 0.15 * float(i % 3), 0.9 - 0.12 * float(i % 2), 0.02), Color("4a5458"))
    for ty in [3.6, 7.4, 11.2, 15.0, 18.8]:
        Kit.box(back, "Tower floor line", Vector3(-9.6, ty, 2.11), Vector3(3.02, 0.12, 0.02), frame_col)
    # stalen dakframe linksboven
    for fx in [-7.5, -4.5, -1.5]:
        Kit.box(back, "Roof frame post", Vector3(fx, h + 1.5, -1.0), Vector3(0.12, 3.0, 0.12), frame_col)
    Kit.box(back, "Roof frame rail", Vector3(-4.5, h + 3.0, -1.0), Vector3(6.1, 0.12, 0.12), frame_col)

func _palm(parent: Node3D, pos: Vector3, k: float = 1.0) -> void:
    Kit.box(parent, "Planter", pos + Vector3(0, 0.45, 0) * k, Vector3(1.1, 0.9, 1.1) * k, Color("f0eee8"))
    Kit.cyl(parent, "Palm trunk", pos + Vector3(0, 1.6, 0) * k, 0.16 * k, 0.11 * k, 1.5 * k, Color("6b5638"), 6)
    var crown: Vector3 = pos + Vector3(0, 2.35, 0) * k
    # bovenste bladeren schuin omhoog, onderste ring hangt wat naar beneden
    for a in range(7):
        var ang: float = float(a) * TAU / 7.0
        Kit.beam(parent, "Palm leaf", crown, crown + Vector3(cos(ang) * 1.0, 0.55, sin(ang) * 1.0) * k, 0.16 * k, Color("4f7d3a"))
        var ang2: float = ang + TAU / 14.0
        Kit.beam(parent, "Palm leaf", crown, crown + Vector3(cos(ang2) * 1.25, -0.25, sin(ang2) * 1.25) * k, 0.16 * k, Color("3f6c30"))

# ---------------------------------------------------------------- wit trappenhuisblok
func _link_block() -> void:
    var white := Color("eceae4")
    var x0 := -21.0
    var x1 := -11.5
    var z0 := -16.0
    var z1 := -6.0
    var h := 23.0
    Kit.box(self, "Link block", Vector3((x0 + x1) * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h, z1 - z0), white, true)
    var f := Kit.face(self, Vector3(x0, 0, (z0 + z1) * 0.5), -90)   # lokaal +X = wereld +Z
    # groot hoekvenster (op de foto rechts op het witte blok)
    Kit.box(f, "Big window frame", Vector3(2.2, 11.0, 0.05), Vector3(5.6, 5.4, 0.1), Color("8d9496"))
    Kit.box(f, "Big window", Vector3(2.2, 11.0, 0.12), Vector3(5.2, 5.0, 0.06), Color("5d6e66"), false, Kit.glass_mat(Color("5d6e66")))
    Kit.box(f, "Big window mullion", Vector3(2.2, 11.0, 0.17), Vector3(0.08, 5.0, 0.04), Color("8d9496"))
    # glazen ingang onder een uitkragende plaat
    Kit.box(f, "Link entrance", Vector3(0.5, 1.7, 0.04), Vector3(6.0, 3.4, 0.08), Color("3a4549"), false, Kit.glass_mat(Color("3a4549")))
    Kit.box(f, "Link canopy", Vector3(0.5, 4.2, 0.9), Vector3(7.5, 0.3, 1.8), Color("c4c6c3"))
    # smalle glasstrook langs het glaspaleis
    Kit.box(self, "Link glass strip", Vector3(-11.75, 13.0, -6.0 + 0.05), Vector3(0.5, 16.0, 0.08), Color("8fb0bb"), false, Kit.glass_mat(Color("8fb0bb")))

# ---------------------------------------------------------------- kubus
func _cube() -> void:
    var stone := Kit.tex_mat_tiles("res://assets/glas_stone.png", Vector2(4.8, 4.8))
    var tiles: StandardMaterial3D = Kit.tex_mat_tiles("res://assets/glas_tiles.png", Vector2(6.0, 5.0)).duplicate()
    tiles.metallic = 0.45
    tiles.roughness = 0.35

    # Plint van grijze natuursteen.
    var px0 := -28.0
    var px1 := -13.5
    var pz0 := -4.0
    var pz1 := 9.0
    var ph := 4.4
    Kit.box(self, "Cube plinth", Vector3((px0 + px1) * 0.5, ph * 0.5, (pz0 + pz1) * 0.5),
        Vector3(px1 - px0, ph, pz1 - pz0), Color.WHITE, true, stone)
    # donkere lamellen-garagedeur in de voorkant
    Kit.box(self, "Garage door", Vector3(-19.0, 1.8, pz1 + 0.04), Vector3(5.0, 3.6, 0.08), Color("4a3f37"))
    for i in range(20):
        Kit.box(self, "Door slat", Vector3(-21.4 + float(i) * 0.25, 1.8, pz1 + 0.1), Vector3(0.06, 3.6, 0.05), Color("5c5048"))
    # winkelruit met rode letters naar de kerkkant
    var side := Kit.face(self, Vector3(px0, 0, (pz0 + pz1) * 0.5), -90)
    Kit.box(side, "Shop window", Vector3(1.5, 1.9, 0.04), Vector3(7.0, 3.2, 0.08), Color("2f3a3f"), false, Kit.glass_mat(Color("2f3a3f")))
    _red_label(side, Vector3(1.5, 2.6, 0.1), 0.016)
    for i in range(6):
        Kit.box(side, "Shop mullion", Vector3(-2.0 + float(i) * 1.4, 1.9, 0.1), Vector3(0.06, 3.2, 0.05), frame_col)
    Kit.box(self, "Plinth coping", Vector3((px0 + px1) * 0.5, ph + 0.06, (pz0 + pz1) * 0.5), Vector3(px1 - px0 + 0.1, 0.12, pz1 - pz0 + 0.1), Color("9ea2a2"))

    # Glazen terrasverdieping onder de kubus, met glazen balustrade op de plintrand.
    var gy0: float = ph + 0.12
    var gh := 3.3
    Kit.box(self, "Terrace storey", Vector3(-20.5, gy0 + gh * 0.5, 2.0), Vector3(12.0, gh, 9.0), Color("41515a"), false, Kit.glass_mat(Color("41515a")))
    for i in range(9):
        Kit.box(self, "Terrace mullion", Vector3(-26.5 + float(i) * 1.5, gy0 + gh * 0.5, 6.53), Vector3(0.07, gh, 0.06), frame_col)
    Kit.box(self, "Balustrade F", Vector3((px0 + px1) * 0.5, gy0 + 0.55, pz1 - 0.1), Vector3(px1 - px0, 1.1, 0.04), Color.WHITE, false, glass_clear)
    Kit.box(self, "Balustrade L", Vector3(px0 + 0.1, gy0 + 0.55, (pz0 + pz1) * 0.5), Vector3(0.04, 1.1, pz1 - pz0), Color.WHITE, false, glass_clear)
    Kit.box(self, "Rail F", Vector3((px0 + px1) * 0.5, gy0 + 1.12, pz1 - 0.1), Vector3(px1 - px0, 0.06, 0.08), frame_col)
    Kit.box(self, "Rail L", Vector3(px0 + 0.1, gy0 + 1.12, (pz0 + pz1) * 0.5), Vector3(0.08, 0.06, pz1 - pz0), frame_col)
    for i in range(8):
        Kit.box(self, "Rail post", Vector3(px0 + 0.1 + float(i) * 2.06, gy0 + 0.56, pz1 - 0.1), Vector3(0.05, 1.12, 0.05), frame_col)

    # De kubus zelf: kraagt aan voorkant en kerkkant uit.
    var cx0 := -30.0
    var cx1 := -13.0
    var cz0 := -6.5
    var cz1 := 12.0
    var cy0: float = gy0 + gh
    var cy1 := 21.2
    var cc := Vector3((cx0 + cx1) * 0.5, (cy0 + cy1) * 0.5, (cz0 + cz1) * 0.5)
    Kit.box(self, "Cube", cc, Vector3(cx1 - cx0, cy1 - cy0, cz1 - cz0), Color.WHITE, false, tiles)
    Kit.box(self, "Cube underside", Vector3(cc.x, cy0 - 0.1, cc.z), Vector3(cx1 - cx0 + 0.1, 0.2, cz1 - cz0 + 0.1), Color("4a3d31"))
    Kit.box(self, "Cube roof", Vector3(cc.x, cy1 + 0.05, cc.z), Vector3(cx1 - cx0 - 0.6, 0.1, cz1 - cz0 - 0.6), Color("8c8f90"))
    # kleine vensters in de kerkzijde (lokaal +X = wereld +Z)
    var cf := Kit.face(self, Vector3(cx0, 0, cc.z), -90)
    for w in [[-5.5, 11.0], [-1.0, 14.5], [3.0, 11.0], [6.5, 16.5], [-5.5, 17.5]]:
        Kit.box(cf, "Cube window frame", Vector3(w[0], w[1], 0.04), Vector3(1.5, 2.1, 0.1), Color("6c7a84"))
        Kit.box(cf, "Cube window", Vector3(w[0], w[1], 0.1), Vector3(1.2, 1.8, 0.06), Color("2c3a42"))
        Kit.box(cf, "Cube window bar", Vector3(w[0], w[1], 0.14), Vector3(1.2, 0.05, 0.03), Color("9aa6ad"))

# ---------------------------------------------------------------- beeld
func _statue(p: Vector3) -> void:
    var bronze := Kit.mat(Color("4b3c2c"), 0.0, 0.5, 0.5)
    Kit.box(self, "Statue base", p + Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 1.0), Color("3b3b3b"), true)
    var b := p + Vector3(0, 0.6, 0)
    Kit.cyl(self, "Statue leg L", b + Vector3(-0.18, 0.45, 0.05), 0.14, 0.16, 0.9, Color.WHITE, 8, "y", false, bronze)
    Kit.cyl(self, "Statue leg R", b + Vector3(0.2, 0.45, -0.08), 0.14, 0.16, 0.9, Color.WHITE, 8, "y", false, bronze)
    Kit.cyl(self, "Statue body", b + Vector3(0, 1.3, 0), 0.28, 0.34, 0.9, Color.WHITE, 8, "y", false, bronze)
    Kit.cyl(self, "Statue head", b + Vector3(0, 1.95, 0), 0.15, 0.13, 0.32, Color.WHITE, 8, "y", false, bronze)
    Kit.beam(self, "Statue arm up", b + Vector3(-0.3, 1.65, 0), b + Vector3(-0.42, 2.55, 0.1), 0.13, Color("4b3c2c"))
    Kit.box(self, "Statue fist", b + Vector3(-0.43, 2.62, 0.1), Vector3(0.2, 0.2, 0.2), Color.WHITE, false, bronze)
    Kit.beam(self, "Statue arm", b + Vector3(0.32, 1.65, 0), b + Vector3(0.3, 1.1, 0.25), 0.12, Color("4b3c2c"))

# ---------------------------------------------------------------- bakstenen torentje
func _brick_tower(p: Vector3) -> void:
    var brick := Kit.tex_mat("res://assets/on_brick.png", Color("c9a294"), 3.0)
    var half := 3.3
    var low := 3.2
    var top := 11.5
    Kit.box(self, "Tower base", p + Vector3(0, low * 0.5, 0), Vector3(half * 2.0, low, half * 2.0), Color("d4cfc4"), true)
    Kit.box(self, "Tower brick", p + Vector3(0, (low + top) * 0.5, 0), Vector3(half * 2.0 - 0.1, top - low, half * 2.0 - 0.1), Color.WHITE, true, brick)
    Kit.box(self, "Tower eave", p + Vector3(0, top + 0.1, 0), Vector3(half * 2.0 + 0.5, 0.2, half * 2.0 + 0.5), Color("e8e4dc"))
    Kit.pyramid(self, "Tower roof", p + Vector3(0, top + 0.2, 0), half + 0.35, 5.2, Color("57524f"))
    Kit.cyl(self, "Tower finial", p + Vector3(0, top + 5.9, 0), 0.05, 0.05, 1.6, Color("3a3a3a"), 6)
    Kit.box(self, "Tower cross", p + Vector3(0, top + 6.4, 0), Vector3(0.6, 0.05, 0.05), Color("3a3a3a"))
    for yaw in [0.0, 90.0, 180.0, -90.0]:
        var f := Kit.face(self, p + Vector3(sin(deg_to_rad(yaw)) * (half - 0.05), 0, cos(deg_to_rad(yaw)) * (half - 0.05)), yaw)
        for wy in [5.6, 8.9]:
            Kit.box(f, "Tower window frame", Vector3(0.0, wy, 0.04), Vector3(1.2, 1.4, 0.1), Color("f2f0ea"))
            Kit.box(f, "Tower window", Vector3(0.0, wy, 0.1), Vector3(0.9, 1.1, 0.04), Color("2e3436"))
            Kit.box(f, "Tower window bar", Vector3(0.0, wy, 0.13), Vector3(0.06, 1.1, 0.03), Color("f2f0ea"))
