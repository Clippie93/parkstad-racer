extends "res://scripts/levels/level_base.gd"
# Level 5: Simpelveld. Over het heuvelland naast de Miljoenenlijn, in een race tegen de
# stoomtrein van de ZLSM. Door het dorp langs Huize Loreto, finish bij station Simpelveld,
# waar de trein ook naartoe rijdt. Het stratenplan is verzonnen en compact.
const LmStation = preload("res://scripts/landmarks/landmark_station_simpelveld.gd")
const LmLoreto = preload("res://scripts/landmarks/landmark_loreto.gd")
const SteamTrain = preload("res://scripts/landmarks/steam_train.gd")
const TeapotHouse = preload("res://scripts/landmarks/teapot_house.gd")
const LmBongard = preload("res://scripts/landmarks/landmark_bongard.gd")
const LmRemigius = preload("res://scripts/landmarks/landmark_remigiuskerk.gd")
const LmFarm = preload("res://scripts/landmarks/landmark_carreboerderij.gd")

const TRACK_X := -38.0          # het spoor loopt recht langs Z
const TRACK_Z0 := 820.0
const TRACK_Z1 := -460.0
const LOOP_R := 60.0            # bochten van de spoorlus; het westspoor ligt op TRACK_X - 2 * LOOP_R
const STATION_Z := -330.0
const VILLAGE_Z := 330.0        # ten noorden hiervan: velden en heuvels
const LORETO_POS := Vector3(140, 0, 60)
const TEAPOT_POS := Vector3(19.0, 0, -262.0)   # Stationsstraat, rechts vlak voor het station
# terugweg (x = 260, naar het noorden): eerst de Sint-Remigiuskerk links in het dorp, dan
# buiten het dorp Kasteel De Bongard rechts in de wei
const REMIGIUS_Z := -300.0
const BONGARD_Z := 300.0
# monumentale carréboerderij (van jouw oudtante), vlak voor de bebouwde kom en vlak voor
# start/finish: op het laatste stuk (z = 760, naar het westen), links van de weg
const FARM_ROAD := Vector3(95, 0, 760)

func build() -> void:
    level_title = "SIMPELVELD"
    seed_value = 6369
    # rondje: na het station naar het oosten en over de velden terug (zonder het spoor te kruisen)
    route = Route.new([
        Vector3(0, 0, 640),
        Vector3(0, 0, 320),
        Vector3(110, 0, 200),
        Vector3(110, 0, -60),
        Vector3(0, 0, -180),
        Vector3(0, 0, -470),
        Vector3(260, 0, -470),
        Vector3(260, 0, 760),
        Vector3(0, 0, 760),
    ], [60.0, 60.0, 60.0, 60.0, 60.0, 80.0, 80.0, 60.0], true)
    checkpoints = [
        {"at": Vector3(0, 0, 480), "name": "MILJOENENLIJN"},
        {"at": Vector3(110, 0, 40), "name": "HUIZE LORETO"},
        {"at": Vector3(0, 0, STATION_Z), "name": "STATION SIMPELVELD"},
        {"at": Vector3(260, 0, REMIGIUS_Z), "name": "SINT-REMIGIUSKERK"},
        {"at": Vector3(260, 0, BONGARD_Z), "name": "KASTEEL DE BONGARD"},
        {"at": FARM_ROAD, "name": "CARREBOERDERIJ"},
    ]
    traffic_cars = 10

    exclusions.append(Rect2(-400, VILLAGE_Z, 800, 600))                       # velden
    for r in _rail_rects():
        exclusions.append(r)                                                    # spoorlus
    _railway()
    place(LmStation.new(), Vector3(TRACK_X + 15.5, 0, STATION_Z), 90.0)
    exclusions.append(Rect2(TRACK_X - 10, STATION_Z - 70, 40, 140))
    place(TeapotHouse.new(), TEAPOT_POS, -90.0)
    exclusions.append(Rect2(TEAPOT_POS.x - 7, TEAPOT_POS.z - 16, 20, 28))
    place(LmLoreto.new(), LORETO_POS, -90.0)
    exclusions.append(Rect2(LORETO_POS.x - 30, LORETO_POS.z - 42, 82, 84))
    # Sint-Remigiuskerk: toren naar de weg, de kerk loopt van de weg af
    var kerk: Node3D = place_beside(LmRemigius.new(), route.closest_s(Vector3(260, 0, REMIGIUS_Z)), -1.0, 15.0, Vector2(1, 1))
    exclude_local(kerk, Rect2(-16, -52, 32, 57))
    var bongard: Node3D = place_beside(LmBongard.new(), route.closest_s(Vector3(260, 0, BONGARD_Z)), 1.0, 33.0, Vector2(1, 1))
    exclude_local(bongard, Rect2(-28, -24, 56, 45))
    var farm: Node3D = place_beside(LmFarm.new(), route.closest_s(FARM_ROAD), 1.0, 17.0, Vector2(1, 1))
    exclude_local(farm, Rect2(-24, -30, 48, 38))
    var train: Node3D = SteamTrain.new()
    train.position = Vector3(TRACK_X, 0.5, 0)
    add_child(train)
    # de trein vertrekt een stuk voor je: je haalt hem in langs de velden, hij komt ongeveer
    # tegelijk met een snelle rit bij het station aan
    train.setup(600.0, STATION_Z - 6.0, 20.0)
    # daarna rijdt hij rondjes over de spoorlus: na 12 s op het station door de zuidbocht
    # naar het westspoor, daar wacht hij aan het noordeinde tot jij aan de oostkant naar
    # het noorden rijdt (ver weg) en komt dan weer het oostspoor op, zodat je hem elke
    # ronde opnieuw inhaalt
    train.loop(TRACK_Z0, TRACK_Z1, LOOP_R, 12.0, func() -> bool:
        var car = get_tree().current_scene.get("car") if get_tree().current_scene != null else null
        return car != null and car.global_position.x > 200.0 and car.global_position.z > 150.0)

    finish_line(3)
    build_road()
    # dorp in het heuvelland: vrijstaand, hoeves en twee-onder-een-kap
    street_mix = {"detached": 3, "farm": 2, "semi": 2, "row": 1}
    build_streetscape()
    _fields()
    town_board(route.closest_s(Vector3(0, 0, VILLAGE_Z + 10)), 1.0, Color("2a5cc0"), [["name", ["Simpelveld", "Zumpelveld", "gem. Simpelveld"]], ["hills", "Simpelveld"]])   # blauw frame, naar jouw foto
    street_sign("MILJOENENLIJN  /  ZLSM", Vector3(-11, 4.0, 640))
    street_sign("STATION", Vector3(11, 4.0, -150))

func _in_hard(p: Vector3, margin: float) -> bool:
    for r in hard_exclusions:
        if r.grow(margin).has_point(Vector2(p.x, p.z)):
            return true
    return false

# Rechthoeken rond de spoorlus (oostspoor, westspoor en de twee bochten).
func _rail_rects() -> Array:
    var w: float = 2.0 * LOOP_R
    return [
        Rect2(TRACK_X - 14, TRACK_Z1, 28, TRACK_Z0 - TRACK_Z1),
        Rect2(TRACK_X - w - 14, TRACK_Z1, 28, TRACK_Z0 - TRACK_Z1),
        Rect2(TRACK_X - w - 14, TRACK_Z1 - LOOP_R - 14, w + 28, LOOP_R + 14),
        Rect2(TRACK_X - w - 14, TRACK_Z0, w + 28, LOOP_R + 14),
    ]

func _near_rail(p: Vector3, margin: float) -> bool:
    for r in _rail_rects():
        if r.grow(margin - 14.0).has_point(Vector2(p.x, p.z)):
            return true
    return false

# Miljoenenlijn als gesloten lus: ballastbed met schuine kanten (de auto rijdt eroverheen),
# dwarsliggers (multimesh) en twee rails, ook door de bochten.
func _railway() -> void:
    const Train = preload("res://scripts/landmarks/steam_train.gd")
    var L: float = 2.0 * (TRACK_Z0 - TRACK_Z1) + 2.0 * PI * LOOP_R
    var step := 3.0
    var n: int = int(ceil(L / step))
    var ballast: Array = []
    var rails: Array = []
    var top := 0.3
    for i in range(n):
        var s0: float = float(i) * L / float(n)
        var s1: float = float(i + 1) * L / float(n)
        var a: Array = Train.loop_pose(s0, TRACK_Z0, TRACK_Z1, LOOP_R)
        var b: Array = Train.loop_pose(s1, TRACK_Z0, TRACK_Z1, LOOP_R)
        var o := Vector3(TRACK_X, 0, 0)
        var pa: Vector3 = a[0] + o
        var pb: Vector3 = b[0] + o
        var na := Vector3(-a[1].z, 0, a[1].x)
        var nb := Vector3(-b[1].z, 0, b[1].x)
        # trapezium: boven 3,4 m breed, onder 5,4 m
        for side in [-1.0, 1.0]:
            Kit._quad(ballast, pa + na * side * 1.7 + Vector3(0, top, 0), pb + nb * side * 1.7 + Vector3(0, top, 0),
                pb + nb * side * 2.7, pa + na * side * 2.7)
        Kit._quad(ballast, pa - na * 1.7 + Vector3(0, top, 0), pb - nb * 1.7 + Vector3(0, top, 0),
            pb + nb * 1.7 + Vector3(0, top, 0), pa + na * 1.7 + Vector3(0, top, 0))
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
    var bm := MeshInstance3D.new()
    bm.name = "Ballast"
    bm.mesh = Kit._mesh_from(ballast, Kit._two_sided(Color("7d756a")))
    add_child(bm)
    var rm := MeshInstance3D.new()
    rm.name = "Rails"
    rm.mesh = Kit._mesh_from(rails, Kit._two_sided(Color("8a8d90")))
    add_child(rm)
    # botsvorm: één glad talud tot net boven de rails, zodat de wielen over het spoor rollen
    var col: Array = []
    for i in range(n):
        var s0: float = float(i) * L / float(n)
        var s1: float = float(i + 1) * L / float(n)
        var a: Array = Train.loop_pose(s0, TRACK_Z0, TRACK_Z1, LOOP_R)
        var b: Array = Train.loop_pose(s1, TRACK_Z0, TRACK_Z1, LOOP_R)
        var o := Vector3(TRACK_X, 0, 0)
        var pa: Vector3 = a[0] + o
        var pb: Vector3 = b[0] + o
        var na := Vector3(-a[1].z, 0, a[1].x)
        var nb := Vector3(-b[1].z, 0, b[1].x)
        var y := Vector3(0, 0.52, 0)
        for side in [-1.0, 1.0]:
            Kit._quad(col, pa + na * side * 1.5 + y, pb + nb * side * 1.5 + y, pb + nb * side * 3.2, pa + na * side * 3.2)
        Kit._quad(col, pa - na * 1.5 + y, pb - nb * 1.5 + y, pb + nb * 1.5 + y, pa + na * 1.5 + y)
    var shape := ConcavePolygonShape3D.new()
    shape.backface_collision = true
    var faces := PackedVector3Array()
    for v in col:
        faces.append(v)
    shape.set_faces(faces)
    var body := StaticBody3D.new()
    body.name = "Track bed"
    var cs := CollisionShape3D.new()
    cs.shape = shape
    body.add_child(cs)
    add_child(body)
    # dwarsliggers
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    var sleeper := BoxMesh.new()
    sleeper.size = Vector3(2.6, 0.1, 0.26)
    mm.mesh = sleeper
    var count: int = int(L / 0.9)
    mm.instance_count = count
    for i in range(count):
        var pr: Array = Train.loop_pose(float(i) * L / float(count), TRACK_Z0, TRACK_Z1, LOOP_R)
        var bs := Basis.looking_at(pr[1], Vector3.UP)
        mm.set_instance_transform(i, Transform3D(bs, pr[0] + Vector3(TRACK_X, 0.35, 0)))
    var mmi := MultiMeshInstance3D.new()
    mmi.name = "Sleepers"
    mmi.multimesh = mm
    mmi.material_override = Kit.mat(Color("4a3d33"))
    add_child(mmi)
    # seinpalen
    for z in [600.0, 200.0, -200.0]:
        Kit.box(self, "Signal post", Vector3(TRACK_X + 3.0, 3.0, z), Vector3(0.2, 6.0, 0.2), Color("e8e8e0"))
        Kit.box(self, "Signal arm", Vector3(TRACK_X + 3.0, 5.6, z), Vector3(1.6, 0.25, 0.08), Color("c9302c"))

# Heuvelland: akkers en weilanden, heggen, losse bomen en glooiingen aan de horizon.
func _fields() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1934
    var crops := [Color("6f8f4a"), Color("8aa257"), Color("b9a660"), Color("7d9a52"), Color("9c8a5c")]
    for i in range(40):
        var p := Vector3(rng.randf_range(-380, 380), 0, rng.randf_range(VILLAGE_Z + 10, 900))
        var sz := Vector3(rng.randf_range(40, 90), 0.04, rng.randf_range(40, 90))
        # de hele akker (met heg) moet naast de weg en het spoor liggen
        var half: float = Vector2(sz.x, sz.z).length() * 0.5
        if route.distance_to(p) < half + 12.0 or _near_rail(p, half + 6.0) or _in_hard(p, half):
            continue
        Kit.box(self, "Field", p + Vector3(0, 0.01 + float(i % 7) * 0.02, 0), sz,   # eigen hoogte: geen knipperen
            crops[rng.randi_range(0, crops.size() - 1)])
        # heg langs de akker
        Kit.box(self, "Hedge", p + Vector3(0, 0.7, sz.z * 0.5), Vector3(sz.x, 1.4, 1.2), Color("3f5a32"))
    for i in range(60):
        var p := Vector3(rng.randf_range(-380, 380), 0, rng.randf_range(VILLAGE_Z + 10, 900))
        if route.distance_to(p) < 14.0 or _near_rail(p, 8.0) or _in_hard(p, 6.0):
            continue
        var h: float = rng.randf_range(6.0, 10.0)
        Kit.cyl(self, "Tree trunk", p + Vector3(0, h * 0.35, 0), 0.25, 0.2, h * 0.7, Color("5b4634"), 6, "y", true)
        var crown := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = h * 0.35
        sm.height = h * 0.6
        sm.radial_segments = 8
        sm.rings = 4
        crown.mesh = sm
        crown.material_override = Kit.mat(Color("4f6e3a"))
        crown.position = p + Vector3(0, h * 0.8, 0)
        add_child(crown)
    # glooiende heuvels aan de horizon
    for i in range(8):
        var p := Vector3(rng.randf_range(-500, 500), 0, rng.randf_range(950, 1200))
        var r: float = rng.randf_range(120, 220)
        if _near_rail(p, r + 10.0):
            continue
        Kit.cyl(self, "Hill", p + Vector3(0, 12.0, 0), r, r * 0.55, 24.0, Color("5f7d47"), 20)
