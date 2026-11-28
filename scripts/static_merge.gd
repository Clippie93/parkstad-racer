extends RefCounted
# Voegt stilstaande losse onderdelen van een level samen tot een paar grote vormen: alle
# blokjes met hetzelfde materiaal binnen een vak van CELL meter worden één mesh. Een gebouw
# van 80 blokjes in 6 kleuren kost de grafische chip dan 6 tekenopdrachten in plaats van 80.
# Dat scheelt vooral op telefoons in de browser veel.
#
# Niet samengevoegd wordt alles wat kan bewegen of veranderen: onderdelen onder een node met
# een eigen script buiten de levels/landmarks (flitsers, verkeerslichten, auto's), onder een
# script met _process (trein, AWACS), onder een bewegend lichaam of in de groep "keep_far".
# Ook materialen met triplanar-textuur in objectruimte (gevels) blijven los, want die textuur
# hangt af van het midden van het eigen blok.
const MeshArrays = preload("res://scripts/mesh_arrays.gd")
const CELL := 60.0
const MAX_SIZE := 120.0

static func merge(root: Node3D) -> int:
	var inv: Transform3D = root.global_transform.affine_inverse()
	var groups := {}       # sleutel -> [materiaal, schaduw, verts, normals, uvs, indices]
	var done: Array = []
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if not _eligible(mi, root):
			continue
		var mesh: Mesh = mi.mesh
		var xf: Transform3D = inv * mi.global_transform
		var box: AABB = xf * mesh.get_aabb()
		if box.size.length() > MAX_SIZE:
			continue
		var c: Vector3 = box.get_center()
		var cell := Vector2i(floori(c.x / CELL), floori(c.z / CELL))
		var nb: Basis = xf.basis.inverse().transposed()
		var ok := true
		for i in mesh.get_surface_count():
			if (mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(i) != Mesh.PRIMITIVE_TRIANGLES) or _material(mi, i) == null:
				ok = false
		if not ok:
			continue
		for i in mesh.get_surface_count():
			var mat: Material = _material(mi, i)
			var key := "%d|%d|%d|%d" % [mat.get_instance_id(), mi.cast_shadow, cell.x, cell.y]
			if not groups.has(key):
				groups[key] = [mat, mi.cast_shadow, PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
			var g: Array = groups[key]
			var a: Array = MeshArrays.surface(mesh, i)
			var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var norms = a[Mesh.ARRAY_NORMAL]
			var uvs = a[Mesh.ARRAY_TEX_UV]
			var idx = a[Mesh.ARRAY_INDEX]
			var base: int = g[2].size()
			for k in verts.size():
				g[2].append(xf * verts[k])
				g[3].append((nb * norms[k]).normalized() if norms != null and norms.size() > k else Vector3.UP)
				g[4].append(uvs[k] if uvs != null and uvs.size() > k else Vector2.ZERO)
			if idx != null and idx.size() > 0:
				for k in idx.size():
					g[5].append(base + idx[k])
			else:
				for k in verts.size():
					g[5].append(base + k)
		done.append(mi)
	if done.size() < 2:
		return 0
	var holder := Node3D.new()
	holder.name = "Merged"
	root.add_child(holder)
	for key in groups:
		var g: Array = groups[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = g[2]
		arrays[Mesh.ARRAY_NORMAL] = g[3]
		arrays[Mesh.ARRAY_TEX_UV] = g[4]
		arrays[Mesh.ARRAY_INDEX] = g[5]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var out := MeshInstance3D.new()
		out.mesh = am
		out.material_override = g[0]
		out.cast_shadow = g[1]
		holder.add_child(out)
	for mi in done:
		mi.get_parent().remove_child(mi)
		mi.free()
	return done.size()

static func _material(mi: MeshInstance3D, i: int) -> Material:
	var m: Material = mi.material_override
	if m == null:
		m = mi.get_surface_override_material(i)
	if m == null:
		m = mi.mesh.surface_get_material(i)
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		if b.uv1_triplanar and not b.uv1_world_triplanar:
			return null
		if b.vertex_color_use_as_albedo:
			return null
		return m
	return null

static func _eligible(mi: MeshInstance3D, root: Node) -> bool:
	if mi.get_script() != null or mi.get_child_count() > 0 or not mi.visible or mi.mesh == null:
		return false
	if mi.is_in_group("keep_far") or mi.material_overlay != null:
		return false
	var n: Node = mi.get_parent()
	while n != null and n != root:
		if not _allowed(n):
			return false
		n = n.get_parent()
	return n == root

static func _allowed(n: Node) -> bool:
	if not n is Node3D or not (n as Node3D).visible or n.is_in_group("keep_far"):
		return false
	if n is CollisionObject3D and not n is StaticBody3D:
		return false
	if n is AnimatableBody3D:
		return false
	var s: Script = n.get_script()
	if s == null:
		return true
	var p: String = s.resource_path
	if not (p.begins_with("res://scripts/landmarks/") or p.begins_with("res://scripts/levels/") or p.begins_with("res://scripts/places/")):
		return false
	return not (n.has_method("_process") or n.has_method("_physics_process"))
