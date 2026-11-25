extends RefCounted
# Gedeelde kop van het menu en de garage: titel, geld en een rij tabbladen.
# Alle tabs horen bij het menu, behalve "garage": dat is een eigen scène.
const Sfx = preload("res://scripts/sfx.gd")

const TABS := [["race", "Racen"], ["garage", "Garage"], ["profile", "Profiel"], ["help", "Uitleg"], ["settings", "Instellingen"]]
const BAR_Y := 92.0
const TAB_H := 46.0
const CONTENT_Y := BAR_Y + TAB_H + 24.0
const YELLOW := Color("f3df68")

# Bouwt de kop op parent. on_tab(id) wordt aangeroepen bij een klik op een tab.
# Geeft de tabknoppen terug (op volgorde van TABS).
static func build(parent: Control, active: String, on_tab: Callable) -> Array:
	var bg := ColorRect.new()
	bg.color = Color("101722")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:      # doorlopen tot de randen van brede/hoge schermen
		bg.set_offset(side, -3000.0)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		bg.set_offset(side, 3000.0)
	parent.add_child(bg)
	var title := _label("PARKSTAD RACER", 44, YELLOW)
	title.position = Vector2(60, 22)
	parent.add_child(title)
	var ver := _label("v" + Game.version(), 16, Color("8d96a0"))
	ver.position = Vector2(60 + title.get_combined_minimum_size().x + 12.0, 46)
	parent.add_child(ver)
	var cash := _label(Game.format_money(Game.money()), 30, Color("7be07b"))
	cash.name = "Cash"
	cash.position = Vector2(860, 30)
	cash.size = Vector2(360, 40)
	cash.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(cash)
	var who := _label("Profiel: %s" % Game.profile_name(), 16, Color("8d96a0"))
	who.position = Vector2(860, 8)
	who.size = Vector2(360, 22)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(who)
	var line := ColorRect.new()
	line.color = YELLOW
	line.position = Vector2(-3000, BAR_Y + TAB_H)
	line.size = Vector2(7280, 4)
	parent.add_child(line)
	var row := HBoxContainer.new()
	row.position = Vector2(60, BAR_Y)
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var buttons := []
	for t in TABS:
		var b := Button.new()
		b.text = String(t[1])
		b.custom_minimum_size = Vector2(180, TAB_H)
		b.add_theme_font_size_override("font_size", 21)
		b.focus_mode = Control.FOCUS_NONE
		_style(b, t[0] == active)
		var id: String = String(t[0])
		b.pressed.connect(func():
			Sfx.play(parent, "click", -8.0)
			on_tab.call(id))
		row.add_child(b)
		buttons.append(b)
	var quit := Button.new()
	quit.text = "Afsluiten"
	quit.custom_minimum_size = Vector2(140, 36)
	quit.position = Vector2(1080, BAR_Y + 6)
	quit.add_theme_font_size_override("font_size", 17)
	quit.focus_mode = Control.FOCUS_NONE
	quit.pressed.connect(func(): parent.get_tree().quit())
	# in de browser kan een spel zichzelf niet afsluiten
	quit.visible = not OS.has_feature("web")
	parent.add_child(quit)
	return buttons

static func refresh_cash(parent: Control) -> void:
	var l := parent.get_node_or_null("Cash") as Label
	if l != null:
		l.text = Game.format_money(Game.money())

static func set_active(buttons: Array, active: String) -> void:
	for i in buttons.size():
		_style(buttons[i], TABS[i][0] == active)

static func _style(b: Button, on: bool) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = YELLOW if on else Color("1e2938")
	n.corner_radius_top_left = 8
	n.corner_radius_top_right = 8
	var h := n.duplicate()
	h.bg_color = YELLOW if on else Color("2c3a4e")
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var fc := Color("101722") if on else Color("cfd3d6")
	b.add_theme_color_override("font_color", fc)
	b.add_theme_color_override("font_hover_color", fc if on else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", fc)

static func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
