extends RefCounted
# Alles hieronder is ontworpen voor 1280x720. Is het scherm breder (telefoon) of hoger
# (tablet), dan blijft de linkerhelft aan de linkerrand en schuift de rechterhelft mee
# naar de rechterrand; de vlakken onderin blijven aan de onderrand.
#
# Veilig gebied: op de iPhone loopt het beeld over het hele scherm (ook langs de Dynamic
# Island en de ronde hoeken, viewport-fit=cover). Knoppen en tellers blijven binnen het
# veilige gebied: screen() is het scherm min die randen, en safe_offset() is hoeveel de
# bedieningslaag naar rechts schuift. De 3D-wereld vult wel het hele scherm.
static var _safe := Vector4.ZERO      # links, boven, rechts, onder (ontwerppixels)
static var _safe_for := Vector2(-1, -1)

static func full() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size

static func safe() -> Vector4:
	if OS.has_environment("PARKSTAD_SAFE"):      # alleen voor tests: "l,t,r,b" in ontwerppixels
		var t: PackedStringArray = OS.get_environment("PARKSTAD_SAFE").split(",")
		return Vector4(float(t[0]), float(t[1]), float(t[2]), float(t[3]))
	if not OS.has_feature("web"):
		return Vector4.ZERO
	var f: Vector2 = full()
	if f == _safe_for:
		return _safe
	_safe_for = f
	_safe = Vector4.ZERO
	var js := "(function(){var s=getComputedStyle(document.documentElement);function g(n){return parseFloat(s.getPropertyValue(n))||0;}return [g('--pr-sal'),g('--pr-sat'),g('--pr-sar'),g('--pr-sab'),window.innerWidth].join(',');})()"
	var r = JavaScriptBridge.eval(js, true)
	if r is String:
		var v: PackedStringArray = String(r).split(",")
		if v.size() == 5 and float(v[4]) > 0.0:
			var k: float = f.x / float(v[4])
			_safe = Vector4(float(v[0]) * k, float(v[1]) * k, float(v[2]) * k, float(v[3]) * k)
	return _safe

static func safe_offset() -> Vector2:
	return Vector2(safe().x, 0.0)

static func screen() -> Vector2:
	var sf: Vector4 = safe()
	return full() - Vector2(sf.x + sf.z, sf.w)

static func extra() -> Vector2:
	return (screen() - Vector2(1280, 720)).max(Vector2.ZERO)

# Schermpunt -> ontwerppunt (voor aanrakingen).
static func to_design(p: Vector2) -> Vector2:
	p -= safe_offset()
	var d: Vector2 = extra()
	return Vector2(p.x - d.x if p.x > screen().x * 0.5 else p.x, p.y - d.y)

# Ontwerprechthoek/-punt onderin -> scherm (rechterhelft schuift mee naar rechts).
static func place(r: Rect2) -> Rect2:
	var d: Vector2 = extra()
	return Rect2(r.position + Vector2(d.x if r.position.x >= 640.0 else 0.0, d.y), r.size)

# Menu's blijven 1280x720 en staan midden op het scherm; de achtergrond loopt door
# tot de randen (zie menu_header.gd).
static func center(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER)
	c.offset_left = -640.0
	c.offset_right = 640.0
	c.offset_top = -360.0
	c.offset_bottom = 360.0
