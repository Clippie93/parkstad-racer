extends RefCounted
# Nederlandse verkeerselementen langs de route van een level. Wordt na level.build()
# aangeroepen door de race (build(level, race)), dus elk level krijgt ze vanzelf.
# - fietsers op de rode fietspaden, met een onderbroken witte streep en af en toe een fiets
# - zebrapaden met blauwe borden en paaltjes (in de bebouwde kom)
# - snelheidsborden (50 in de kom, 80 erbuiten, 100 op de Buitenring)
# - voorrangswegborden (oranje ruit) en handwijzers vlak voor de kruisingen
# - moderne bushaltes (tegelperron, abri), flitspalen, bloembakken, ondergrondse containers
# - op de Buitenring: alleen snelheidsborden en een flitser (paaltjes staan in de finale zelf)
const Kit = preload("res://scripts/build_kit.gd")
const Cyclist = preload("res://scripts/cyclist.gd")
const SpeedCamera = preload("res://scripts/speed_camera.gd")
const Intersection = preload("res://scripts/intersection.gd")

var lv
var r
var rng := RandomNumberGenerator.new()
var used: Array = []        # afstanden waar al iets staat (niet alles op één plek)
var crossings: Array = []   # afstanden van de kruisingen met verkeerslichten
var zebra_s: Array = []     # afstanden van de zebrapaden
var bus_s: Array = []       # afstanden van de bushaltes

func build(level, race) -> void:
    lv = level
    r = level.route
    rng.seed = int(level.seed_value) * 7 + 3
    for c in level.checkpoints:
        used.append(r.closest_s(c["at"]))
    for t in level.town_sign_s:
        used.append(t)
    if level.dual:
        # geen reflectorpalen en hectometerpaaltjes langs de buitenkant: daar staat een
        # vangrail (met reflectoren), en de hectometerpaaltjes staan in de middenberm
        _speed_signs()
        _speed_cameras(race, 1)
        return
    _intersections(race)
    _cyclists()
    _zebras()
    _priority_signs()
    _anwb_signs()
    _speed_signs()
    _bus_stops()
    _speed_cameras(race, 2)
    _planters_and_bins()
    _bike_markings()

# ---------------------------------------------------------------- hulpjes
func _free(s: float, gap: float) -> bool:
    for u in used:
        var d: float = absf(float(u) - s)
        if r.closed:
            d = minf(d, r.length - d)
        if d < gap:
            return false
    return true

func _straight(s: float) -> bool:
    return r.curvature(s, 10.0) < 0.004

# Een plek naast de weg op afstand s: side 1 = rechts, offset = meters vanaf de wegas.
func _spot(s: float, side: float, offset: float) -> Node3D:
    var f := Node3D.new()
    var p: Vector3 = r.pos_at(s) + r.right_at(s) * side * offset
    var b: Basis = r.basis_at(s)
    if side < 0.0:
        b = b.rotated(Vector3.UP, PI)
    f.transform = Transform3D(b, p)
    lv.add_child(f)
    return f

func _walk_offset() -> float:
    return lv.road_hw + lv.CURB_W + lv.BIKE_W + lv.WALK_W * 0.5

func _ok_place(s: float, side: float, offset: float) -> bool:
    var p: Vector3 = r.pos_at(s) + r.right_at(s) * side * offset
    return not lv.in_landmark(p) and r.distance_to(p) > offset - 1.5 and not lv.near_lamp(p, 1.2)

# Rond verkeersbord op een paal; het bord kijkt naar het aankomende verkeer (+Z van de plek).
func _round_sign(f: Node3D, x: float, y: float, ring: Color, face: Color, text: String, ink: Color) -> void:
    Kit.cyl(f, "Sign back", Vector3(x, y, -0.026), 0.42, 0.42, 0.012, Color("8d9396"), 24, "z")
    Kit.cyl(f, "Sign ring", Vector3(x, y, 0.0), 0.42, 0.42, 0.04, ring, 24, "z")
    Kit.cyl(f, "Sign face", Vector3(x, y, 0.025), 0.32, 0.32, 0.03, face, 24, "z")
    if text != "":
        # drie cijfers (100) passen anders niet binnen de rode rand
        Kit.label(f, text, Vector3(x, y, 0.045), 0.0075 if text.length() <= 2 else 0.0052, ink, 64)

func _post(f: Node3D, x: float, h: float) -> void:
    Kit.box(f, "Sign post", Vector3(x, h * 0.5, -0.04), Vector3(0.07, h, 0.07), Color("9aa0a4"))

# ---------------------------------------------------------------- fietsers
func _cyclists() -> void:
    var shirts := [Color("d23c3c"), Color("2f5d8a"), Color("f2c230"), Color("3f6b45"), Color("e8e6e0"), Color("7a3fa0"), Color("e07b28")]
    var bikes := [Color("1f1f1f"), Color("2c4a6e"), Color("8a1f1f"), Color("dcdcdc")]
    var n: int = int(r.length / 180.0)
    for i in range(n):
        var c := Cyclist.new()
        lv.add_child(c)
        var side: float = 1.0 if i % 2 == 0 else -1.0
        c.setup(lv, r.length * (float(i) + rng.randf() * 0.5) / float(n), rng.randf_range(4.0, 6.5), side,
            shirts[rng.randi_range(0, shirts.size() - 1)], bikes[rng.randi_range(0, bikes.size() - 1)])

# ---------------------------------------------------------------- kruisingen
# Eén of twee kruisingen met verkeerslichten per level, op een recht stuk in de bebouwde
# kom, waar de zijweg niet door een bezienswaardigheid of een ander stuk route loopt.
func _intersections(race) -> void:
    var made := 0
    var last := -INF
    var s: float = r.length * 0.15
    while s < r.length * 0.9 and made < 2:
        if s - last > 350.0 and _intersection_fits(s):
            var x := Intersection.new()
            lv.add_child(x)
            x.setup(lv, race, s, rng.randf_range(0.0, 20.0))
            used.append(s)
            crossings.append(s)
            last = s
            made += 1
            s += 350.0
        else:
            s += 15.0

func _intersection_fits(s: float) -> bool:
    if not _free(s, 60.0):
        return false
    for d in [-30.0, 0.0, 30.0]:
        if not lv.is_town(s + d) or not _straight(s + d):
            return false
    var c: Vector3 = r.pos_at(s)
    var right: Vector3 = r.right_at(s)
    var fwd: Vector3 = r.dir_at(s)
    for side in [-1.0, 1.0]:
        var x: float = lv.road_hw + 2.0
        while x <= Intersection.SIDE_LEN + 6.0:
            for z in [-5.0, 0.0, 5.0]:
                var p: Vector3 = c + right * side * x + fwd * z
                if lv.in_landmark(p):
                    return false
                if x > lv.road_hw + 14.0 and r.distance_to(p) < lv.road_hw + 14.0:
                    return false
            x += 4.0
    return true

# ---------------------------------------------------------------- zebrapaden
func _zebras() -> void:
    var s := 120.0
    while s < r.length - 60.0:
        if lv.is_town(s) and _straight(s) and _free(s, 60.0) and _ok_place(s, 1.0, _walk_offset()) and _ok_place(s, -1.0, _walk_offset()):
            _zebra(s)
            used.append(s)
            zebra_s.append(s)
            s += 380.0
        else:
            s += 20.0

func _zebra(s: float) -> void:
    var f := _spot(s, 1.0, 0.0)
    # witte balken in rijrichting, over de hele rijbaan
    var x: float = -lv.road_hw + 0.6
    while x < lv.road_hw - 0.5:
        Kit.box(f, "Zebra bar", Vector3(x, 0.05, 0), Vector3(0.5, 0.02, 4.0), Color("f2f2ee"))
        x += 1.0
    # zebrabord (L2) aan beide kanten vlak voor het zebrapad, en Amsterdammertjes langs de band
    for side in [-1.0, 1.0]:
        var g := _spot(s - side * 2.6, side, _walk_offset())
        _post(g, 0.0, 2.75)
        _zebra_sign(g, 2.75)
        for k in range(5):
            var bo := _spot(s - 6.0 + float(k) * 3.0, side, lv.road_hw + lv.CURB_W * 0.5)
            Kit.cyl(bo, "Bollard", Vector3(0, 0.45, 0), 0.08, 0.1, 0.9, Color("6b2e22"), 8)

# Bord L2 (voetgangersoversteekplaats): blauw vierkant met witte rand, witte driehoek met
# de punt omhoog, daarin een zwarte lopende voetganger op een zwart zebrapad.
func _zebra_sign(g: Node3D, y: float) -> void:
    _plate(g, Vector3(0, y, 0), Vector2(0.64, 0.64), Color("1d4f9c"))
    _prism(g, "Zebra sign triangle", Vector3(0, y - 0.03, 0.03), 0.5, 0.43, 0.01, Color("f4f4ee"))
    var ink := Color("1a1a1a")
    # zebra: vijf schuine balkjes onder in de driehoek
    for k in range(5):
        var bar := Kit.box(g, "Zebra sign stripe", Vector3(-0.13 + float(k) * 0.065, y - 0.19, 0.04), Vector3(0.035, 0.07, 0.01), ink)
        bar.rotation_degrees.z = -18.0
    # voetganger: hoofd, romp, armen en benen in looppas
    Kit.cyl(g, "Zebra sign head", Vector3(0.0, y + 0.085, 0.04), 0.028, 0.028, 0.01, ink, 12, "z")
    _stick(g, Vector2(0.0, y + 0.05), Vector2(-0.012, y - 0.06), 0.032, ink)    # romp
    _stick(g, Vector2(-0.012, y - 0.06), Vector2(-0.06, y - 0.15), 0.026, ink)  # achterbeen
    _stick(g, Vector2(-0.012, y - 0.06), Vector2(0.045, y - 0.15), 0.026, ink)  # voorbeen
    _stick(g, Vector2(0.0, y + 0.035), Vector2(-0.055, y - 0.03), 0.02, ink)    # arm
    _stick(g, Vector2(0.0, y + 0.035), Vector2(0.045, y - 0.025), 0.02, ink)    # arm

# Recht balkje van a naar b (in het vlak van een bord), voor pictogrammen.
func _stick(g: Node3D, a: Vector2, b: Vector2, w: float, color: Color) -> void:
    var d: Vector2 = b - a
    var bar := Kit.box(g, "Sign pictogram", Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.04), Vector3(w, d.length() + w * 0.5, 0.01), color)
    bar.rotation.z = atan2(-d.x, d.y)

# Bordplaat: rand en vlak aan de voorkant, grijze achterkant (zoals echte borden).
func _plate(g: Node3D, pos: Vector3, size: Vector2, face: Color, border := Color("f4f4ee")) -> void:
    Kit.box(g, "Sign back", pos + Vector3(0, 0, -0.012), Vector3(size.x, size.y, 0.012), Color("8d9396"))
    Kit.box(g, "Sign border", pos, Vector3(size.x, size.y, 0.014), border)
    Kit.box(g, "Sign face", pos + Vector3(0, 0, 0.012), Vector3(size.x - 0.05, size.y - 0.05, 0.012), face)

# Driehoek (punt omhoog) als dun prisma, voor bordpictogrammen en pijlpunten.
func _prism(g: Node3D, n: String, pos: Vector3, w: float, h: float, depth: float, color: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(w, h, depth)
    mi.mesh = pm
    mi.material_override = Kit.mat(color)
    mi.name = n
    mi.position = pos
    g.add_child(mi)
    return mi

# ---------------------------------------------------------------- borden
# Snelheidsborden langs de route, niet bij een plaatsnaambord, kruising of zebrapad.
func _speed_signs() -> void:
    var s := 70.0
    while s < r.length - 40.0:
        var town: bool = lv.is_town(s)
        var limit: String = "100" if lv.dual else ("50" if town else "80")
        var off: float = (lv.road_hw + 2.4) if lv.dual else (_walk_offset() + 1.6)
        if _free(s, 25.0) and _ok_place(s, 1.0, off) and not lv.roadside_blocked(s):
            var f := _spot(s, 1.0, off)
            _post(f, 0.0, 2.6)
            _round_sign(f, 0.0, 2.6, Color("c8202a"), Color("f4f4ee"), limit, Color("1a1a1a"))
            used.append(s)
            s += 420.0
        else:
            s += 30.0

# Voorrangsweg (oranje ruit) vlak voor elke kruising, in beide rijrichtingen.
func _priority_signs() -> void:
    for c in crossings:
        for side in [1.0, -1.0]:
            var s: float = float(c) - side * 26.0
            var off: float = _walk_offset() + 1.0
            if r.closed:
                s = fposmod(s, r.length)
            if s < 5.0 or s > r.length - 5.0 or not _ok_place(s, side, off):
                continue
            var f := _spot(s, side, off)
            _post(f, 0.0, 2.5)
            var back := Kit.box(f, "Sign back", Vector3(0, 2.55, -0.025), Vector3(0.62, 0.62, 0.012), Color("8d9396"))
            back.rotation_degrees.z = 45.0
            var outer := Kit.box(f, "Priority sign border", Vector3(0, 2.55, 0), Vector3(0.62, 0.62, 0.03), Color("f4f4ee"))
            outer.rotation_degrees.z = 45.0
            var inner := Kit.box(f, "Priority sign", Vector3(0, 2.55, 0.02), Vector3(0.42, 0.42, 0.03), Color("f2a20c"))
            inner.rotation_degrees.z = 45.0
            used.append(s)

func _sign_text(f: Node3D, text: String, x: float, y: float, px: float, align: HorizontalAlignment, z := 0.04) -> void:
    var l: Label3D = Kit.label(f, text, Vector3(x, y, z), px, Color.WHITE, 64)
    # Label3D staat gecentreerd op zijn positie: schuif hem op met de halve tekstbreedte,
    # zodat x de linker- (LEFT) of rechterrand (RIGHT) van de tekst is.
    var font: Font = l.font if l.font != null else ThemeDB.fallback_font
    var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
    l.offset = Vector2(w * 0.5 * (1.0 if align == HORIZONTAL_ALIGNMENT_LEFT else -1.0), 0)

# Handwijzer zoals in Nederland, kort voor een kruising: een witte mast met blauw-witte
# banden en een zwarte voet, met blauwe pijlvormige bladen die naar links of rechts
# wijzen (de zijweg op). Op elk blad één plaatsnaam met de afstand.
# Echte richtingen: elk blad wijst alleen een zijweg op die ongeveer de kant van die plaats
# op gaat (in het spel is -Z het noorden en +X het oosten), en de afstand is de echte
# afstand hemelsbreed vanaf het centrum van de gemeente, plus wat omrijden.
const PLACES := {
    "Heerlen": Vector2(50.888, 5.979), "Kerkrade": Vector2(50.866, 6.070),
    "Landgraaf": Vector2(50.900, 6.025), "Brunssum": Vector2(50.947, 5.970),
    "Simpelveld": Vector2(50.834, 5.981), "Voerendaal": Vector2(50.879, 5.930),
    "Nuth": Vector2(50.917, 5.886), "Schinnen": Vector2(50.943, 5.870),
    "Hoensbroek": Vector2(50.923, 5.928), "Maastricht": Vector2(50.851, 5.691),
    "Sittard": Vector2(51.000, 5.869), "Geleen": Vector2(50.974, 5.829),
    "Valkenburg": Vector2(50.865, 5.832), "Aken": Vector2(50.776, 6.084),
    "Gulpen": Vector2(50.815, 5.889), "Schinveld": Vector2(50.969, 6.000),
    "Ubach over Worms": Vector2(50.918, 6.050), "Bocholtz": Vector2(50.818, 6.006),
    "Eygelshoven": Vector2(50.893, 6.060), "Klimmen": Vector2(50.873, 5.884),
    "Herzogenrath": Vector2(50.870, 6.094), "Geilenkirchen": Vector2(50.965, 6.120),
}
# centrum van elk level (id uit Game.LEVELS)
const LEVEL_HOME := {
    "heerlen": "Heerlen", "kerkrade": "Kerkrade", "landgraaf": "Landgraaf",
    "brunssum": "Brunssum", "simpelveld": "Simpelveld", "voerendaal": "Voerendaal",
    "beekdaelen": "Nuth", "finale": "Heerlen",
}
const SIGN_CONE := 65.0     # graden: zover mag de zijweg van de echte richting afwijken

# [naam, kompasrichting in graden (0 = noord, 90 = oost), km] van alle plaatsen behalve thuis
func _destinations() -> Array:
    var home: String = String(LEVEL_HOME.get(String(Game.current_level().get("id", "")), "Heerlen"))
    var h: Vector2 = PLACES[home]
    var out: Array = []
    for n in PLACES:
        if n == home:
            continue
        var q: Vector2 = PLACES[n]
        var north: float = (q.x - h.x) * 111.0
        var east: float = (q.y - h.y) * 111.0 * cos(deg_to_rad(h.x))
        var km: float = Vector2(east, north).length()
        if km < 2.0:
            continue
        out.append([n, fposmod(rad_to_deg(atan2(east, north)), 360.0), maxi(2, roundi(km * 1.25))])
    return out

# kompasrichting van een richting in de spelwereld
static func _bearing(v: Vector3) -> float:
    return fposmod(rad_to_deg(atan2(v.x, -v.z)), 360.0)

# Plaatsen die ongeveer in richting b liggen, de best passende eerst; een beetje
# afwisselen tussen kruisingen (k) zodat niet overal hetzelfde blad hangt.
func _pick(dests: Array, b: float, n: int, k: int, skip: Array) -> Array:
    var fit: Array = []
    for d in dests:
        if skip.has(d[0]):
            continue
        var diff: float = absf(angle_difference(deg_to_rad(b), deg_to_rad(float(d[1]))))
        if rad_to_deg(diff) <= SIGN_CONE:
            fit.append([diff, d])
    fit.sort_custom(func(a, c): return a[0] < c[0])
    var out: Array = []
    var take: int = mini(fit.size(), n + 1)
    for i in range(take):
        out.append(fit[(i + k) % take][1])
    return out.slice(0, n)

func _anwb_signs() -> void:
    var dests := _destinations()
    var k := 0
    for c in crossings:
        # op de hoek van de kruising, net voor de zijweg en achter het trottoir, zodat
        # de bladen boven het trottoir de zijweg op wijzen
        var off: float = _walk_offset() + lv.WALK_W * 0.5 + 1.0
        var s: float = float(c) - (Intersection.SIDE_HW + 5.5)
        var tries := 0
        while tries < 6 and not (_ok_place(s, 1.0, off) and not lv.near_lamp(r.pos_at(s) + r.right_at(s) * off, 2.6)):
            s -= 1.5
            tries += 1
        if s < 5.0 or tries >= 6:
            continue
        # zijwegen bij de kruising: links en rechts van de rijrichting
        var right: Vector3 = r.right_at(float(c))
        var lefts: Array = _pick(dests, _bearing(-right), 2, k, [])
        var names_l: Array = lefts.map(func(d): return d[0])
        var rights: Array = _pick(dests, _bearing(right), 1, k, names_l)
        k += 1
        if lefts.is_empty() and rights.is_empty():
            continue
        var f := _spot(s, 1.0, off)
        f.name = "Handwijzer"
        _handwijzer_mast(f)
        # hoog aan de mast, zoals in het echt (de mast is ook een stuk hoger dan eerst)
        var left_y := [4.4, 3.82]
        for i in range(lefts.size()):
            _blade(f, String(lefts[i][0]), int(lefts[i][2]), -1.0, left_y[i])
        for d in rights:
            _blade(f, String(d[0]), int(d[2]), 1.0, 3.24)
        used.append(s)

func _handwijzer_mast(f: Node3D) -> void:
    Kit.cyl(f, "Handwijzer base", Vector3(0, 0.3, 0), 0.11, 0.11, 0.6, Color("1c1c1c"), 12)
    Kit.cyl(f, "Handwijzer mast", Vector3(0, 2.3, 0), 0.11, 0.1, 4.6, Color("f2f2ee"), 12, "y", true)   # botst, net als een lantaarnpaal
    for i in range(4):
        var band := Kit.cyl(f, "Handwijzer band", Vector3(0, 0.85 + float(i) * 0.3, 0), 0.104, 0.104, 0.13, Color("1d4f9c"), 12)
        band.rotation_degrees.z = 14.0
    Kit.cyl(f, "Handwijzer cap", Vector3(0, 4.63, 0), 0.105, 0.105, 0.06, Color("1d4f9c"), 12)

# Pijlvormig blad: dir -1 wijst naar links, 1 naar rechts. Naam links, afstand rechts.
func _blade(f: Node3D, town: String, km: int, dir: float, y: float) -> void:
    var length := 2.5
    var h := 0.46
    var tip := 0.3
    var body: float = length - tip
    var cx: float = dir * (0.1 + body * 0.5)
    var white := Color("f4f4ee")
    var blue := Color("1d4f9c")
    Kit.box(f, "Blade back", Vector3(cx, y, -0.02), Vector3(body, h, 0.012), Color("8d9396"))
    Kit.box(f, "Blade border", Vector3(cx, y, 0), Vector3(body, h, 0.02), white)
    # blauw vlak tot precies aan de punt (geen witte streep tussen vlak en punt)
    Kit.box(f, "ANWB sign", Vector3(dir * (0.12 + (body - 0.02) * 0.5), y, 0.012), Vector3(body - 0.02, h - 0.05, 0.012), blue)
    var tip_x: float = dir * (0.1 + body + tip * 0.5)
    var t1 := _prism(f, "Blade tip border", Vector3(tip_x - dir * 0.001, y, 0), h, tip, 0.02, white)
    t1.rotation_degrees.z = -90.0 * dir
    var t2 := _prism(f, "Blade tip", Vector3(tip_x - dir * 0.02, y, 0.012), h - 0.05, tip - 0.04, 0.012, blue)
    t2.rotation_degrees.z = -90.0 * dir
    # alleen de plaatsnaam (in het echt staan er geen kilometers op), midden op het blad
    var font: Font = ThemeDB.fallback_font
    var tw: float = font.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
    var px: float = minf(0.005, (body - 0.55) / tw)
    Kit.label(f, town, Vector3(cx, y, 0.026), px, Color.WHITE, 64)

# ---------------------------------------------------------------- straatmeubilair
func _bus_stops() -> void:
    var made := 0
    var s: float = r.length * 0.15
    while s < r.length - 60.0 and made < 2:
        var side: float = 1.0 if made == 0 else -1.0
        var off: float = _walk_offset() + 2.4
        if lv.is_town(s) and _straight(s) and _free(s, 50.0) and _ok_place(s, side, off):
            _bus_stop(s, side)
            used.append(s)
            bus_s.append(s)
            made += 1
            s += r.length * 0.35
        else:
            s += 30.0

func _bus_stop(s: float, side: float) -> void:
    # Moderne halte zoals in Parkstad: een perron van grijze tegels met een witte
    # geleidelijn, een abri met donkergrijs frame, glas, een sedumdak, een houten bank
    # en een verlichte reclamevitrine, en een gele afvalbak. Geen los H-bord meer.
    # In een _spot ligt de weg altijd aan lokaal -X; de pivot draait +Z die kant op.
    var spot := _spot(s, side, _walk_offset() + 2.4)
    var f := Node3D.new()
    f.rotation_degrees.y = -90.0
    spot.add_child(f)
    var frame := Color("2f353b")
    # perron: van de buitenkant van het trottoir (z = 1.4) tot achter de abri
    Kit.box(f, "Bus platform", Vector3(0, 0.04, -0.15), Vector3(9.0, 0.08, 3.1), Color("8f918d"))
    var top := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(9.0, 3.1)
    top.mesh = pm
    top.material_override = _paving_mat(Vector2(9.0, 3.1))
    top.name = "Bus platform tiles"
    top.position = Vector3(0, 0.082, -0.15)
    f.add_child(top)
    # witte geleidelijn (ribbeltegels) evenwijdig aan de stoep, plus een aftakking naar de instap
    Kit.box(f, "Guide line", Vector3(0, 0.085, 0.95), Vector3(8.4, 0.01, 0.3), Color("e6e6e0"))
    for k in range(4):
        Kit.box(f, "Guide rib", Vector3(0, 0.093, 0.83 + float(k) * 0.08), Vector3(8.4, 0.008, 0.035), Color("fbfbf6"))
    Kit.box(f, "Guide attention", Vector3(-2.6, 0.086, 0.95), Vector3(0.6, 0.012, 0.6), Color("e6e6e0"))
    for i in range(4):
        for j in range(4):
            Kit.cyl(f, "Guide dot", Vector3(-2.82 + float(i) * 0.145, 0.095, 0.73 + float(j) * 0.145), 0.025, 0.025, 0.012, Color("fbfbf6"), 6)
    # abri: lange kant langs de stoep, open kant naar de weg
    var glass := Kit.glass_mat(Color("b4d2da"))
    Kit.box(f, "Shelter back", Vector3(0, 1.3, -0.75), Vector3(3.8, 2.2, 0.04), Color.WHITE, true, glass)
    Kit.box(f, "Shelter side", Vector3(-1.9, 1.3, -0.3), Vector3(0.04, 2.2, 0.9), Color.WHITE, false, glass)
    for x in [-1.95, 0.0, 1.95]:
        Kit.box(f, "Shelter post", Vector3(x, 1.3, -0.78), Vector3(0.07, 2.45, 0.07), frame)
    for x in [-1.95, 1.95]:
        Kit.box(f, "Shelter post", Vector3(x, 1.3, 0.15), Vector3(0.07, 2.45, 0.07), frame)
    Kit.box(f, "Shelter rail", Vector3(0, 0.22, -0.75), Vector3(3.8, 0.05, 0.06), frame)
    Kit.box(f, "Shelter roof", Vector3(0, 2.56, -0.3), Vector3(4.2, 0.14, 1.45), frame)
    Kit.box(f, "Shelter sedum", Vector3(0, 2.65, -0.3), Vector3(4.0, 0.05, 1.3), Color("6f7d4a"))
    for x in [-1.3, -0.6, 0.2, 0.9, 1.5]:
        Kit.box(f, "Sedum patch", Vector3(x, 2.68, -0.3 + fmod(x * 7.0, 0.5)), Vector3(0.35, 0.03, 0.4), Color("9a6a52") if x > 0.5 else Color("8a9a52"))
    # houten bank op een donker frame, tegen de achterwand
    for x in [-1.0, 0.8]:
        Kit.box(f, "Bench leg", Vector3(x, 0.24, -0.5), Vector3(0.06, 0.4, 0.4), frame)
    for k in range(3):
        Kit.box(f, "Bench slat", Vector3(-0.1, 0.46, -0.64 + float(k) * 0.13), Vector3(2.4, 0.04, 0.1), Color("b88a5a"))
    # verlichte reclamevitrine aan de open kant (rechts), in een donker frame
    Kit.box(f, "Ad case", Vector3(1.95, 1.25, -0.3), Vector3(0.14, 2.0, 1.05), frame)
    for d in [-1.0, 1.0]:
        Kit.box(f, "Ad poster", Vector3(1.95 + d * 0.075, 1.3, -0.3), Vector3(0.01, 1.7, 0.92), Color("f0ece2"), false, Kit.mat(Color("f0ece2"), 0.25))
        Kit.box(f, "Ad poster band", Vector3(1.95 + d * 0.08, 0.75, -0.3), Vector3(0.01, 0.42, 0.92), Color("c8202a"), false, Kit.mat(Color("c8202a"), 0.25))
        Kit.box(f, "Ad poster block", Vector3(1.95 + d * 0.08, 1.55, -0.3), Vector3(0.01, 0.7, 0.62), Color("2f6b8a"), false, Kit.mat(Color("2f6b8a"), 0.25))
        var l: Label3D = Kit.label(f, "BEZOEK\nPARKSTAD", Vector3(1.95 + d * 0.09, 0.75, -0.3), 0.0021, Color.WHITE, 64)
        l.rotation_degrees.y = 90.0 * d
    # gele afvalbak op een paaltje naast de abri
    Kit.box(f, "Bin post", Vector3(-2.45, 0.45, 0.2), Vector3(0.06, 0.9, 0.06), frame)
    Kit.box(f, "Bin", Vector3(-2.45, 0.75, 0.32), Vector3(0.4, 0.6, 0.22), Color("f2c230"))
    Kit.box(f, "Bin lid", Vector3(-2.45, 1.07, 0.32), Vector3(0.42, 0.06, 0.24), Color("3a3e44"))
    # bushalte-markering op de weg
    var m := _spot(s, side, lv.road_hw - 1.8)
    Kit.label(m, "BUS", Vector3(0, 0.05, 0), 0.03, Color("f2f2ee"), 64).rotation_degrees.x = -90.0

# Grijze betontegels van 30 x 30 cm met donkere voegen, als getekende textuur.
static var _paving: Dictionary = {}
func _paving_mat(size: Vector2) -> StandardMaterial3D:
    var key := "%s" % size
    if _paving.has(key):
        return _paving[key]
    var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
    var g := RandomNumberGenerator.new()
    g.seed = 11
    for ty in range(2):
        for tx in range(2):
            var v: float = 0.5 + g.randf_range(-0.03, 0.03)
            img.fill_rect(Rect2i(tx * 32, ty * 32, 32, 32), Color(v, v, v * 0.98))
    for i in range(64):
        for k in [0, 1, 32, 33]:
            img.set_pixel(i, k, Color(0.34, 0.34, 0.33))
            img.set_pixel(k, i, Color(0.34, 0.34, 0.33))
    img.generate_mipmaps()
    var m := StandardMaterial3D.new()
    m.albedo_texture = ImageTexture.create_from_image(img)
    m.roughness = 1.0
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    m.uv1_scale = Vector3(size.x / 0.6, size.y / 0.6, 1.0)
    _paving[key] = m
    return m

func _speed_cameras(race, count: int) -> void:
    var made := 0
    var s: float = r.length * 0.4
    while s < r.length * 1.4 and made < count:
        var ss: float = fposmod(s, r.length)
        # op de band naast de rijbaan: goed te zien, en om te rijden als je durft
        var off: float = (lv.road_hw + 1.2) if lv.dual else (lv.road_hw + lv.CURB_W * 0.5)
        if _straight(ss) and _free(ss, 40.0) and _ok_place(ss, 1.0, off) and not lv.roadside_blocked(ss):
            var cam = SpeedCamera.new()
            var f := _spot(ss, 1.0, off)
            f.add_child(cam)
            var limit: float = 100.0 if lv.dual else (50.0 if lv.is_town(ss) else 80.0)
            cam.setup(race, limit, lv.road_hw + off)
            used.append(ss)
            made += 1
            s += r.length * 0.45
        else:
            s += 30.0

func _planters_and_bins() -> void:
    var s := 40.0
    var k := 0
    while s < r.length - 20.0:
        var side: float = 1.0 if k % 2 == 0 else -1.0
        var off: float = _walk_offset() + (1.7 if k % 3 == 2 else 0.3)
        if lv.is_town(s) and _free(s, 12.0) and _ok_place(s, side, off):
            var f := _spot(s, side, off)
            if k % 3 == 2:
                # iets achter het trottoir, zodat ze niet tussen de lantaarnpalen staan
                _containers(f)
            else:
                # betonnen bloembak met groen en bloemen
                Kit.box(f, "Planter", Vector3(0, 0.35, 0), Vector3(1.6, 0.7, 0.8), Color("b8b2a6"), true)
                Kit.box(f, "Planter green", Vector3(0, 0.78, 0), Vector3(1.4, 0.2, 0.6), Color("4f7d3a"))
                for i in range(4):
                    Kit.cyl(f, "Flower", Vector3(-0.5 + float(i) * 0.33, 0.92, 0.05), 0.12, 0.12, 0.1, [Color("d23c6e"), Color("f2c230"), Color("e8e6e0"), Color("c8202a")][i], 8)
            k += 1
        s += 85.0

# Ondergrondse containers zoals in Parkstad: een rij donkerblauwe inwerpzuilen op een
# betonnen plaat, met drie hijsogen bovenop, een inwerptrommel of -klep aan de voorkant
# (naar de stoep) en witte opdruk. De laatste is zwart met een pasjeslezer (restafval).
# De zuilen zijn massief. Voorkant = -X van de plek (naar de weg).
func _containers(f: Node3D) -> void:
    var navy := Color("1f2b5e")
    var black := Color("25282c")
    var steel := Color("8f9599")
    for i in range(4):
        var c := Vector3(0, 0, -3.3 + float(i) * 2.2)
        var col: Color = black if i == 3 else navy
        Kit.box(f, "Container pad", c + Vector3(0, 0.06, 0), Vector3(1.7, 0.08, 1.7), Color("8a8c88"))
        Kit.box(f, "Container plate", c + Vector3(0, 0.11, 0), Vector3(1.45, 0.03, 1.45), Color("6c7074"))
        Kit.box(f, "Container column", c + Vector3(0.05, 0.68, 0), Vector3(0.72, 1.1, 0.9), col, true)
        var top := Kit.box(f, "Container top", c + Vector3(0.0, 1.28, 0), Vector3(0.86, 0.12, 0.96), col)
        top.rotation_degrees.z = 8.0      # schuin aflopend naar voren
        for z in [-0.3, 0.0, 0.3]:
            Kit.cyl(f, "Lifting eye post", c + Vector3(0.12, 1.42, z), 0.03, 0.03, 0.14, steel, 6)
            Kit.cyl(f, "Lifting eye", c + Vector3(0.12, 1.55, z), 0.07, 0.07, 0.025, steel, 10, "z")
        var front := c + Vector3(-0.32, 0, 0)
        match i:
            0:
                # papier: rechthoekige klep
                Kit.box(f, "Container hatch", front + Vector3(0, 0.92, 0), Vector3(0.04, 0.32, 0.5), Color("11131a"))
            1, 2:
                # plastic / glas: ronde inwerpopening met rand
                Kit.cyl(f, "Container ring", front + Vector3(0, 0.92, 0), 0.19, 0.19, 0.04, Color("c9ccd0"), 16, "x")
                Kit.cyl(f, "Container hole", front + Vector3(-0.01, 0.92, 0), 0.14, 0.14, 0.04, Color("0d0f12"), 16, "x")
            3:
                # restafval: trommel met pasjeslezer
                Kit.box(f, "Container drum", front + Vector3(0, 0.9, 0.08), Vector3(0.05, 0.36, 0.5), Color("3a3e44"))
                Kit.box(f, "Card reader", front + Vector3(0, 1.08, -0.33), Vector3(0.05, 0.16, 0.12), Color("e3dfcf"))
        # witte opdruk onderaan en een sticker met het soort afval
        Kit.box(f, "Container print", front + Vector3(0, 0.3, 0.25), Vector3(0.02, 0.07, 0.24), Color("e8e8e4"))
        Kit.box(f, "Container sticker", front + Vector3(0, 0.62, 0), Vector3(0.02, 0.12, 0.5), Color("dfe3e8") if i < 3 else Color("e1c24a"))

# ---------------------------------------------------------------- Buitenring
func _highway_posts() -> void:
    # hectometerpaaltjes (groen, wit getal) en reflectorpalen langs de buitenkant
    var s := 0.0
    var hm := 0
    while s < r.length - 1.0:
        var f := _spot(s, 1.0, lv.road_hw + 1.3)
        Kit.box(f, "Reflector post", Vector3(0, 0.5, 0), Vector3(0.12, 1.0, 0.12), Color("f2f2ee"))
        Kit.box(f, "Reflector band", Vector3(0, 0.85, 0), Vector3(0.13, 0.18, 0.13), Color("1a1a1a"))
        Kit.box(f, "Reflector", Vector3(0, 0.85, 0.07), Vector3(0.06, 0.1, 0.01), Color("e8a33a"))
        if int(s) % 100 < 50:
            var g := _spot(s + 2.0, 1.0, lv.road_hw + 2.2)
            # paaltje tot onder het bordje (niet erdoorheen)
            Kit.box(g, "Hectometer post", Vector3(0, 0.48, -0.04), Vector3(0.08, 0.96, 0.06), Color("9aa0a4"))
            Kit.box(g, "Hectometer sign", Vector3(0, 1.1, 0.0), Vector3(0.36, 0.28, 0.03), Color("2f6b3f"))
            # Nederlandse notatie met komma; lange getallen (12,4) kleiner zodat ze binnen het bordje passen
            var txt: String = ("%.1f" % (float(hm) / 10.0)).replace(".", ",")
            Kit.label(g, txt, Vector3(0, 1.1, 0.02), minf(0.004, 0.3 / (float(txt.length()) * 64.0 * 0.6)), Color.WHITE, 64)
            hm += 1
        s += 50.0

# ---------------------------------------------------------------- fietspadmarkering
# Zoals op de foto's (27-11): een onderbroken witte streep op de grens van asfalt en rood
# fietspad en af en toe een witte fiets, rechtop gezien vanuit de fietser (rechts met het
# verkeer mee, links tegemoet). Alles in twee meshes (twee tekenopdrachten). Niet op
# kruisingen, zebrapaden, bushaltes en pleinen van bezienswaardigheden: daar ligt iets
# anders bovenop, en twee vlakken op bijna dezelfde hoogte gaan knipperen.
const MARK_Y := 0.075          # fietspad ligt op 0,065: 1 cm erboven
const BIKE_SYMBOL_EVERY := 70.0

func _bike_markings() -> void:
    var b0: float = lv.road_hw + lv.CURB_W
    var flats := _flat_overlays()
    # onderbroken streep: 1 m streep, 1 m open
    var dashes: Array = []
    var st0 := 2.0
    while st0 < r.length - 3.0:
        if _marking_ok(st0, 6.0, flats, b0):
            dashes.append([st0, st0 + 1.0, lv.road_hw + 0.04, lv.road_hw + 0.19, MARK_Y, 1.0])
            dashes.append([st0, st0 + 1.0, -lv.road_hw - 0.19, -lv.road_hw - 0.04, MARK_Y, 1.0])
        st0 += 2.0
    lv._ribbon("Bike path dashes", lv.LINE, dashes)
    # fietssymbolen
    var xf: Array[Transform3D] = []
    var mid: float = b0 + lv.BIKE_W * 0.5 + 0.06
    var sb := 40.0
    var side := 1.0
    while sb < r.length - 40.0:
        if _marking_ok(sb, 12.0, flats, b0) and _free(sb, 10.0):
            var a: Vector3 = r.pos_at(sb - 1.0)
            var b: Vector3 = r.pos_at(sb + 1.0)
            var fwd: Vector3 = (b - a).normalized()
            var right: Vector3 = r.right_at(sb)
            if side < 0.0:
                fwd = -fwd
                right = -right
            var up: Vector3 = right.cross(fwd).normalized()
            if up.y < 0.0:
                up = -up
            var at: Vector3 = r.pos_at(sb) + r.right_at(sb) * side * mid
            at.y = r.pos_at(sb).y + MARK_Y + 0.001
            xf.append(Transform3D(Basis(right, up, -fwd), at))
        sb += BIKE_SYMBOL_EVERY * 0.5
        side = -side
    if xf.is_empty():
        return
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = _bike_symbol_mesh()
    mm.instance_count = xf.size()
    for i in xf.size():
        mm.set_instance_transform(i, xf[i])
    var mmi := MultiMeshInstance3D.new()
    mmi.name = "Bike path symbols"
    mmi.multimesh = mm
    mmi.material_override = Kit.two_sided_mat(lv.LINE)
    mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    lv.add_child(mmi)

# Mag hier markering liggen? Niet bij kruisingen (zijweg ligt over het fietspad), zebrapaden,
# bushaltes, in een bezienswaardigheid, of waar een plat vlak (plein, perron) over het
# fietspad ligt.
func _marking_ok(s: float, gap: float, flats: Dictionary, b0: float) -> bool:
    for c in crossings:
        if absf(float(c) - s) < Intersection.SIDE_HW + 6.0 + gap:
            return false
    for z in zebra_s + bus_s:
        if absf(float(z) - s) < 8.0 + gap:
            return false
    for side in [-1.0, 1.0]:
        var p: Vector3 = r.pos_at(s) + r.right_at(s) * side * (b0 + lv.BIKE_W * 0.5)
        if lv.in_landmark(p):
            return false
        for box in flats.get(Vector2i(floori(p.x / FLAT_CELL), floori(p.z / FLAT_CELL)), []):
            var bb: AABB = box
            if p.x > bb.position.x - 0.5 and p.x < bb.end.x + 0.5 and p.z > bb.position.z - 0.5 and p.z < bb.end.z + 0.5 \
                    and bb.end.y > p.y + 0.03 and bb.position.y < p.y + 0.4:
                return false
    return true

# Platte dingen op straathoogte (pleinen, perrons, opritten) als wereld-AABB's, per vak van
# FLAT_CELL meter (snel opzoeken). De weg zelf (de lange linten) telt niet mee.
const FLAT_CELL := 20.0
func _flat_overlays() -> Dictionary:
    var out := {}
    for n in lv.find_children("*", "MeshInstance3D", true, false):
        var mi := n as MeshInstance3D
        if mi.mesh == null:
            continue
        var bb: AABB = mi.global_transform * mi.mesh.get_aabb()
        if bb.size.y > 0.5 or bb.size.x > 400.0 or bb.size.z > 400.0:
            continue
        for cx in range(floori(bb.position.x / FLAT_CELL), floori(bb.end.x / FLAT_CELL) + 1):
            for cz in range(floori(bb.position.z / FLAT_CELL), floori(bb.end.z / FLAT_CELL) + 1):
                var key := Vector2i(cx, cz)
                if not out.has(key):
                    out[key] = []
                out[key].append(bb)
    return out

# Witte fiets van opzij, plat op de grond: lengte dwars over het pad (x), "boven" van de fiets
# in rijrichting (-z). Ongeveer 1,3 m breed.
func _bike_symbol_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var k := 0.85
    var w := 0.1
    var to3 := func(v: Vector2) -> Vector3: return Vector3(v.x * k, 0.0, -v.y * k)
    var quad := func(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
        for v in [a, b, c, a, c, d]:
            st.set_normal(Vector3.UP)
            st.add_vertex(to3.call(v))
    var stick := func(a: Vector2, b: Vector2) -> void:
        var n: Vector2 = (b - a).normalized().orthogonal() * w * 0.5
        var e: Vector2 = (b - a).normalized() * w * 0.3
        quad.call(a - e + n, b + e + n, b + e - n, a - e - n)
    # wielen: ringen
    for cx in [-0.52, 0.52]:
        var c := Vector2(cx, 0.0)
        var ro := 0.3
        var ri := ro - w
        var segs := 22
        for i in segs:
            var t0: float = TAU * i / segs
            var t1: float = TAU * (i + 1) / segs
            quad.call(c + Vector2(cos(t0), sin(t0)) * ri, c + Vector2(cos(t0), sin(t0)) * ro,
                c + Vector2(cos(t1), sin(t1)) * ro, c + Vector2(cos(t1), sin(t1)) * ri)
    # frame: trapas, zadelpen, stuurbuis, achtervork en voorvork
    var bb := Vector2(-0.02, 0.02)
    var seat := Vector2(-0.18, 0.46)
    var head := Vector2(0.36, 0.44)
    var rear := Vector2(-0.52, 0.0)
    var front := Vector2(0.52, 0.0)
    stick.call(bb, seat)
    stick.call(seat, head)
    stick.call(bb, head)
    stick.call(bb, rear)
    stick.call(seat, rear)
    stick.call(head, front)
    # zadel en stuur
    stick.call(Vector2(-0.3, 0.52), Vector2(-0.08, 0.52))
    stick.call(head, Vector2(0.3, 0.6))
    stick.call(Vector2(0.3, 0.6), Vector2(0.42, 0.62))
    return st.commit()
