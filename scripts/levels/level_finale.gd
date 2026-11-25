extends "res://scripts/levels/level_base.gd"
# Finale: de Buitenring Parkstad Limburg (N300), 3 ronden. Een gescheiden weg met twee
# rijstroken per richting, vangrail in de middenberm, viaducten en blauwe portaalborden.
# Langs de ring staan bezienswaardigheden uit alle gemeenten: het Parkstad Limburg Stadion
# bij start/finish, Mijnmuseum ON I, Abdij Rolduc, het Pinkpop-terrein, de Gregoriuskerk,
# Kasteel Terborgh, Kasteel Cortenbach en station Simpelveld met de stoomtrein; binnen de
# ring SnowWorld op de Wilhelminaberg. Het tracé is verzonnen; alleen het soort weg klopt.
const LmSnow = preload("res://scripts/landmarks/landmark_snowworld.gd")
const PlsSite = preload("res://scripts/places/pls_site.gd")
const LmOn = preload("res://scripts/landmarks/landmark_on.gd")
const LmRolduc = preload("res://scripts/landmarks/landmark_rolduc.gd")
const LmPinkpop = preload("res://scripts/landmarks/landmark_pinkpop.gd")
const LmGregorius = preload("res://scripts/landmarks/landmark_gregoriuskerk.gd")
const LmTerborgh = preload("res://scripts/landmarks/landmark_terborgh.gd")
const LmCortenbach = preload("res://scripts/landmarks/landmark_cortenbach.gd")
const LmStation = preload("res://scripts/landmarks/landmark_station_simpelveld.gd")
const SteamTrain = preload("res://scripts/landmarks/steam_train.gd")
const Awacs = preload("res://scripts/landmarks/awacs.gd")

const SCALE := 0.8
# viaducten (fractie van de ronde); de eerste twee liggen in een verdiepte bak met
# keermuren, de derde op taluds
const VIADUCTS := [0.26, 0.55, 0.75]
const CUT_HALF := 95.0

func build() -> void:
    level_title = "PARKSTAD FINALE"
    seed_value = 300
    road_hw = 11.5
    dual = true
    laps = 3
    traffic_lanes = [3.8, 8.2]
    traffic_cars = 30
    # rondje met de klok mee; de eerste hoek ligt midden op het startrechte stuk
    var pts := [Vector3(0, 0, 0), Vector3(0, 0, -450), Vector3(350, 0, -650), Vector3(750, 0, -500),
        Vector3(800, 0, 0), Vector3(650, 0, 400), Vector3(200, 0, 450), Vector3(0, 0, 250)]
    var scaled: Array = []
    for p in pts:
        scaled.append(p * SCALE)
    route = Route.new(scaled, [170.0, 170.0, 170.0, 170.0, 170.0, 170.0, 170.0], true)
    var L: float = route.length
    # elk checkpoint komt net ná de bezienswaardigheden van die gemeente (zie _landmarks),
    # zodat de naam in beeld klopt met wat je ziet
    var cps := [["KERKRADE", 0.14], ["HEERLEN", 0.23], ["LANDGRAAF", 0.46], ["BRUNSSUM", 0.53],
        ["SIMPELVELD", 0.63], ["BEEKDAELEN", 0.72], ["VOERENDAAL", 0.84]]
    for c in cps:
        checkpoints.append({"at": route.pos_at(L * float(c[1])), "name": c[0]})
    checkpoints.append({"at": route.pos_at(L - 6.0), "name": "START / FINISH"})

    # langs de ring geen straatbebouwing; wel landschap, stadsranden en de bezienswaardigheden
    exclusions.append(Rect2(-3000, -3000, 6000, 6000))
    _landmarks(L)

    build_road()
    forest(Rect2(-480, 240, 420, 520), 320.0, 1)         # Schinveldse bossen, buiten de ring
    countryside(Rect2(-600, -900, 1450, 1500), 5)
    _heath(Rect2(560, 120, 300, 340))                      # Brunssummerheide, binnen de bocht
    # stadsranden buiten de ring, bij het stuk van die gemeente
    _skyline(_outside(L * 0.10, 260.0), 12)                # Kerkrade
    _skyline(_outside(L * 0.20, 250.0), 12)                # Heerlen
    _skyline(_outside(L * 0.50, 230.0), 10)                # Brunssum
    _buitenring(L)
    for f in VIADUCTS:
        _viaduct(L * f)
    _gantry(120.0, "N300  BUITENRING", "Kerkrade  /  Heerlen")
    _gantry(L * 0.36, "Landgraaf  /  SnowWorld", "Brunssum")
    _gantry(L * 0.66, "Beekdaelen  /  Voerendaal", "Parkstad Limburg Stadion")
    var plane: Node3D = Awacs.new()
    add_child(plane)
    plane.cross_route(route, 170.0, 38.0, 6.0)   # ~150 m voor de start schuin over de weg

func _landmarks(L: float) -> void:
    # stadion bij start/finish, links van het startrechte stuk, hoofdgevel naar de weg
    place_beside(PlsSite.new(), 30.0, -1.0, 135.0, Vector2(110, 110))
    # binnen de ring: SnowWorld met de hal van de weg af, de berg midden in de ring
    place_beside(LmSnow.new(), L * 0.43, 1.0, 62.0, Vector2(60, 60))
    # buiten de ring, rechts in rijrichting is binnen; buiten = links (-1)
    # volgorde langs de ring: Kerkrade (stadion, Rolduc), Heerlen (ON I), Landgraaf
    # (Pinkpop, SnowWorld), Brunssum (Gregoriuskerk), Simpelveld (station en stoomtrein),
    # Beekdaelen (Terborgh), Voerendaal (Cortenbach)
    place_beside(LmRolduc.new(), L * 0.1, -1.0, 88.0, Vector2(70, 70))
    place_beside(LmOn.new(), L * 0.19, -1.0, 60.0, Vector2(55, 40))
    place_beside(LmPinkpop.new(), L * 0.33, -1.0, 100.0, Vector2(90, 90))
    place_beside(LmGregorius.new(), L * 0.5, -1.0, 36.0, Vector2(45, 45))
    place_beside(LmStation.new(), L * 0.6, -1.0, 34.0, Vector2(40, 30))
    place_beside(LmTerborgh.new(), L * 0.69, -1.0, 34.0, Vector2(40, 40))
    place_beside(LmCortenbach.new(), L * 0.8, -1.0, 34.0, Vector2(45, 45))
    _train(L)

# Stoomtrein: een spoorlus buiten de ring bij station Simpelveld. Het voorste rechte stuk
# loopt evenwijdig aan de ring (achter het perron, 49,5 m van de weg), het achterste 70 m
# verder weg. De trein rijdt in de rijrichting mee, stopt 8 s bij het station en rijdt
# meteen weer door, zodat je hem elke ronde ziet (eerst stond hij stil achter het station).
const TRAIN_TOP := 80.0
const TRAIN_BOT := -75.0
const TRAIN_R := 35.0
func _train(L: float) -> void:
    var s0: float = L * 0.625
    var dir: Vector3 = route.dir_at(s0)
    var train: Node3D = SteamTrain.new()
    train.position = route.pos_at(s0) - route.right_at(s0) * 49.5 + Vector3(0, 0.5, 0)
    # lokaal -z = rijrichting, lokaal +x = naar de weg (het achterste spoor ligt op -2r)
    train.rotation.y = atan2(-dir.x, -dir.z)
    add_child(train)
    var station_z: float = (s0 - L * 0.6)        # station ligt zoveel meter terug (lokaal +z)
    # setup/loop gebruiken position.z als lokale startplek en zetten die op 0 (gemaakt voor
    # een spoor langs de z-as); de echte plek daarna terugzetten
    var wp: Vector3 = train.position
    train.setup(TRAIN_TOP, station_z - 30.0, 20.0)
    train.loop(TRAIN_TOP, TRAIN_BOT, TRAIN_R, 8.0, func() -> bool: return true)
    train.position = wp
    _rails(train.transform, TRAIN_TOP, TRAIN_BOT, TRAIN_R)
    # geen bomen of akkers op het spoor
    var lo := Vector2(INF, INF)
    var hi := Vector2(-INF, -INF)
    for c in [Vector3(14, 0, TRAIN_TOP + TRAIN_R + 10), Vector3(14, 0, TRAIN_BOT - TRAIN_R - 10),
            Vector3(-2.0 * TRAIN_R - 14, 0, TRAIN_TOP + TRAIN_R + 10), Vector3(-2.0 * TRAIN_R - 14, 0, TRAIN_BOT - TRAIN_R - 10)]:
        var w: Vector3 = train.transform * c
        lo = Vector2(minf(lo.x, w.x), minf(lo.y, w.z))
        hi = Vector2(maxf(hi.x, w.x), maxf(hi.y, w.z))
    hard_exclusions.append(Rect2(lo, hi - lo))

# Ballastbed, dwarsliggers en rails langs de lus (zoals in het Simpelveld-level).
func _rails(xf: Transform3D, top_z: float, bot_z: float, r: float) -> void:
    var len_: float = 2.0 * (top_z - bot_z) + 2.0 * PI * r
    var n: int = int(ceil(len_ / 3.0))
    var ballast: Array = []
    var rails: Array = []
    var sleepers: Array = []
    var y_top := Vector3(0, 0.3, 0)
    for i in range(n):
        var a: Array = SteamTrain.loop_pose(float(i) * len_ / float(n), top_z, bot_z, r)
        var b: Array = SteamTrain.loop_pose(float(i + 1) * len_ / float(n), top_z, bot_z, r)
        var pa: Vector3 = xf * a[0]
        var pb: Vector3 = xf * b[0]
        pa.y = 0.0
        pb.y = 0.0
        var da: Vector3 = xf.basis * a[1]
        var db: Vector3 = xf.basis * b[1]
        var na := Vector3(-da.z, 0, da.x)
        var nb := Vector3(-db.z, 0, db.x)
        for side in [-1.0, 1.0]:
            Kit._quad(ballast, pa + na * side * 1.7 + y_top, pb + nb * side * 1.7 + y_top, pb + nb * side * 2.7, pa + na * side * 2.7)
        Kit._quad(ballast, pa - na * 1.7 + y_top, pb - nb * 1.7 + y_top, pb + nb * 1.7 + y_top, pa + na * 1.7 + y_top)
        for side in [-0.72, 0.72]:
            var ra: Vector3 = pa + na * side
            var rb: Vector3 = pb + nb * side
            var y0 := Vector3(0, 0.4, 0)
            var y1 := Vector3(0, 0.52, 0)
            var t := na * 0.05
            var tb := nb * 0.05
            Kit._quad(rails, ra - t + y1, rb - tb + y1, rb + tb + y1, ra + t + y1)
            Kit._quad(rails, ra - t + y0, rb - tb + y0, rb - tb + y1, ra - t + y1)
            Kit._quad(rails, ra + t + y0, rb + tb + y0, rb + tb + y1, ra + t + y1)
        sleepers.append(Transform3D(Basis.looking_at(da, Vector3.UP), pa + Vector3(0, 0.36, 0)))
    var bm := MeshInstance3D.new()
    bm.name = "Ballast"
    bm.mesh = Kit._mesh_from(ballast, Kit._two_sided(Color("7d756a")))
    add_child(bm)
    var rm := MeshInstance3D.new()
    rm.name = "Rails"
    rm.mesh = Kit._mesh_from(rails, Kit._two_sided(Color("8a8d90")))
    add_child(rm)
    var sl := BoxMesh.new()
    sl.size = Vector3(2.6, 0.12, 0.25)
    _multimesh("Sleepers", sl, sleepers, Kit.mat(Color("5a4a3c")))

# Punt buiten de ring (links in rijrichting) op afstand s, zoveel meter van de weg.
func _outside(s: float, dist: float) -> Vector3:
    var p: Vector3 = route.pos_at(s) - route.right_at(s) * dist
    return Vector3(p.x, 0, p.z)

# Heide met stuifzand en dennen (zoals in het Brunssum-level, maar dunner).
func _heath(area: Rect2) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 2007
    Kit.box(self, "Heath ground", Vector3(area.get_center().x, 0.0, area.get_center().y), Vector3(area.size.x, 0.01, area.size.y), Color("6c7150"))
    for i in range(30):
        var p := Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
        var sz := Vector3(rng.randf_range(15, 40), 0.06, rng.randf_range(15, 40))
        if route.distance_to(p) < Vector2(sz.x, sz.z).length() * 0.5 + 16.0 or _excluded_hard(p):
            continue
        Kit.box(self, "Heather", p + Vector3(0, 0.02 + float(i % 7) * 0.02, 0), sz,   # eigen hoogte: geen knipperen
            Color("7b5d6b") if i % 2 == 0 else Color("bba77c"))
    for i in range(60):
        var p := Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
        if route.distance_to(p) < 18.0 or _excluded_hard(p):
            continue
        var h: float = rng.randf_range(9.0, 15.0)
        Kit.cyl(self, "Pine trunk", p + Vector3(0, h * 0.5, 0), 0.25, 0.18, h, Color("5b4634"), 6)
        Kit.cyl(self, "Pine crown", p + Vector3(0, h, 0), 2.6, 1.2, 3.2, Color("2e4a2e"), 8)

# Stadsrand aan de horizon: een cluster flats en huizenblokken.
func _skyline(center: Vector3, n: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(center.x * 7.0 + center.z)
    var tints := [Color("d9c3b4"), Color("e8e0cf"), Color("c7cfcc"), Color("e0b8a4"), Color("bdb5ad")]
    for i in range(n):
        var p := center + Vector3(rng.randf_range(-140, 140), 0, rng.randf_range(-90, 90))
        if route.distance_to(p) < 60.0 or _excluded_hard(p):
            continue
        var floors: int = rng.randi_range(4, 12)
        var w: float = rng.randf_range(14.0, 30.0)
        var mat := Kit.tex_mat("res://assets/town_facade.png", tints[rng.randi_range(0, tints.size() - 1)], 14.0)
        Kit.facade_block(self, "Skyline block", p, Vector2(w, rng.randf_range(12.0, 18.0)), floors, mat, false)

# Viaduct dwars over de ring (naar jouw foto): een slank betonnen dek met twee groeven in de
# rand en een licht stalen hekwerk erop, in de middenberm een rij van vier ronde pijlers
# onder een kesp; aan de zijkanten landhoofden (in de bak tegen de keermuren).
func _viaduct(s: float) -> void:
    var f := Node3D.new()
    f.name = "Viaduct"
    f.transform = Transform3D(route.basis_at(s), route.pos_at(s))
    add_child(f)
    var span: float = road_hw * 2.0 + 8.0
    var concrete := Color("bdbab2")
    var deck_y := 7.0
    Kit.box(f, "Deck", Vector3(0, deck_y, 0), Vector3(span + 24.0, 1.1, 11.0), concrete)
    for z in [-5.6, 5.6]:
        Kit.box(f, "Deck fascia", Vector3(0, deck_y + 0.15, z), Vector3(span + 24.0, 1.4, 0.3), Color("cac7c0"))
        for gy in [-0.15, 0.25]:
            Kit.box(f, "Fascia groove", Vector3(0, deck_y + gy, z * 1.03), Vector3(span + 24.0, 0.05, 0.05), Color("9a978f"))
        # hekwerk: staander om de 2 m, leuning en spijlen als vlak
        Kit.box(f, "Railing top", Vector3(0, deck_y + 2.0, z * 0.98), Vector3(span + 24.0, 0.08, 0.08), Color("c8ccd0"))
        Kit.box(f, "Railing mesh", Vector3(0, deck_y + 1.4, z * 0.98), Vector3(span + 24.0, 1.1, 0.03), Color(0.75, 0.78, 0.8, 1.0))
        var n: int = int((span + 24.0) / 2.0)
        for k in range(n + 1):
            Kit.box(f, "Railing post", Vector3(-(span + 24.0) * 0.5 + float(k) * 2.0, deck_y + 1.4, z * 0.98), Vector3(0.07, 1.3, 0.07), Color("a9aeb2"))
    for x in [-span * 0.5, span * 0.5]:
        Kit.box(f, "Abutment", Vector3(x + signf(x) * 5.0, (deck_y - 0.5) * 0.5, 0), Vector3(10.0, deck_y - 0.5, 11.0), concrete, true)
    Kit.box(f, "Pier cap", Vector3(0, deck_y - 0.9, 0), Vector3(1.4, 0.6, 9.0), concrete)
    for z in [-3.6, -1.2, 1.2, 3.6]:
        Kit.cyl(f, "Pier", Vector3(0, (deck_y - 1.2) * 0.5, z), 0.55, 0.55, deck_y - 1.2, concrete, 14, "y", true)
    Kit.box(f, "Pier base", Vector3(0, 0.3, 0), Vector3(1.6, 0.6, 9.4), Color("a9a69e"), true)
    Kit.box(f, "Bridge car", Vector3(-6.0, deck_y + 1.2, 2.0), Vector3(4.2, 1.4, 1.9), Color("2f5d8a"))

# ---------------------------------------------------------------- Buitenring (jouw foto's, 20-11)
func _tex2(path: String, mpt: float, tint := Color.WHITE) -> Material:
    var m: StandardMaterial3D = Kit.tex_mat(path, tint, mpt).duplicate()
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func _in_cut(s: float) -> bool:
    var L: float = route.length
    for f in [VIADUCTS[0], VIADUCTS[1]]:
        if absf(s - L * f) < CUT_HALF + 2.0:
            return true
    return false

func roadside_blocked(s: float) -> bool:
    var L: float = route.length
    return _in_cut(s) or _in_bay(s, [L * 0.12, L * 0.40, L * 0.64, L * 0.9], 62.0)

func _in_bay(s: float, bays: Array, half := 52.0) -> bool:
    for b in bays:
        if s > float(b) - half and s < float(b) + half:
            return true
    return false

# Bord vluchthaven (naar jouw plaatje): blauw vierkant met een witte rand, links een
# onderbroken streep en rechts een doorgetrokken lijn die opzij uitbuigt.
func _bay_sign(c: Vector3, b: Basis) -> void:
    var f := Node3D.new()
    f.name = "Bay sign"
    f.transform = Transform3D(b, c)
    add_child(f)
    var w := Color("f4f4ee")
    Kit.box(f, "Bay sign panel", Vector3.ZERO, Vector3(0.8, 0.8, 0.04), Color("1d56a8"))
    Kit.box(f, "Bay sign border", Vector3(0, 0, 0.022), Vector3(0.72, 0.72, 0.005), w)
    Kit.box(f, "Bay sign field", Vector3(0, 0, 0.026), Vector3(0.66, 0.66, 0.005), Color("1d56a8"))
    for k in range(4):
        Kit.box(f, "Bay sign dash", Vector3(-0.13, 0.26 - float(k) * 0.17, 0.03), Vector3(0.055, 0.1, 0.004), w)
    # rechterlijn: recht, schuin naar buiten, recht, schuin terug, recht
    var pts := [Vector2(0.03, 0.31), Vector2(0.03, 0.2), Vector2(0.19, 0.12), Vector2(0.19, -0.12), Vector2(0.03, -0.2), Vector2(0.03, -0.31)]
    for k in range(pts.size() - 1):
        var a: Vector2 = pts[k]
        var e: Vector2 = pts[k + 1]
        var seg := Kit.box(f, "Bay sign line", Vector3((a.x + e.x) * 0.5, (a.y + e.y) * 0.5, 0.03), Vector3(0.055, a.distance_to(e) + 0.05, 0.004), w)
        seg.rotation.z = atan2(e.x - a.x, a.y - e.y)

# Wegprofiel en wat erlangs staat: geleiderails langs de buitenkant, twee verdiepte bakken met
# keermuren (schanskorven met een betonnen barrier ervoor aan de ene kant, groene
# terrasmuren aan de andere), taluds met bomen, betonnen geluidsschermen met groeven,
# geasfalteerde vluchthavens, grastegels in de berm voor de afwatering, groene
# hectometerpaaltjes, blauwe
# bewegwijzering op palen en hoge lantaarnpalen in de bakken.
func _buitenring(L: float) -> void:
    var steel := Kit.two_sided_mat(Color("8e959a"))
    var concrete := Kit.two_sided_mat(Color("aaa79f"))
    var gabion := _tex2("res://assets/gabion.png", 4.0, Color(0.82, 0.78, 0.72))
    var noise := _tex2("res://assets/noise_wall.png", 6.0)
    var grid := _tex2("res://assets/grass_grid.png", 2.0)
    var green := Kit.two_sided_mat(Color("5b7d3a"))
    var green2 := Kit.two_sided_mat(Color("4a6a30"))
    var bank := Kit.two_sided_mat(Color("7a8a4e"))
    var edge: float = road_hw + 1.4             # buitenrand van de asfaltberm
    var bays := [L * 0.12, L * 0.40, L * 0.64, L * 0.9]
    # geleiderails langs de buitenkant (niet in de bakken, daar staat de betonnen barrier);
    # bij een vluchthaven buigt de rail naar buiten
    for side in [-1.0, 1.0]:
        var s := 0.0
        while s < L:
            var e: float = minf(s + 4.0, L)
            var mid: float = (s + e) * 0.5
            var o: float = side * (edge + 0.3)
            var skip: bool = _in_cut(s) or _in_cut(e)
            if side > 0.0:
                for b in bays:
                    var d: float = absf(mid - float(b))
                    if d < 48.0:
                        o = edge + 3.6
                    elif d < 54.0:
                        skip = true
            if not skip:
                route_band("Outer rail", s, e, o, 0.45, o, 0.8, steel, true, 0.0, 4.0)
                if int(s / 4.0) % 2 == 0:
                    route_posts("Outer rail posts", s, s + 0.1, [o + side * 0.15], 4.0, Vector3(0.1, 0.75, 0.1), Color("8f979c"))
            s = e
    # vluchthavens met grastegels (rechts in rijrichting); schuine stukken vangrail sluiten
    # de haven aan op de gewone vangrail
    for b in bays:
        for e in [[float(b) - 54.0, float(b) - 48.0], [float(b) + 54.0, float(b) + 48.0]]:
            var pa: Vector3 = route.pos_at(e[0]) + route.right_at(e[0]) * (edge + 0.3)
            var pb: Vector3 = route.pos_at(e[1]) + route.right_at(e[1]) * (edge + 3.6)
            var link := Kit.box(self, "Bay rail", (pa + pb) * 0.5 + Vector3(0, 0.62, 0), Vector3(0.3, 0.35, pa.distance_to(pb) + 0.4), Color("8e959a"), true)
            link.basis = Basis.looking_at((pb - pa).normalized(), Vector3.UP)
        route_band("Emergency bay", float(b) - 50.0, float(b) + 50.0, edge, 0.03, edge + 3.4, 0.03, Kit.two_sided_mat(ROAD_GRAY), false, 0.0, 2.0)
        route_band("Emergency bay line", float(b) - 50.0, float(b) + 50.0, edge - 0.05, 0.04, edge + 0.15, 0.04, Kit.two_sided_mat(Color("dedbd0")))
        var sign_p: Vector3 = route.pos_at(float(b) - 56.0) + route.right_at(float(b) - 56.0) * (edge + 1.0)
        Kit.cyl(self, "Bay sign post", sign_p + route.dir_at(float(b) - 56.0) * 0.08 + Vector3(0, 1.35, 0), 0.05, 0.05, 2.7, Color("c8ccd0"), 6)
        _bay_sign(sign_p + Vector3(0, 2.4, 0), route.basis_at(float(b) - 56.0))
    # grastegels in de berm voor de afwatering, op een paar plekken (vooral in bochten)
    for g in [[L * 0.07, 70.0, 1.0], [L * 0.33, 80.0, 1.0], [L * 0.48, 60.0, -1.0], [L * 0.79, 90.0, 1.0], [L * 0.95, 60.0, -1.0]]:
        var o0: float = g[2] * (road_hw + 0.25)
        var o1: float = g[2] * (edge - 0.05)
        route_band("Drain tiles", float(g[0]), float(g[0]) + float(g[1]), o0, 0.036, o1, 0.036, grid, false, 0.0, 2.0)
    # verdiepte bakken rond de eerste twee viaducten
    for k in range(2):
        var c: float = L * float(VIADUCTS[k])
        var s0: float = c - CUT_HALF
        var s1: float = c + CUT_HALF
        for side in [-1.0, 1.0]:
            # betonnen barrier langs de berm
            route_band("Concrete barrier", s0, s1, side * (edge + 0.2), 0.0, side * (edge + 0.2), 0.9, concrete, true, 0.0, 3.0)
            route_band("Barrier top", s0, s1, side * (edge + 0.2), 0.9, side * (edge + 0.5), 0.9, concrete)
            var gab: bool = (side > 0.0) == (k == 0)
            if gab:
                # schanskorvenmuur van 6 m met een betonnen geluidsscherm erop
                route_band("Gabion wall", s0, s1, side * (edge + 0.6), 0.0, side * (edge + 0.6), 6.5, gabion, false, 25.0)
                route_band("Gabion top", s0, s1, side * (edge + 0.6), 6.5, side * (edge + 3.0), 6.5, bank, false, 25.0)
                route_band("Noise wall", s0 + 26.0, s1 - 26.0, side * (edge + 2.2), 6.5, side * (edge + 2.2), 9.3, noise)
            else:
                # groene terrasmuur: treden van 1,1 m met klimop
                for t in range(6):
                    var o0: float = side * (edge + 0.6 + float(t) * 0.7)
                    var o1: float = side * (edge + 0.6 + float(t + 1) * 0.7)
                    route_band("Terrace step", s0, s1, o0, float(t) * 1.1, o0, float(t + 1) * 1.1, green if t % 2 == 0 else green2, false, 25.0)
                    route_band("Terrace tread", s0, s1, o0, float(t + 1) * 1.1, o1, float(t + 1) * 1.1, green2, false, 25.0)
                route_band("Terrace top", s0, s1, side * (edge + 4.8), 6.6, side * (edge + 12.0), 6.6, bank, false, 25.0)
                route_band("Noise wall", s0 + 26.0, s1 - 26.0, side * (edge + 5.5), 6.6, side * (edge + 5.5), 9.0, noise)
            # hoge lantaarnpalen in de bak
            var s := s0 + 20.0
            while s < s1 - 10.0:
                lamppost(route.pos_at(s) + route.right_at(s) * side * (edge + 0.35), -route.right_at(s) * side)
                s += 45.0
    # taluds langs de derde viaduct en een paar stukken met bomen erop (zoals je foto)
    var c3: float = L * float(VIADUCTS[2])
    for side in [-1.0, 1.0]:
        route_band("Embankment", c3 - 80.0, c3 + 80.0, side * (edge + 1.5), 0.0, side * (edge + 12.0), 6.2, bank, false, 30.0)
        route_band("Embankment top", c3 - 80.0, c3 + 80.0, side * (edge + 12.0), 6.2, side * (edge + 18.0), 6.2, bank, false, 30.0)
    # (niet over de vluchthaven bij 0,64 ronde of de bak bij 0,55; altijd achter de vangrail)
    for r in [[L * 0.592, L * 0.62, 1.0], [L * 0.04, L * 0.09, 1.0]]:
        route_band("Grass bank", r[0], r[1], r[2] * (edge + 4.5), 0.0, r[2] * (edge + 13.0), 4.0, bank, false, 20.0)
        route_band("Grass bank top", r[0], r[1], r[2] * (edge + 13.0), 4.0, r[2] * (edge + 21.0), 4.0, bank, false, 20.0)
        var rng := RandomNumberGenerator.new()
        rng.seed = int(r[0])
        var s := float(r[0]) + 24.0
        while s < float(r[1]) - 24.0:
            var p: Vector3 = route.pos_at(s) + route.right_at(s) * r[2] * (edge + 15.0 + rng.randf_range(0.0, 4.0))
            var h: float = rng.randf_range(9.0, 14.0)
            Kit.cyl(self, "Bank tree", p + Vector3(0, 4.0 + h * 0.35, 0), 0.25, 0.18, h * 0.7, Color("5b5148"), 6)
            var cr := MeshInstance3D.new()
            var sm := SphereMesh.new()
            sm.radius = h * 0.28
            sm.height = h * 0.5
            sm.radial_segments = 8
            sm.rings = 4
            cr.mesh = sm
            cr.material_override = Kit.mat(Color("6a7a48"))
            cr.position = p + Vector3(0, 4.0 + h * 0.75, 0)
            add_child(cr)
            s += rng.randf_range(7.0, 12.0)
    # betonnen geluidsscherm met groeven langs een stuk buitenkant
    # (achter de vangrail van de vluchthaven bij 0,9 ronde: die ligt tot edge + 3,6)
    route_band("Noise wall", L * 0.84, L * 0.92, edge + 5.0, 0.0, edge + 5.0, 3.8, noise)
    # groene hectometerpaaltjes in de middenberm, om de 100 m
    var s := 50.0
    while s < L:
        for side in [-1.0, 1.0]:
            var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * 1.0
            Kit.box(self, "Hectometer post", p + Vector3(0, 0.55, 0), Vector3(0.06, 1.1, 0.06), Color("c8ccd0"))
            var hb := Kit.box(self, "Hectometer sign", p + Vector3(0, 1.15, 0), Vector3(0.36, 0.24, 0.03), Color("2f7a3c"))
            hb.basis = route.basis_at(s)
            var lab := Kit.label(self, ("%.1f" % (40.0 + s / 1000.0 * 4.0)).replace(".", ","), p + Vector3(0, 1.15, 0) - route.dir_at(s) * side * 0.02, 0.0028, Color.WHITE, 40)
            lab.basis = route.basis_at(s) * (Basis() if side > 0.0 else Basis(Vector3.UP, PI))
        s += 100.0
    # blauwe bewegwijzering op twee palen naast de weg
    for e in [[L * 0.30, "Amstenrade\nHeerlen - Hoensbroek\nBrunssum - Treebeek"], [L * 0.60, "Landgraaf\nKerkrade\nSimpelveld"]]:
        var sp: float = float(e[0])
        var base: Vector3 = route.pos_at(sp) + route.right_at(sp) * (edge + 1.6)
        for o in [-1.0, 1.0]:
            Kit.cyl(self, "Sign post", base + route.dir_at(sp) * 0.14 + route.right_at(sp) * o * 0.9 + Vector3(0, 2.9, 0), 0.08, 0.08, 5.8, Color("e8ecef"), 8)
        var sb := Kit.box(self, "Direction sign", base + Vector3(0, 4.6, 0), Vector3(2.8, 2.4, 0.08), Color("1d4f9c"))
        sb.basis = route.basis_at(sp)
        var fr := Kit.box(self, "Direction sign border", base + Vector3(0, 4.6, 0) + route.dir_at(sp) * 0.03, Vector3(2.9, 2.5, 0.04), Color("f2f2ee"))
        fr.basis = route.basis_at(sp)
        var lab := Kit.label(self, String(e[1]), base + Vector3(0, 4.7, 0) - route.dir_at(sp) * 0.06, 0.0032, Color.WHITE, 64)
        lab.basis = route.basis_at(sp)

# Blauw portaalbord over de rijbaan in rijrichting, met twee regels.
func _gantry(s: float, top: String, bottom: String) -> void:
    var f := Node3D.new()
    f.name = "Gantry"
    f.transform = Transform3D(route.basis_at(s), route.pos_at(s))
    add_child(f)
    var steel := Color("8c949a")
    for x in [1.6, road_hw + 1.4]:
        Kit.box(f, "Gantry post", Vector3(x, 3.8, 0), Vector3(0.5, 7.6, 0.5), steel, true)
    var w: float = road_hw - 0.2
    var cx: float = (1.6 + road_hw + 1.4) * 0.5
    Kit.box(f, "Gantry beam", Vector3(cx, 7.4, 0), Vector3(road_hw + 0.4, 0.5, 0.5), steel)
    Kit.box(f, "Sign", Vector3(cx, 8.9, 0.3), Vector3(w, 2.6, 0.12), Color("1d4f9c"))
    Kit.box(f, "Sign border", Vector3(cx, 8.9, 0.24), Vector3(w + 0.2, 2.8, 0.06), Color("f4f4ee"))
    var face := Kit.face(f, Vector3(cx, 0, 0.38), 0)
    Kit.label(face, top, Vector3(0, 9.6, 0), _fit(top, w - 0.6, 0.012), Color.WHITE, 90)
    Kit.label(face, bottom, Vector3(0, 8.4, 0), _fit(bottom, w - 0.6, 0.011), Color.WHITE, 90)
