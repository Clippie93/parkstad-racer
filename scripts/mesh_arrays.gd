extends RefCounted
# Mesh-gegevens (hoekpunten, normalen, ...) opvragen zonder de grafische chip op te houden.
#
# surface_get_arrays() op een BoxMesh/SphereMesh/... leest de gegevens terug uit het
# videogeheugen. In de browser (WebGL) wacht dat telkens tot de chip klaar is: op een
# goedkope Android-telefoon zo'n 7 ms per keer. Bij het samenvoegen van een level (7000+
# blokjes in Heerlen) liep het laden daardoor op tot ruim een minuut. Daarom:
# - een gewone BoxMesh: één keer een kubus van 1x1x1 uitlezen en die opschalen;
# - andere vormen: per combinatie van instellingen maar één keer uitlezen (gedeeld).
static var _cache := {}
static var reads := 0    # aantal echte terugleesacties (voor tests)

static func surface(mesh: Mesh, i: int) -> Array:
	if mesh is BoxMesh:
		var b := mesh as BoxMesh
		if b.subdivide_width == 0 and b.subdivide_height == 0 and b.subdivide_depth == 0 and not b.flip_faces and not b.add_uv2:
			return _scaled(_unit_box(), b.size)
	if mesh is PrimitiveMesh:
		var key: String = _key(mesh)
		if not _cache.has(key):
			reads += 1
			_cache[key] = mesh.surface_get_arrays(i)
		return _cache[key]
	# overige meshes (SurfaceTool): vaak één mesh voor veel exemplaren; de uitkomst bij de
	# mesh zelf bewaren, dan verdwijnt hij ook weer met de mesh
	var meta := "_arrays_%d" % i
	if mesh.has_meta(meta):
		return mesh.get_meta(meta)
	reads += 1
	var a: Array = mesh.surface_get_arrays(i)
	mesh.set_meta(meta, a)
	return a

static func _unit_box() -> Array:
	if not _cache.has("unit_box"):
		var m := BoxMesh.new()
		m.size = Vector3.ONE
		reads += 1
		_cache["unit_box"] = m.surface_get_arrays(0)
	return _cache["unit_box"]

static func _scaled(a: Array, size: Vector3) -> Array:
	var out: Array = a.duplicate(false)
	var src: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var v := PackedVector3Array()
	v.resize(src.size())
	for k in src.size():
		v[k] = src[k] * size
	out[Mesh.ARRAY_VERTEX] = v
	return out

static func _key(mesh: Mesh) -> String:
	var parts: PackedStringArray = [mesh.get_class()]
	for p in mesh.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_STORAGE):
			continue
		var n: String = p["name"]
		if n == "material" or n.begins_with("resource_") or n == "script":
			continue
		parts.append("%s=%s" % [n, str(mesh.get(n))])
	return "|".join(parts)

# SurfaceTool afronden en de gegevens meteen bij de mesh bewaren, zodat samenvoegen ze
# later niet uit het videogeheugen hoeft terug te lezen
static func commit(st: SurfaceTool, material: Material = null) -> ArrayMesh:
	var a: Array = st.commit_to_arrays()
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	if material != null:
		m.surface_set_material(0, material)
	m.set_meta("_arrays_0", a)
	return m
