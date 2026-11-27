extends Node3D
# Basis voor een gemeente-level. Een level zet in build():
#   route        - de Route (hoekpunten + bochtstralen)
#   checkpoints  - [{"at": Vector3, "name": String}], de laatste is de finish
#   traffic_end  - punt waar het verkeer omkeert (bijv. voor een plein)
#   exclusions   - Rect2's (x,z) waar geen straatbebouwing mag komen
# en roept daarna build_road() en build_streetscape() aan.
const Kit = preload("res://scripts/build_kit.gd")
const Houses = preload("res://scripts/levels/houses.gd")
const Route = preload("res://scripts/route.gd")

const ROAD_GRAY := Color("3a3e44")
const SIDEWALK := Color("9b9a90")
const LINE := Color("dedbd0")
const BIKE_RED := Color("a4483a")
const CURB_W := 0.4      # band tussen rijbaan en fietspad
const BIKE_W := 2.0      # fietspad
const WALK_W := 2.0      # trottoir

var route: Route
var level_title := ""
var checkpoints: Array = []
var traffic_end := Vector3.INF
var traffic_cars := 14
var exclusions: Array[Rect2] = []
var seed_value := 1
var town_s: Array = []           # afstanden langs de route met bebouwing (= bebouwde kom)
var town_sign_s: Array = []      # afstanden van de plaatsnaamborden (daar geen ander bord)
var lamp_points: Array = []      # voeten van de lantaarnpalen (borden niet ertegenaan zetten)
var road_hw := 7.0                 # halve wegbreedte
var laps := 1                      # aantal ronden (alleen zinvol op een gesloten route)
var dual := false                  # gescheiden weg (2x2) met middenberm en vangrail
var traffic_lanes: Array = [3.4]   # rijstrookafstand tot de wegas (meerijdend rechts, tegemoet links)
# Moeilijk: extra sterkte van de tegenstanderauto's in dit level (bovenop de rest). Voor
# levels waar ze door verkeer en kruisingen veel tijd verliezen en jij dus te makkelijk wint.
var hard_boost := 1.0
# Moeilijk: inhaalhulp voor tegenstanders achter jou in dit level (zie race.CATCH_UP).
var hard_catch_up := 0.0
var no_overtake: Array = []        # [[s0, s1], ...]: hier niet links inhalen (bv. middenberm)
# Straatbebouwing: welke huistypes (zie houses.gd) en hoe vaak, per level in te stellen.
var street_mix := {"row": 3, "semi": 2, "detached": 1}
var plots: Array = []              # [body, type, transform, gevelkleur, dakkleur, muurschildering, kant, s]
# Kans dat na een pand een open plek komt met een muurschildering op de zijgevel van het
# volgende pand (Heerlen: street-art).
var murals := 0.0
# (alleen op flats en winkelpanden: op gewone woonhuizen staan ze in het echt niet)
const MURAL_KINDS := {"shop": [9.4, 10.0], "flat": [11.6, 11.6]}

func build() -> void:
    pass

func traffic_end_s() -> float:
    if route.closed:
        return route.length
    if traffic_end == Vector3.INF:
        return route.length - 20.0
    return route.closest_s(traffic_end)

func exclude_box(center: Vector3, aabb_min: Vector3, aabb_max: Vector3, margin := 5.0) -> void:
    exclusions.append(Rect2(center.x + aabb_min.x - margin, center.z + aabb_min.z - margin,
        aabb_max.x - aabb_min.x + margin * 2.0, aabb_max.z - aabb_min.z + margin * 2.0))

func place(landmark: Node3D, pos: Vector3, yaw_deg := 0.0) -> Node3D:
    landmark.position = pos
    landmark.rotation_degrees.y = yaw_deg
    add_child(landmark)
    return landmark

# ---------------------------------------------------------------- weg
func _strip(st: SurfaceTool, s0: float, s1: float, o0: float, o1: float, y: float, step := 2.0) -> void:
    var s: float = s0
    var prev_a := Vector3.ZERO
    var prev_b := Vector3.ZERO
    var first := true
    while true:
        var p: Vector3 = route.pos_at(s)
        var r: Vector3 = route.right_at(s)
        var a: Vector3 = p + r * o0 + Vector3(0, y, 0)
        var b: Vector3 = p + r * o1 + Vector3(0, y, 0)
        if not first:
            for v in [prev_a, prev_b, b, prev_a, b, a]:
                st.set_normal(Vector3.UP)
                st.add_vertex(v)
        prev_a = a
        prev_b = b
        first = false
        if s >= s1:
            break
        s = minf(s + step, s1)

# strips: [[s0, s1, o0, o1, y, step], ...] in één mesh
func _ribbon(n: String, color: Color, strips: Array) -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for q in strips:
        _strip(st, q[0], q[1], q[2], q[3], q[4], q[5])
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = st.commit()
    mi.material_override = Kit.two_sided_mat(color)
    add_child(mi)

func build_road() -> void:
    var L: float = route.length
    _ribbon("Asphalt", ROAD_GRAY, [[0.0, L, -road_hw, road_hw, 0.03, 2.0]])
    if dual:
        # autoweg: smalle asfaltberm (vluchtstrook) naast de kantstreep, daarna gras
        _ribbon("Shoulders", ROAD_GRAY, [[0.0, L, -road_hw - 1.4, -road_hw, 0.03, 2.0], [0.0, L, road_hw, road_hw + 1.4, 0.03, 2.0]])
    else:
        # Nederlands wegprofiel: smalle band, rood fietspad, dan het trottoir
        var b0: float = road_hw + CURB_W
        var b1: float = b0 + BIKE_W
        _ribbon("Curbs", SIDEWALK, [[0.0, L, -b0, -road_hw, 0.07, 2.0], [0.0, L, road_hw, b0, 0.07, 2.0]])
        _ribbon("Bike paths", BIKE_RED, [[0.0, L, -b1, -b0, 0.065, 2.0], [0.0, L, b0, b1, 0.065, 2.0]])
        _ribbon("Sidewalks", SIDEWALK, [[0.0, L, -b1 - WALK_W, -b1, 0.07, 2.0], [0.0, L, b1, b1 + WALK_W, 0.07, 2.0]])
    _ribbon("Edge lines", LINE, [[0.0, L, -road_hw + 0.5, -road_hw + 0.65, 0.045, 2.0], [0.0, L, road_hw - 0.65, road_hw - 0.5, 0.045, 2.0]])
    var dashes: Array = []
    var s := 4.0
    while s < L - 6.0:
        if dual:
            # rijstrookstrepen tussen de twee stroken van elke rijbaan
            var mid: float = (1.2 + road_hw - 0.6) * 0.5
            dashes.append([s, s + 5.0, mid - 0.1, mid + 0.1, 0.045, 1.0])
            dashes.append([s, s + 5.0, -mid - 0.1, -mid + 0.1, 0.045, 1.0])
        else:
            dashes.append([s, s + 5.0, -0.12, 0.12, 0.045, 1.0])
        s += 12.0
    _ribbon("Lane dashes", LINE, dashes)
    if dual:
        _ribbon("Median", Color("6f8a52"), [[0.0, L, -1.2, 1.2, 0.05, 2.0]])
        _ribbon("Median lines", LINE, [[0.0, L, -1.45, -1.3, 0.045, 2.0], [0.0, L, 1.3, 1.45, 0.045, 2.0]])
        _guardrail()

# stalen vangrail op de middenberm: aan beide kanten een verzinkte geleiderail op paaltjes
# (naar jouw foto's van de Buitenring), met per stuk een onzichtbaar botsblok zodat je niet
# de tegenrijbaan op kunt
func _guardrail() -> void:
    var seg := 10.0
    var s := 0.0
    while s < route.length - 1.0:
        var e: float = minf(s + seg, route.length)
        var a: Vector3 = route.pos_at(s)
        var b: Vector3 = route.pos_at(e)
        var body := StaticBody3D.new()
        body.name = "Guardrail"
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(1.3, 0.9, a.distance_to(b) + 0.3)
        cs.shape = shape
        body.add_child(cs)
        body.transform = Transform3D(Basis.looking_at((b - a).normalized(), Vector3.UP), (a + b) * 0.5 + Vector3(0, 0.45, 0))
        add_child(body)
        s = e
    var steel := Kit.two_sided_mat(Color("8e959a"))
    route_band("Median rail", 0.0, route.length, -0.62, 0.45, -0.62, 0.8, steel)
    route_band("Median rail", 0.0, route.length, 0.62, 0.45, 0.62, 0.8, steel)
    route_posts("Median rail posts", 0.0, route.length, [-0.5, 0.5], 2.0, Vector3(0.1, 0.75, 0.1), Color("8f979c"))

# Plekken langs de rand waar geen bord of flitser mag staan (bv. een vluchthaven).
func roadside_blocked(_s: float) -> bool:
    return false

# Strook langs de route tussen twee lijnen (offset o, hoogte h): een muur, talud of vlak.
# ramp: aan beide uiteinden lopen de hoogtes over zoveel meter op vanaf nul.
func route_band(n: String, s0: float, s1: float, o0: float, h0: float, o1: float, h1: float,
        mat: Material, collide := false, ramp := 0.0, step := 3.0) -> MeshInstance3D:
    var t: Array = []
    var s: float = s0
    while s < s1 - 0.01:
        var e: float = minf(s + step, s1)
        var ka: float = 1.0 if ramp <= 0.0 else clampf(minf(s - s0, s1 - s) / ramp, 0.0, 1.0)
        var kb: float = 1.0 if ramp <= 0.0 else clampf(minf(e - s0, s1 - e) / ramp, 0.0, 1.0)
        var pa: Vector3 = route.pos_at(s)
        var pb: Vector3 = route.pos_at(e)
        var ra: Vector3 = route.right_at(s)
        var rb: Vector3 = route.right_at(e)
        Kit._quad(t, pa + ra * o0 + Vector3(0, h0 * ka, 0), pb + rb * o0 + Vector3(0, h0 * kb, 0),
            pb + rb * o1 + Vector3(0, h1 * kb, 0), pa + ra * o1 + Vector3(0, h1 * ka, 0))
        s = e
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = Kit._mesh_from(t, mat)
    add_child(mi)
    if collide:
        var shape := ConcavePolygonShape3D.new()
        shape.backface_collision = true
        var faces := PackedVector3Array()
        for v in t:
            faces.append(v)
        shape.set_faces(faces)
        var body := StaticBody3D.new()
        body.name = n + " body"
        var cs := CollisionShape3D.new()
        cs.shape = shape
        body.add_child(cs)
        add_child(body)
    return mi

# Paaltjes langs de route op vaste afstanden (multimesh), op de gegeven offsets.
func route_posts(n: String, s0: float, s1: float, offsets: Array, every: float, size: Vector3, color: Color) -> void:
    var xf: Array = []
    var s: float = s0
    while s < s1:
        for o in offsets:
            xf.append(Transform3D(route.basis_at(s) * Basis.from_scale(size), route.pos_at(s) + route.right_at(s) * float(o) + Vector3(0, size.y * 0.5, 0)))
        s += every
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    _multimesh(n, box, xf, Kit.mat(color))

# ---------------------------------------------------------------- bebouwing
func _excluded(p: Vector3, radius: float) -> bool:
    for r in exclusions:
        if r.grow(radius).has_point(Vector2(p.x, p.z)):
            return true
    return false

func build_streetscape(skip_start := 0.0, skip_end := 0.0) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var kinds: Array = []
    var weights: Array = []
    var total := 0.0
    for k in street_mix:
        kinds.append(k)
        weights.append(float(street_mix[k]))
        total += float(street_mix[k])
    # voorgevel op deze afstand van de wegas: net achter de stoep, met tuin of stoep ervoor
    var walk_edge: float = road_hw + CURB_W + BIKE_W + WALK_W + 0.2
    for side in [-1.0, 1.0]:
        var s := skip_start + 6.0 + rng.randf_range(0.0, 8.0)
        var tries := 0
        while s < route.length - skip_end:
            # type kiezen volgens de mix van dit level; past het niet, probeer dan iets kleiners
            var pick: float = rng.randf() * total
            var kind: String = kinds[0]
            for i in kinds.size():
                pick -= float(weights[i])
                if pick <= 0.0:
                    kind = kinds[i]
                    break
            if tries > 0:
                kind = "detached" if kinds.has("detached") or tries > 1 else kind
            var inf: Dictionary = Houses.info(kind)
            var w: float = inf["w"]
            var sc: float = s + w * 0.5
            if sc + w * 0.5 > route.length - skip_end:
                break
            var front: float = walk_edge + float(inf["front"])
            if _plot_fits(sc, side, w, float(inf["d"]), front, walk_edge):
                _add_plot(kind, inf, sc, side, front, rng)
                s += w + rng.randf_range(1.5, 5.0)
                # af en toe een open plek (pleintje); daar kan een muurschildering komen
                if murals > 0.0 and rng.randf() < 0.15:
                    s += rng.randf_range(9.0, 14.0)
                tries = 0
            else:
                tries += 1
                if tries > 2:
                    s += 6.0
                    tries = 0

    # lantaarnpalen langs de stoep
    var s := skip_start + 6.0
    while s < route.length - skip_end:
        for side in [-1.0, 1.0]:
            var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * (road_hw + (2.4 if dual else CURB_W + BIKE_W + 1.6))
            if _excluded(p, 1.0) or route.distance_to(p) < road_hw + 1.5:
                continue
            lamppost(p, -route.right_at(s) * side)
        s += 34.0

# Past een huis van breedte w en diepte d op afstand sc (midden) aan deze kant? De hoeken
# moeten vrij van de weg blijven (ook in de binnenbocht) en buiten bezienswaardigheden.
func _plot_fits(sc: float, side: float, w: float, d: float, front: float, walk_edge: float) -> bool:
    var c: Vector3 = route.pos_at(sc)
    var fwd: Vector3 = route.dir_at(sc)
    var rt: Vector3 = route.right_at(sc) * side
    var mid: Vector3 = c + rt * (front + d * 0.5)
    if _excluded(mid, maxf(w, d) * 0.5):
        return false
    for a in [-w * 0.5, 0.0, w * 0.5]:
        for o in [walk_edge, front, front + d]:
            var p: Vector3 = c + fwd * a + rt * o
            if route.distance_to(p) < o - 1.2 or _excluded(p, 1.0):
                return false
    return true

# Een huis neerzetten: nu alleen een botsvorm (met een onzichtbare voetafdruk, zodat een
# kruising hem nog kan weghalen); de echte huizen komen er in finish_streetscape() in één
# keer bij, als MultiMesh per type.
func _add_plot(kind: String, inf: Dictionary, sc: float, side: float, front: float, rng: RandomNumberGenerator) -> void:
    var c: Vector3 = route.pos_at(sc)
    var to_road: Vector3 = -route.right_at(sc) * side
    to_road = Vector3(to_road.x, 0, to_road.z).normalized()
    var x_axis: Vector3 = Vector3.UP.cross(to_road)
    var origin: Vector3 = c - to_road * front
    origin.y = c.y
    var xf := Transform3D(Basis(x_axis, Vector3.UP, to_road), origin)
    var w: float = inf["w"]
    var d: float = inf["d"]
    var h: float = inf["h"]
    var body := StaticBody3D.new()
    body.name = "Street building"
    body.transform = xf
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(w, h, d)
    cs.shape = shape
    cs.position = Vector3(0, h * 0.5, -d * 0.5)
    body.add_child(cs)
    # bomen in de voortuin botsen ook (het huisblok houdt op bij de gevel)
    for t in inf.get("trees", []):
        var tcs := CollisionShape3D.new()
        var tshape := CylinderShape3D.new()
        tshape.radius = 0.3
        tshape.height = 3.0
        tcs.shape = tshape
        tcs.position = Vector3(t.x, 1.5, t.y)
        body.add_child(tcs)
    var foot := MeshInstance3D.new()
    var fm := BoxMesh.new()
    var fd: float = d + float(inf["front"])
    fm.size = Vector3(w, h, fd)
    foot.mesh = fm
    foot.position = Vector3(0, h * 0.5, -d + fd * 0.5)
    foot.visible = false
    body.add_child(foot)
    add_child(body)
    var walls: Array = inf["walls"]
    var roofs: Array = inf["roofs"]
    plots.append([body, kind, xf, walls[rng.randi_range(0, walls.size() - 1)], roofs[rng.randi_range(0, roofs.size() - 1)],
        0.0, side, sc])
    town_s.append(sc)

# Haal huizen (nog niet als MultiMesh neergezet) weg waarvan het perceel, tuin incl., binnen
# margin meter van p ligt: bv. waar een plaatsnaambord komt.
func _clear_plots_at(p: Vector3, margin: float) -> void:
    for i in range(plots.size() - 1, -1, -1):
        var pl: Array = plots[i]
        var inf: Dictionary = Houses.info(String(pl[1]))
        var q: Vector3 = (pl[2] as Transform3D).affine_inverse() * p
        if absf(q.x) < float(inf["w"]) * 0.5 + margin and q.z > -float(inf["d"]) - margin and q.z < float(inf["front"]) + margin:
            if is_instance_valid(pl[0]):
                pl[0].queue_free()
            plots.remove_at(i)

# Na de kruisingen (die huizen op hun zijweg weghalen): alle overgebleven huizen per type
# als MultiMesh, in vakken van CHUNK meter.
func finish_streetscape() -> void:
    var left: Array = []
    for p in plots:
        var body: Node = p[0]
        if is_instance_valid(body) and not body.is_queued_for_deletion():
            left.append(p)
    _choose_murals(left)
    var by_kind := {}
    for p in left:
        var body: Node = p[0]
        for k in body.get_children():
            if k is MeshInstance3D:
                k.free()
        var key := "%s|%d|%d" % [p[1], floori(p[2].origin.x / CHUNK), floori(p[2].origin.z / CHUNK)]
        if not by_kind.has(key):
            by_kind[key] = [p[1], []]
        by_kind[key][1].append(p)
    for key in by_kind:
        var list: Array = by_kind[key][1]
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        # instancekleur wit: anders vermenigvuldigt de renderer de vertexkleuren met 0
        mm.use_colors = true
        mm.use_custom_data = true
        mm.mesh = Houses.mesh(String(by_kind[key][0]))
        mm.instance_count = list.size()
        for i in range(list.size()):
            mm.set_instance_transform(i, list[i][2])
            # gevelkleur in rgb, nummer van de dakkleur in a
            var wc: Color = list[i][3]
            wc.a = float(Houses.roof_palette().find(list[i][4]))
            mm.set_instance_custom_data(i, wc)
            mm.set_instance_color(i, Color.WHITE)
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "Houses " + String(by_kind[key][0])
        mmi.multimesh = mm
        add_child(mmi)
    _murals(by_kind)
    plots.clear()

# Kies muurschilderingen pas als alles staat (kruisingen en borden hebben dan al huizen
# weggehaald): alleen op een flat of winkelpand waarvan de zijgevel naar het aankomende
# verkeer echt vrij staat (open plek van minstens 7 m ervoor, geen bezienswaardigheid), en
# niet te dicht bij elkaar.
func _choose_murals(list: Array) -> void:
    if murals <= 0.0:
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value * 31 + 7
    var cands: Array = []
    for side in [-1.0, 1.0]:
        var row: Array = []
        for p in list:
            if float(p[6]) == side:
                row.append(p)
        row.sort_custom(func(a, b): return float(a[7]) < float(b[7]))
        for i in range(row.size()):
            var p: Array = row[i]
            if not MURAL_KINDS.has(String(p[1])):
                continue
            var inf: Dictionary = Houses.info(String(p[1]))
            var start: float = float(p[7]) - float(inf["w"]) * 0.5
            var gap := INF
            if i > 0:
                var q: Array = row[i - 1]
                gap = start - (float(q[7]) + float(Houses.info(String(q[1]))["w"]) * 0.5)
            if gap < 7.0:
                continue
            # vlak voor de muur geen bezienswaardigheid (die zou hem verbergen)
            var look: float = start - minf(gap, 20.0) * 0.5
            var o: float = road_hw + CURB_W + BIKE_W + WALK_W + float(inf["front"]) + float(inf["d"]) * 0.5
            if in_landmark(route.pos_at(look) + route.right_at(look) * side * o):
                continue
            cands.append(p)
    cands.sort_custom(func(a, b): return float(a[7]) < float(b[7]))
    var last := -INF
    for p in cands:
        if float(p[7]) - last < 110.0 or rng.randf() > murals:
            continue
        p[5] = rng.randf_range(0.01, 0.99)
        last = float(p[7])

# Muurschilderingen (mural.gdshader) op de zijgevel die naar het aankomende verkeer kijkt:
# één vlak per muur, samen in één MultiMesh per vak.
func _murals(by_kind: Dictionary) -> void:
    var cells := {}
    for key in by_kind:
        for p in by_kind[key][1]:
            if float(p[5]) <= 0.0:
                continue
            var kind: String = p[1]
            var inf: Dictionary = Houses.info(kind)
            var w: float = inf["w"]
            var d: float = inf["d"]
            var side: float = p[6]
            # kant met de muur naar -s (naar jou toe als je aan komt rijden): rechts +X, links -X
            var sgn: float = side
            var h: float = float(MURAL_KINDS[kind][0 if sgn < 0.0 else 1])
            var mh: float = h - 0.8
            var md: float = d - 0.8
            var b := Basis.from_scale(Vector3(1.0, mh, md))
            if sgn < 0.0:
                b = Basis(Vector3.UP, PI) * b
            var local := Transform3D(b, Vector3(sgn * (w * 0.5 + 0.05), 0.4, -d * 0.5))
            var t: Transform3D = (p[2] as Transform3D) * local
            var ck := Vector2i(floori(t.origin.x / CHUNK), floori(t.origin.z / CHUNK))
            if not cells.has(ck):
                cells[ck] = []
            cells[ck].append([t, Color(float(p[5]), md / mh / 4.0, 0.0, 0.0)])
    if cells.is_empty():
        return
    # vlak in het YZ-vlak dat naar +X kijkt, y 0..1, z -0,5..0,5
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_normal(Vector3.RIGHT)
    var corners := [[Vector3(0, 0, 0.5), Vector2(0, 1)], [Vector3(0, 0, -0.5), Vector2(1, 1)],
        [Vector3(0, 1, -0.5), Vector2(1, 0)], [Vector3(0, 1, 0.5), Vector2(0, 0)]]
    for i in [0, 2, 1, 0, 3, 2]:   # met de klok mee = voorkant in Godot
        st.set_uv(corners[i][1])
        st.set_normal(Vector3.RIGHT)
        st.add_vertex(corners[i][0])
    var quad: ArrayMesh = st.commit()
    var mat := ShaderMaterial.new()
    mat.shader = load("res://scripts/mural.gdshader")
    quad.surface_set_material(0, mat)
    for ck in cells:
        var list: Array = cells[ck]
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.use_colors = true
        mm.use_custom_data = true
        mm.mesh = quad
        mm.instance_count = list.size()
        for i in range(list.size()):
            mm.set_instance_transform(i, list[i][0])
            mm.set_instance_custom_data(i, list[i][1])
            mm.set_instance_color(i, Color.WHITE)
        var mmi := MultiMeshInstance3D.new()
        mmi.name = "Murals"
        mmi.multimesh = mm
        mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(mmi)

# Nederlandse lantaarnpaal: slanke lichtgrijze mast van 8 m met een zwarte voet en een
# paar naden, bovenop een platte, donkergrijze armatuur die iets schuin naar de weg wijst.
# De mast is massief: ertegenaan rijden kost snelheid.
func lamppost(p: Vector3, to_road: Vector3) -> void:
    lamp_points.append(p)
    var pole := Color("b7bbb8")
    Kit.cyl(self, "Lamppost", p + Vector3(0, 4.0, 0), 0.1, 0.065, 8.0, pole, 8, "y", true)
    Kit.cyl(self, "Lamppost foot", p + Vector3(0, 0.45, 0), 0.12, 0.12, 0.9, Color("26282a"), 8)
    for y in [3.2, 5.6]:
        Kit.cyl(self, "Lamppost joint", p + Vector3(0, y, 0), 0.095, 0.095, 0.08, Color("9ea29f"), 8)
    var d: Vector3 = Vector3(to_road.x, 0, to_road.z).normalized()
    var b := Basis.looking_at(d, Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(10.0))
    var head := Kit.box(self, "Lamp head", p + Vector3(0, 8.05, 0) + d * 0.32, Vector3(0.34, 0.11, 0.85), Color("4a4f52"))
    head.basis = b
    var lens := Kit.box(self, "Lamp lens", p + Vector3(0, 7.99, 0) + d * 0.36, Vector3(0.26, 0.02, 0.6), Color("e8e2ba"))
    lens.basis = b

func street_sign(text: String, pos: Vector3, color := Color("f4f5e9")) -> void:
    # Een bezienswaardigheid met een eigen checkpoint heeft geen los bordje nodig: de naam
    # staat al op de checkpointpoort. Daarom geen bordje als een deel van de tekst
    # (gescheiden door "/") overeenkomt met een checkpointnaam.
    if _matches_checkpoint(text):
        return
    Kit.box(self, "Sign post", pos - Vector3(0, 1.7, 0), Vector3(0.22, 3.5, 0.22), Color("d5d4cc"), true)
    var label := Label3D.new()
    label.text = text
    label.font_size = 82
    label.pixel_size = 0.009
    label.modulate = color
    label.outline_size = 7
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.position = pos
    add_child(label)

func _matches_checkpoint(text: String) -> bool:
    for part in text.split("/"):
        var p: String = part.strip_edges().to_upper()
        if p == "":
            continue
        for cp in checkpoints:
            var n: String = String(cp["name"]).to_upper()
            if n.contains(p) or p.contains(n):
                return true
    return false

# Plaatsnaambord (bebouwde kom) naast de weg op afstand s: blauw met witte rand en witte
# letters, zoals in Nederland. Eronder een kleiner bord: de dialectnaam (blauw, wit schrift),
# of met sub_white de wijk/kern in omgekeerde kleuren (wit, blauw schrift), zoals in Landgraaf.
func town_sign(text: String, s: float, side := 1.0, dialect := "", sub_white := false, post_color := Color("8a8f92")) -> void:
    var blue := Color("1d4f9c")
    var white := Color("f4f4ee")
    var f: Node3D = _town_sign_spot(s, side)[0]
    var top := 3.3
    for x in [-1.57, 1.57]:
        Kit.box(f, "Town sign post", Vector3(x, top * 0.5, -0.02), Vector3(0.14, top, 0.14), post_color, true)
    Kit.box(f, "Town sign border", Vector3(0, 2.75, 0), Vector3(3.0, 1.1, 0.06), white)
    Kit.box(f, "Town sign", Vector3(0, 2.75, 0.02), Vector3(2.86, 0.96, 0.04), blue)
    Kit.label(f, text, Vector3(0, 2.75, 0.05), _fit(text, 2.6, 0.008), white, 90)
    _sign_collider(f, Vector3(0, 1.65, 0), Vector3(3.0, 3.3, 0.2))
    if dialect != "":
        var bg: Color = white if sub_white else blue
        var ink: Color = blue if sub_white else white
        Kit.box(f, "Sub sign border", Vector3(0, 1.85, 0), Vector3(3.0, 0.62, 0.06), ink)
        Kit.box(f, "Sub sign", Vector3(0, 1.85, 0.02), Vector3(2.88, 0.5, 0.04), bg)
        Kit.label(f, dialect, Vector3(0, 1.88, 0.05), _fit(dialect, 2.5, 0.0048), ink, 90)

# ---------------------------------------------------------------- plaatsnaamborden per gemeente
# Elke gemeente heeft een eigen bord (naar jouw Street View-foto's, 25-11): een frame van
# palen met een dwarsbalk bovenop (geel, goud of blauw), en daarin van boven naar onder
# een stapel panelen. Een paneel is een Array:
#   ["name", ["Heerlen", "Heële"], skyline := false]  blauw bord met witte rand en tekst;
#        skyline: wit vlakje met een zwart silhouet (kerk, huizen, molen) eronder
#   ["limit", "50", "welkom !"]   wit paneel met een maximumsnelheidsbord (+ tekstje rechts)
#   ["zone", "30"]                wit paneel met een zone-bord
#   ["strip", "Welkom", inkt, achtergrond]   smalle strook met tekst
#   ["hills", "Simpelveld"]       wit paneel met golvende heuvels en de naam erboven
#   ["host"]                      Brunssum: blauw-wit paneel "Host to / Home to you!"
#   ["bars", n]                   n rood-wit-rode schrikhekken
const BOARD_W := 2.5
func town_board(s: float, side: float, frame_color: Color, panels: Array) -> void:
    var spot: Array = _town_sign_spot(s, side)
    var f: Node3D = spot[0]
    var blue := Color("1d4f9c")
    var white := Color("f4f4ee")
    var red := Color("d8322a")
    var black := Color("1a1a1a")
    var w := BOARD_W
    var y := 3.4          # bovenkant van de stapel
    for pn in panels:
        y -= _panel(f, pn, y, w, blue, white, red, black)
        y -= 0.04
    var top := 3.55
    # past de stapel niet (veel panelen), dan wordt het bord hoger in plaats van de grond in
    if y < 0.3:
        var dy: float = 0.3 - y
        for c in f.get_children():
            (c as Node3D).position.y += dy
        y += dy
        top += dy
    for x in [-w * 0.5 - 0.1, w * 0.5 + 0.1]:
        Kit.box(f, "Sign frame post", Vector3(x, top * 0.5, 0), Vector3(0.14, top, 0.14), frame_color, true)
    # de borden zelf botsen ook: een onzichtbaar blok tussen de palen, tot de grond (tussen
    # de palen door of onder het bord door rijden kan dan niet)
    _sign_collider(f, Vector3(0, top * 0.5, 0), Vector3(w + 0.34, top, 0.2))
    Kit.box(f, "Sign frame top", Vector3(0, top - 0.07, 0), Vector3(w + 0.34, 0.14, 0.14), frame_color)

# Onzichtbaar botsblok voor een bord (lokaal in f); de palen botsen al zelf.
func _sign_collider(f: Node3D, center: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = "Sign collider"
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    cs.shape = shape
    body.add_child(cs)
    body.position = center
    f.add_child(body)

# Bouwt één paneel met de bovenkant op hoogte y; geeft de hoogte terug.
func _panel(f: Node3D, pn: Array, y: float, w: float, blue: Color, white: Color, red: Color, black: Color) -> float:
    var kind: String = String(pn[0])
    match kind:
        "name":
            var lines: Array = pn[1]
            var sky: bool = pn.size() > 2 and bool(pn[2])
            var lh := 0.44
            var h: float = 0.22 + lh * float(lines.size()) + (0.62 if sky else 0.0)
            Kit.box(f, "Name sign", Vector3(0, y - h * 0.5, 0.0), Vector3(w, h, 0.05), blue)
            # witte binnenrand
            var bw: float = w - 0.1
            var bh: float = h - 0.1
            for e in [[0.0, bh * 0.5, bw, 0.035], [0.0, -bh * 0.5, bw, 0.035], [-bw * 0.5, 0.0, 0.035, bh], [bw * 0.5, 0.0, 0.035, bh]]:
                Kit.box(f, "Name sign rim", Vector3(e[0], y - h * 0.5 + e[1], 0.03), Vector3(e[2], e[3], 0.01), white)
            var longest := 0
            for l in lines:
                if not String(l).begins_with("gem."):
                    longest = maxi(longest, String(l).length())
            for i in range(lines.size()):
                var t: String = String(lines[i])
                var small: bool = t.begins_with("gem.")
                # niet hoger dan de regelafstand, niet breder dan het bord (hoofdletters zijn breed)
                var px: float = minf(_fit("x".repeat(longest), w - 0.7, 0.0062), lh * 0.85 / 90.0) * (0.7 if small else 1.0)
                Kit.label(f, t, Vector3(0, y - 0.11 - lh * (float(i) + 0.5), 0.04), px, white, 90)
            if sky:
                _sign_skyline(f, y - h + 0.36, black, white)
            return h
        "limit":
            var h := 1.05
            Kit.box(f, "White panel", Vector3(0, y - h * 0.5, 0.0), Vector3(w, h, 0.05), Color("e8e8e4"))
            var has_text: bool = pn.size() > 2
            var cx: float = -0.35 if has_text else 0.0
            _speed_disc(f, Vector3(cx, y - h * 0.5, 0.03), 0.42, String(pn[1]), red, black)
            if has_text:
                Kit.label(f, String(pn[2]), Vector3(0.75, y - h * 0.5 + 0.12, 0.04), 0.0022, Color("2a2a2a"), 64)
            return h
        "zone":
            var h := 1.0
            Kit.box(f, "White panel", Vector3(0, y - h * 0.5, 0.0), Vector3(w, h, 0.05), Color("e8e8e4"))
            Kit.box(f, "Zone sign border", Vector3(0, y - h * 0.5, 0.03), Vector3(0.82, 0.92, 0.01), black)
            Kit.box(f, "Zone sign", Vector3(0, y - h * 0.5, 0.035), Vector3(0.76, 0.86, 0.01), white)
            Kit.label(f, "ZONE", Vector3(0, y - 0.17, 0.045), 0.0022, black, 64)
            _speed_disc(f, Vector3(0, y - h * 0.5 - 0.08, 0.04), 0.27, String(pn[1]), red, black)
            return h
        "strip":
            var h := 0.34
            var ink: Color = pn[2] if pn.size() > 2 else Color("2f7a6a")
            var bg: Color = pn[3] if pn.size() > 3 else Color("e8e8e4")
            Kit.box(f, "Strip", Vector3(0, y - h * 0.5, 0.0), Vector3(w, h, 0.05), bg)
            Kit.label(f, String(pn[1]), Vector3(0, y - h * 0.5, 0.035), _fit(String(pn[1]), w - 0.2, 0.0034), ink, 64)
            return h
        "hills":
            var h := 1.15
            Kit.box(f, "White panel", Vector3(0, y - h * 0.5, 0.0), Vector3(w, h, 0.05), Color("f2f2ee"))
            var yb: float = y - h + 0.03
            _hill(f, -w * 0.5, w * 0.5, yb, 0.3, 0.55, Color("e8d870"), 0.03)
            _hill(f, -w * 0.5, w * 0.5, yb, 0.75, 0.5, Color("b4c85a"), 0.034)
            _hill(f, -w * 0.5, w * 0.5, yb, -0.1, 0.36, Color("c8323c"), 0.038)
            _hill(f, -w * 0.5, w * 0.3, yb, -0.7, 0.24, Color("9a1e2a"), 0.042)
            Kit.label(f, String(pn[1]), Vector3(0, y - 0.38, 0.04), 0.0032, Color("a0283a"), 64)
            return h
        "host":
            var h := 1.2
            Kit.box(f, "Host panel", Vector3(0, y - h * 0.5, 0.0), Vector3(w, h, 0.05), Color("eef0f2"))
            Kit.box(f, "Host band", Vector3(0, y - h * 0.5, 0.03), Vector3(w, 0.62, 0.01), Color("4a8ad0"))
            Kit.cyl(f, "Globe", Vector3(-0.72, y - h * 0.5 - 0.05, 0.036), 0.48, 0.48, 0.01, Color("2a62b0"), 24, "z")
            Kit.label(f, "Host to", Vector3(0.38, y - h * 0.5 + 0.14, 0.045), 0.0034, white, 64)
            Kit.label(f, "Home to you!", Vector3(0.38, y - h * 0.5 - 0.14, 0.045), 0.0034, white, 64)
            return h
        "bars":
            var n: int = int(pn[1])
            var bh := 0.3
            var gap := 0.18
            for i in range(n):
                var cy: float = y - gap - bh * 0.5 - float(i) * (bh + gap)
                for k in range(3):
                    var c: Color = white if k == 1 else red
                    Kit.box(f, "Bar", Vector3((float(k) - 1.0) * w / 3.0, cy, 0.0), Vector3(w / 3.0, bh, 0.05), c)
            return float(n) * (bh + gap) + gap
    return 0.0

func _speed_disc(f: Node3D, c: Vector3, r: float, text: String, red: Color, black: Color) -> void:
    Kit.cyl(f, "Speed disc rim", c, r, r, 0.012, red, 28, "z")
    Kit.cyl(f, "Speed disc", c + Vector3(0, 0, 0.006), r * 0.76, r * 0.76, 0.012, Color("f8f8f4"), 28, "z")
    Kit.label(f, text, c + Vector3(0, 0, 0.016), r * 0.0105, black, 90)

# Golvende heuvel als vlak (sinusbult) tussen x0 en x1 op hoogte yb.
func _hill(f: Node3D, x0: float, x1: float, yb: float, peak_x: float, peak_h: float, color: Color, z: float) -> void:
    var t: Array = []
    var n := 16
    for i in range(n):
        var xa: float = lerpf(x0, x1, float(i) / float(n))
        var xb: float = lerpf(x0, x1, float(i + 1) / float(n))
        var ha: float = peak_h * maxf(0.0, cos((xa - peak_x) * 1.3))
        var hb: float = peak_h * maxf(0.0, cos((xb - peak_x) * 1.3))
        Kit._quad(t, Vector3(xa, yb, z), Vector3(xb, yb, z), Vector3(xb, yb + hb, z), Vector3(xa, yb + ha, z))
    var mi := MeshInstance3D.new()
    mi.name = "Sign hill"
    mi.mesh = Kit._mesh_from(t, Kit._two_sided(color))
    f.add_child(mi)

# Wit vlakje met een zwart silhouet: huizen, een kerk met spits en een molen.
func _sign_skyline(f: Node3D, cy: float, black: Color, white: Color) -> void:
    Kit.box(f, "Skyline panel", Vector3(0, cy, 0.03), Vector3(1.5, 0.52, 0.01), white)
    var base: float = cy - 0.2
    Kit.box(f, "Skyline ground", Vector3(0, base + 0.03, 0.04), Vector3(1.36, 0.06, 0.01), black)
    for e in [[-0.52, 0.22, 0.12], [-0.3, 0.12, 0.16], [0.02, 0.32, 0.14], [0.28, 0.2, 0.1]]:
        Kit.box(f, "Skyline house", Vector3(e[0], base + e[2] * 0.5, 0.04), Vector3(e[1], e[2], 0.01), black)
    Kit.box(f, "Skyline tower", Vector3(-0.38, base + 0.15, 0.04), Vector3(0.08, 0.3, 0.01), black)
    var sp := Kit.cyl(f, "Skyline spire", Vector3(-0.38, base + 0.37, 0.04), 0.05, 0.0, 0.15, black, 3, "y")
    sp.scale = Vector3(1, 1, 0.1)
    Kit.box(f, "Skyline mill", Vector3(0.48, base + 0.12, 0.04), Vector3(0.08, 0.22, 0.01), black)
    for a in [45.0, -45.0]:
        var bl := Kit.box(f, "Mill blade", Vector3(0.48, base + 0.24, 0.045), Vector3(0.36, 0.025, 0.01), black)
        bl.rotation_degrees.z = a

# Plek en oriëntatie voor een plaatsnaambord: naast het trottoir, niet achter een lantaarnpaal.
func _town_sign_spot(s: float, side: float) -> Array:
    var off: float = road_hw + (1.6 if dual else CURB_W + BIKE_W + WALK_W + 0.5)
    var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * off
    var tries := 0
    while near_lamp(p, 10.0) and tries < 24:
        s += 1.5
        p = route.pos_at(s) + route.right_at(s) * side * off
        tries += 1
    town_sign_s.append(s)
    _clear_plots_at(p, 4.0)
    var f := Node3D.new()
    f.name = "Town sign"
    f.position = p
    f.basis = route.basis_at(s)   # lokaal +Z kijkt naar het aankomende verkeer
    add_child(f)
    return [f, s]

# pixelgrootte zodat de tekst binnen de bordbreedte past (schatting: letter = 0,55 x lettergrootte)
func _fit(text: String, width: float, max_pixel: float) -> float:
    return minf(max_pixel, width / (float(text.length()) * 90.0 * 0.55))

# Heuvelland in een rechthoek (x, z): akkers met heggen, losse bomen en glooiingen
# aan de horizon. Laat een strook langs de route vrij.
func countryside(area: Rect2, seed_extra := 0, horizon_z := INF) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value + seed_extra
    var crops := [Color("6f8f4a"), Color("8aa257"), Color("b9a660"), Color("7d9a52"), Color("9c8a5c")]
    var n_fields := 0
    for i in range(int(area.get_area() / 4500.0)):
        var p := Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
        var sz := Vector3(rng.randf_range(40, 90), 0.04, rng.randf_range(40, 90))
        # de hele akker (met heg) moet naast de weg liggen
        if route.distance_to(p) < Vector2(sz.x, sz.z).length() * 0.5 + 12.0 or _excluded_hard(p):
            continue
        # elke akker een eigen hoogte (stapjes van 2 cm): overlappende akkers op precies
        # dezelfde hoogte gaan knipperen (z-fighting), vooral op telefoons
        n_fields += 1
        Kit.box(self, "Field", p + Vector3(0, 0.01 + float(n_fields % 7) * 0.02, 0), sz, crops[rng.randi_range(0, crops.size() - 1)])
        Kit.box(self, "Hedge", p + Vector3(0, 0.7, sz.z * 0.5), Vector3(sz.x, 1.4, 1.2), Color("3f5a32"))
    var trunks: Array[Transform3D] = []
    var crowns: Array[Transform3D] = []
    for i in range(int(area.get_area() / 1600.0)):
        var p := Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
        var d: float = route.distance_to(p)
        if d < 14.0 or _excluded_hard(p):
            continue
        var h: float = rng.randf_range(6.0, 10.0)
        trunks.append(Transform3D(Basis().scaled(Vector3(0.8, h * 0.7, 0.8)), p + Vector3(0, h * 0.35, 0)))
        crowns.append(Transform3D(Basis().scaled(Vector3(h * 0.35, h * 0.3, h * 0.35)), p + Vector3(0, h * 0.8, 0)))
        if d < 40.0:
            var body := StaticBody3D.new()
            var cs := CollisionShape3D.new()
            var shape := CylinderShape3D.new()
            shape.radius = 0.3
            shape.height = 5.0
            cs.shape = shape
            body.add_child(cs)
            body.position = p + Vector3(0, 2.5, 0)
            add_child(body)
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.25
    trunk_mesh.bottom_radius = 0.3
    trunk_mesh.height = 1.0
    trunk_mesh.radial_segments = 6
    trunk_mesh.rings = 1
    _multimesh("Tree trunks", trunk_mesh, trunks, Kit.mat(Color("5b4634")))
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.0
    crown_mesh.height = 2.0
    crown_mesh.radial_segments = 8
    crown_mesh.rings = 4
    _multimesh("Tree crowns", crown_mesh, crowns, Kit.mat(Color("4f6e3a")))
    if horizon_z != INF:
        for i in range(8):
            var p := Vector3(rng.randf_range(area.position.x - 100, area.end.x + 100), 0, horizon_z + rng.randf_range(0, 250))
            var r: float = rng.randf_range(120, 220)
            Kit.cyl(self, "Hill", p + Vector3(0, 12.0, 0), r, r * 0.55, 24.0, Color("5f7d47"), 20)

# landmarks (niet de grote landschapsvlakken) blijven vrij van akkers en bomen
var hard_exclusions: Array[Rect2] = []
var pits: Array[Rect2] = []        # gaten in de grond (wereld-xz), bv. een verlaagde vijver
# schuine open stroken (bv. de aanvliegroute door het bos): [a, b, halve breedte]
var clear_strips: Array = []
func _excluded_hard(p: Vector3) -> bool:
    for r in hard_exclusions:
        if r.has_point(Vector2(p.x, p.z)):
            return true
    for c in clear_strips:
        var a: Vector3 = c[0]
        var b: Vector3 = c[1]
        var ab := Vector2(b.x - a.x, b.z - a.z)
        var ap := Vector2(p.x - a.x, p.z - a.z)
        var t: float = clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
        if (ap - ab * t).length() < float(c[2]):
            return true
    return false

# Bos in een rechthoek: dichte loofbomen, donkere bosbodem. Laat de weg vrij.
# Getekend met MultiMesh (één draw call per soort); alleen bomen dicht bij de weg botsen.
func forest(area: Rect2, per_tree := 260.0, seed_extra := 0) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value + seed_extra
    Kit.box(self, "Forest floor", Vector3(area.get_center().x, 0.0, area.get_center().y), Vector3(area.size.x, 0.01, area.size.y), Color("3f5531"))
    var colors := [Color("3b5a2e"), Color("4a6b36"), Color("2f4a28"), Color("566f3a")]
    var trunks: Array[Transform3D] = []
    var crowns: Array = [[], [], [], []]
    for i in range(int(area.get_area() / per_tree)):
        var p := Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
        var d: float = route.distance_to(p)
        if d < 13.0 or _excluded_hard(p):
            continue
        var h: float = rng.randf_range(12.0, 22.0)
        trunks.append(Transform3D(Basis().scaled(Vector3(1.0, h * 0.8, 1.0)), p + Vector3(0, h * 0.4, 0)))
        crowns[rng.randi_range(0, 3)].append(Transform3D(Basis().scaled(Vector3(h * 0.3, h * 0.32, h * 0.3)), p + Vector3(0, h * 0.82, 0)))
        if d < 40.0:
            var body := StaticBody3D.new()
            var cs := CollisionShape3D.new()
            var shape := CylinderShape3D.new()
            shape.radius = 0.4
            shape.height = 6.0
            cs.shape = shape
            body.add_child(cs)
            body.position = p + Vector3(0, 3.0, 0)
            add_child(body)
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.25
    trunk_mesh.bottom_radius = 0.35
    trunk_mesh.height = 1.0
    trunk_mesh.radial_segments = 6
    trunk_mesh.rings = 1
    _multimesh("Forest trunks", trunk_mesh, trunks, Kit.mat(Color("4e3d2e")))
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.0
    crown_mesh.height = 2.0
    crown_mesh.radial_segments = 8
    crown_mesh.rings = 4
    for k in range(4):
        _multimesh("Forest crowns", crown_mesh, crowns[k], Kit.mat(colors[k]))
    # bosrand: een dichte strook struiken en jonge bomen vlak achter de berm, in groen en
    # geelgroen (zoals langs de weg door de Schinveldse bossen)
    var shrub_cols := [Color("4f6e34"), Color("6d8a3a"), Color("8f9a3e"), Color("5b7a3c")]
    var shrubs: Array = [[], [], [], []]
    var s := 0.0
    while s < route.length:
        for side in [-1.0, 1.0]:
            var off: float = road_hw + CURB_W + BIKE_W + WALK_W + 1.5 + rng.randf_range(0.0, 4.0)
            var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * off
            if not area.has_point(Vector2(p.x, p.z)) or _excluded_hard(p):
                continue
            if route.distance_to(p) < off - 0.5:
                continue
            var hh: float = rng.randf_range(2.2, 5.5)
            var ww: float = rng.randf_range(2.0, 3.6)
            shrubs[rng.randi_range(0, 3)].append(Transform3D(Basis().scaled(Vector3(ww, hh * 0.5, ww)), p + Vector3(0, hh * 0.45, 0)))
        s += 2.6
    for k in range(4):
        _multimesh("Forest edge", crown_mesh, shrubs[k], Kit.mat(shrub_cols[k]))

const CHUNK := 160.0

func _multimesh(n: String, mesh: Mesh, xforms: Array, mat: Material) -> void:
    # Opgedeeld in vakken van CHUNK meter: dan tekent de grafische chip alleen de vakken die
    # in beeld zijn (en binnen het schaduwbereik), in plaats van steeds het hele bos.
    var cells := {}
    for x in xforms:
        var t: Transform3D = x
        var key := Vector2i(floori(t.origin.x / CHUNK), floori(t.origin.z / CHUNK))
        if not cells.has(key):
            cells[key] = []
        cells[key].append(t)
    for key in cells:
        var list: Array = cells[key]
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = mesh
        mm.instance_count = list.size()
        for i in range(list.size()):
            mm.set_instance_transform(i, list[i])
        var mmi := MultiMeshInstance3D.new()
        mmi.name = n
        mmi.multimesh = mm
        mmi.material_override = mat
        add_child(mmi)

# Limburgs wegkruis tussen knotlinden, naar jouw foto (20-11): een grijs stenen kruis met
# klaverblad-uiteinden op een getrapte sokkel, met een groene krans met rode en witte
# bloemen; links en rechts een oude knotlinde die zich splitst in dikke, rechtopstaande
# takken vol jong lichtgroen uitlopend blad, verder rechts een linde als rechte zuil.
# Een grasveldje met een paar paaltjes. Lokale ruimte: +Z = naar de weg, kruis langs X.
func wayside_cross(pos: Vector3, yaw_deg := 0.0) -> void:
    var f := Node3D.new()
    f.name = "Wayside cross"
    f.position = pos
    f.rotation_degrees.y = yaw_deg
    add_child(f)
    var stone := Color("a4a29a")
    Kit.box(f, "Cross lawn", Vector3(1.0, 0.02, 0), Vector3(16.0, 0.04, 8.0), Color("6f9a4c"))
    # getrapte sokkel en zuil
    Kit.box(f, "Cross plinth", Vector3(0, 0.12, 0), Vector3(2.0, 0.24, 1.6), stone, true)
    Kit.box(f, "Cross step", Vector3(0, 0.36, 0), Vector3(1.3, 0.24, 1.0), stone)
    Kit.box(f, "Cross pedestal", Vector3(0, 1.05, 0), Vector3(0.75, 1.15, 0.55), stone)
    Kit.box(f, "Cross pedestal cap", Vector3(0, 1.7, 0), Vector3(0.95, 0.16, 0.7), stone)
    Kit.box(f, "Cross shaft", Vector3(0, 2.75, 0), Vector3(0.3, 2.0, 0.24), stone)
    Kit.box(f, "Cross beam", Vector3(0, 3.35, 0), Vector3(1.4, 0.28, 0.24), stone)
    # klaverblad-uiteinden (drie bolletjes per arm)
    for e in [Vector3(-0.78, 3.35, 0), Vector3(0.78, 3.35, 0), Vector3(0, 3.95, 0)]:
        Kit.box(f, "Cross end", e, Vector3(0.36, 0.36, 0.26), stone)
    Kit.box(f, "Cross plaque", Vector3(0, 1.1, 0.29), Vector3(0.45, 0.55, 0.03), Color("8a877f"))
    # krans met bloemen rond het kruishart
    var wreath := MeshInstance3D.new()
    wreath.name = "Wreath"
    var tm := TorusMesh.new()
    tm.inner_radius = 0.42
    tm.outer_radius = 0.58
    tm.rings = 16
    tm.ring_segments = 8
    wreath.mesh = tm
    wreath.material_override = Kit.mat(Color("2f5a2c"))
    wreath.position = Vector3(0, 3.25, 0.2)
    wreath.rotation_degrees.x = 90.0
    f.add_child(wreath)
    for k in range(10):
        var a: float = float(k) * TAU / 10.0
        Kit.box(f, "Wreath flower", Vector3(cos(a) * 0.5, 3.25 + sin(a) * 0.5, 0.3), Vector3(0.14, 0.14, 0.1), Color("c8302c") if k % 2 == 0 else Color("f2f0ea"))
    # knotlinden
    _pollard(f, Vector3(-3.4, 0, -0.4), [Vector3(-2.4, 4.0, 0.2), Vector3(1.9, 4.4, -0.2)], 0.62, 2.0)
    _pollard(f, Vector3(3.6, 0, -0.6), [Vector3(-0.7, 5.0, 0.0), Vector3(0.9, 4.6, 0.3), Vector3(0.2, 3.6, -0.6)], 0.5, 2.4)
    _pollard(f, Vector3(7.0, 0, 0.2), [], 0.38, 5.0)
    # houten paaltjes en een stenen paaltje vooraan
    for x in [-5.6, -2.0, 1.8, 5.0]:
        Kit.box(f, "Fence post", Vector3(x, 0.55, -3.6), Vector3(0.14, 1.1, 0.14), Color("6a5a48"))
    Kit.box(f, "Stone post", Vector3(7.8, 0.4, 2.6), Vector3(0.35, 0.8, 0.35), Color("cfcac0"))
    Kit.box(f, "Wood post", Vector3(-1.6, 0.4, 3.4), Vector3(0.3, 0.8, 0.3), Color("7a6a58"))

# Knotlinde: dikke stam, die zich splitst in rechtopstaande takken (limbs, relatief t.o.v.
# de stamtop), met knobbelige koppen en overal jonge lichtgroene scheuten.
func _pollard(f: Node3D, base: Vector3, limbs: Array, r: float, trunk_h: float) -> void:
    var bark := Color("7a7466")
    var shoot_cols := [Color("a8c84a"), Color("8db43c"), Color("c2d65a")]
    Kit.cyl(f, "Pollard trunk", base + Vector3(0, trunk_h * 0.5, 0), r * 0.85, r, trunk_h, bark, 10, "y", true)
    var top: Vector3 = base + Vector3(0, trunk_h, 0)
    var heads: Array = []
    if limbs.is_empty():
        heads.append(top)
        Kit.cyl(f, "Pollard knob", top + Vector3(0, 0.15, 0), r * 1.05, r * 0.9, 0.5, bark, 10)
    for l in limbs:
        var e: Vector3 = top + l
        var mid: Vector3 = top + Vector3(l.x * 0.55, l.y * 0.45, l.z * 0.55)
        Kit.beam(f, "Pollard limb", top, mid, r * 1.0, bark)
        Kit.beam(f, "Pollard limb", mid, e, r * 0.75, bark)
        heads.append(e)
        # scheuten langs de tak
        for k in range(4):
            var p: Vector3 = top.lerp(e, 0.3 + float(k) * 0.17) + Vector3(0.25 if k % 2 == 0 else -0.25, 0, 0.2)
            _shoot_blob(f, p, 0.32 + float(k % 2) * 0.12, shoot_cols[k % 3])
    for h in heads:
        Kit.cyl(f, "Pollard head", h + Vector3(0, 0.15, 0), r * 0.75, r * 0.9, 0.4, bark, 8)
        for k in range(6):
            var a: float = float(k) * TAU / 6.0
            _shoot_blob(f, h + Vector3(cos(a) * 0.35, 0.45 + float(k % 2) * 0.25, sin(a) * 0.35), 0.38, shoot_cols[k % 3])
    # scheuten onderaan de stam
    _shoot_blob(f, base + Vector3(0.4, 0.3, 0.4), 0.45, shoot_cols[1])
    _shoot_blob(f, base + Vector3(-0.3, 1.2, 0.5), 0.35, shoot_cols[0])

func _shoot_blob(f: Node3D, p: Vector3, size: float, color: Color) -> void:
    var mi := MeshInstance3D.new()
    mi.name = "Pollard shoots"
    var sm := SphereMesh.new()
    sm.radius = 1.0
    sm.height = 1.6
    sm.radial_segments = 7
    sm.rings = 4
    mi.mesh = sm
    mi.material_override = Kit.mat(color)
    mi.scale = Vector3(size, size, size)
    mi.position = p
    f.add_child(mi)

# Zet een landmark naast de weg op afstand s, `offset` meter van de wegas (side 1 = rechts,
# -1 = links), met de lokale +Z-kant (de voorkant) naar de weg. half_size = halve maat van het
# terrein voor de vrije zone (geen akkers, bomen of bebouwing).
func place_beside(landmark: Node3D, s: float, side: float, offset: float, half_size: Vector2) -> Node3D:
    var right: Vector3 = route.right_at(s)
    var p: Vector3 = route.pos_at(s) + right * side * offset
    var to_road: Vector3 = -right * side
    place(landmark, p, rad_to_deg(atan2(to_road.x, to_road.z)))
    var r := Rect2(p.x - half_size.x, p.z - half_size.y, half_size.x * 2.0, half_size.y * 2.0)
    hard_exclusions.append(r)
    exclusions.append(r)
    return landmark

# Geen huizen, bomen of akkers op een rechthoek in de lokale ruimte van een bezienswaardigheid.
func exclude_local(lm: Node3D, local: Rect2) -> void:
    var lo := Vector2(INF, INF)
    var hi := Vector2(-INF, -INF)
    for c in [local.position, Vector2(local.end.x, local.position.y), local.end, Vector2(local.position.x, local.end.y)]:
        var w: Vector3 = lm.transform * Vector3(c.x, 0, c.y)
        lo = Vector2(minf(lo.x, w.x), minf(lo.y, w.z))
        hi = Vector2(maxf(hi.x, w.x), maxf(hi.y, w.z))
    var r := Rect2(lo, hi - lo)
    exclusions.append(r)
    hard_exclusions.append(r)

# Gat in de grond onder een bezienswaardigheid: rect in de lokale xz-ruimte van de node.
func add_pit(landmark: Node3D, local: Rect2) -> void:
    var lo := Vector2(INF, INF)
    var hi := Vector2(-INF, -INF)
    for c in [local.position, Vector2(local.end.x, local.position.y), local.end, Vector2(local.position.x, local.end.y)]:
        var w: Vector3 = landmark.transform * Vector3(c.x, 0, c.y)
        lo = Vector2(minf(lo.x, w.x), minf(lo.y, w.z))
        hi = Vector2(maxf(hi.x, w.x), maxf(hi.y, w.z))
    pits.append(Rect2(lo, hi - lo))

# Rondjes: de laatste "checkpoint" is de start/finishlijn, net voor het startpunt.
func finish_line(n := 3) -> void:
    laps = n
    checkpoints.append({"at": route.pos_at(route.length - 6.0), "name": "START / FINISH"})

# Mag een computercoureur op afstand s de linkerstrook (tegenrijbaan) op?
func can_overtake(s: float) -> bool:
    for r in no_overtake:
        if s >= float(r[0]) - 30.0 and s <= float(r[1]):
            return false
    return true

# Staat er binnen r meter (horizontaal) van p een lantaarnpaal?
func near_lamp(p: Vector3, r: float) -> bool:
    for q in lamp_points:
        if Vector2(q.x - p.x, q.z - p.z).length() < r:
            return true
    return false

# Ligt afstand s in de bebouwde kom (straatbebouwing binnen 40 m)?
func is_town(s: float) -> bool:
    for t in town_s:
        var d: float = absf(float(t) - s)
        if route.closed:
            d = minf(d, route.length - d)
        if d < 40.0:
            return true
    return false

# Ligt p binnen het terrein van een bezienswaardigheid (een kleine vrije zone, geen landschap)?
func in_landmark(p: Vector3) -> bool:
    for r in exclusions:
        if r.get_area() < 60000.0 and r.has_point(Vector2(p.x, p.z)):
            return true
    for r in hard_exclusions:
        if r.get_area() < 60000.0 and r.has_point(Vector2(p.x, p.z)):
            return true
    return false

# Bomen botsen (27-11): elke boomstam zonder eigen botsvorm krijgt een onzichtbare cilinder.
# Losse stammen (MeshInstance met "trunk" in de naam) altijd; stammen in een MultiMesh (bos,
# landschap) tot TREE_SOLID_DIST van de route, voor zover daar nog geen botsvorm staat.
# Struiken en kruinen blijven doorrijdbaar. Wordt aangeroepen voordat StaticMerge de losse
# onderdelen samenvoegt (dan zijn de namen weg). Geeft het aantal nieuwe botsvormen terug.
const TREE_SOLID_DIST := 45.0
func solid_trees() -> int:
    var have := {}        # vakjes van 2 m met al een ronde botsvorm (bomen uit forest() e.d.)
    for body in find_children("*", "StaticBody3D", true, false):
        for cs in body.get_children():
            if cs is CollisionShape3D and cs.shape is CylinderShape3D:
                var q: Vector3 = (cs as Node3D).global_position
                have[Vector2i(floori(q.x / 2.0), floori(q.z / 2.0))] = true
    var added := 0
    for n in find_children("*", "MeshInstance3D", true, false):
        var mi := n as MeshInstance3D
        if not String(mi.name).to_lower().contains("trunk") or mi.mesh == null:
            continue
        var solid := false
        var up: Node = mi.get_parent()
        while up != null and up != self:
            if up is CollisionObject3D:
                solid = true
                break
            up = up.get_parent()
        if solid:
            continue
        var r: float = 0.3
        var h: float = 4.0
        if mi.mesh is CylinderMesh:
            var cm := mi.mesh as CylinderMesh
            r = maxf(cm.top_radius, cm.bottom_radius)
            h = cm.height
        else:
            var bb: AABB = mi.mesh.get_aabb()
            r = maxf(bb.size.x, bb.size.z) * 0.5
            h = bb.size.y
        var sc: Vector3 = mi.global_transform.basis.get_scale()
        _tree_body(mi.global_position, r * maxf(sc.x, sc.z), h * sc.y)
        added += 1
    for n in find_children("*", "MultiMeshInstance3D", true, false):
        var mmi := n as MultiMeshInstance3D
        if not String(mmi.name).to_lower().contains("trunk") or mmi.multimesh == null:
            continue
        var mm := mmi.multimesh
        var r0: float = 0.3
        if mm.mesh is CylinderMesh:
            r0 = maxf((mm.mesh as CylinderMesh).top_radius, (mm.mesh as CylinderMesh).bottom_radius)
        for i in mm.instance_count:
            var t: Transform3D = mmi.global_transform * mm.get_instance_transform(i)
            var p: Vector3 = t.origin
            if have.has(Vector2i(floori(p.x / 2.0), floori(p.z / 2.0))):
                continue
            if route.distance_to(p) > TREE_SOLID_DIST:
                continue
            var sc: Vector3 = t.basis.get_scale()
            _tree_body(p, r0 * maxf(sc.x, sc.z), sc.y)
            added += 1
    return added

func _tree_body(center: Vector3, r: float, h: float) -> void:
    var body := StaticBody3D.new()
    body.name = "Tree body"
    body.add_to_group("tree_body")
    var cs := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = clampf(r, 0.12, 0.7)
    shape.height = clampf(h, 1.5, 8.0)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)
    # onderkant van de cilinder op de voet van de stam
    body.global_position = center - Vector3(0, h * 0.5, 0) + Vector3(0, shape.height * 0.5, 0)
