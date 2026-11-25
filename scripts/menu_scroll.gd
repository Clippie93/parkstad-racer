extends Node
# Laat een menu (ontwerp 1280x720, midden op het scherm) op en neer vegen, zodat er op
# telefoons boven en onder wat ruimte is en niets tegen de rand of de afgeronde hoeken zit.
# Werkt ook als de veeg op een knop begint: zodra de vinger echt beweegt, wordt de knop
# losgelaten (er wordt dan niets aangetikt) en schuift het menu mee.
# Is een pagina langer dan het scherm (content_h), dan kan dat ook met het muiswiel.
const Fit = preload("res://scripts/screen_fit.gd")

const MARGIN := 64.0        # ruimte boven en onder het menu (ontwerppixels)
const START_DRAG := 14.0    # zoveel moet de vinger bewegen voor het een veeg is

var target: Control
var shift := 0.0
var touching := false
var finger := -1            # welke vinger veegt (Safari op de iPhone nummert vingers niet
                            # vanaf 0 maar met willekeurige grote getallen)
var dragging := false
var start := Vector2.ZERO
var speed := 0.0
var cancelling := false
var margin := 0.0           # MARGIN op aanraakschermen, anders 0 (zoals vroeger)
var content_h := 720.0      # hoogte van de getoonde pagina in ontwerppixels
var slider: Range = null    # schuifregelaar onder de vinger bij het neerzetten
var slider_value := 0.0

static func attach(c: Control) -> void:
	var s = load("res://scripts/menu_scroll.gd").new()
	s.margin = MARGIN if DisplayServer.is_touchscreen_available() else 0.0
	s.name = "MenuScroll"
	s.target = c
	c.add_child(s)

func _ready() -> void:
	get_viewport().size_changed.connect(_clamp)
	to_top()

func to_top() -> void:
	shift = _bounds().y
	speed = 0.0
	_apply()

func set_content_height(h: float) -> void:
	content_h = maxf(720.0, h)
	to_top()

# (laagste, hoogste) verschuiving: bovenaan staat de bovenkant op 'margin' van de rand,
# onderaan de onderkant van de pagina. Past alles, dan staat het menu zoals vroeger.
func _bounds() -> Vector2:
	var half: float = (Fit.screen().y - 720.0) * 0.5
	var hi: float = margin - half
	var lo: float = 720.0 + half - margin - content_h
	if lo >= hi:
		var v: float = clampf(0.0, hi, lo)
		return Vector2(v, v)
	return Vector2(lo, hi)

func _clamp() -> void:
	var b: Vector2 = _bounds()
	shift = clampf(shift, b.x, b.y)
	_apply()

func _apply() -> void:
	target.offset_top = -360.0 + shift
	target.offset_bottom = 360.0 + shift

func _input(event: InputEvent) -> void:
	if dragging and not cancelling and (event is InputEventMouseMotion or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and not event.pressed:
			dragging = false
		return
	# (een aanraking komt eerst als nagebootste muisklik binnen, nog voor de aanraking zelf)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not cancelling:
		_prepare_press(event.position)
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var b: Vector2 = _bounds()
		if b.x != b.y:
			shift += 60.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -60.0
			_clamp()
		return
	if event is InputEventScreenTouch:
		if event.pressed and not touching:
			finger = event.index
			touching = true
			start = event.position
			dragging = false
			speed = 0.0
		elif not event.pressed and event.index == finger:
			touching = false
			dragging = false
			finger = -1
	elif event is InputEventScreenDrag and event.index == finger and touching:
		if not dragging and absf(event.position.y - start.y) > START_DRAG:
			var b: Vector2 = _bounds()
			if b.x == b.y:
				return
			dragging = true
			_cancel_press()
			if slider != null and is_instance_valid(slider):
				slider.value = slider_value
			slider = null
		if dragging:
			var dy: float = event.relative.y
			shift += dy
			speed = dy / maxf(get_process_delta_time(), 0.001)
			_clamp()

# Na het loslaten nog even doorglijden.
func _process(delta: float) -> void:
	if touching or absf(speed) < 5.0:
		return
	shift += speed * delta
	speed = move_toward(speed, 0.0, 2600.0 * delta)
	var before := shift
	_clamp()
	if shift != before:
		speed = 0.0

# Laat de knop onder de vinger los op een punt buiten het scherm: dan wordt hij niet
# aangetikt als de vinger na de veeg weer wordt opgetild. Ook de muisbewegingen die bij
# de veeg horen gaan daarna niet meer naar de knoppen.
func _cancel_press() -> void:
	# eerst 'wegschuiven' (anders denkt de knop dat de vinger er nog op staat, want hij
	# schuift met de vinger mee), dan loslaten
	var mv := InputEventMouseMotion.new()
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	mv.position = Vector2(-10000, -10000)
	mv.global_position = mv.position
	cancelling = true
	get_viewport().push_input(mv)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = Vector2(-10000, -10000)
	ev.global_position = ev.position
	get_viewport().push_input(ev)
	cancelling = false

# Voor de knop onder de vinger: een keuzelijst klapt pas open bij loslaten (anders gaat
# hij al open als een veeg erop begint), en van een schuifregelaar onthouden we de
# waarde, zodat een veeg die erop begint het volume niet verandert.
func _prepare_press(p: Vector2) -> void:
	slider = null
	for c in target.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree() or not ctl.get_global_rect().has_point(p):
			continue
		if ctl is OptionButton:
			(ctl as OptionButton).action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		elif ctl is Slider:
			slider = ctl
			slider_value = (ctl as Slider).value
