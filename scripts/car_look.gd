extends RefCounted
# Uiterlijk van een raceauto, opgebouwd uit een zijprofiel in plaats van losse blokken.
# Drie modellen:
#   "hatch"  - korte rallyhatchback met ronde koplampen en steile achterklep
#   "coupe"  - lage sportcoupé met lange motorkap, fastback en achterspoiler
#   "sedan"  - sedan met aparte kofferbak
#   "estate" - stationwagen (alleen de politie)
#   "pickup", "van", "retro", "proto" - voorstellen voor nieuwe auto's (25-11)
# Elke auto krijgt lak, twee racestrepen, een startnummer op deuren en dak, velgen,
# koplampen, achterlichten, spiegels en een uitlaat. Voorkant = lokaal -Z.
const Kit = preload("res://scripts/build_kit.gd")

# Profielen in (z, y): z van voor (-) naar achter (+), y omhoog.
const STYLES := {
    "hatch": {
        "body": [Vector2(-1.93, 0.30), Vector2(-1.93, 0.66), Vector2(-1.74, 0.80), Vector2(-0.75, 0.90),
            Vector2(1.80, 0.92), Vector2(1.93, 0.86), Vector2(1.93, 0.30)],
        "cabin": [Vector2(-0.72, 0.90), Vector2(-0.05, 1.42), Vector2(1.52, 1.40), Vector2(1.80, 0.92)],
        "cabin_w": [0.86, 0.64], "wheel_z": [-1.22, 1.25], "round_lights": true, "spoiler": false,
    },
    "coupe": {
        "body": [Vector2(-1.96, 0.28), Vector2(-1.96, 0.58), Vector2(-1.72, 0.70), Vector2(-0.42, 0.84),
            Vector2(1.62, 0.86), Vector2(1.96, 0.80), Vector2(1.96, 0.30)],
        "cabin": [Vector2(-0.40, 0.84), Vector2(0.28, 1.25), Vector2(0.92, 1.25), Vector2(1.72, 0.86)],
        "cabin_w": [0.84, 0.6], "wheel_z": [-1.28, 1.3], "round_lights": false, "spoiler": true,
    },
    # stationwagen (zoals de politieauto): lang dak tot bijna achteraan, steile achterklep
    "estate": {
        "body": [Vector2(-2.0, 0.30), Vector2(-2.0, 0.6), Vector2(-1.8, 0.74), Vector2(-0.62, 0.86),
            Vector2(1.84, 0.9), Vector2(2.0, 0.82), Vector2(2.0, 0.30)],
        "cabin": [Vector2(-0.6, 0.86), Vector2(0.12, 1.32), Vector2(1.38, 1.3), Vector2(1.9, 0.9)],
        "cabin_w": [0.86, 0.68], "wheel_z": [-1.3, 1.3], "round_lights": false, "spoiler": false,
    },
    # ---- voorstellen voor nieuwe auto's (25-11), nog niet in de garage ----
    # pick-up: hoog op de wielen, cabine voorin, open laadbak achter
    "pickup": {
        "body": [Vector2(-2.05, 0.42), Vector2(-2.05, 0.82), Vector2(-1.85, 0.98), Vector2(-0.95, 1.04),
            Vector2(2.0, 1.04), Vector2(2.05, 0.98), Vector2(2.05, 0.42)],
        "cabin": [Vector2(-0.92, 1.04), Vector2(-0.45, 1.6), Vector2(0.45, 1.6), Vector2(0.55, 1.04)],
        "cabin_w": [0.88, 0.8], "wheel_z": [-1.3, 1.32], "round_lights": false, "spoiler": false,
        "wheel_r": 0.42, "bed": [0.62, 1.96],
    },
    # busje: hoog en hoekig, ramen rondom
    "van": {
        "body": [Vector2(-2.1, 0.32), Vector2(-2.1, 0.74), Vector2(-1.92, 0.94), Vector2(-1.3, 1.0),
            Vector2(2.06, 1.02), Vector2(2.1, 0.96), Vector2(2.1, 0.32)],
        "cabin": [Vector2(-1.27, 1.0), Vector2(-0.78, 1.86), Vector2(1.98, 1.86), Vector2(2.08, 1.02)],
        "cabin_w": [0.9, 0.86], "wheel_z": [-1.38, 1.36], "round_lights": true, "spoiler": false,
    },
    # kleine, ronde klassieker met ronde koplampen
    "retro": {
        "body": [Vector2(-1.75, 0.3), Vector2(-1.75, 0.6), Vector2(-1.55, 0.76), Vector2(-0.5, 0.84),
            Vector2(1.15, 0.86), Vector2(1.6, 0.76), Vector2(1.75, 0.62), Vector2(1.75, 0.3)],
        "cabin": [Vector2(-0.48, 0.84), Vector2(0.0, 1.3), Vector2(0.68, 1.3), Vector2(1.3, 0.85)],
        "cabin_w": [0.82, 0.6], "wheel_z": [-1.12, 1.12], "round_lights": true, "spoiler": false,
    },
    # prototype: plat en wigvormig, kleine koepel, grote vleugel
    "proto": {
        "body": [Vector2(-2.15, 0.26), Vector2(-2.15, 0.42), Vector2(-1.2, 0.62), Vector2(-0.3, 0.74),
            Vector2(1.6, 0.8), Vector2(2.15, 0.82), Vector2(2.15, 0.28)],
        "cabin": [Vector2(-0.4, 0.74), Vector2(0.25, 1.08), Vector2(0.85, 1.08), Vector2(1.5, 0.8)],
        "cabin_w": [0.7, 0.5], "wheel_z": [-1.35, 1.4], "round_lights": false, "spoiler": true,
    },
    "sedan": {
        "body": [Vector2(-1.95, 0.30), Vector2(-1.95, 0.64), Vector2(-1.72, 0.78), Vector2(-0.64, 0.88),
            Vector2(1.32, 0.90), Vector2(1.95, 0.88), Vector2(1.95, 0.30)],
        "cabin": [Vector2(-0.62, 0.88), Vector2(0.02, 1.38), Vector2(0.95, 1.38), Vector2(1.42, 0.90)],
        "cabin_w": [0.86, 0.66], "wheel_z": [-1.25, 1.28], "round_lights": false, "spoiler": false,
    },
}
const BODY_HW := 0.92

static func paint(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = 0.0
    m.roughness = 0.45
    m.metallic_specular = 0.7
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func build(car: Node3D, body: Color, stripe: Color, style: String, number: int) -> void:
    var st: Dictionary = STYLES.get(style, STYLES["hatch"])
    var lak := paint(body)
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color("26333c")
    glass.metallic = 0.6
    glass.roughness = 0.08
    glass.cull_mode = BaseMaterial3D.CULL_DISABLED
    var dark := Kit.mat(Color("1c1f23"))
    # carrosserie en cabine (ramen) als geëxtrudeerde profielen
    _loft(car, "Body", st["body"], BODY_HW, BODY_HW, lak)
    var cw: Array = st["cabin_w"]
    _loft(car, "Cabin glass", st["cabin"], float(cw[0]), float(cw[1]), glass)
    # dak in lakkleur over het bovenste stuk van de cabine
    var cab: Array = st["cabin"]
    var roof_a: Vector2 = cab[1]
    var roof_b: Vector2 = cab[2]
    Kit.box(car, "Roof", Vector3(0, roof_a.y + 0.02, (roof_a.x + roof_b.x) * 0.5),
        Vector3(float(cw[1]) * 2.0 + 0.04, 0.05, roof_b.x - roof_a.x + 0.06), Color.WHITE, false, lak)
    # stijlen tussen de ramen (B-stijl) in lakkleur
    for x in [-1.0, 1.0]:
        var bz: float = (roof_a.x + roof_b.x) * 0.5
        Kit.box(car, "B pillar", Vector3(x * (float(cw[0]) + float(cw[1])) * 0.5, (roof_a.y + 0.9) * 0.5, bz),
            Vector3(0.05, roof_a.y - 0.9, 0.12), Color.WHITE, false, lak)
    # bumpers, dorpels en grille in zwart kunststof
    var front: float = (st["body"][0] as Vector2).x
    var rear: float = (st["body"][st["body"].size() - 1] as Vector2).x
    Kit.box(car, "Front bumper", Vector3(0, 0.36, front - 0.03), Vector3(BODY_HW * 2.0 + 0.02, 0.16, 0.12), dark.albedo_color)
    Kit.box(car, "Rear bumper", Vector3(0, 0.36, rear + 0.03), Vector3(BODY_HW * 2.0 + 0.02, 0.16, 0.12), dark.albedo_color)
    Kit.box(car, "Grille", Vector3(0, 0.55, front - 0.015), Vector3(0.9, 0.14, 0.04), Color("111316"))
    for x in [-1.0, 1.0]:
        Kit.box(car, "Sill", Vector3(x * (BODY_HW + 0.005), 0.33, 0), Vector3(0.03, 0.08, 2.6), Color("16181b"))
    # open laadbak (pick-up): donkere bak in de bovenkant, met een rand in lakkleur
    if st.has("bed"):
        var bed: Array = st["bed"]
        var top: float = (st["body"][4] as Vector2).y
        Kit.box(car, "Bed", Vector3(0, top + 0.005, (float(bed[0]) + float(bed[1])) * 0.5),
            Vector3(BODY_HW * 2.0 - 0.16, 0.012, float(bed[1]) - float(bed[0])), Color("1e2124"))
        Kit.box(car, "Roll bar", Vector3(0, top + 0.35, float(bed[0]) + 0.1), Vector3(BODY_HW * 2.0 - 0.2, 0.07, 0.07), Color("2a2d31"))
        for x in [-1.0, 1.0]:
            Kit.box(car, "Roll bar post", Vector3(x * (BODY_HW - 0.12), top + 0.17, float(bed[0]) + 0.1), Vector3(0.07, 0.35, 0.07), Color("2a2d31"))
    if number != -1:      # de politie (-1) krijgt eigen, smalle lampen
        _lights(car, st, front, rear)
    _wheels(car, st)
    # startnummer < 0: geen racestrepen en geen nummers (bv. de politie)
    if number >= 0:
        _stripes(car, st, stripe)
        _numbers(car, st, number, stripe)
    # spiegels en uitlaat
    for x in [-1.0, 1.0]:
        var c0: Vector2 = cab[0]
        var mz: float = c0.x + 0.35
        Kit.box(car, "Mirror arm", Vector3(x * (float(cw[0]) + 0.05), c0.y + 0.1, mz), Vector3(0.12, 0.03, 0.05), Color("16181b"))
        Kit.box(car, "Mirror", Vector3(x * (float(cw[0]) + 0.13), c0.y + 0.13, mz), Vector3(0.06, 0.11, 0.17), Color.WHITE, false, lak)
    Kit.cyl(car, "Exhaust", Vector3(0.55, 0.3, rear + 0.08), 0.05, 0.05, 0.16, Color("9aa0a4"), 10, "z")
    if bool(st["spoiler"]):
        for x in [-0.6, 0.6]:
            Kit.box(car, "Spoiler post", Vector3(x, 0.98, rear - 0.2), Vector3(0.05, 0.22, 0.08), dark.albedo_color)
        Kit.box(car, "Spoiler wing", Vector3(0, 1.1, rear - 0.18), Vector3(1.7, 0.05, 0.32), Color.WHITE, false, paint(stripe))

# Extrudeert een (z, y)-profiel over de breedte; de breedte mag naar boven toe smaller worden.
static func _loft(parent: Node3D, n: String, prof: Array, hw_bottom: float, hw_top: float, mat: Material) -> void:
    var ys: Array = prof.map(func(p): return (p as Vector2).y)
    var y0: float = ys.min()
    var y1: float = ys.max()
    var pts := PackedVector2Array(prof)
    var hw := func(y: float) -> float:
        return lerpf(hw_bottom, hw_top, 0.0 if y1 - y0 < 0.001 else (y - y0) / (y1 - y0))
    var verts: Array = []
    # zijvlakken
    var tri: PackedInt32Array = Geometry2D.triangulate_polygon(pts)
    for side in [-1.0, 1.0]:
        for i in range(0, tri.size(), 3):
            for k in [0, 1, 2]:
                var p: Vector2 = pts[tri[i + k]]
                verts.append(Vector3(side * hw.call(p.y), p.y, p.x))
    # rondom (motorkap, ruiten, dak, achterkant, bodem)
    for i in range(pts.size()):
        var a: Vector2 = pts[i]
        var b: Vector2 = pts[(i + 1) % pts.size()]
        var al := Vector3(-hw.call(a.y), a.y, a.x)
        var ar := Vector3(hw.call(a.y), a.y, a.x)
        var bl := Vector3(-hw.call(b.y), b.y, b.x)
        var br := Vector3(hw.call(b.y), b.y, b.x)
        verts.append_array([al, ar, br, al, br, bl])
    # normalen zelf zetten: elk vlak wijst van het midden van het profiel af
    var center := Vector3.ZERO
    for p in pts:
        center += Vector3(0, p.y, p.x)
    center /= float(pts.size())
    var stool := SurfaceTool.new()
    stool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(0, verts.size(), 3):
        var v0: Vector3 = verts[i]
        var v1: Vector3 = verts[i + 1]
        var v2: Vector3 = verts[i + 2]
        var nrm: Vector3 = (v1 - v0).cross(v2 - v0)
        if nrm.length() < 0.000001:
            continue
        nrm = nrm.normalized()
        var flip: bool = nrm.dot((v0 + v1 + v2) / 3.0 - center) < 0.0
        if flip:
            nrm = -nrm
        for v in ([v0, v2, v1] if flip else [v0, v1, v2]):
            stool.set_normal(nrm)
            stool.add_vertex(v)
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = stool.commit()
    mi.material_override = mat
    parent.add_child(mi)

static func _lights(car: Node3D, st: Dictionary, front: float, rear: float) -> void:
    var head := Kit.mat(Color("fff6d8"), 0.8)
    var tail := Kit.mat(Color("d01c1c"), 0.9)
    for x in [-1.0, 1.0]:
        if bool(st["round_lights"]):
            Kit.cyl(car, "Headlight ring", Vector3(x * 0.62, 0.68, front - 0.02), 0.15, 0.15, 0.04, Color("c8ccd0"), 16, "z")
            Kit.cyl(car, "Headlight", Vector3(x * 0.62, 0.68, front - 0.04), 0.12, 0.12, 0.03, Color.WHITE, 16, "z", false, head)
        else:
            Kit.box(car, "Headlight", Vector3(x * 0.6, 0.66, front - 0.03), Vector3(0.42, 0.1, 0.05), Color.WHITE, false, head)
        Kit.box(car, "Tail light", Vector3(x * 0.62, 0.7, rear + 0.02), Vector3(0.38, 0.12, 0.04), Color.WHITE, false, tail)

static func _wheels(car: Node3D, st: Dictionary) -> void:
    var tyre := Color("15171a")
    var rim := Color("c9ced2")
    var r: float = float(st.get("wheel_r", 0.34))
    for z in st["wheel_z"]:
        for x in [-1.0, 1.0]:
            var c := Vector3(x * 0.84, r, float(z))
            Kit.cyl(car, "Tyre", c, r, r, 0.26, tyre, 18, "x")
            Kit.cyl(car, "Rim", c + Vector3(x * 0.1, 0, 0), 0.23, 0.23, 0.08, rim, 18, "x")
            Kit.cyl(car, "Hub", c + Vector3(x * 0.14, 0, 0), 0.06, 0.06, 0.03, Color("3a3f44"), 10, "x")
            for k in range(5):
                var a: float = float(k) * TAU / 5.0
                var spoke := Kit.box(car, "Spoke", c + Vector3(x * 0.145, sin(a) * 0.12, cos(a) * 0.12), Vector3(0.02, 0.2, 0.045), Color("8d9398"))
                spoke.rotation.x = -a
            # wielkast: donkere boog boven het wiel
            Kit.box(car, "Arch", Vector3(x * (BODY_HW + 0.01), r + 0.28, float(z)), Vector3(0.04, 0.08, 0.8 + (r - 0.34) * 2.0), Color("16181b"))

# Twee racestrepen over motorkap, dak en achterkant.
static func _stripes(car: Node3D, st: Dictionary, color: Color) -> void:
    var body: Array = st["body"]
    var cab: Array = st["cabin"]
    # alleen over lak: motorkap (tot de voorruit), dak, en achterkant (na de achterruit)
    var segs: Array = [[body[1], body[2]], [body[2], body[3]], [cab[1], cab[2]]]
    var after: Array = []
    for i in range(1, body.size() - 1):
        var p: Vector2 = body[i]
        if p.x >= (cab[3] as Vector2).x - 0.01:
            after.append(p)
    for i in range(after.size() - 1):
        segs.append([after[i], after[i + 1]])
    var mat := paint(color)
    for x in [-0.2, 0.2]:
        for sg in segs:
            var a: Vector2 = sg[0]
            var b: Vector2 = sg[1]
            var d := Vector3(0, b.y - a.y, b.x - a.x)
            if d.length() < 0.05:
                continue
            var mid := Vector3(x, (a.y + b.y) * 0.5, (a.x + b.x) * 0.5)
            var up: Vector3 = Vector3.RIGHT.cross(d.normalized()).normalized()
            if up.y < 0.0:
                up = -up
            var strip := MeshInstance3D.new()
            var bm := BoxMesh.new()
            bm.size = Vector3(0.16, 0.01, d.length())
            strip.mesh = bm
            strip.material_override = mat
            strip.transform = Transform3D(Basis.looking_at(d.normalized(), up), mid + up * 0.012)
            car.add_child(strip)

# Startnummer in een wit rondje op beide deuren en op het dak.
static func _numbers(car: Node3D, st: Dictionary, number: int, ring: Color) -> void:
    var cab: Array = st["cabin"]
    var roof_a: Vector2 = cab[1]
    var roof_b: Vector2 = cab[2]
    var dz: float = (roof_a.x + roof_b.x) * 0.5
    # op de deuren: niet tot over de zwarte rand van de achterste wielkast (0,4 voor de
    # wielas begint die rand, het rondje is 0,24 breed)
    var sz: float = minf(dz, float(st["wheel_z"][1]) - 0.4 - 0.24 - 0.06)
    for x in [-1.0, 1.0]:
        Kit.cyl(car, "Number disc", Vector3(x * (BODY_HW + 0.008), 0.62, sz), 0.24, 0.24, 0.015, Color("f4f4ee"), 20, "x")
        var f := Node3D.new()
        f.position = Vector3(x * (BODY_HW + 0.02), 0.62, sz)
        f.rotation_degrees.y = 90.0 * x
        car.add_child(f)
        Kit.label(f, str(number), Vector3.ZERO, 0.0055, Color("15181c"), 64)
    var rf := Node3D.new()
    rf.position = Vector3(0, roof_a.y + 0.06, dz)
    rf.rotation_degrees = Vector3(-90, 0, 0)
    car.add_child(rf)
    Kit.cyl(rf, "Roof number disc", Vector3(0, 0, -0.005), 0.26, 0.26, 0.01, Color("f4f4ee"), 20, "z")
    Kit.label(rf, str(number), Vector3(0, 0, 0.004), 0.006, Color("15181c"), 64)
