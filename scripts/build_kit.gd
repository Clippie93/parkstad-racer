extends RefCounted
# Gedeelde bouwset voor alle gebouwen. Gebruik:
#   const Kit = preload("res://scripts/build_kit.gd")
#   Kit.box(self, "Muur", Vector3(0, 5, 0), Vector3(10, 10, 1), Color.WHITE, true)
#
# Conventie: een "face" is een Node3D waarvan +Z naar buiten wijst. Alles wat op
# een gevel hoort (ramen, letters, panelen) bouw je in de lokale ruimte van een face,
# dan hoef je nooit meer met wereldcoördinaten of draaiingen te rekenen.

const MeshArrays = preload("res://scripts/mesh_arrays.gd")
static var _cache: Dictionary = {}

# ---------- materialen ----------

static func mat(color: Color, glow: float = 0.0, metallic: float = 0.0, rough: float = 1.0) -> StandardMaterial3D:
    var key := "%s|%s|%s|%s" % [color.to_html(true), glow, metallic, rough]
    if _cache.has(key):
        return _cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = metallic
    if glow > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = glow
    _cache[key] = m
    return m

static func glass_mat(color: Color) -> StandardMaterial3D:
    # Lichtgevend genoeg om als glas te lezen, zonder echte reflecties nodig te hebben.
    var key := "glass|%s" % color.to_html(true)
    if _cache.has(key):
        return _cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.15
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = 0.07
    _cache[key] = m
    return m

static func tex_mat(path: String, tint: Color = Color.WHITE, meters_per_tile: float = 8.0) -> StandardMaterial3D:
    # Triplanar: textuur herhaalt zich per `meters_per_tile` meter, op elke vlakorientatie.
    var key := "tex|%s|%s|%s" % [path, tint.to_html(true), meters_per_tile]
    if _cache.has(key):
        return _cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_texture = load(path) as Texture2D
    m.albedo_color = tint
    m.roughness = 1.0
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
    m.uv1_triplanar = true
    var s := 1.0 / meters_per_tile
    m.uv1_scale = Vector3(s, s, s)
    _cache[key] = m
    return m

# ---------- primitieven ----------

static func box(parent: Node3D, n: String, pos: Vector3, size: Vector3, color: Color,
        solid: bool = false, material: Material = null) -> Node3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = material if material != null else mat(color)
    var root: Node3D = mi
    if solid:
        var body := StaticBody3D.new()
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        body.add_child(cs)
        body.add_child(mi)
        root = body
    root.name = n
    root.position = pos
    parent.add_child(root)
    return root

# Gevelblok met de textuur town_facade (5 verdiepingen per tegel): de textuur wordt
# vanuit het midden van de box gelegd, dus kies de boxhoogte zo dat er een tegelrand op
# maaiveld valt. Bij een oneven aantal zichtbare verdiepingen zakt de box één verdieping
# onder de grond. floor_h = tegelmaat / 5; ground = midden van de onderkant op maaiveld.
static func facade_block(parent: Node3D, n: String, ground: Vector3, size_xz: Vector2, floors: int,
        material: Material, solid: bool = true, floor_h: float = 2.8) -> Node3D:
    var k: int = floors + (floors % 2)            # even aantal verdiepingen in de box
    var h: float = float(k) * floor_h
    var top: float = float(floors) * floor_h
    return box(parent, n, ground + Vector3(0, top - h * 0.5, 0), Vector3(size_xz.x, h, size_xz.y), Color.WHITE, solid, material)

static func cyl(parent: Node3D, n: String, pos: Vector3, r_bottom: float, r_top: float, h: float,
        color: Color, segs: int = 16, axis: String = "y", solid: bool = false,
        material: Material = null) -> Node3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.bottom_radius = r_bottom
    cm.top_radius = r_top
    cm.height = h
    cm.radial_segments = segs
    cm.rings = 1
    mi.mesh = cm
    mi.material_override = material if material != null else mat(color)
    var root: Node3D = mi
    if solid:
        var body := StaticBody3D.new()
        var cs := CollisionShape3D.new()
        var shape := CylinderShape3D.new()
        shape.radius = maxf(r_bottom, r_top)
        shape.height = h
        cs.shape = shape
        body.add_child(cs)
        body.add_child(mi)
        root = body
    root.name = n
    root.position = pos
    if axis == "z":
        root.rotation_degrees.x = 90.0
    elif axis == "x":
        root.rotation_degrees.z = 90.0
    parent.add_child(root)
    return root

static func beam(parent: Node3D, n: String, a: Vector3, b: Vector3, thickness: float, color: Color) -> Node3D:
    var d: Vector3 = b - a
    var length: float = d.length()
    if length < 0.001:
        return null
    var node := box(parent, n, (a + b) * 0.5, Vector3(thickness, length, thickness), color)
    var dir: Vector3 = d / length
    if absf(dir.dot(Vector3.UP)) < 0.9999:
        node.basis = Basis(Quaternion(Vector3.UP, dir))
    return node

static func pyramid(parent: Node3D, n: String, base_center: Vector3, half_width: float, rise: float, color: Color) -> Node3D:
    # Vierzijdige piramide (torendak). half_width = halve zijde van het grondvlak.
    var node := cyl(parent, n, base_center + Vector3(0, rise * 0.5, 0),
        half_width * sqrt(2.0), 0.0, rise, color, 4)
    node.rotation_degrees.y = 45.0
    return node

# ---------- eigen meshes ----------

static func _quad(t: Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
    t.append_array([a, b, c, a, c, d])

static func _mesh_from(tris: Array, material: Material) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(material)
    st.set_smooth_group(-1) # vlakke normalen
    for v: Vector3 in tris:
        st.add_vertex(v)
    st.generate_normals()
    return MeshArrays.commit(st, material)

static func _two_sided(color: Color) -> StandardMaterial3D:
    var key := "2s|%s" % color.to_html(true)
    if _cache.has(key):
        return _cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 1.0
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    _cache[key] = m
    return m

static func gable(parent: Node3D, n: String, base_center: Vector3, width: float, length: float,
        rise: float, color: Color, along_x: bool = false) -> MeshInstance3D:
    # Zadeldak. Nok loopt langs Z (of langs X met along_x).
    var hw := width * 0.5
    var hl := length * 0.5
    var a := Vector3(-hw, 0, -hl)
    var b := Vector3(hw, 0, -hl)
    var c := Vector3(0, rise, -hl)
    var d := Vector3(-hw, 0, hl)
    var e := Vector3(hw, 0, hl)
    var f := Vector3(0, rise, hl)
    var t: Array = []
    t.append_array([a, b, c, d, e, f])
    _quad(t, a, d, f, c)
    _quad(t, b, e, f, c)
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = _mesh_from(t, _two_sided(color))
    mi.position = base_center
    if along_x:
        mi.rotation_degrees.y = 90.0
    parent.add_child(mi)
    return mi

static func wedge(parent: Node3D, n: String, pos: Vector3, width: float, depth: float,
        y_low: float, y_high: float, top_color: Color, wall_color: Color) -> MeshInstance3D:
    # Oplopende tribune. Laag aan -Z, hoog aan +Z. Draai de node (yaw) om te richten.
    var hw := width * 0.5
    var hd := depth * 0.5
    var tl := Vector3(-hw, y_low, -hd)
    var tr := Vector3(hw, y_low, -hd)
    var bh := Vector3(hw, y_high, hd)
    var bl := Vector3(-hw, y_high, hd)
    var top: Array = []
    _quad(top, tl, tr, bh, bl)
    var walls: Array = []
    _quad(walls, Vector3(-hw, 0, hd), Vector3(hw, 0, hd), bh, bl)
    _quad(walls, Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), tr, tl)
    walls.append_array([Vector3(-hw, 0, -hd), Vector3(-hw, 0, hd), bl,
        Vector3(-hw, 0, -hd), bl, tl])
    walls.append_array([Vector3(hw, 0, -hd), Vector3(hw, 0, hd), bh,
        Vector3(hw, 0, -hd), bh, tr])
    var mesh := ArrayMesh.new()
    for pair in [[top, top_color], [walls, wall_color]]:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        st.set_material(_two_sided(pair[1]))
        st.set_smooth_group(-1)
        for v: Vector3 in pair[0]:
            st.add_vertex(v)
        st.generate_normals()
        st.commit(mesh)
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = mesh
    mi.position = pos
    parent.add_child(mi)
    return mi

# ---------- gevels ----------

static func face(parent: Node3D, pos: Vector3, yaw_deg: float) -> Node3D:
    # +Z van de face wijst naar buiten. yaw 0 = +Z, 90 = +X, 180 = -Z, -90 = -X.
    var f := Node3D.new()
    f.name = "Face"
    f.position = pos
    f.rotation_degrees.y = yaw_deg
    parent.add_child(f)
    return f

static func arch_window(f: Node3D, x: float, y_bottom: float, w: float, h: float, z: float,
        glass: Color, frame: Color) -> void:
    # Rondboogvenster in face-ruimte. y_bottom = onderkant, h = totale hoogte incl. boog.
    var r := w * 0.5
    var straight := maxf(h - r, 0.2)
    box(f, "WinFrame", Vector3(x, y_bottom + straight * 0.5, z), Vector3(w + 0.5, straight, 0.12), frame)
    cyl(f, "WinFrameArch", Vector3(x, y_bottom + straight, z), r + 0.25, r + 0.25, 0.12, frame, 20, "z")
    box(f, "WinGlass", Vector3(x, y_bottom + straight * 0.5, z + 0.06), Vector3(w, straight, 0.1), glass)
    cyl(f, "WinGlassArch", Vector3(x, y_bottom + straight, z + 0.06), r, r, 0.1, glass, 20, "z")
    box(f, "WinMullion", Vector3(x, y_bottom + straight * 0.5, z + 0.12), Vector3(0.1, straight + r, 0.06), frame)

static func rect_window(f: Node3D, x: float, y_bottom: float, w: float, h: float, z: float,
        glass: Color, frame: Color) -> void:
    box(f, "WinFrame", Vector3(x, y_bottom + h * 0.5, z), Vector3(w + 0.4, h + 0.4, 0.12), frame)
    box(f, "WinGlass", Vector3(x, y_bottom + h * 0.5, z + 0.06), Vector3(w, h, 0.1), glass)

static func label(parent: Node3D, text: String, pos: Vector3, pixel: float, color: Color,
        size: int = 64, outline: int = 0, billboard: bool = false) -> Label3D:
    var l := Label3D.new()
    l.text = text
    l.font_size = size
    l.pixel_size = pixel
    l.modulate = color
    l.outline_size = outline
    l.outline_modulate = Color(0, 0, 0, 0.85)
    l.double_sided = false
    if billboard:
        l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.position = pos
    parent.add_child(l)
    return l

static func tex_panel(parent: Node3D, n: String, pos: Vector3, size: Vector2, path: String) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = n
    var q := QuadMesh.new()
    q.size = size
    mi.mesh = q
    var key := "panel|%s" % path
    var m: StandardMaterial3D
    if _cache.has(key):
        m = _cache[key]
    else:
        m = StandardMaterial3D.new()
        m.albedo_texture = load(path) as Texture2D
        m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
        m.cull_mode = BaseMaterial3D.CULL_DISABLED
        m.roughness = 1.0
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
        _cache[key] = m
    mi.material_override = m
    mi.position = pos
    parent.add_child(mi)
    return mi

# ---------- tongewelf (halve cilinder-schil) ----------

static func two_sided_mat(color: Color) -> StandardMaterial3D:
    return _two_sided(color)

static func glass_two_sided(color: Color) -> StandardMaterial3D:
    var key := "glass2s|%s" % color.to_html(true)
    if _cache.has(key):
        return _cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.15
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = 0.07
    _cache[key] = m
    return m

static func vault(parent: Node3D, n: String, pos: Vector3, width: float, length: float,
        rise: float, material: Material, steps: int = 10) -> MeshInstance3D:
    # Tongewelf: boog over X (breedte), as langs Z (lengte). Onderkant op y=0.
    var hw := width * 0.5
    var hl := length * 0.5
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(material)
    st.set_smooth_group(0)
    for i in range(steps):
        var a0 := PI * float(i) / float(steps)
        var a1 := PI * float(i + 1) / float(steps)
        var p0 := Vector3(cos(a0) * hw, sin(a0) * rise, 0.0)
        var p1 := Vector3(cos(a1) * hw, sin(a1) * rise, 0.0)
        var q: Array = [p0 + Vector3(0, 0, -hl), p1 + Vector3(0, 0, -hl), p1 + Vector3(0, 0, hl),
            p0 + Vector3(0, 0, -hl), p1 + Vector3(0, 0, hl), p0 + Vector3(0, 0, hl)]
        for v: Vector3 in q:
            st.add_vertex(v)
    st.generate_normals()
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = st.commit()
    mi.position = pos
    parent.add_child(mi)
    return mi

static func tex_mat_tiles(path: String, tile: Vector2) -> StandardMaterial3D:
    # Triplanar met aparte tegelmaat per as: tile.x meter breed, tile.y meter hoog.
    var key := "tiles|%s|%s" % [path, tile]
    if _cache.has(key):
        return _cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_texture = load(path) as Texture2D
    m.roughness = 1.0
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    m.uv1_triplanar = true
    # wereldcoördinaten: aangrenzende blokken krijgen doorlopende banden en vensters
    m.uv1_world_triplanar = true
    m.uv1_scale = Vector3(1.0 / tile.x, 1.0 / tile.y, 1.0 / tile.x)
    _cache[key] = m
    return m

static func frustum(parent: Node3D, n: String, base_center: Vector3, width: float, depth: float,
        inset: float, height: float, color: Color) -> MeshInstance3D:
    # Afgeknotte piramide op een rechthoek (schild- of mansardedak). inset = hoeveel de
    # bovenrand aan elke kant terugspringt; inset >= halve diepte geeft een nok.
    var hw := width * 0.5
    var hd := depth * 0.5
    var tw := maxf(0.0, hw - inset)
    var td := maxf(0.0, hd - inset)
    var a := Vector3(-hw, 0, -hd)
    var b := Vector3(hw, 0, -hd)
    var c := Vector3(hw, 0, hd)
    var d := Vector3(-hw, 0, hd)
    var e := Vector3(-tw, height, -td)
    var f := Vector3(tw, height, -td)
    var g := Vector3(tw, height, td)
    var h := Vector3(-tw, height, td)
    var t: Array = []
    _quad(t, a, b, f, e)
    _quad(t, b, c, g, f)
    _quad(t, c, d, h, g)
    _quad(t, d, a, e, h)
    if td > 0.0:
        _quad(t, e, f, g, h)
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = _mesh_from(t, _two_sided(color))
    mi.position = base_center
    parent.add_child(mi)
    return mi
