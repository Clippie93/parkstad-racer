extends "res://scripts/cyclist.gd"
# Scooter of motor op de weg: rijdt mee in het verkeer (eigen strook, mee of tegemoet),
# stopt voor rood en houdt afstand tot wie ervoor rijdt, net als een verkeersauto. Staat
# ook in TrafficCar.all, zodat verkeersauto's er afstand van houden, en in race.traffic,
# zodat de tegenstanders eromheen sturen. Aanrijden werkt als bij een fietser: hij valt om
# en blijft even liggen (het verkeer erachter wacht), en dat kost je tijd.
const TrafficCar = preload("res://scripts/traffic_car.gd")
const Intersection = preload("res://scripts/intersection.gd")

var s_max := 0.0
var top := 10.0         # kruissnelheid; `speed` is de snelheid van dit moment
var oncoming := false
var lane := 3.4

func setup_road(r, start_s: float, end_s: float, v: float, against: bool, on_lane: float, variant: String, paint: Color, seed_n: int) -> void:
    route = r
    s = start_s
    s_max = end_s
    top = v
    speed = v
    oncoming = against
    side = -1.0 if against else 1.0
    lane = on_lane
    kind = variant
    _build_moto(paint, seed_n)
    if not TrafficCar.all.has(self):
        TrafficCar.all.append(self)
    _apply()

func _enter_tree() -> void:
    if route != null and not TrafficCar.all.has(self):
        TrafficCar.all.append(self)

func _exit_tree() -> void:
    TrafficCar.all.erase(self)

func _report_hit() -> void:
    var race := get_tree().current_scene
    if race != null and race.has_method("rider_hit"):
        race.rider_hit(kind)

func _process(delta: float) -> void:
    if route == null:
        return
    if down_time > 0.0:
        down_time -= delta
        speed = 0.0
        fall = move_toward(fall, 1.45 if down_time > 0.8 else 0.0, delta * 4.0)
        _apply()
        return
    fall = move_toward(fall, 0.0, delta * 4.0)
    var target: float = minf(top, _room_ahead() * 0.8)
    speed = move_toward(speed, maxf(target, 0.0), (9.0 if target < speed else 4.0) * delta)
    if oncoming:
        s -= speed * delta
        if route.closed:
            s = fposmod(s, route.length)
        elif s < 5.0:
            s = s_max
    else:
        s += speed * delta
        if route.closed:
            s = fposmod(s, route.length)
        elif s > s_max:
            s = 5.0
    roll = fposmod(roll - speed * delta / wheel_r, TAU)
    for w in wheels:
        (w as Node3D).rotation.x = roll
    _apply()

# vrije weg voor hem: tot een stopstreep bij rood, of tot een voorligger in zijn strook
func _room_ahead() -> float:
    var room := 1000.0
    for x in Intersection.all:
        if x.route != route or not x.main_must_stop():
            continue
        var gap: float = _ahead(x.stop_s(oncoming)) - 1.6
        if gap > -1.0 and gap < 40.0:
            room = minf(room, maxf(gap, 0.0))
    for o in TrafficCar.all:
        if o == self or o.oncoming != oncoming or absf(o.lane - lane) > 1.2:
            continue
        var gap: float = _ahead(o.s) - 6.0
        if gap > -2.0 and gap < 40.0:
            room = minf(room, maxf(gap, 0.0))
    return room

func _ahead(s2: float) -> float:
    var d: float = (s2 - s) if not oncoming else (s - s2)
    if route.closed:
        d = fposmod(d + route.length * 0.5, route.length) - route.length * 0.5
    return d

func _apply() -> void:
    var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * lane
    var b: Basis = route.basis_at(s)
    if oncoming:
        b = b.rotated(Vector3.UP, PI)
    transform = Transform3D(b * Basis(Vector3(0, 0, 1), -fall), p + Vector3(0, 0.04, 0))

# ---------------------------------------------------------------- uiterlijk
func _build_moto(paint: Color, seed_n: int) -> void:
    name = "Rider"
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_n * 6151 + 7
    var skin: Color = SKINS[rng.randi_range(0, SKINS.size() - 1)]
    var pants: Color = PANTS[rng.randi_range(0, PANTS.size() - 1)]
    var dark := Color("1c1d20")
    var metal := Color("8d9196")
    var jacket: Color = [Color("1d1e21"), Color("3a2a22"), Color("2b3440"), Color("5a1f1f"), Color("e9e7e2"), Color("4a4f57")][rng.randi_range(0, 5)]
    var helmet: Color = [Color("e9e7e2"), Color("1d1e21"), Color("b8242a"), paint, Color("8c9196")][rng.randi_range(0, 4)]
    _st = SurfaceTool.new()
    _st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var hip: Vector3
    var shoulder: Vector3
    var head_c: Vector3
    var knee_z: float
    var foot: Vector3
    var grip_l: Vector3
    var grip_r: Vector3
    var hit := Vector3(0.8, 1.6, 1.9)
    if kind == "scooter":
        # bromscooter: kleine wielen, ronde achterkap met zadel, plat voetplateau,
        # hoog voorscherm met het stuur erboven
        var R := 0.23
        _wheel(0.52, R, 0.075, metal)
        _wheel(-0.6, R, 0.075, metal)
        _ball(Vector3(0, 0.5, 0.36), 0.3, paint, Vector3(0.62, 0.85, 1.45))          # achterkap
        _box(Vector3(0.1, 0.27, 0.42), Vector3(0.12, 0.22, 0.4), Color("3a3d42"))      # motor aan de zijkant
        _box(Vector3(0, 0.76, 0.32), Vector3(0.3, 0.09, 0.62), dark)                   # zadel
        _box(Vector3(0, 0.3, -0.12), Vector3(0.34, 0.06, 0.6), paint.darkened(0.25))   # voetplateau
        _box(Vector3(0, 0.6, -0.46), Vector3(0.42, 0.62, 0.1), paint, Basis(Vector3(1, 0, 0), -0.22))   # voorscherm
        _ball(Vector3(0, R * 2.0 + 0.02, -0.6), 0.2, paint, Vector3(0.7, 0.35, 1.1))   # voorspatbord
        _tube(Vector3(0, R, -0.6), Vector3(0, 0.95, -0.44), 0.05, dark)                # balhoofd
        _box(Vector3(0, 1.0, -0.42), Vector3(0.36, 0.1, 0.14), paint)                 # stuurkap
        _box(Vector3(0, 0.98, -0.5), Vector3(0.14, 0.08, 0.03), Color("f4f1d8"))       # koplamp
        _box(Vector3(0, 0.62, 0.84), Vector3(0.14, 0.05, 0.03), Color("c8241e"))       # achterlicht
        _box(Vector3(0, 0.34, 0.84), Vector3(0.18, 0.12, 0.02), Color("e8c21c"))       # gele kentekenplaat
        grip_l = Vector3(-0.3, 1.02, -0.38)
        grip_r = Vector3(0.3, 1.02, -0.38)
        if rng.randf() < 0.3:
            # bezorger: grote box achterop
            var boxc: Color = [Color("e05a1e"), Color("1d1e21"), Color("2c8a4a"), Color("e8e6e0")][rng.randi_range(0, 3)]
            _box(Vector3(0, 1.0, 0.62), Vector3(0.42, 0.42, 0.42), boxc)
            jacket = boxc
        hip = Vector3(0, 0.86, 0.26)
        shoulder = Vector3(0, 1.38, 0.18)
        head_c = Vector3(0, 1.56, 0.12)
        knee_z = -0.18
        foot = Vector3(0, 0.36, -0.2)
    else:
        # motor: tank, motorblok met uitlaat, sportief zadel met opgetild achterdeel,
        # schuine voorvork, voetsteunen; rijder licht voorovergebogen
        var R := 0.32
        _wheel(0.72, R, 0.08, dark)
        _wheel(-0.74, R, 0.07, dark)
        _box(Vector3(0, 0.5, -0.02), Vector3(0.3, 0.32, 0.5), Color("3a3d42"))         # motorblok
        _box(Vector3(0, 0.5, -0.02), Vector3(0.34, 0.08, 0.3), metal)                  # koelribben
        _tube(Vector3(0.14, 0.38, 0.1), Vector3(0.17, 0.5, 0.85), 0.09, metal)         # uitlaat
        _tube(Vector3(0, 0.55, 0.2), Vector3(0, R, 0.72), 0.06, dark)                  # achterbrug
        _ball(Vector3(0, 0.9, -0.2), 0.22, paint, Vector3(0.95, 0.7, 1.35))            # tank
        _box(Vector3(0, 0.88, 0.25), Vector3(0.26, 0.09, 0.4), dark)                   # zadel
        _box(Vector3(0, 0.92, 0.6), Vector3(0.2, 0.1, 0.36), paint, Basis(Vector3(1, 0, 0), 0.25))   # kont
        _box(Vector3(0, 0.92, 0.8), Vector3(0.12, 0.05, 0.03), Color("c8241e"))
        _box(Vector3(0, 0.7, 0.88), Vector3(0.18, 0.12, 0.02), Color("e8c21c"))
        _tube(Vector3(0, 0.85, -0.5), Vector3(0, 0.74, 0.3), 0.06, paint.darkened(0.3))   # frame
        for sx in [-1.0, 1.0]:
            _tube(Vector3(sx * 0.09, 1.0, -0.5), Vector3(sx * 0.09, R, -0.74), 0.05, metal)   # voorvork
            _box(Vector3(sx * 0.17, 0.4, 0.2), Vector3(0.1, 0.03, 0.06), dark)                # voetsteun
        _ball(Vector3(0, 0.96, -0.62), 0.09, dark)
        _box(Vector3(0, 0.96, -0.7), Vector3(0.12, 0.12, 0.02), Color("f4f1d8"))       # koplamp
        _box(Vector3(0, R * 2.0 + 0.03, -0.74), Vector3(0.14, 0.03, 0.4), paint)       # voorspatbord
        _tube(Vector3(-0.34, 1.06, -0.42), Vector3(0.34, 1.06, -0.42), 0.035, dark)    # stuur
        grip_l = Vector3(-0.32, 1.06, -0.42)
        grip_r = Vector3(0.32, 1.06, -0.42)
        hip = Vector3(0, 0.98, 0.26)
        shoulder = Vector3(0, 1.46, 0.0)
        head_c = Vector3(0, 1.62, -0.12)
        knee_z = -0.12
        foot = Vector3(0, 0.44, 0.2)
        hit = Vector3(0.8, 1.7, 2.2)
    # rijder: romp, benen (stil), armen naar het stuur, hoofd met helm
    _tube(hip + Vector3(0, 0.02, 0), shoulder, 0.34, jacket)
    _box(hip + Vector3(0, 0.03, 0), Vector3(0.34, 0.14, 0.26), pants)
    for sx in [-1.0, 1.0]:
        var hp: Vector3 = hip + Vector3(sx * 0.11, 0, 0)
        var knee := Vector3(sx * 0.19, hip.y + 0.02, knee_z)
        var ft: Vector3 = foot + Vector3(sx * 0.17, 0, 0)
        _tube(hp, knee, 0.14, pants)
        _tube(knee, ft, 0.12, pants)
        _box(ft + Vector3(0, -0.02, -0.05), Vector3(0.11, 0.08, 0.24), dark)
        var sh: Vector3 = shoulder + Vector3(sx * 0.19, -0.04, 0)
        var hand: Vector3 = grip_l if sx < 0.0 else grip_r
        var elbow: Vector3 = (sh + hand) * 0.5 + Vector3(sx * 0.06, -0.06, 0.02)
        _tube(sh, elbow, 0.1, jacket)
        _tube(elbow, hand, 0.09, jacket)
        _box(hand, Vector3(0.08, 0.08, 0.1), dark)   # handschoen
    _tube(shoulder + Vector3(0, -0.02, 0), head_c + Vector3(0, -0.06, 0.02), 0.09, skin)
    _ball(head_c + Vector3(0, 0.02, 0), 0.155, helmet, Vector3(0.95, 1.0, 1.08))
    if kind == "motor":
        _box(head_c + Vector3(0, 0.03, -0.14), Vector3(0.2, 0.08, 0.04), Color("15161a"))   # vizier
    else:
        _box(head_c + Vector3(0, -0.01, -0.13), Vector3(0.18, 0.12, 0.03), skin)          # open helm: gezicht
        _box(head_c + Vector3(0, 0.06, -0.15), Vector3(0.2, 0.04, 0.03), Color("15161a"))  # klep/vizier omhoog
    var body := MeshInstance3D.new()
    body.name = "Body"
    body.mesh = _st.commit()
    body.material_override = _vmat()
    add_child(body)
    _st = null
    _hit_area(hit)
