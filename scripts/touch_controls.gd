extends CanvasLayer
# Aanraakknoppen voor spelen op een telefoon of tablet. Elke knop is een TouchScreenButton
# die dezelfde invoeractie indrukt als het toetsenbord (gas, rem, sturen, handrem, R, Esc),
# zodat de auto en het pauzemenu er niets van hoeven te weten. Meerdere vingers tegelijk
# werkt (sturen + gas + handrem).
# Drie besturingen (Instellingen > Besturing), naar voorbeeld van mobiele racegames:
#  - "tap":   automatisch gas; linkerduim stuurt (twee vlakken links), rechterduim remt
#             onderin of trekt de handrem daarboven (pijltjesbesturing).
#  - "tilt":  automatisch gas; kantel de telefoon om te sturen; links vasthouden = remmen,
#             rechts vasthouden = handrem (zoals Asphalt en Real Racing).
#  - "stick": zwevende joystick links, gas/rem/handrem-knoppen rechts.
# Altijd: pauze (boven midden) en terug naar checkpoint (rechtsboven).

const FILL := Color(1, 1, 1, 0.14)
const FILL_DOWN := Color(0.95, 0.87, 0.4, 0.45)
const EDGE := Color(1, 1, 1, 0.6)

const Fit = preload("res://scripts/screen_fit.gd")

var buttons := []   # [knop, middelpunt in ontwerp, straal, "bottom"/"top"]
# Paneel van de race (pauze, eindklassement): zolang dat in beeld is, zijn de knoppen weg
# en reageren joystick en vlakken niet op je vinger (je tikt dan op de knoppen/tabjes).
var blocker: CanvasItem = null
var blocked := false

# Aan of uit volgens de instelling (automatisch = alleen met een touchscreen).
static func enabled() -> bool:
	match Game.touch_mode():
		"on":
			return true
		"off":
			return false
	return DisplayServer.is_touchscreen_available()

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var h: float = 720.0
	match Game.touch_scheme():
		"stick":
			add_child(Joystick.new())
			_button("accelerate", Vector2(1160, h - 130), 100.0, "up", "GAS")
			_button("brake", Vector2(950, h - 95), 76.0, "down", "REM")
			_button("handbrake", Vector2(1010, h - 300), 64.0, "", "HANDREM")
		"tilt":
			add_child(TiltSteer.new())
		_:
			add_child(TapSteer.new())
	_button("reset_car", Vector2(1215, 160), 44.0, "", "R")
	_button("ui_cancel", Vector2(640, 46), 36.0, "", "II")
	_layout()
	get_viewport().size_changed.connect(_layout)

func _process(_delta: float) -> void:
	var b: bool = blocker != null and blocker.visible
	if b == blocked:
		return
	blocked = b
	visible = not b
	for c in get_children():
		if c.has_method("set_blocked"):
			c.set_blocked(b)

# Knoppen op hun plek zetten voor de huidige schermmaat.
func _layout() -> void:
	# hele laag binnen het veilige gebied (iPhone: niet achter de Dynamic Island)
	offset = Fit.safe_offset()
	var d: Vector2 = Fit.extra()
	for e in buttons:
		var c: Vector2 = e[1]
		var r: float = e[2]
		if c.y < 300.0:
			c.x += d.x * (0.5 if c.x == 640.0 else 1.0)   # bovenin: pauze midden, R rechts
		else:
			c += Vector2(d.x if c.x >= 640.0 else 0.0, d.y)
		e[0].position = c - Vector2(r, r)

# Ronde knop met middelpunt c en straal r; icon = pijlrichting, text = opschrift.
func _button(action: String, c: Vector2, r: float, icon: String, text: String) -> void:
	var b := TouchScreenButton.new()
	b.action = action
	b.texture_normal = _tex(r, icon, FILL)
	b.texture_pressed = _tex(r, icon, FILL_DOWN)
	var shape := CircleShape2D.new()
	shape.radius = r
	b.shape = shape
	b.shape_centered = true
	b.position = c - Vector2(r, r)
	buttons.append([b, c, r])
	b.passby_press = true          # met je duim van links naar rechts schuiven werkt
	add_child(b)
	if text != "":
		var l := Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", int(clampf(r * 0.34, 16.0, 30.0)) if text.length() > 2 else int(r * 0.7))
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(r * 2.0, r * 2.0)
		if icon != "":
			l.position.y = r * 0.42 * (1.0 if icon == "up" else -1.0)
		b.add_child(l)

# Cirkel met rand en eventueel een driehoekige pijl, getekend in een Image.
static func _tex(r: float, icon: String, fill: Color) -> ImageTexture:
	var n: int = int(r * 2.0)
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(r, r)
	var tri: PackedVector2Array = _arrow(icon, c, r)
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var d: float = p.distance_to(c)
			if d > r:
				continue
			var col: Color = fill
			# rand van 4 px, zacht afgerond
			var edge: float = clampf((d - (r - 5.0)) / 2.0, 0.0, 1.0)
			col = col.lerp(EDGE, edge)
			col.a *= clampf(r - d, 0.0, 1.0)
			if tri.size() == 3 and Geometry2D.point_is_inside_triangle(p, tri[0], tri[1], tri[2]):
				col = Color(1, 1, 1, 0.85)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _arrow(icon: String, c: Vector2, r: float) -> PackedVector2Array:
	var s: float = r * 0.42
	match icon:
		"left":
			return PackedVector2Array([c + Vector2(-s, 0), c + Vector2(s * 0.6, -s), c + Vector2(s * 0.6, s)])
		"right":
			return PackedVector2Array([c + Vector2(s, 0), c + Vector2(-s * 0.6, -s), c + Vector2(-s * 0.6, s)])
		"up":
			return PackedVector2Array([c + Vector2(0, -s * 0.9), c + Vector2(-s * 0.8, s * 0.2), c + Vector2(s * 0.8, s * 0.2)])
		"down":
			return PackedVector2Array([c + Vector2(0, s * 0.9), c + Vector2(-s * 0.8, -s * 0.2), c + Vector2(s * 0.8, -s * 0.2)])
	return PackedVector2Array()


# Zwevende joystick voor sturen. Raak je de linkerhelft van het scherm aan, dan verschijnt
# de joystick onder je duim; schuif opzij om te sturen. Hoe verder opzij, hoe harder
# (via de sterkte van steer_left / steer_right, die car.gd al leest).
class Joystick extends Control:
	const REST := Vector2(210, 560)    # plek van de joystick als je hem niet aanraakt
	const RADIUS := 105.0              # zo ver kan de knop uit het midden
	const DEAD := 0.1                  # kleine bewegingen tellen niet
	const ZONE := Rect2(0, 190, 600, 530)   # linkerhelft, onder de tijd en ronde-info
	var finger := -1
	var base := REST
	var knob := Vector2.ZERO           # verplaatsing van de knop t.o.v. base

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		base = _rest()
		get_viewport().size_changed.connect(func():
			if finger < 0:
				base = _rest()
				queue_redraw())

	func _rest() -> Vector2:
		return REST + Vector2(0, Fit.extra().y)

	var blocked := false

	func set_blocked(b: bool) -> void:
		blocked = b
		finger = -1
		base = _rest()
		knob = Vector2.ZERO
		_apply()

	func _input(event: InputEvent) -> void:
		if blocked:
			return
		if event is InputEventScreenTouch:
			if event.pressed and finger < 0 and ZONE.has_point(Fit.to_design(event.position)):
				finger = event.index
				base = event.position
				knob = Vector2.ZERO
				_apply()
			elif not event.pressed and event.index == finger:
				finger = -1
				base = _rest()
				knob = Vector2.ZERO
				_apply()
		elif event is InputEventScreenDrag and event.index == finger:
			knob = (event.position - base).limit_length(RADIUS)
			_apply()

	func _apply() -> void:
		var x: float = knob.x / RADIUS
		var a: float = maxf(0.0, (absf(x) - DEAD) / (1.0 - DEAD))
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if a > 0.0:
			Input.action_press("steer_right" if x > 0.0 else "steer_left", a)
		queue_redraw()

	func _exit_tree() -> void:
		Input.action_release("steer_left")
		Input.action_release("steer_right")

	func _draw() -> void:
		var on: bool = finger >= 0
		draw_circle(base, RADIUS + 14.0, Color(1, 1, 1, 0.10 if on else 0.07))
		draw_arc(base, RADIUS + 14.0, 0.0, TAU, 64, Color(1, 1, 1, 0.5), 3.0, true)
		# pijltjes links en rechts op de rand
		for d in [-1.0, 1.0]:
			var tip: Vector2 = base + Vector2(d * (RADIUS - 6.0), 0)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-d * 20.0, -16.0), tip + Vector2(-d * 20.0, 16.0)]), Color(1, 1, 1, 0.5))
		var k: Vector2 = base + knob
		draw_circle(k, 50.0, Color(0.95, 0.87, 0.4, 0.55) if on else Color(1, 1, 1, 0.25))
		draw_arc(k, 50.0, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 3.0, true)


# Gemeenschappelijk voor tikken en kantelen: vingers bijhouden per schermhelft (de
# bovenste strook met pauze, R en de tijd telt niet mee) en automatisch gas geven.
class HalfTouch extends Control:
	const TOP := 210.0
	var fingers := {}          # vinger-index -> -1 (links) of 1 (rechts)
	var pos := {}              # vinger-index -> plek op het scherm
	var left := false
	var right := false

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	var blocked := false

	func set_blocked(b: bool) -> void:
		blocked = b
		fingers.clear()
		pos.clear()
		if b:
			left = false
			right = false
			_exit_tree()
			queue_redraw()
		else:
			_update()

	func _input(event: InputEvent) -> void:
		if blocked:
			return
		if event is InputEventScreenTouch:
			var p: Vector2 = Fit.to_design(event.position)
			if event.pressed and p.y > TOP:
				fingers[event.index] = -1 if p.x < 640.0 else 1
				pos[event.index] = p
			elif not event.pressed:
				fingers.erase(event.index)
				pos.erase(event.index)
			_update()
		elif event is InputEventScreenDrag and fingers.has(event.index):
			var p: Vector2 = Fit.to_design(event.position)
			fingers[event.index] = -1 if p.x < 640.0 else 1
			pos[event.index] = p
			_update()

	func _update() -> void:
		left = fingers.values().has(-1)
		right = fingers.values().has(1)
		_apply()
		queue_redraw()

	func _apply() -> void:
		pass

	# automatisch gas, behalve tijdens remmen
	func _gas(on: bool) -> void:
		if on:
			Input.action_press("accelerate")
		else:
			Input.action_release("accelerate")

	func _act(action: String, on: bool, strength: float = 1.0) -> void:
		if on:
			Input.action_press(action, strength)
		else:
			Input.action_release(action)

	func _exit_tree() -> void:
		for a in ["accelerate", "brake", "handbrake", "steer_left", "steer_right"]:
			Input.action_release(a)

	# Grote, doorzichtige vlakken onderin links en rechts met een opschrift.
	func _zone(design: Rect2, text: String, active: bool) -> void:
		var rect: Rect2 = Fit.place(design)
		draw_rect(rect, Color(0.95, 0.87, 0.4, 0.18) if active else Color(1, 1, 1, 0.04))
		draw_rect(rect, Color(1, 1, 1, 0.25), false, 2.0)
		var f: Font = ThemeDB.fallback_font
		var fs: int = 64 if text.length() == 1 else 22   # pijltjes groot, woorden normaal
		var sz: Vector2 = f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var y: float = rect.size.y * 0.5 + fs * 0.35 if fs > 22 else rect.size.y - 22.0
		draw_string(f, rect.position + Vector2((rect.size.x - sz.x) * 0.5, y), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.55))

# Tikken (pijltjesbesturing): de linkerduim stuurt op de linkerhelft van het scherm
# (links van SPLIT = links, rechts ervan = rechts; je duim kan heen en weer schuiven),
# de rechterduim remt (onderin) of trekt de handrem (daarboven). Automatisch gas.
class TapSteer extends HalfTouch:
	const SPLIT := 300.0
	const BRAKE_Y := 450.0
	var steer_l := false
	var steer_r := false
	var braking := false
	var hand := false

	func _ready() -> void:
		super._ready()
		_gas(true)

	func _apply() -> void:
		steer_l = false
		steer_r = false
		braking = false
		hand = false
		for i in pos:
			var p: Vector2 = pos[i]
			if p.x < 640.0:
				if p.x < SPLIT:
					steer_l = true
				else:
					steer_r = true
			elif p.y > BRAKE_Y:
				braking = true
			else:
				hand = true
		if steer_l and steer_r:
			steer_l = false
			steer_r = false
		_act("steer_left", steer_l)
		_act("steer_right", steer_r)
		_act("brake", braking)
		_act("handbrake", hand)
		_gas(not braking)

	func _draw() -> void:
		_zone(Rect2(12, 470, SPLIT - 22, 238), "<", steer_l)
		_zone(Rect2(SPLIT + 10, 470, 250, 238), ">", steer_r)
		_zone(Rect2(1010, 470, 258, 238), "REM", braking)
		_zone(Rect2(1010, 260, 258, 180), "HANDREM", hand)

# Kantelen: telefoon kantelen = sturen; links vasthouden = remmen, rechts = handrem.
# In de browser leest dit de kanteling via deviceorientation (op iPhone moet je eerst één
# keer op het scherm tikken om toestemming te geven), anders de versnellingsmeter.
class TiltSteer extends HalfTouch:
	const FULL := 22.0      # graden kantelen voor vol sturen
	const DEAD := 2.5       # graden die niet meetellen
	var web := false
	var tilt := 0.0

	func _ready() -> void:
		super._ready()
		_gas(true)
		web = OS.has_feature("web")
		if web:
			JavaScriptBridge.eval("""
				if (!window.parkstadTiltSetup) {
					window.parkstadTiltSetup = true;
					window.parkstadTilt = 0;
					var h = function (e) {
						var a = (screen.orientation && screen.orientation.angle) || window.orientation || 0;
						var t;
						if (a == 90) t = e.beta; else if (a == 270 || a == -90) t = -e.beta; else t = e.gamma;
						window.parkstadTilt = t || 0;
					};
					var start = function () { window.addEventListener('deviceorientation', h); };
					if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
						var f = function () {
							DeviceOrientationEvent.requestPermission().then(function (r) { if (r == 'granted') start(); });
							document.removeEventListener('touchend', f);
						};
						document.addEventListener('touchend', f);
					} else { start(); }
				}
			""", true)

	func _process(_delta: float) -> void:
		if blocked:
			return
		var deg: float
		if web:
			deg = float(JavaScriptBridge.eval("window.parkstadTilt || 0", true))
		else:
			var g: Vector3 = Input.get_accelerometer()
			deg = rad_to_deg(atan2(g.y, -g.z)) if g.length() > 0.1 else 0.0
		if Game.tilt_inverted():
			deg = -deg
		tilt = deg
		var a: float = clampf((absf(deg) - DEAD) / (FULL - DEAD), 0.0, 1.0)
		_act("steer_right", deg > 0.0 and a > 0.0, a)
		_act("steer_left", deg < 0.0 and a > 0.0, a)
		queue_redraw()

	func _apply() -> void:
		_act("brake", left)
		_act("handbrake", right)
		_gas(not left)

	func _draw() -> void:
		_zone(Rect2(12, 470, 300, 238), "REMMEN", left)
		_zone(Rect2(968, 470, 300, 238), "HANDREM", right)
		# kantelmeter bovenin
		var c := Vector2(640 + Fit.extra().x * 0.5, 128)
		draw_line(c - Vector2(120, 0), c + Vector2(120, 0), Color(1, 1, 1, 0.35), 4.0)
		var x: float = clampf(tilt / FULL, -1.0, 1.0) * 120.0
		draw_circle(c + Vector2(x, 0), 11.0, Color(0.95, 0.87, 0.4, 0.8))
