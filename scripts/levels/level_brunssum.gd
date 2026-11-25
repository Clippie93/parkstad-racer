extends "res://scripts/levels/level_base.gd"
# Level 4: Brunssum. Start op de Brunssummerheide (heide, stuifzand, dennen en berken),
# bij het plaatsnaambord de bebouwde kom in, langs het schachtwiel, finish op het plein voor
# de Heilige Gregoriuskerk van Gottfried Böhm. Het stratenplan is verzonnen en compact.
const LmGregorius = preload("res://scripts/landmarks/landmark_gregoriuskerk.gd")
const LmWiel = preload("res://scripts/landmarks/landmark_mijnwiel.gd")
const LmSterrenwacht = preload("res://scripts/landmarks/landmark_sterrenwacht.gd")
const LmClemens = preload("res://scripts/landmarks/landmark_clemens.gd")
const LmVijverpark = preload("res://scripts/landmarks/landmark_vijverpark.gd")
const LmRaadhuis = preload("res://scripts/landmarks/landmark_raadhuis_brunssum.gd")
const LmBrikke = preload("res://scripts/landmarks/landmark_brikke_oave.gd")
const LmDalmacija = preload("res://scripts/landmarks/landmark_dalmacija.gd")

const HEATH_Z := 250.0          # tot hier (vanaf het noorden) ligt de heide
const KERK_POS := Vector3(-250, 0, -10)
const WIEL_POS := Vector3(-420, 0, 420)
const STAR_POS := Vector3(-27, 0, 640)   # sterrenwacht links van de weg, vlak na de start

func build() -> void:
    level_title = "BRUNSSUM"
    seed_value = 5281
    # rondje: langs de kerk naar het westen en door de heide terug naar de start
    route = Route.new([
        Vector3(0, 0, 700),
        Vector3(0, 0, 560),
        Vector3(50, 0, 440),
        Vector3(50, 0, 0),
        Vector3(-420, 0, 0),
        Vector3(-420, 0, 820),
        Vector3(0, 0, 820),
    ], [90.0, 90.0, 55.0, 70.0, 80.0, 70.0], true)
    checkpoints = [
        {"at": Vector3(50, 0, 190), "name": "LINDEPLEIN"},
        {"at": Vector3(-110, 0, 0), "name": "CENTRUM"},
        {"at": Vector3(-250, 0, 0), "name": "GREGORIUSKERK"},
        {"at": Vector3(-420, 0, 232), "name": "CLEMENSDOMEIN"},
        {"at": Vector3(-420, 0, 470), "name": "SCHACHTWIEL"},
        # over de heide terug naar de finish (lag eerst vlak na de start)
        {"at": route.pos_at(2050.0), "name": "BRUNSSUMMERHEIDE"},
    ]
    traffic_cars = 12

    # heide: geen bebouwing ten noorden van HEATH_Z
    exclusions.append(Rect2(-620, HEATH_Z, 1020, 810))
    place(LmSterrenwacht.new(), STAR_POS, 90.0)
    hard_exclusions.append(Rect2(STAR_POS.x - 12, STAR_POS.z - 30, 26, 70))
    # schachtwiel (24-11, jouw wens: weg uit de buurt van het Lindeplein): op de terugweg
    # aan de rand van de heide, links in het open heideveld, zodat de lange heideweg ook
    # een herkenningspunt heeft
    var wiel: Node3D = place_beside(LmWiel.new(), route.closest_s(WIEL_POS), -1.0, 22.0, Vector2(13, 13))
    wiel.rotation_degrees.y -= 50.0   # schuin naar het aankomende verkeer: geen wiel op z'n kant
    # kerk: de straat loopt langs de pleinrand (z=0 lokaal), dus 10 m van de wegas
    place(LmGregorius.new(), KERK_POS)
    exclusions.append(Rect2(KERK_POS.x - 45, KERK_POS.z - 60, 90, 62))

    # Clemensdomein (Oude Clemenskerk op de heuvel) rechts van de weg, op het stuk naar het
    # noorden vlak voor de heide
    place_beside(LmClemens.new(), route.closest_s(Vector3(-420, 0, 150)), 1.0, 45.0, Vector2(32, 40))

    # Vijverpark met het Lindeplein links van de weg, vlak voor de bocht naar het centrum;
    # de vijver ligt lager dan de weg (gat in de grond)
    # zoals op de kaart: je rijdt langs het Lindeplein (met het nieuwe gemeentehuis aan het
    # eind en de vijver erachter), neemt de bocht en komt bij het oude gemeentehuis uit
    var vp: Node3D = place_beside(LmVijverpark.new(), route.closest_s(Vector3(50, 0, 165)), -1.0, 93.0, Vector2(1, 1))
    # plein + park (x -71..39) en het gemeentehuis links ervan (x -107..-77), lokaal
    exclude_local(vp, Rect2(-108, -80, 150, 156))
    # het oude gemeentehuis op de buitenhoek van de bocht: je rijdt er recht op af
    # (zoals op jouw foto vanaf de Lindeplein-straat)
    var corner := Vector3(50, 0, 0)
    var corner_apex: Vector3 = route.pos_at(route.closest_s(corner))   # midden van de bocht
    var out_dir: Vector3 = (corner - corner_apex).normalized()
    var rh_pos: Vector3 = corner_apex + out_dir * 30.0
    place(LmRaadhuis.new(), rh_pos, rad_to_deg(atan2(-out_dir.x, -out_dir.z)))
    hard_exclusions.append(Rect2(rh_pos.x - 20, rh_pos.z - 20, 40, 40))
    exclusions.append(Rect2(rh_pos.x - 20, rh_pos.z - 20, 40, 40))
    # tegenover het Lindeplein de Brikke Oave (de oude steenoven, nu theater en café)
    place_beside(LmBrikke.new(), route.closest_s(Vector3(50, 0, 185)), 1.0, 22.0, Vector2(14, 20))
    # en een stukje verder (richting de heide) Steakhouse Dalmacija met een buurpand
    place_beside(LmDalmacija.new(), route.closest_s(Vector3(50, 0, 222)), 1.0, 15.5, Vector2(10, 16))
    add_pit(vp, vp.pit_rect())

    finish_line(3)
    build_road()
    # mijnkolonie: mijnwerkerswoningen en rijtjes
    street_mix = {"mine": 4, "row": 3, "semi": 2, "detached": 1}
    build_streetscape()
    _heath()
    town_board(route.closest_s(Vector3(50, 0, HEATH_Z - 10)), 1.0, Color("c8a440"), [["name", ["Brunssum", "Broenssem"]], ["host"],
        ["strip", "Partnergemeente Alsdorf", Color("3a3a3a"), Color("e4e4e0")], ["strip", "WELKOM - WILLKOMMEN - BIENVENUE - WELCOME", Color("8a2a2a"), Color("eeeeea")]])   # naar jouw foto
    street_sign("BRUNSSUMMERHEIDE", Vector3(-12, 4.0, 700))
    street_sign("CENTRUM  /  GREGORIUSKERK", Vector3(62, 4.0, 40))

# Brunssummerheide: dicht bos van loofbomen en sparren (zoals de Schinveldse bossen) met open
# heidevelden ertussen: paarse heide, stuifzand en lage duinen. Twee velden liggen aan de
# weg, zodat je afwisselend door het bos en langs open heide rijdt.
const CLEARINGS := [
    [Vector3(40, 0, 500), 85.0],     # aan de weg, na de start
    [Vector3(-190, 0, 640), 120.0],  # midden in het bos
    [Vector3(-390, 0, 420), 75.0],   # aan de westkant van het rondje
    [Vector3(-170, 0, 880), 60.0],   # aan de noordkant
]

func _in_clearing(p: Vector3, margin := 0.0) -> bool:
    for c in CLEARINGS:
        if Vector2(p.x - c[0].x, p.z - c[0].z).length() < float(c[1]) + margin:
            return true
    return false

func _heath() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 2007
    var area := Rect2(-620, HEATH_Z, 1020, 1060.0 - HEATH_Z)   # ook buiten het rondje (west en noord)
    # bosbodem overal, en in de open velden de bruingroene heidebodem
    Kit.box(self, "Forest floor", Vector3(area.get_center().x, 0.0, area.get_center().y), Vector3(area.size.x, 0.01, area.size.y), Color("3f5531"))
    var k := 0
    for c in CLEARINGS:
        # elk veld een eigen hoogte (geen knipperen), maar altijd onder het asfalt (0,03)
        Kit.cyl(self, "Heath ground", c[0] + Vector3(0, 0.008 + float(k) * 0.003, 0), float(c[1]), float(c[1]), 0.01, Color("8a8456"), 28)
        k += 1
    # paarse heide en strogele grasplukken (naar jouw foto's, 20-11)
    var heather := [Color("8e7392"), Color("9b7fa0"), Color("85708a"), Color("b3a466"), Color("a39660")]
    for i in range(90):
        var c: Array = CLEARINGS[i % CLEARINGS.size()]
        var a: float = rng.randf() * TAU
        var p: Vector3 = c[0] + Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, float(c[1]) - 12.0)
        var sz := Vector3(rng.randf_range(10, 30), 0.06, rng.randf_range(10, 30))
        # de hele heideplek moet naast weg en stoep liggen, niet alleen het midden
        if route.distance_to(p) < Vector2(sz.x, sz.z).length() * 0.5 + road_hw + 4.0:
            continue
        Kit.box(self, "Heather", p + Vector3(0, 0.04 + float(i % 7) * 0.02, 0), sz,   # eigen hoogte: geen knipperen
            heather[rng.randi_range(0, heather.size() - 1)])
    for i in range(14):
        var c: Array = CLEARINGS[i % CLEARINGS.size()]
        var a: float = rng.randf() * TAU
        var r: float = rng.randf_range(8.0, 18.0)
        var p: Vector3 = c[0] + Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, maxf(0.0, float(c[1]) - r - 6.0))
        if route.distance_to(p) < r + road_hw + 6.0:
            continue
        Kit.cyl(self, "Sand dune", p + Vector3(0, 1.0, 0), r, r * 0.45, 2.0, Color("cfc4a6"), 12)
    _heath_details(rng)
    # het bos, zoals de Schinveldse bossen: loofbomen met grote ronde kruinen en kegelvormige
    # sparren die bijna tot de grond groen zijn (geen kale stammen met een kruintje erop);
    # in de heidevelden maar een enkele boom
    var leaf_trunks: Array = []
    var leaf_crowns: Array = [[], [], []]
    var fir_trunks: Array = []
    var fir_crowns: Array = []
    for i in range(int(area.get_area() / 120.0)):
        var p := Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
        var d: float = route.distance_to(p)
        if d < 13.0 or _excluded_hard(p):
            continue
        var open: bool = _in_clearing(p)
        if open and rng.randf() > 0.06:
            continue
        if rng.randf() < 0.6:
            var h: float = rng.randf_range(12.0, 20.0)
            leaf_trunks.append(Transform3D(Basis().scaled(Vector3(1.0, h * 0.8, 1.0)), p + Vector3(0, h * 0.4, 0)))
            leaf_crowns[rng.randi_range(0, 2)].append(Transform3D(Basis().scaled(Vector3(h * 0.3, h * 0.32, h * 0.3)), p + Vector3(0, h * 0.78, 0)))
        else:
            # grove den: lange kale roodbruine stam met een platte, onregelmatige kroon
            var h: float = rng.randf_range(14.0, 22.0)
            fir_trunks.append(Transform3D(Basis().scaled(Vector3(0.9, h * 0.8, 0.9)), p + Vector3(0, h * 0.4, 0)))
            for j in range(3):
                var off := Vector3(rng.randf_range(-1.8, 1.8), rng.randf_range(-1.2, 0.8), rng.randf_range(-1.8, 1.8))
                var w: float = rng.randf_range(2.0, 3.4)
                fir_crowns.append(Transform3D(Basis().scaled(Vector3(w, w * 0.45, w)), p + Vector3(0, h * 0.85, 0) + off))
        if d < 40.0:
            var body := StaticBody3D.new()
            var cs := CollisionShape3D.new()
            var shape := CylinderShape3D.new()
            shape.radius = 0.3
            shape.height = 6.0
            cs.shape = shape
            body.add_child(cs)
            body.position = p + Vector3(0, 3.0, 0)
            add_child(body)
    var trunk := CylinderMesh.new()
    trunk.top_radius = 0.25
    trunk.bottom_radius = 0.35
    trunk.height = 1.0
    trunk.radial_segments = 6
    trunk.rings = 1
    var round := SphereMesh.new()
    round.radius = 1.0
    round.height = 2.0
    round.radial_segments = 8
    round.rings = 4
    var cone := CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 1.0
    cone.height = 1.0
    cone.radial_segments = 8
    cone.rings = 1
    _multimesh("Leaf trunks", trunk, leaf_trunks, Kit.mat(Color("4e3d2e")))
    var leaf_colors := [Color("3b5a2e"), Color("4a6b36"), Color("566f3a")]
    for j in range(3):
        _multimesh("Leaf crowns", round, leaf_crowns[j], Kit.mat(leaf_colors[j]))
    _multimesh("Pine trunks", trunk, fir_trunks, Kit.mat(Color("8a5a3e")))
    _multimesh("Pine crowns", round, fir_crowns, Kit.mat(Color("2c4a30")))
    _heath_road()

# Jonge dennetjes, berkjes, heidestruikjes en witte zandpaden in de heidevelden.
func _heath_details(rng: RandomNumberGenerator) -> void:
    var bushes: Array = [[], [], []]
    var pines: Array = []
    var birch_trunks: Array = []
    var birch_crowns: Array = []
    for c in CLEARINGS:
        var r: float = float(c[1])
        for i in range(int(r * r * 0.11)):
            var a: float = rng.randf() * TAU
            var p: Vector3 = c[0] + Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * (r - 4.0)
            if route.distance_to(p) < 13.0 or _excluded_hard(p):
                continue
            var roll: float = rng.randf()
            if roll < 0.9:
                var w: float = rng.randf_range(0.4, 0.95)
                bushes[rng.randi_range(0, 2)].append(Transform3D(Basis().scaled(Vector3(w, w * 0.45, w)), p + Vector3(0, w * 0.15, 0)))
            elif roll < 0.97:
                var h: float = rng.randf_range(1.2, 4.0)
                pines.append(Transform3D(Basis().scaled(Vector3(h * 0.35, h, h * 0.35)), p + Vector3(0, h * 0.5, 0)))
            else:
                var h: float = rng.randf_range(3.0, 6.0)
                birch_trunks.append(Transform3D(Basis().scaled(Vector3(0.35, h * 0.8, 0.35)), p + Vector3(0, h * 0.4, 0)))
                birch_crowns.append(Transform3D(Basis().scaled(Vector3(h * 0.22, h * 0.35, h * 0.22)), p + Vector3(0, h * 0.75, 0)))
        # een kronkelend wit zandpad door het veld
        var prev: Vector3 = c[0] + Vector3(-r * 0.8, 0, 0)
        for k in range(1, 9):
            var q: Vector3 = c[0] + Vector3(-r * 0.8 + float(k) * r * 0.2, 0, sin(float(k) * 0.9) * r * 0.25)
            if route.distance_to(q) > 14.0 and route.distance_to(prev) > 14.0:
                var seg := Kit.box(self, "Sand path", (prev + q) * 0.5 + Vector3(0, 0.05, 0), Vector3(2.2, 0.02, prev.distance_to(q) + 1.0), Color("ddd6c4"))
                seg.rotation.y = atan2(q.x - prev.x, q.z - prev.z)
            prev = q
    var round := SphereMesh.new()
    round.radius = 1.0
    round.height = 2.0
    round.radial_segments = 7
    round.rings = 4
    var cone := CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 1.0
    cone.height = 1.0
    cone.radial_segments = 7
    cone.rings = 1
    var stick := CylinderMesh.new()
    stick.top_radius = 0.08
    stick.bottom_radius = 0.12
    stick.height = 1.0
    stick.radial_segments = 5
    stick.rings = 1
    var bush_cols := [Color("9a7ea2"), Color("86708e"), Color("9a9a58")]
    for k in range(3):
        _multimesh("Heather bushes", round, bushes[k], Kit.mat(bush_cols[k]))
    _multimesh("Young pines", cone, pines, Kit.mat(Color("2f5a30")))
    _multimesh("Birch trunks", stick, birch_trunks, Kit.mat(Color("e8e6de")))
    _multimesh("Birch crowns", round, birch_crowns, Kit.mat(Color("8fae4e")))

# Langs de heideweg: een dichte bosrand van struiken en jonge bomen achter de berm; bij de
# open heidevelden blijft het zicht vrij. (De vangrail en het draadhek van jouw foto horen
# bij de Buitenring, niet hier.)
func _heath_road() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 4411
    var shrubs: Array = [[], [], []]
    var off_rail: float = road_hw + CURB_W + BIKE_W + WALK_W + 0.6   # buitenrand van de stoep
    var s := 0.0
    var step := 4.0
    while s < route.length:
        var pa: Vector3 = route.pos_at(s)
        var pb: Vector3 = route.pos_at(minf(s + step, route.length))
        if pa.z > HEATH_Z + 8.0 and pb.z > HEATH_Z + 8.0:
            for side in [-1.0, 1.0]:
                # struiken achter de berm, behalve langs de open heide
                var sp: Vector3 = pa + route.right_at(s) * side * (off_rail + 1.0 + rng.randf_range(0.0, 3.5))
                if not _in_clearing(sp, -6.0) and not _excluded_hard(sp) and route.distance_to(sp) > off_rail:
                    var hh: float = rng.randf_range(2.5, 6.0)
                    var ww: float = rng.randf_range(2.2, 3.8)
                    shrubs[rng.randi_range(0, 2)].append(Transform3D(Basis().scaled(Vector3(ww, hh * 0.5, ww)), sp + Vector3(0, hh * 0.45, 0)))
        s += step
    var round := SphereMesh.new()
    round.radius = 1.0
    round.height = 2.0
    round.radial_segments = 8
    round.rings = 4
    var cols := [Color("3f6a2e"), Color("4f7a34"), Color("5d8a3a")]
    for k in range(3):
        _multimesh("Heath edge", round, shrubs[k], Kit.mat(cols[k]))
