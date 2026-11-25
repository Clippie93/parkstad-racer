extends Node3D
# Parkstad Limburg Stadion met parkeerterrein en een plein voor de hoofdentree.
# Op het plein het zitobject in de vorm van de zwarte vlakken van het Roda JC-logo,
# naar jouw foto's (20-11). Vervangt de rotonde.
# Oorsprong = midden van het stadion; de hoofdgevel en de toegangsweg liggen aan +Z.
# Gebruikt door het Kerkrade-level en de finale.
const Kit = preload("res://scripts/build_kit.gd")
const LmPls = preload("res://scripts/landmarks/landmark_pls.gd")

const ROAD_GRAY := Color("353940")
const WHITE := Color("dedbd0")

func _ready() -> void:
    name = "PLS site"
    Kit.box(self, "PLS parking", Vector3(0, 0.095, 85), Vector3(125, 0.12, 44), Color("44484c"))
    for x in range(-54, 55, 9):
        if absf(float(x)) < 10.0:
            continue
        Kit.box(self, "Parking bay marking", Vector3(float(x), 0.17, 91), Vector3(0.16, 0.03, 18), WHITE)
    Kit.box(self, "PLS access lane", Vector3(0, 0.18, 92), Vector3(17, 0.04, 27), ROAD_GRAY)
    # plein van lichte klinkers voor de hoofdentree, met het zitobject in het midden
    Kit.box(self, "PLS plaza", Vector3(0, 0.2, 70.5), Vector3(70, 0.1, 17), Color("a59d91"))
    for k in range(9):
        Kit.box(self, "Plaza joint", Vector3(0, 0.255, 63.0 + float(k) * 1.9), Vector3(70, 0.01, 0.06), Color("8f887d"))
    _seating(Vector3(0, 0.25, 71.0))
    add_child(LmPls.new())

# Zitobject naar jouw foto's: de zwarte vlakken van het Roda JC-logo als zitbanken
# (de gele delen zijn er niet). Van bovenaf: de strepen buiten de ring zijn lage banken,
# de dunne zwarte cirkel is een staande stalen ring, de letters zijn zitplaten op pootjes.
# LOGO_RUNS: per rij cellen van 5 px (logo 500 px breed) de zwarte stukken: rij, van, tot.
const LOGO_PX := 0.018     # meter per logopixel: logo 9 m breed
const LOGO_CELL := 5
const LOGO_RUNS := [
    1, 43, 56, 2, 41, 58, 3, 41, 58, 4, 41, 58, 5, 30, 31, 5, 41, 58, 5, 68, 69, 6, 27, 31, 6, 41, 58, 6, 68, 72,
    7, 26, 31, 7, 41, 58, 7, 68, 73, 8, 24, 31, 8, 41, 58, 8, 68, 75, 9, 22, 31, 9, 41, 58, 9, 68, 77, 10, 21, 31,
    10, 41, 58, 10, 68, 78, 11, 20, 31, 11, 41, 58, 11, 68, 79, 12, 19, 31, 12, 41, 58, 12, 68, 80, 13, 17, 31, 13, 41, 58,
    13, 68, 82, 14, 17, 31, 14, 41, 58, 14, 68, 82, 15, 17, 31, 15, 41, 58, 15, 68, 82, 16, 17, 31, 16, 41, 58, 16, 68, 82,
    17, 17, 31, 17, 41, 58, 17, 68, 82, 18, 17, 31, 18, 41, 44, 18, 54, 58, 18, 68, 82, 19, 17, 31, 19, 68, 82, 20, 17, 31,
    20, 68, 82, 21, 17, 31, 21, 68, 82, 22, 17, 31, 22, 68, 82, 23, 17, 31, 23, 68, 82, 24, 17, 30, 24, 69, 82, 25, 17, 29,
    25, 70, 82, 26, 7, 7, 26, 17, 28, 26, 71, 82, 26, 92, 92, 27, 7, 7, 27, 17, 27, 27, 72, 82, 27, 92, 92, 28, 6, 7,
    28, 17, 26, 28, 73, 82, 28, 92, 93, 29, 6, 7, 29, 17, 25, 29, 74, 82, 29, 92, 93, 30, 5, 7, 30, 17, 24, 30, 75, 82,
    30, 92, 94, 31, 5, 7, 31, 17, 23, 31, 76, 82, 31, 92, 94, 32, 4, 7, 32, 17, 23, 32, 76, 82, 32, 92, 95, 33, 4, 7,
    33, 17, 22, 33, 39, 53, 33, 77, 82, 33, 92, 95, 34, 4, 7, 34, 17, 21, 34, 39, 53, 34, 78, 82, 34, 92, 95, 35, 3, 7,
    35, 17, 21, 35, 39, 53, 35, 78, 82, 35, 92, 96, 36, 3, 7, 36, 17, 20, 36, 39, 53, 36, 79, 82, 36, 92, 96, 37, 3, 7,
    37, 17, 20, 37, 39, 53, 37, 79, 82, 37, 92, 96, 38, 3, 7, 38, 17, 19, 38, 46, 53, 38, 80, 82, 38, 92, 96, 39, 2, 7,
    39, 17, 19, 39, 46, 53, 39, 63, 66, 39, 80, 82, 39, 92, 97, 40, 2, 7, 40, 17, 19, 40, 31, 36, 40, 40, 43, 40, 46, 53,
    40, 60, 68, 40, 80, 82, 40, 92, 97, 41, 2, 7, 41, 17, 19, 41, 30, 36, 41, 39, 43, 41, 46, 53, 41, 59, 69, 41, 80, 82,
    41, 92, 97, 42, 2, 7, 42, 17, 18, 42, 30, 36, 42, 38, 43, 42, 46, 53, 42, 58, 69, 42, 81, 82, 42, 92, 97, 43, 2, 7,
    43, 17, 18, 43, 30, 43, 43, 46, 53, 43, 57, 69, 43, 81, 82, 43, 92, 97, 44, 1, 7, 44, 17, 18, 44, 30, 43, 44, 46, 53,
    44, 56, 63, 44, 67, 69, 44, 81, 82, 44, 92, 98, 45, 1, 7, 45, 17, 18, 45, 30, 43, 45, 46, 53, 45, 56, 62, 45, 67, 69,
    45, 81, 82, 45, 92, 98, 46, 1, 7, 46, 17, 18, 46, 30, 43, 46, 46, 53, 46, 56, 62, 46, 81, 82, 46, 92, 98, 47, 1, 7,
    47, 17, 18, 47, 30, 38, 47, 46, 53, 47, 56, 62, 47, 81, 82, 47, 92, 98, 48, 1, 7, 48, 17, 17, 48, 30, 37, 48, 46, 53,
    48, 56, 62, 48, 82, 82, 48, 92, 98, 49, 1, 7, 49, 17, 17, 49, 30, 37, 49, 46, 53, 49, 56, 62, 49, 82, 82, 49, 92, 98,
    50, 1, 7, 50, 17, 17, 50, 30, 36, 50, 46, 53, 50, 56, 62, 50, 68, 69, 50, 82, 82, 50, 92, 98, 51, 1, 7, 51, 17, 17,
    51, 30, 36, 51, 46, 53, 51, 56, 63, 51, 67, 69, 51, 82, 82, 51, 92, 98, 52, 1, 7, 52, 17, 18, 52, 30, 36, 52, 46, 53,
    52, 57, 63, 52, 66, 69, 52, 81, 82, 52, 92, 98, 53, 1, 7, 53, 17, 18, 53, 30, 36, 53, 46, 53, 53, 57, 69, 53, 81, 82,
    53, 92, 98, 54, 1, 7, 54, 17, 18, 54, 30, 36, 54, 46, 53, 54, 58, 69, 54, 81, 82, 54, 92, 98, 55, 2, 7, 55, 17, 18,
    55, 30, 36, 55, 46, 53, 55, 59, 69, 55, 81, 82, 55, 92, 97, 56, 2, 7, 56, 17, 18, 56, 30, 36, 56, 46, 53, 56, 61, 69,
    56, 81, 82, 56, 92, 97, 57, 2, 7, 57, 17, 18, 57, 46, 53, 57, 81, 82, 57, 92, 97, 58, 2, 7, 58, 17, 19, 58, 46, 53,
    58, 80, 82, 58, 92, 97, 59, 2, 7, 59, 17, 19, 59, 35, 41, 59, 46, 53, 59, 80, 82, 59, 92, 97, 60, 2, 7, 60, 17, 19,
    60, 35, 41, 60, 46, 53, 60, 80, 82, 60, 92, 97, 61, 3, 7, 61, 17, 20, 61, 35, 42, 61, 46, 53, 61, 79, 82, 61, 92, 96,
    62, 3, 7, 62, 17, 20, 62, 36, 52, 62, 79, 82, 62, 92, 96, 63, 3, 7, 63, 17, 21, 63, 37, 52, 63, 78, 82, 63, 92, 96,
    64, 3, 7, 64, 17, 21, 64, 38, 50, 64, 78, 82, 64, 92, 96, 65, 4, 7, 65, 17, 22, 65, 41, 48, 65, 77, 82, 65, 92, 95,
    66, 4, 7, 66, 17, 22, 66, 77, 82, 66, 92, 95, 67, 5, 7, 67, 17, 23, 67, 76, 82, 67, 92, 94, 68, 5, 7, 68, 17, 24,
    68, 75, 82, 68, 92, 94, 69, 5, 7, 69, 17, 24, 69, 75, 82, 69, 92, 94, 70, 6, 7, 70, 17, 25, 70, 74, 82, 70, 92, 93,
    71, 6, 7, 71, 17, 26, 71, 73, 82, 71, 92, 93, 72, 7, 7, 72, 17, 27, 72, 72, 82, 72, 92, 92, 73, 7, 7, 73, 17, 28,
    73, 71, 82, 73, 92, 92, 74, 17, 29, 74, 70, 82, 75, 17, 31, 75, 68, 82, 76, 17, 31, 76, 68, 82, 77, 17, 31, 77, 68, 82,
    78, 17, 31, 78, 68, 82, 79, 17, 31, 79, 68, 82, 80, 17, 31, 80, 41, 42, 80, 57, 58, 80, 68, 82, 81, 17, 31, 81, 41, 58,
    81, 68, 82, 82, 17, 31, 82, 41, 58, 82, 68, 82, 83, 17, 31, 83, 41, 58, 83, 68, 82, 84, 17, 31, 84, 41, 58, 84, 68, 82,
    85, 17, 31, 85, 41, 58, 85, 68, 82, 86, 18, 31, 86, 41, 58, 86, 68, 81, 87, 19, 31, 87, 41, 58, 87, 68, 80, 88, 20, 31,
    88, 41, 58, 88, 68, 79, 89, 22, 31, 89, 41, 58, 89, 68, 77, 90, 23, 31, 90, 41, 58, 90, 68, 76, 91, 25, 31, 91, 41, 58,
    91, 68, 74, 92, 26, 31, 92, 41, 58, 92, 68, 73, 93, 28, 31, 93, 41, 58, 93, 68, 71, 94, 30, 31, 94, 41, 58, 94, 68, 69,
    95, 41, 58, 96, 41, 58, 97, 41, 58, 98, 47, 52,
]

func _seating(c: Vector3) -> void:
    var steel := Kit.mat(Color("34373a"), 0.0, 0.4, 0.6)
    var leg_m := Kit.mat(Color("3a4f78"))
    var plates := SurfaceTool.new()
    plates.begin(Mesh.PRIMITIVE_TRIANGLES)
    plates.set_smooth_group(-1)   # vlakke normalen, anders strepen in de belichting
    var legs := SurfaceTool.new()
    legs.begin(Mesh.PRIMITIVE_TRIANGLES)
    legs.set_smooth_group(-1)
    var s: float = LOGO_PX
    var cell: float = float(LOGO_CELL)
    # alle zwarte cellen; daarna per cel boven- en onderkant, en zijkanten alleen waar de
    # buurcel leeg is (geen binnenwanden, anders strepen in de belichting)
    var cells := {}
    for k in range(0, LOGO_RUNS.size(), 3):
        for i in range(LOGO_RUNS[k + 1], LOGO_RUNS[k + 2] + 1):
            cells[Vector2i(i, LOGO_RUNS[k])] = true
    for key in cells:
        var i: int = key.x
        var j: int = key.y
        var x0: float = (float(i) * cell - 250.0) * s
        var x1: float = (float(i + 1) * cell - 250.0) * s
        var z0: float = (float(j) * cell - 249.0) * s
        var z1: float = (float(j + 1) * cell - 249.0) * s
        var mid := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
        # letters (binnen de ring) iets hoger dan de banken
        var top: float = 0.62 if mid.length() < 108.0 * s else 0.46
        var bot: float = top - 0.08
        _quad(plates, Vector3(x0, top, z0), Vector3(x0, top, z1), Vector3(x1, top, z1), Vector3(x1, top, z0))
        _quad(plates, Vector3(x0, bot, z0), Vector3(x1, bot, z0), Vector3(x1, bot, z1), Vector3(x0, bot, z1))
        if not cells.has(Vector2i(i - 1, j)):
            _quad(plates, Vector3(x0, bot, z0), Vector3(x0, bot, z1), Vector3(x0, top, z1), Vector3(x0, top, z0))
        if not cells.has(Vector2i(i + 1, j)):
            _quad(plates, Vector3(x1, bot, z1), Vector3(x1, bot, z0), Vector3(x1, top, z0), Vector3(x1, top, z1))
        if not cells.has(Vector2i(i, j - 1)):
            _quad(plates, Vector3(x1, bot, z0), Vector3(x0, bot, z0), Vector3(x0, top, z0), Vector3(x1, top, z0))
        if not cells.has(Vector2i(i, j + 1)):
            _quad(plates, Vector3(x0, bot, z1), Vector3(x1, bot, z1), Vector3(x1, top, z1), Vector3(x0, top, z1))
        if i % 7 == 3 and j % 7 == 3:
            var lx: float = (x0 + x1) * 0.5
            var lz: float = (z0 + z1) * 0.5
            _add_box(legs, Vector3(lx - 0.04, 0.0, lz - 0.04), Vector3(lx + 0.04, bot, lz + 0.04))
    plates.generate_normals()
    legs.generate_normals()
    var pm: ArrayMesh = plates.commit()
    var mi := MeshInstance3D.new()
    mi.name = "Logo benches"
    mi.mesh = pm
    mi.material_override = steel
    var body := StaticBody3D.new()
    body.name = "Logo seating"
    body.position = c
    var cs := CollisionShape3D.new()
    cs.shape = pm.create_trimesh_shape()
    body.add_child(cs)
    body.add_child(mi)
    var lm := MeshInstance3D.new()
    lm.name = "Logo bench legs"
    lm.mesh = legs.commit()
    lm.material_override = leg_m
    body.add_child(lm)
    add_child(body)
    # staande stalen ring op de plek van de dunne zwarte cirkel
    var r: float = 117.0 * s
    var n := 40
    for k in range(n):
        var a: float = TAU * float(k) / float(n)
        var seg := Kit.box(self, "Seating ring", c + Vector3(cos(a) * r, 0.42, sin(a) * r), Vector3(0.07, 0.84, TAU * r / float(n) + 0.03), Color.WHITE, true, steel)
        seg.rotation.y = -a

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
    st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
    st.add_vertex(a); st.add_vertex(c); st.add_vertex(d)

# Box van a (min) tot b (max) als zes vlakken in een SurfaceTool.
func _add_box(st: SurfaceTool, a: Vector3, b: Vector3) -> void:
    var v := [Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z), Vector3(a.x, a.y, b.z),
        Vector3(a.x, b.y, a.z), Vector3(b.x, b.y, a.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z)]
    for q in [[4, 7, 6, 5], [0, 1, 2, 3], [3, 2, 6, 7], [1, 0, 4, 5], [0, 3, 7, 4], [2, 1, 5, 6]]:
        st.add_vertex(v[q[0]]); st.add_vertex(v[q[1]]); st.add_vertex(v[q[2]])
        st.add_vertex(v[q[0]]); st.add_vertex(v[q[2]]); st.add_vertex(v[q[3]])
