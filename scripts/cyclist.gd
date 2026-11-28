extends Node3D
# Fietser op het fietspad: rijdt in de richting van zijn kant van de weg (rechts mee, links
# tegen de rijrichting in), trapt, en volgt de route rond. Raak je er een, dan valt hij
# om (en kost het je snelheid); na een paar seconden staat hij weer op en fietst verder.
const Kit = preload("res://scripts/build_kit.gd")

var route
var level
var s := 0.0
var speed := 5.0
var side := 1.0           # 1 = rechterfietspad (mee), -1 = linkerfietspad (tegemoet)
var offset := 8.4
var legs: Array = []      # per been [dij, scheen, heup, pedaalkant]
var kind := "city"
var crank_c := Vector3(0, 0.3, 0.02)   # trapas
const CRANK := 0.17
const THIGH := 0.46
const SHIN := 0.47
var crank := 0.0
var wheels: Array = []    # velg + spaken, draaien om de as
var wheel_r := 0.34
var roll := 0.0
var fall := 0.0           # hoek waarmee hij omligt (0 = rechtop)
var down_time := 0.0      # hoe lang hij nog blijft liggen
var check_t := 0.0        # tijd tot de volgende controle of er iets op het fietspad staat
var query: PhysicsShapeQueryParameters3D

func setup(lv, start_s: float, v: float, on_side: float, shirt: Color, bike: Color, variant := "city", seed_n := 0) -> void:
    kind = variant
    level = lv
    route = lv.route
    s = start_s
    speed = v
    side = on_side
    offset = lv.road_hw + lv.CURB_W + lv.BIKE_W * 0.5
    _build(shirt, bike, seed_n)
    _apply()

# Opbouw (28-11): het stilstaande deel (fiets, romp, armen, hoofd, bagage) is één mesh met
# kleuren per hoekpunt; alleen de benen bewegen (dij en scheen per been, met een knie die
# meebuigt op de trappers). Soorten: stadsfiets, met krat voorop, met kinderzitje, met
# rugzak, e-bike en wielrenner.
static var _mat: StandardMaterial3D
const SKINS := [Color("e8c4a6"), Color("d9a984"), Color("b07c58"), Color("7a4e34"), Color("f0d2bc")]
const HAIRS := [Color("2b2018"), Color("5a3a22"), Color("a8763e"), Color("d8b46a"), Color("1a1a1a"), Color("8a4a2a")]
const PANTS := [Color("2b3a55"), Color("1f2226"), Color("4a4f57"), Color("6b5a44"), Color("2e4d6e")]
var _st: SurfaceTool

func _vmat() -> StandardMaterial3D:
    if _mat == null:
        _mat = StandardMaterial3D.new()
        _mat.vertex_color_use_as_albedo = true
        _mat.roughness = 0.85
    return _mat

func _put(mesh: PrimitiveMesh, xf: Transform3D, col: Color, st: SurfaceTool = null) -> void:
    var t: SurfaceTool = st if st != null else _st
    var arr: Array = mesh.get_mesh_arrays()
    var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
    var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
    var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
    var nb: Basis = xf.basis.inverse().transposed()
    if idx.is_empty():
        for i in v.size():
            t.set_color(col)
            t.set_normal((nb * nr[i]).normalized())
            t.add_vertex(xf * v[i])
    else:
        for i in idx:
            t.set_color(col)
            t.set_normal((nb * nr[i]).normalized())
            t.add_vertex(xf * v[i])

func _box(c: Vector3, size: Vector3, col: Color, rot := Basis(), st: SurfaceTool = null) -> void:
    var m := BoxMesh.new()
    m.size = size
    _put(m, Transform3D(rot, c), col, st)

# balk van a naar b (dikte w)
func _tube(a: Vector3, b: Vector3, w: float, col: Color, st: SurfaceTool = null) -> void:
    var d: Vector3 = b - a
    if d.length() < 0.001:
        return
    var rot := Basis()
    if absf(d.normalized().dot(Vector3.UP)) < 0.9999:
        rot = Basis(Quaternion(Vector3.UP, d.normalized()))
    _box((a + b) * 0.5, Vector3(w, d.length(), w), col, rot, st)

func _ball(c: Vector3, r: float, col: Color, squash := Vector3.ONE) -> void:
    var m := SphereMesh.new()
    m.radius = r
    m.height = r * 2.0
    m.radial_segments = 10
    m.rings = 5
    _put(m, Transform3D(Basis().scaled(squash), c), col)

func _wheel(z: float, r: float, tyre: float, rim_col: Color) -> void:
    var t := TorusMesh.new()
    t.inner_radius = r - tyre
    t.outer_radius = r
    t.rings = 18
    t.ring_segments = 5
    # torus ligt plat (as langs Y): kantelen zodat de as langs X loopt. De band is rond en
    # blijft in het vaste deel; velg, spaken en naaf draaien (eigen mesh rond de as).
    _put(t, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0, r, z)), Color("1c1d20"))
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rim := TorusMesh.new()
    rim.inner_radius = r - tyre - 0.025
    rim.outer_radius = r - tyre + 0.005
    rim.rings = 18
    rim.ring_segments = 4
    _put(rim, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3.ZERO), rim_col, st)
    # spaken: drie dunne balken door de naaf
    for k in 3:
        var ang: float = PI * float(k) / 3.0
        var dir := Vector3(0, cos(ang), sin(ang)) * (r - tyre - 0.01)
        _tube(-dir, dir, 0.012, Color("b8bcc0"), st)
    _box(Vector3.ZERO, Vector3(0.1, 0.05, 0.05), Color("8a8e92"), Basis(), st)
    var w := MeshInstance3D.new()
    w.name = "Wheel"
    w.mesh = st.commit()
    w.material_override = _vmat()
    w.position = Vector3(0, r, z)
    add_child(w)
    wheels.append(w)
    wheel_r = r

func _mudguard(z: float, r: float, col: Color) -> void:
    var prev := Vector3.ZERO
    for i in 9:
        var ang: float = deg_to_rad(-30.0 + 210.0 * float(i) / 8.0)   # van achter-onder over de top naar voor
        var p := Vector3(0, r + sin(ang) * (r + 0.04), z + cos(ang) * (r + 0.04) * (1.0 if z > 0.0 else -1.0))
        if i > 0:
            _tube(prev, p, 0.06, col)
        prev = p

func _build(shirt: Color, bike: Color, seed_n: int) -> void:
    name = "Cyclist"
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_n * 7919 + 13
    var skin: Color = SKINS[rng.randi_range(0, SKINS.size() - 1)]
    var hair: Color = HAIRS[rng.randi_range(0, HAIRS.size() - 1)]
    var pants: Color = PANTS[rng.randi_range(0, PANTS.size() - 1)]
    var dark := Color("1f2226")
    var chrome := Color("a9adb1")
    var racer: bool = kind == "racer"
    var fat: bool = kind == "fatbike"
    if kind == "ebike":
        hair = [Color("c9c9c4"), Color("9a9a96"), Color("e4e2dc")][rng.randi_range(0, 2)]
    if racer:
        pants = Color("17181b")
    _st = SurfaceTool.new()
    _st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var R: float = 0.34 if not fat else 0.31
    var rear := Vector3(0, R, 0.55)
    var front := Vector3(0, R, -0.58 if fat else -0.55)
    var bb := Vector3(0, 0.3, 0.02)
    crank_c = bb
    # wielen (fatbike: kleine wielen met dikke, brede banden en zwarte velgen)
    var tyre: float = 0.035
    if racer:
        tyre = 0.022
    elif fat:
        tyre = 0.11
    _wheel(rear.z, R, tyre, chrome if not fat else Color("2a2b2e"))
    _wheel(front.z, R, tyre, chrome if not fat else Color("2a2b2e"))
    var seat: Vector3
    var head_top: Vector3
    var head_bot: Vector3
    var hip: Vector3
    var shoulder: Vector3
    var head_c: Vector3
    var grip_l: Vector3
    var grip_r: Vector3
    if racer:
        # racefiets: diamantframe, laag stuur met beugels
        seat = Vector3(0, 0.82, 0.16)
        head_top = Vector3(0, 0.86, -0.42)
        head_bot = Vector3(0, 0.7, -0.46)
        _tube(bb, seat, 0.04, bike)
        _tube(bb, head_bot, 0.045, bike)
        _tube(seat, head_top, 0.035, bike)
        _tube(seat, rear, 0.025, bike)
        _tube(bb, rear, 0.025, bike)
        _tube(head_top, head_bot, 0.045, bike)
        _tube(head_bot, front, 0.03, bike)
        _tube(seat, seat + Vector3(0, 0.12, 0.03), 0.03, chrome)
        _box(seat + Vector3(0, 0.14, 0.0), Vector3(0.12, 0.04, 0.26), dark)
        _tube(head_top, head_top + Vector3(0, 0.03, -0.1), 0.03, dark)
        var bar: Vector3 = head_top + Vector3(0, 0.03, -0.1)
        _tube(bar + Vector3(-0.2, 0, 0), bar + Vector3(0.2, 0, 0), 0.03, dark)
        for sx in [-1.0, 1.0]:
            _tube(bar + Vector3(sx * 0.2, 0, 0), bar + Vector3(sx * 0.2, -0.13, -0.08), 0.03, dark)
        grip_l = bar + Vector3(-0.2, -0.02, -0.03)
        grip_r = bar + Vector3(0.2, -0.02, -0.03)
        hip = seat + Vector3(0, 0.2, 0.02)
        shoulder = Vector3(0, 1.36, -0.26)
        head_c = Vector3(0, 1.5, -0.42)
    elif fat:
        # fatbike: dik frame met accu, lang zadel (soms met iemand achterop), hoog breed stuur,
        # verende voorvork, grote koplamp en voetsteunen
        seat = Vector3(0, 0.8, 0.28)
        head_top = Vector3(0, 0.98, -0.44)
        head_bot = Vector3(0, 0.66, -0.5)
        var mid := Vector3(0, 0.62, -0.06)
        _tube(bb, mid, 0.07, bike)
        _tube(mid, head_bot, 0.08, bike)
        _tube(Vector3(0, 0.74, 0.1), Vector3(0, 0.84, -0.4), 0.06, bike)
        _box(Vector3(0, 0.52, -0.24), Vector3(0.13, 0.18, 0.36), Color("26282b"), Basis(Vector3(1, 0, 0), 0.5))   # accu
        _tube(bb, Vector3(0, 0.7, 0.18), 0.06, bike)
        _tube(Vector3(0, 0.7, 0.18), rear + Vector3(0.12, 0, 0), 0.04, bike)
        _tube(Vector3(0, 0.7, 0.18), rear + Vector3(-0.12, 0, 0), 0.04, bike)
        _tube(bb + Vector3(0.12, 0, 0), rear + Vector3(0.12, 0, 0), 0.04, bike)
        _tube(bb + Vector3(-0.12, 0, 0), rear + Vector3(-0.12, 0, 0), 0.04, bike)
        _box(Vector3(0, R, rear.z), Vector3(0.3, 0.12, 0.12), Color("2a2c30"))   # naafmotor
        # verende voorvork: dikke poten aan beide kanten van de band
        for sx in [-1.0, 1.0]:
            _tube(head_bot + Vector3(sx * 0.12, 0.02, 0), front + Vector3(sx * 0.12, 0, 0), 0.06, Color("2a2c30"))
            _tube(head_bot + Vector3(sx * 0.12, 0.02, 0), head_bot + Vector3(sx * 0.12, -0.14, -0.03), 0.075, chrome)
        _tube(head_top, head_bot, 0.08, bike)
        # spatborden: kort en breed
        for z in [rear.z, front.z]:
            _box(Vector3(0, R * 2.0 + 0.04, z), Vector3(0.28, 0.03, 0.32), bike)
        # lang zadel en bagagedrager
        _box(Vector3(0, 0.85, 0.36), Vector3(0.22, 0.09, 0.62), Color("141517"))
        _box(Vector3(0, 0.8, 0.36), Vector3(0.18, 0.03, 0.6), Color("2a2c30"))
        _tube(Vector3(0, 0.78, 0.62), rear + Vector3(0, 0.1, 0.05), 0.04, Color("2a2c30"))
        _box(Vector3(0, 0.78, 0.68), Vector3(0.12, 0.05, 0.03), Color("c8241e"))     # achterlicht
        for sx in [-1.0, 1.0]:
            _box(Vector3(sx * 0.2, 0.3, 0.42), Vector3(0.12, 0.03, 0.06), Color("2a2c30"))   # voetsteun
        # koplamp en stuur
        _ball(head_top + Vector3(0, -0.08, -0.1), 0.075, Color("26282b"))
        _box(head_top + Vector3(0, -0.08, -0.17), Vector3(0.12, 0.12, 0.02), Color("f4f1d8"))
        var stem: Vector3 = head_top + Vector3(0, 0.12, 0.04)
        _tube(head_top, stem, 0.05, Color("2a2c30"))
        grip_l = stem + Vector3(-0.34, 0.04, 0.12)
        grip_r = stem + Vector3(0.34, 0.04, 0.12)
        _tube(grip_l, grip_r, 0.035, Color("2a2c30"))
        hip = seat + Vector3(0, 0.12, 0.02)
        shoulder = Vector3(0, 1.4, 0.16)
        head_c = Vector3(0, 1.56, 0.1)
        if rng.randf() < 0.35:
            # iemand achterop, zit stil met de voeten op de steunen
            var p_shirt: Color = [Color("e9e7e2"), Color("1d1e21"), Color("b9586e"), Color("6d8fb3")][rng.randi_range(0, 3)]
            var p_skin: Color = SKINS[rng.randi_range(0, SKINS.size() - 1)]
            var p_hair: Color = HAIRS[rng.randi_range(0, HAIRS.size() - 1)]
            var p_hip := Vector3(0, 0.94, 0.52)
            _box(p_hip, Vector3(0.32, 0.13, 0.24), pants)
            for sx in [-1.0, 1.0]:
                var knee := Vector3(sx * 0.17, 0.96, 0.2)
                _tube(p_hip + Vector3(sx * 0.1, 0, 0), knee, 0.12, pants)
                _tube(knee, Vector3(sx * 0.2, 0.36, 0.38), 0.1, pants)
                _box(Vector3(sx * 0.2, 0.34, 0.34), Vector3(0.1, 0.07, 0.22), Color("e8e8e4"))
            _tube(p_hip, Vector3(0, 1.36, 0.5), 0.3, p_shirt)
            _tube(Vector3(0, 1.34, 0.5), Vector3(0, 1.44, 0.49), 0.08, p_skin)
            _ball(Vector3(0, 1.5, 0.48), 0.11, p_skin)
            _ball(Vector3(0, 1.54, 0.5), 0.118, p_hair, Vector3(1.0, 0.85, 1.0))
            if rng.randf() < 0.5:
                _box(Vector3(0, 1.4, 0.58), Vector3(0.15, 0.24, 0.08), p_hair)   # lang haar
            # armen om de bestuurder heen
            for sx in [-1.0, 1.0]:
                var p_sh := Vector3(sx * 0.17, 1.3, 0.5)
                var p_el := Vector3(sx * 0.22, 1.12, 0.38)
                _tube(p_sh, p_el, 0.08, p_shirt)
                _tube(p_el, Vector3(sx * 0.15, 1.08, 0.16), 0.07, p_skin)
    else:
        # Hollandse stadsfiets: lage instap, spatborden, kettingkast, bagagedrager, stuur naar achteren
        seat = Vector3(0, 0.8, 0.2)
        head_top = Vector3(0, 0.9, -0.42)
        head_bot = Vector3(0, 0.68, -0.47)
        var low := Vector3(0, 0.44, -0.24)
        _tube(bb, seat, 0.045, bike)
        _tube(bb, low, 0.05, bike)
        _tube(low, head_bot, 0.05, bike)
        _tube(Vector3(0, 0.6, 0.12), Vector3(0, 0.76, -0.43), 0.035, bike)
        _tube(seat, rear, 0.03, bike)
        _tube(bb, rear, 0.03, bike)
        _tube(head_top, head_bot, 0.05, bike)
        _tube(head_bot, front, 0.035, bike)
        _tube(seat, seat + Vector3(0, 0.14, 0.04), 0.03, chrome)
        _box(seat + Vector3(0, 0.17, 0.04), Vector3(0.18, 0.07, 0.26), dark)
        _mudguard(rear.z, R, bike)
        _mudguard(front.z, R, bike)
        _box(Vector3(0.07, 0.31, 0.3), Vector3(0.03, 0.13, 0.62), bike)               # kettingkast
        _box(Vector3(0, 0.76, 0.52), Vector3(0.2, 0.03, 0.44), dark)                  # bagagedrager
        _tube(Vector3(0.09, 0.76, 0.7), rear + Vector3(0.09, 0, 0), 0.02, dark)
        _tube(Vector3(-0.09, 0.76, 0.7), rear + Vector3(-0.09, 0, 0), 0.02, dark)
        _box(Vector3(0, 0.74, 0.76), Vector3(0.08, 0.05, 0.03), Color("c8241e"))      # achterlicht
        _box(Vector3(0, 0.66, -0.58), Vector3(0.08, 0.07, 0.08), Color("eeeac8"))     # koplamp
        _tube(head_top, head_top + Vector3(0, 0.1, 0.02), 0.035, chrome)
        var stem: Vector3 = head_top + Vector3(0, 0.1, 0.02)
        grip_l = stem + Vector3(-0.27, 0.04, 0.2)
        grip_r = stem + Vector3(0.27, 0.04, 0.2)
        _tube(stem + Vector3(-0.12, 0, 0), stem + Vector3(0.12, 0, 0), 0.03, chrome)
        _tube(stem + Vector3(-0.12, 0, 0), grip_l, 0.03, chrome)
        _tube(stem + Vector3(0.12, 0, 0), grip_r, 0.03, chrome)
        hip = seat + Vector3(0, 0.24, 0.05)
        shoulder = Vector3(0, 1.58, 0.14)
        head_c = Vector3(0, 1.74, 0.1)
        if kind == "crate":
            var crate: Color = [Color("1e2a3a"), Color("8a5a32"), Color("22252a"), Color("3a5a8a")][rng.randi_range(0, 3)]
            _box(Vector3(0, 0.72, -0.66), Vector3(0.36, 0.03, 0.3), dark)
            _box(Vector3(0, 0.86, -0.66), Vector3(0.38, 0.26, 0.32), crate)
            _box(Vector3(0, 0.99, -0.66), Vector3(0.3, 0.02, 0.24), crate.darkened(0.4))
        elif kind == "child":
            _box(Vector3(0, 0.9, 0.56), Vector3(0.32, 0.26, 0.34), Color("2a2c30"))
            _box(Vector3(0, 1.08, 0.7), Vector3(0.32, 0.4, 0.06), Color("2a2c30"))
            var kid: Color = [Color("e07b28"), Color("3fa0d8"), Color("e04f8a"), Color("7ac043")][rng.randi_range(0, 3)]
            _box(Vector3(0, 1.13, 0.58), Vector3(0.2, 0.26, 0.16), kid)
            _ball(Vector3(0, 1.36, 0.58), 0.085, skin)
            _ball(Vector3(0, 1.4, 0.59), 0.095, kid.lightened(0.3), Vector3(1, 0.75, 1))   # helmpje
        elif kind == "ebike":
            _box(Vector3(0, 0.82, 0.5), Vector3(0.12, 0.08, 0.32), Color("3a3d42"))    # accu op de drager
            _box(Vector3(0, R, rear.z), Vector3(0.12, 0.14, 0.14), Color("2a2c30"))    # naafmotor
        if kind != "child" and kind != "ebike" and rng.randf() < 0.35:
            # fietstas aan de drager
            var bag: Color = [Color("1f2226"), Color("6b3a2a"), Color("2f4a3a")][rng.randi_range(0, 2)]
            _box(Vector3(0.13, 0.62, 0.52), Vector3(0.09, 0.26, 0.34), bag)
    # romp: van heup naar schouders
    _tube(hip + Vector3(0, 0.02, 0), shoulder, 0.33, shirt)
    _box(hip + Vector3(0, 0.03, 0), Vector3(0.34, 0.14, 0.26), pants)
    # armen: schouder -> elleboog -> hand aan het stuur
    for sx in [-1.0, 1.0]:
        var sh: Vector3 = shoulder + Vector3(sx * 0.19, -0.04, 0)
        var hand: Vector3 = grip_l if sx < 0.0 else grip_r
        var elbow: Vector3 = (sh + hand) * 0.5 + Vector3(sx * 0.05, -0.04 if not racer else -0.1, 0.02)
        _tube(sh, elbow, 0.09, shirt)
        _tube(elbow, hand, 0.075, skin if not racer else shirt)
        _box(hand, Vector3(0.07, 0.07, 0.09), skin if not racer else dark)
    # hoofd
    _tube(shoulder + Vector3(0, -0.02, 0), head_c + Vector3(0, -0.06, 0.02), 0.08, skin)
    _ball(head_c, 0.115, skin, Vector3(0.95, 1.05, 1.0))
    if racer:
        var helmet: Color = shirt.lightened(0.2)
        _ball(head_c + Vector3(0, 0.05, 0.03), 0.135, helmet, Vector3(0.95, 0.7, 1.25))
        _box(head_c + Vector3(0, 0.01, -0.11), Vector3(0.2, 0.04, 0.03), Color("15161a"))   # zonnebril
    else:
        _ball(head_c + Vector3(0, 0.04, 0.025), 0.122, hair, Vector3(1.0, 0.85, 1.0))
        if rng.randf() < 0.4:
            _box(head_c + Vector3(0, -0.12, 0.08), Vector3(0.16, 0.22, 0.08), hair)  # lang haar
    if fat:
        _box(shoulder + Vector3(0, 0.04, 0.13), Vector3(0.26, 0.16, 0.1), shirt.darkened(0.15))   # capuchon van de hoodie
    if kind == "backpack":
        var pack: Color = [Color("2a2c30"), Color("c84a2a"), Color("2c5a8a"), Color("4a6a3a")][rng.randi_range(0, 3)]
        _box((hip + shoulder) * 0.5 + Vector3(0, 0.06, 0.2), Vector3(0.3, 0.38, 0.16), pack)
    var body := MeshInstance3D.new()
    body.name = "Body"
    body.mesh = _st.commit()
    body.material_override = _vmat()
    add_child(body)
    _st = null
    # benen: dij (heup -> knie) en scheen met schoen (knie -> trapper), elk een eigen mesh
    var shoe: Color = [Color("1f1f1f"), Color("e8e8e4"), Color("6b4a2a"), Color("2a3a5a")][rng.randi_range(0, 3)]
    for i in 2:
        var sx: float = -1.0 if i == 0 else 1.0
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        _box(Vector3(0, -THIGH * 0.5, 0), Vector3(0.13, THIGH, 0.14), pants, Basis(), st)
        var thigh := MeshInstance3D.new()
        thigh.name = "Thigh"
        thigh.mesh = st.commit()
        thigh.material_override = _vmat()
        add_child(thigh)
        st = SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        _box(Vector3(0, -SHIN * 0.5, 0), Vector3(0.11, SHIN, 0.12), pants if not racer else skin, Basis(), st)
        _box(Vector3(0, -SHIN + 0.02, -0.06), Vector3(0.1, 0.07, 0.24), shoe, Basis(), st)
        var shin := MeshInstance3D.new()
        shin.name = "Shin"
        shin.mesh = st.commit()
        shin.material_override = _vmat()
        add_child(shin)
        legs.append([thigh, shin, hip + Vector3(sx * 0.1, 0, 0), sx])
    _pose_legs()
    _hit_area(Vector3(0.7, 1.8, 1.7))

# aanraakzone: een auto die hier doorheen rijdt, raakt de fietser
func _hit_area(size: Vector3) -> void:
    var area := Area3D.new()
    var cs := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    cs.shape = box
    cs.position.y = size.y * 0.5
    area.add_child(cs)
    add_child(area)
    area.body_entered.connect(_on_hit)

# Benen op de trappers: trapper op de cirkel rond de trapas, knie met twee-delige IK in het
# vlak van de fiets (knie naar voren).
func _pose_legs() -> void:
    for i in legs.size():
        var L: Array = legs[i]
        var ang: float = crank + float(i) * PI
        var hp: Vector3 = L[2]
        var pedal: Vector3 = crank_c + Vector3(float(L[3]) * 0.14, -sin(ang) * CRANK, -cos(ang) * CRANK)
        pedal.y += 0.07   # enkel boven de trapper
        var d: Vector3 = pedal - hp
        var dist: float = clampf(d.length(), absf(THIGH - SHIN) + 0.01, THIGH + SHIN - 0.01)
        var dir: Vector3 = d.normalized()
        # hoek bij de heup (cosinusregel)
        var a: float = acos(clampf((THIGH * THIGH + dist * dist - SHIN * SHIN) / (2.0 * THIGH * dist), -1.0, 1.0))
        # knie naar voren (-Z): draai dir om de X-as
        var side_ax := Vector3(1, 0, 0)
        var k1: Vector3 = hp + dir.rotated(side_ax, a) * THIGH
        var k2: Vector3 = hp + dir.rotated(side_ax, -a) * THIGH
        var knee: Vector3 = k1 if k1.z < k2.z else k2
        (L[0] as Node3D).transform = Transform3D(_down_to(knee - hp), hp)
        (L[1] as Node3D).transform = Transform3D(_down_to(pedal - knee), knee)

# basis waarvan -Y in richting v wijst
func _down_to(v: Vector3) -> Basis:
    var d: Vector3 = v.normalized()
    if absf(d.dot(Vector3.DOWN)) > 0.9999:
        return Basis()
    return Basis(Quaternion(Vector3.DOWN, d))

func _on_hit(body: Node3D) -> void:
    if not (body is ArcadeCar) or down_time > 0.0 or not visible:
        return
    if absf(body.drive_speed) < 3.0:
        return
    down_time = 4.0
    body.drive_speed *= 0.8
    body.bumped.emit(absf(body.drive_speed))
    if not body.ai:
        _report_hit()

func _report_hit() -> void:
    var race := get_tree().current_scene
    if race != null and race.has_method("cyclist_hit"):
        race.cyclist_hit()

func _process(delta: float) -> void:
    if route == null:
        return
    if down_time > 0.0:
        # omgevallen: liggen, daarna weer overeind komen
        down_time -= delta
        fall = move_toward(fall, 1.45 if down_time > 0.8 else 0.0, delta * 4.0)
        _apply()
        return
    fall = move_toward(fall, 0.0, delta * 4.0)
    check_t -= delta
    s = fposmod(s + side * speed * delta, route.length) if route.closed else clampf(s + side * speed * delta, 0.0, route.length)
    var cad: float = 2.2
    if kind == "racer":
        cad = 1.6
    elif kind == "fatbike":
        cad = 0.9   # de motor doet het werk: rustig meetrappen
    crank += speed * delta * cad
    # wielen rollen mee: bovenkant naar voren (-Z) = negatieve draaiing om X
    roll = fposmod(roll - speed * delta / wheel_r, TAU)
    for w in wheels:
        (w as Node3D).rotation.x = roll
    _pose_legs()
    _apply()

func _apply() -> void:
    var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * offset
    var b: Basis = route.basis_at(s)
    if side < 0.0:
        b = b.rotated(Vector3.UP, PI)
    # omvallen = kantelen om de rijrichting, weg van de weg
    transform = Transform3D(b * Basis(Vector3(0, 0, 1), -fall), p + Vector3(0, 0.07, 0))
    # niet door gebouwen fietsen: alleen waar echt iets op het fietspad staat (een muur, een
    # gebouw) is hij even onzichtbaar. Vroeger gold dat voor het hele terrein rond een
    # bezienswaardigheid, ook waar het fietspad gewoon vrij is.
    if check_t <= 0.0 and is_inside_tree():
        check_t = 0.2
        visible = not _blocked(p)

func _blocked(p: Vector3) -> bool:
    if query == null:
        var box := BoxShape3D.new()
        box.size = Vector3(0.5, 1.2, 1.2)
        query = PhysicsShapeQueryParameters3D.new()
        query.shape = box
        query.collide_with_areas = false
    query.transform = Transform3D(global_transform.basis.orthonormalized(), p + Vector3(0, 1.0, 0))
    for r in get_world_3d().direct_space_state.intersect_shape(query, 4):
        if r["collider"] is StaticBody3D:
            return true
    return false
