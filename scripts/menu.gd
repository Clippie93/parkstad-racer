extends Control
# Hoofdmenu: één plaatsnaambord per gemeente, de Parkstad Finale als laatste. Een tik op
# een bord vraagt: racen of vrij rijden. Groot genoeg om op een telefoon te tikken.
# Verborgen testmodus: vijf keer snel op T drukken of op de titel PARKSTAD RACER tikken
# zet alle levels vrij (of weer dicht).

const Fit = preload("res://scripts/screen_fit.gd")
const MenuScroll = preload("res://scripts/menu_scroll.gd")
const Sfx = preload("res://scripts/sfx.gd")
const TITLE_RECT := Rect2(50, 14, 420, 70)   # titel in de kop (ontwerpcoördinaten)
const Header = preload("res://scripts/menu_header.gd")
const TouchControls = preload("res://scripts/touch_controls.gd")

const LIST_X := 60.0
const LIST_W := 1160.0
const ROW_H := 44.0
const SIGN_W := 270.0
const SIGN_H := 160.0
const SIGN_BLUE := Color("1d4f9c")

var t_presses: Array[float] = []
var toast: Label
var tabs: Array = []
var race_page: Control
var help_page: Control
var settings_page: Control
var profile_page: Control
var together_page: Control
var together_status: Label
var together_players: Label
var together_code: LineEdit
var together_leave: Button
var lobby_box: Control          # instellingen van de kamer (host kiest, de rest ziet ze)
var lobby_level: OptionButton
var lobby_rule: OptionButton
var lobby_start: Button
var lobby_info: Label
var first_level: Button
var help_box: VBoxContainer
var controls_help: Label     # Besturing-kolom: tekst hangt af van toetsenbord of aanraken
var scroll: Node

func _ready() -> void:
    Fit.center(self)
    MenuScroll.attach(self)
    scroll = get_node_or_null("MenuScroll")
    tabs = Header.build(self, Game.menu_tab, _on_tab)
    race_page = _race_page()
    add_child(race_page)
    help_page = _help_page()
    add_child(help_page)
    settings_page = _settings_page()
    add_child(settings_page)
    profile_page = _profile_page()
    add_child(profile_page)
    together_page = _together_page()
    add_child(together_page)
    Game.play_menu_music()
    toast = _label("", 18, Color("f3df68"))
    toast.position = Vector2(LIST_X, 670)
    add_child(toast)
    _show(Game.menu_tab if Game.menu_tab != "garage" else "race")

func _on_tab(id: String) -> void:
    if id == "garage":
        Game.garage()
    else:
        _show(id)

func _show(id: String) -> void:
    Game.menu_tab = id
    Header.set_active(tabs, id)
    race_page.visible = id == "race"
    help_page.visible = id == "help"
    settings_page.visible = id == "settings"
    profile_page.visible = id == "profile"
    together_page.visible = id == "together"
    if id == "together":
        _refresh_together()
    if id == "race" and first_level != null:
        first_level.call_deferred("grab_focus")
    if scroll != null:
        scroll.set_content_height(720.0)
        if id == "help":
            if controls_help != null:
                controls_help.text = _controls_text()   # besturing kan bij Instellingen gewijzigd zijn
            _fit_help.call_deferred()
        else:
            _fit_page.call_deferred(id)

# Ook de andere pagina's kunnen langer zijn dan het scherm (Instellingen): dan scrollen ze,
# ook met het muiswiel of de trackpad in de browser op de computer.
func _fit_page(id: String) -> void:
    await get_tree().process_frame
    if Game.menu_tab != id:
        return
    var page: Control = {"race": race_page, "settings": settings_page, "profile": profile_page, "together": together_page}.get(id, null)
    if page == null:
        return
    var bottom := 720.0
    for c in page.find_children("*", "Control", true, false):
        var ctl := c as Control
        if ctl.is_visible_in_tree():
            bottom = maxf(bottom, ctl.get_global_rect().end.y - page.get_global_rect().position.y + 30.0)
    scroll.set_content_height(bottom)

# De uitleg kan langer zijn dan het scherm: dan scrollt hij (zodra de tekst is opgemaakt).
func _fit_help() -> void:
    await get_tree().process_frame
    if Game.menu_tab == "help":
        scroll.set_content_height(help_box.position.y + help_box.get_combined_minimum_size().y + 30.0)

func _race_page() -> Control:
    var page := Control.new()
    page.set_anchors_preset(Control.PRESET_FULL_RECT)
    page.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var gap: float = (LIST_W - 4.0 * SIGN_W) / 3.0
    for i in range(Game.LEVELS.size()):
        var x: float = LIST_X + float(i % 4) * (SIGN_W + gap)
        var y: float = Header.CONTENT_Y + float(i / 4) * (SIGN_H + 72.0)
        var btn := _city_sign(i, Vector2(x, y))
        page.add_child(btn)
        page.add_child(_sign_status(i, Vector2(x, y + SIGN_H + 8.0)))
        if first_level == null and not btn.disabled:
            first_level = btn
    var hint := _label("Tik op een stad om te racen of vrij te rijden. Haal de top 3 om de volgende stad vrij te spelen.", 16, Color("8d96a0"))
    hint.position = Vector2(LIST_X + 4, Header.CONTENT_Y + 2.0 * (SIGN_H + 72.0) + 6.0)
    page.add_child(hint)
    if Game.test_mode():
        var tag := _label("TESTMODUS", 16, Color("ef5a4f"))
        tag.position = Vector2(LIST_X + LIST_W - 100, hint.position.y + 24.0)
        page.add_child(tag)
    return page

# Plaatsnaambord (blauw met witte rand en letters, zoals bij de bebouwde kom).
func _city_sign(i: int, at: Vector2) -> Button:
    var info: Dictionary = Game.LEVELS[i]
    var open: bool = Game.is_built(i) and Game.is_unlocked(i)
    var finale: bool = i == Game.LEVELS.size() - 1
    var btn := Button.new()
    btn.position = at
    btn.size = Vector2(SIGN_W, SIGN_H)
    btn.disabled = not open
    btn.focus_mode = Control.FOCUS_ALL
    var bg: Color = SIGN_BLUE if open else Color("3c4450")
    var states := {"normal": bg, "hover": bg.lightened(0.12), "pressed": bg.darkened(0.15), "disabled": bg, "focus": bg}
    for st in states:
        var sb := StyleBoxFlat.new()
        sb.bg_color = states[st]
        sb.set_corner_radius_all(14)
        sb.set_border_width_all(7 if st != "focus" else 9)
        sb.border_color = Color.WHITE if open else Color("7d8691")
        if st == "focus" or st == "hover":
            sb.border_color = Color("f3df68")
        if st == "focus":
            sb.draw_center = false
        btn.add_theme_stylebox_override(st, sb)
    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_FULL_RECT)
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    btn.add_child(box)
    var name_l := _label("Parkstad" if finale else String(info["name"]), 44, Color.WHITE if open else Color("9aa3ad"))
    name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(name_l)
    if finale:
        var sub := _label("Buitenring  -  finale", 20, Color.WHITE if open else Color("9aa3ad"))
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(sub)
    if open:
        btn.pressed.connect(func():
            Sfx.play(self, "click", -8.0)
            _choose_mode(i))
    return btn

# Onder het bord: beste tijd en medaille op de gekozen moeilijkheid (of waarom de stad nog
# dicht is), en daaronder per moeilijkheid in de kleur van de medaille die je daar hebt.
const DIFF_SHORT := ["Makkelijk", "Normaal", "Moeilijk"]
func _sign_status(i: int, at: Vector2) -> Control:
    var box := VBoxContainer.new()
    box.position = at
    box.size = Vector2(SIGN_W, 0)
    box.add_theme_constant_override("separation", 0)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var text := ""
    var color := Color("8d96a0")
    var open := false
    if not Game.is_built(i):
        text = "binnenkort"
    elif not Game.is_unlocked(i):
        text = "haal eerst %s" % Game.LEVELS[i - 1]["name"]
    else:
        open = true
        var id := String(Game.LEVELS[i]["id"])
        var best: float = Game.best_time(id)
        if best > 0.0:
            var medal: int = Game.best_medal(id)
            text = "%s   %s" % [Game.format_time(best), Game.MEDAL_NAMES[medal]]
            color = Game.MEDAL_COLORS[medal]
        else:
            text = "nog niet gereden"
            color = Color("cfd3d6")
    var l := _label(text, 20, color)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.custom_minimum_size = Vector2(SIGN_W, 0)
    box.add_child(l)
    if open:
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 12)
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var id := String(Game.LEVELS[i]["id"])
        for d in range(3):
            var m: int = Game.best_medal(id, d)
            var dl := _label(DIFF_SHORT[d], 14, Game.MEDAL_COLORS[m] if m > 0 else Color("4f5966"))
            row.add_child(dl)
        box.add_child(row)
    return box

# Keuzescherm na een tik op een stad: racen of vrij rijden.
var mode_layer: Control
func _choose_mode(i: int) -> void:
    _close_mode()
    var info: Dictionary = Game.LEVELS[i]
    mode_layer = Control.new()
    mode_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(mode_layer)
    var dim := ColorRect.new()
    dim.color = Color(0.03, 0.05, 0.08, 0.82)
    dim.position = Vector2(-3000, -3000)
    dim.size = Vector2(7280, 6720)
    dim.gui_input.connect(func(e):
        if e is InputEventMouseButton and e.pressed:
            _close_mode())
    mode_layer.add_child(dim)
    var title := _label(String(info["name"]).to_upper(), 48, Color("f3df68"))
    title.position = Vector2(0, 180)
    title.size = Vector2(1280, 60)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode_layer.add_child(title)
    var race := _mode_button("RACEN", "Tegen 7 tegenstanders, met\ncheckpoints, klok en prijzengeld", Vector2(230, 270), Color("b8322c"))
    race.pressed.connect(func(): Game.start_level(i, false))
    mode_layer.add_child(race)
    var ride := _mode_button("VRIJ RIJDEN", "Rustig langs de bezienswaardigheden,\nzonder klok of tegenstanders", Vector2(660, 270), Color("2e7d4f"))
    ride.pressed.connect(func(): Game.start_level(i, true))
    mode_layer.add_child(ride)
    var back := Button.new()
    back.text = "Terug"
    back.add_theme_font_size_override("font_size", 24)
    back.position = Vector2(540, 520)
    back.size = Vector2(200, 56)
    back.pressed.connect(_close_mode)
    mode_layer.add_child(back)
    race.focus_neighbor_right = ride.get_path()
    ride.focus_neighbor_left = race.get_path()
    race.call_deferred("grab_focus")

func _mode_button(title: String, text: String, at: Vector2, color: Color) -> Button:
    var b := Button.new()
    b.position = at
    b.size = Vector2(390, 220)
    for st in ["normal", "hover", "pressed", "focus"]:
        var sb := StyleBoxFlat.new()
        sb.bg_color = color.lightened(0.1) if st == "hover" else (color.darkened(0.15) if st == "pressed" else color)
        sb.set_corner_radius_all(14)
        sb.set_border_width_all(6)
        sb.border_color = Color("f3df68") if st in ["focus", "hover"] else Color(1, 1, 1, 0.7)
        if st == "focus":
            sb.draw_center = false
        b.add_theme_stylebox_override(st, sb)
    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_FULL_RECT)
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 14)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.add_child(box)
    var t := _label(title, 42, Color.WHITE)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(t)
    var d := _label(text, 19, Color(1, 1, 1, 0.85))
    d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(d)
    return b

func _close_mode() -> void:
    if mode_layer != null:
        mode_layer.queue_free()
        mode_layer = null
        if first_level != null:
            first_level.grab_focus()

func _profile_page() -> Control:
    var page := Control.new()
    page.set_anchors_preset(Control.PRESET_FULL_RECT)
    page.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var y: float = Header.CONTENT_Y
    for i in range(1, Game.SLOTS + 1):
        page.add_child(_slot_card(i, y))
        y += 124.0
    var note := _label("Elk profiel heeft eigen geld, auto's, upgrades, records en medailles. Geluidsinstellingen gelden voor alle profielen.", 15, Color("8d96a0"))
    note.position = Vector2(LIST_X + 4, y + 4)
    page.add_child(note)
    return page

func _slot_card(i: int, y: float) -> Control:
    var active: bool = Game.slot_exists(i) and i == Game.slot
    var card := Panel.new()
    card.position = Vector2(LIST_X, y)
    card.size = Vector2(LIST_W, 112)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color("1a2230")
    sb.set_corner_radius_all(8)
    if active:
        sb.border_color = Color("f3df68")
        sb.set_border_width_all(3)
    card.add_theme_stylebox_override("panel", sb)
    var buttons := HBoxContainer.new()
    buttons.position = Vector2(LIST_W - 520, 34)
    buttons.size = Vector2(500, 44)
    buttons.alignment = BoxContainer.ALIGNMENT_END
    buttons.add_theme_constant_override("separation", 10)
    card.add_child(buttons)
    if not Game.slot_exists(i):
        var empty := _label("%d.  Leeg" % i, 26, Color("6f7880"))
        empty.position = Vector2(22, 36)
        card.add_child(empty)
        buttons.add_child(_card_button("Nieuw profiel", func(): _ask_name(i, true)))
        return card
    var info: Dictionary = Game.slot_info(i)
    var head := HBoxContainer.new()
    head.position = Vector2(22, 14)
    head.add_theme_constant_override("separation", 14)
    card.add_child(head)
    head.add_child(_label("%d.  %s" % [i, info["name"]], 26, Color("f3df68") if active else Color.WHITE))
    if active:
        var tag := _label("IN GEBRUIK", 15, Color("101722"))
        var tsb := StyleBoxFlat.new()
        tsb.bg_color = Color("f3df68")
        tsb.set_corner_radius_all(4)
        tsb.content_margin_left = 8
        tsb.content_margin_right = 8
        tag.add_theme_stylebox_override("normal", tsb)
        tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        head.add_child(tag)
    var line := "%s     %d goud   %d zilver   %d brons" % [Game.format_money(int(info["money"])), info["gold"], info["silver"], info["bronze"]]
    var l2 := _label(line, 18, Color("cfd3d6"))
    l2.position = Vector2(26, 52)
    card.add_child(l2)
    var l3 := _label("Laatst gespeeld: %s" % _date(int(info["last"])), 15, Color("8d96a0"))
    l3.position = Vector2(26, 80)
    card.add_child(l3)
    if not active:
        buttons.add_child(_card_button("Kies", func():
            Game.select_slot(i)
            _reload()))
    buttons.add_child(_card_button("Hernoem", func(): _ask_name(i, false)))
    buttons.add_child(_card_button("Wis", func(): _ask_delete(i)))
    return card

func _card_button(text: String, action: Callable) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(130, 44)
    b.add_theme_font_size_override("font_size", 18)
    b.pressed.connect(func():
        Sfx.play(self, "click", -8.0)
        action.call())
    return b

func _date(unix: int) -> String:
    if unix <= 0:
        return "-"
    var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
    var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix + bias * 60)
    return "%02d-%02d-%d  %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]

func _reload() -> void:
    Game.menu_tab = "profile"
    get_tree().reload_current_scene()

# Naam vragen voor een nieuw profiel (is_new) of om te hernoemen.
func _ask_name(i: int, is_new: bool) -> void:
    # Op de telefoon (web) het venstertje van de browser zelf: dan komt het toetsenbord
    # gewoon tevoorschijn (in het spel zelf deed iOS dat niet).
    if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
        var ask: String = "Naam voor het nieuwe profiel (max. 16 tekens):" if is_new else "Nieuwe naam voor dit profiel (max. 16 tekens):"
        var cur: String = "" if is_new else Game.profile_name(i)
        var r = JavaScriptBridge.eval("prompt(%s, %s)" % [JSON.stringify(ask), JSON.stringify(cur)], true)
        if r == null:
            return
        var nm: String = String(r).strip_edges().left(16)
        if is_new:
            Game.create_slot(i, nm)
        else:
            Game.rename_slot(i, nm)
        _reload()
        return
    var dlg := ConfirmationDialog.new()
    dlg.title = "Nieuw profiel" if is_new else "Profiel hernoemen"
    dlg.ok_button_text = "Maak profiel" if is_new else "Opslaan"
    dlg.cancel_button_text = "Annuleren"
    var box := VBoxContainer.new()
    box.add_child(_label("Naam (max. 16 tekens):", 16, Color.WHITE))
    var edit := LineEdit.new()
    edit.max_length = 16
    edit.custom_minimum_size = Vector2(320, 36)
    edit.text = "" if is_new else Game.profile_name(i)
    edit.placeholder_text = "Speler %d" % i
    box.add_child(edit)
    dlg.add_child(box)
    dlg.register_text_enter(edit)
    var ok := func():
        if is_new:
            Game.create_slot(i, edit.text)
        else:
            Game.rename_slot(i, edit.text)
        _reload()
    dlg.confirmed.connect(ok)
    dlg.canceled.connect(dlg.queue_free)
    add_child(dlg)
    dlg.popup_centered()
    edit.grab_focus()
    edit.select_all()

func _ask_delete(i: int) -> void:
    var dlg := ConfirmationDialog.new()
    dlg.title = "Profiel wissen"
    dlg.dialog_text = "Weet je zeker dat je profiel \"%s\" wilt wissen?\nAl het geld, de auto's, records en medailles van dit profiel\nworden verwijderd. Dit kan niet ongedaan worden gemaakt." % Game.profile_name(i)
    dlg.ok_button_text = "Wissen"
    dlg.cancel_button_text = "Annuleren"
    dlg.confirmed.connect(func():
        Game.delete_slot(i)
        _reload())
    dlg.canceled.connect(dlg.queue_free)
    add_child(dlg)
    dlg.popup_centered()
    dlg.get_cancel_button().grab_focus()   # Enter = annuleren, niet per ongeluk wissen

func _settings_page() -> Control:
    var page := Control.new()
    page.set_anchors_preset(Control.PRESET_FULL_RECT)
    page.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var head := _label("Geluid", 26, Color("f3df68"))
    head.position = Vector2(LIST_X, Header.CONTENT_Y)
    page.add_child(head)
    var y: float = Header.CONTENT_Y + 56.0
    for bus in Game.AUDIO_BUSES:
        var l := _label(String(Game.AUDIO_BUSES[bus]), 20, Color("cfd3d6"))
        l.position = Vector2(LIST_X, y)
        page.add_child(l)
        var pct := _label("", 20, Color.WHITE)
        pct.position = Vector2(LIST_X + 640, y)
        page.add_child(pct)
        var sl := HSlider.new()
        sl.position = Vector2(LIST_X + 220, y + 4)
        sl.size = Vector2(400, 24)
        sl.min_value = 0.0
        sl.max_value = 1.0
        sl.step = 0.05
        sl.value = Game.volume(bus)
        pct.text = "%d%%" % roundi(sl.value * 100.0)
        var b: String = String(bus)
        sl.value_changed.connect(func(v: float):
            Game.set_volume(b, v)
            pct.text = "%d%%" % roundi(v * 100.0)
            if b == "SFX":
                Sfx.play(self, "click", -4.0))
        page.add_child(sl)
        y += 52.0
    var head2 := _label("Besturing", 26, Color("f3df68"))
    head2.position = Vector2(LIST_X, y + 30.0)
    page.add_child(head2)
    var tl := _label("Aanraakknoppen", 20, Color("cfd3d6"))
    tl.position = Vector2(LIST_X, y + 86.0)
    page.add_child(tl)
    var opt := OptionButton.new()
    opt.position = Vector2(LIST_X + 220, y + 80.0)
    opt.custom_minimum_size = Vector2(520, 40)
    opt.add_theme_font_size_override("font_size", 18)
    var modes := [["auto", "Automatisch (alleen op touchscreen)"], ["on", "Altijd aan"], ["off", "Uit"]]
    for m in modes:
        opt.add_item(String(m[1]))
        if m[0] == Game.touch_mode():
            opt.select(opt.item_count - 1)
    opt.item_selected.connect(func(idx: int): Game.set_touch_mode(String(modes[idx][0])))
    page.add_child(opt)
    var sl2 := _label("Soort besturing", 20, Color("cfd3d6"))
    sl2.position = Vector2(LIST_X, y + 138.0)
    page.add_child(sl2)
    var opt2 := OptionButton.new()
    opt2.position = Vector2(LIST_X + 220, y + 132.0)
    opt2.custom_minimum_size = Vector2(520, 40)
    opt2.add_theme_font_size_override("font_size", 18)
    var schemes := [["tap", "Pijltjes: links sturen, rechts remmen (auto-gas)"], ["tilt", "Kantelen: telefoon als stuur (auto-gas)"], ["stick", "Joystick + knoppen"]]
    for m in schemes:
        opt2.add_item(String(m[1]))
        if m[0] == Game.touch_scheme():
            opt2.select(opt2.item_count - 1)
    opt2.item_selected.connect(func(idx: int): Game.set_touch_scheme(String(schemes[idx][0])))
    page.add_child(opt2)
    var inv := CheckBox.new()
    inv.text = "Kantelen omkeren (als sturen de verkeerde kant op gaat)"
    inv.add_theme_font_size_override("font_size", 17)
    inv.position = Vector2(LIST_X + 220, y + 184.0)
    _checkbox_look(inv)
    inv.button_pressed = Game.tilt_inverted()
    inv.toggled.connect(func(on: bool): Game.set_tilt_inverted(on))
    page.add_child(inv)
    var dl := _label("Moeilijkheid", 20, Color("cfd3d6"))
    dl.position = Vector2(LIST_X, y + 242.0)
    page.add_child(dl)
    var opt3 := OptionButton.new()
    opt3.position = Vector2(LIST_X + 220, y + 236.0)
    opt3.custom_minimum_size = Vector2(520, 40)
    opt3.add_theme_font_size_override("font_size", 18)
    var diffs := ["Makkelijk: tragere tegenstanders, meer tijd", "Normaal", "Moeilijk: snellere tegenstanders, minder tijd"]
    for d in diffs:
        opt3.add_item(d)
    opt3.select(Game.difficulty())
    opt3.item_selected.connect(func(idx: int):
        Game.set_difficulty(idx)
        Header.refresh_who(self))
    page.add_child(opt3)
    var pol := CheckBox.new()
    pol.text = "Politie inschakelen"
    pol.add_theme_font_size_override("font_size", 17)
    _checkbox_look(pol)
    pol.position = Vector2(LIST_X + 220, y + 284.0)
    pol.button_pressed = Game.police_enabled()
    pol.toggled.connect(func(on: bool): Game.set_police_enabled(on))
    page.add_child(pol)
    # Beeld: rechts naast Geluid (daar is ruimte)
    var gh := _label("Beeld", 26, Color("f3df68"))
    gh.position = Vector2(860, Header.CONTENT_Y)
    page.add_child(gh)
    var opt4 := OptionButton.new()
    opt4.position = Vector2(860, Header.CONTENT_Y + 50.0)
    opt4.custom_minimum_size = Vector2(360, 40)
    opt4.add_theme_font_size_override("font_size", 18)
    var gfx := [["auto", "Automatisch"], ["high", "Mooi"], ["low", "Snel"]]
    for m in gfx:
        opt4.add_item(String(m[1]))
        if m[0] == Game.graphics_mode():
            opt4.select(opt4.item_count - 1)
    opt4.item_selected.connect(func(idx: int): Game.set_graphics_mode(String(gfx[idx][0])))
    page.add_child(opt4)
    var gt := _label("Snel: lagere resolutie, minder schaduw\nen detail in de verte. Automatisch kiest\nSnel op telefoon en tablet.", 16, Color("9aa3ab"))
    gt.position = Vector2(860, Header.CONTENT_Y + 100.0)
    page.add_child(gt)
    # camerastandpunt (ook te wisselen in het pauzemenu)
    var ch := _label("Camera", 20, Color("cfd3d6"))
    ch.position = Vector2(860, Header.CONTENT_Y + 190.0)
    page.add_child(ch)
    var opt5 := OptionButton.new()
    opt5.position = Vector2(860, Header.CONTENT_Y + 222.0)
    opt5.custom_minimum_size = Vector2(360, 40)
    opt5.add_theme_font_size_override("font_size", 18)
    for c in Game.CAMERA_VIEWS:
        opt5.add_item(String(c[1]))
        if c[0] == Game.camera_view():
            opt5.select(opt5.item_count - 1)
    opt5.item_selected.connect(func(idx: int): Game.set_camera_view(String(Game.CAMERA_VIEWS[idx][0])))
    page.add_child(opt5)
    # batterij sparen: 30 beeldjes per seconde en geen schaduwen
    var bat := CheckBox.new()
    bat.text = "Batterij sparen"
    bat.add_theme_font_size_override("font_size", 17)
    _checkbox_look(bat)
    bat.position = Vector2(860, Header.CONTENT_Y + 280.0)
    bat.button_pressed = Game.battery_saver()
    bat.toggled.connect(func(on: bool): Game.set_battery_saver(on))
    page.add_child(bat)
    var bt := _label("30 beeldjes per seconde en geen schaduwen:
de telefoon blijft koeler en gaat langer mee.", 16, Color("9aa3ab"))
    bt.position = Vector2(860, Header.CONTENT_Y + 320.0)
    page.add_child(bt)
    # iPhone/iPad in de browser: uitleg om het spel op het beginscherm te zetten
    # (die komt ook vanzelf, zie html/head_include in export_presets.cfg)
    # Android (Chrome e.d.): de knop opent meteen de installatievraag van de browser
    if _js_true("window.parkstadCanInstallApp && window.parkstadCanInstallApp()"):
        var ih := _label("App", 20, Color("cfd3d6"))
        ih.position = Vector2(860, Header.CONTENT_Y + 390.0)
        page.add_child(ih)
        var ib := _card_button("Installeer Parkstad Racer als app", func():
            JavaScriptBridge.eval("window.parkstadInstallApp && window.parkstadInstallApp()", true))
        ib.position = Vector2(860, Header.CONTENT_Y + 422.0)
        ib.custom_minimum_size = Vector2(360, 44)
        ib.add_theme_font_size_override("font_size", 16)
        page.add_child(ib)
    elif _js_true("window.parkstadCanInstall && window.parkstadCanInstall()"):
        var ah := _label("Beginscherm", 20, Color("cfd3d6"))
        ah.position = Vector2(860, Header.CONTENT_Y + 390.0)
        page.add_child(ah)
        var ab := _card_button("Zo zet je het spel op je beginscherm", func():
            JavaScriptBridge.eval("window.parkstadShowInstall && window.parkstadShowInstall()", true))
        ab.position = Vector2(860, Header.CONTENT_Y + 422.0)
        ab.custom_minimum_size = Vector2(360, 44)
        ab.add_theme_font_size_override("font_size", 16)
        page.add_child(ab)
    return page

# Vraag iets aan de webpagina; de browser geeft ja/nee terug als 0/1 (of niets).
func _js_true(expr: String) -> bool:
    if not OS.has_feature("web"):
        return false
    var r = JavaScriptBridge.eval("(%s) ? 1 : 0" % expr, true)
    return r != null and typeof(r) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL] and int(r) == 1

# Besturing-uitleg voor dit apparaat: toetsen, of de gekozen aanraakbesturing.
func _controls_text() -> String:
    if not TouchControls.enabled():
        return "Gas: pijltje omhoog / W\nRemmen en achteruit: pijltje omlaag / S\nSturen: pijltjes / A en D\nHandrem: spatie\nTerug naar checkpoint: R\nPauze: Esc\n\nCamera wissel je in het pauzemenu."
    var t: String
    match Game.touch_scheme():
        "tilt":
            t = "Gas gaat vanzelf.\nSturen: kantel de telefoon.\nLinks vasthouden: remmen.\nRechts vasthouden: handrem."
        "tap":
            t = "Gas gaat vanzelf.\nSturen: links op het scherm (linker- of rechtervlak).\nRechts onderin: remmen.\nRechts daarboven: handrem."
        _:
            t = "Sturen: joystick links.\nRechts: gas, rem en handrem."
    return t + "\nBovenin: pauze en R (terug naar checkpoint).\n\nAndere besturing kies je bij Instellingen.\nCamera wissel je in het pauzemenu.\nTelefoon warm? Zet Batterij sparen aan."

func _help_page() -> Control:
    var page := Control.new()
    page.set_anchors_preset(Control.PRESET_FULL_RECT)
    page.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var cols := [
        ["Besturing", _controls_text()],
        ["De race", "Top 3 = medaille en de volgende stad vrij.\n\nDe klok loopt af: elk checkpoint geeft extra tijd. Ze staan vlak voor de bezienswaardigheden.\n\nVrij rijden: zonder klok en tegenstanders.\n\nHet niveau kies je bij Instellingen."],
        ["Geld en garage", "Prijzengeld per plaats: meer in latere steden en op Moeilijk.\n\nFlitspaal omver: extra tijd en geld. Door rood: kleine bonus.\n\nGeflitst? Dan komt de politie. Aangehouden: boete en tijdverlies. Ontsnapt: bonus.\n\nFietser geraakt: -8 s en de politie komt.\n\nIn de garage: auto's, upgrades en lak."],
    ]
    help_box = VBoxContainer.new()
    help_box.position = Vector2(LIST_X, Header.CONTENT_Y)
    help_box.size = Vector2(LIST_W, 0)
    help_box.add_theme_constant_override("separation", 36)
    help_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    page.add_child(help_box)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 40)
    help_box.add_child(row)
    var w := (LIST_W - 2.0 * 40.0) / 3.0
    for c in cols:
        var col := VBoxContainer.new()
        col.custom_minimum_size = Vector2(w, 0)
        col.add_theme_constant_override("separation", 12)
        row.add_child(col)
        col.add_child(_label(String(c[0]), 26, Color("f3df68")))
        var body := _label(String(c[1]), 18, Color("cfd3d6"))
        if c[0] == "Besturing":
            controls_help = body
        body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        body.custom_minimum_size = Vector2(w, 0)
        col.add_child(body)
    var credit := _label("Motorgeluid: \"rally car idle loop\" via Pixabay (freesound_community), Pixabay-licentie.\nStoomtrein: \"Steam Train Locomotive\" door MeijstroAudio (freesound.org/s/371885, CC BY 4.0).\nStoomfluit: \"Steam train whistles; pulls out\" door craigsmith (freesound.org/s/675313, CC0).\nAWACS: \"airplane pass\" via Pixabay (freesound_community).\nAuto's in het verkeer: Car Kit door Kenney (kenney.nl, CC0).\nOverige geluiden en muziek zijn in code gemaakt.", 14, Color("8d96a0"))
    help_box.add_child(credit)
    return page

func _input(event: InputEvent) -> void:
    if mode_layer != null and event.is_action_pressed("ui_cancel"):
        _close_mode()
        get_viewport().set_input_as_handled()
        return
    # vijf keer snel op T, of (op telefoon/tablet) vijf keer snel op de titel tikken
    var tap := false
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
        tap = true
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var local: Vector2 = (make_input_local(event) as InputEventMouseButton).position
        tap = TITLE_RECT.has_point(local)
    if tap:
        var now: float = Time.get_ticks_msec() / 1000.0
        t_presses.append(now)
        while t_presses.size() > 0 and now - t_presses[0] > 3.0:
            t_presses.pop_front()
        if t_presses.size() >= 5:
            t_presses.clear()
            var on: bool = not Game.test_mode()
            Game.set_test_mode(on)
            toast.text = "Testmodus aan: alle levels vrij" if on else "Testmodus uit"
            get_viewport().set_input_as_handled()
            await get_tree().create_timer(1.2).timeout
            get_tree().reload_current_scene()

# Duidelijke vinkjes: uit = lichte rand, aan = geel vlak met donker vinkje.
var _box_off: Texture2D
var _box_on: Texture2D
func _checkbox_look(cb: CheckBox) -> void:
    if _box_off == null:
        _box_off = _box_texture(false)
        _box_on = _box_texture(true)
    for n in ["unchecked", "unchecked_disabled"]:
        cb.add_theme_icon_override(n, _box_off)
    for n in ["checked", "checked_disabled"]:
        cb.add_theme_icon_override(n, _box_on)
    cb.add_theme_constant_override("h_separation", 12)
    cb.add_theme_color_override("font_color", Color("cfd3d6"))
    cb.add_theme_color_override("font_hover_color", Color.WHITE)
    cb.add_theme_color_override("font_pressed_color", Color.WHITE)
    cb.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
    cb.add_theme_color_override("font_focus_color", Color.WHITE)

static func _box_texture(on: bool) -> Texture2D:
    const N := 30
    var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var edge := Color("f3df68") if on else Color("cfd3d6")
    var fill := Color("f3df68") if on else Color("1e2938")
    for y in N:
        for x in N:
            var dx: float = maxf(0.0, maxf(5.0 - x, x - (N - 6.0)))
            var dy: float = maxf(0.0, maxf(5.0 - y, y - (N - 6.0)))
            var r: float = sqrt(dx * dx + dy * dy)   # afgeronde hoeken
            if r > 5.5:
                continue
            var border: bool = x < 3 or y < 3 or x >= N - 3 or y >= N - 3 or r > 2.5
            img.set_pixel(x, y, edge if border else fill)
    if on:
        var ink := Color("101722")
        var pts := [Vector2(7, 15), Vector2(12, 21), Vector2(23, 9)]
        for k in range(2):
            var a: Vector2 = pts[k]
            var b: Vector2 = pts[k + 1]
            for t in range(41):
                var p: Vector2 = a.lerp(b, float(t) / 40.0)
                for oy in range(-2, 2):
                    for ox in range(-2, 2):
                        var q := Vector2i(int(p.x) + ox, int(p.y) + oy)
                        if q.x >= 0 and q.y >= 0 and q.x < N and q.y < N:
                            img.set_pixelv(q, ink)
    return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------- samen racen (test)
# Fase 1 van de multiplayer (MULTIPLAYER_PLAN.md): kamer maken of meedoen met een code.
# Daarna kiest iedereen zelf hetzelfde level bij Racen en zie je elkaar als spookauto.
func _together_page() -> Control:
    var page := Control.new()
    page.set_anchors_preset(Control.PRESET_FULL_RECT)
    page.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var head := _label("Samen racen", 26, Color("f3df68"))
    head.position = Vector2(LIST_X, Header.CONTENT_Y)
    page.add_child(head)
    var tag := _label("TEST", 14, Color("101722"))
    var tag_bg := ColorRect.new()
    tag_bg.color = Color("e07b28")
    tag_bg.position = Vector2(LIST_X + 182.0, Header.CONTENT_Y + 8.0)
    tag_bg.size = Vector2(52, 22)
    page.add_child(tag_bg)
    tag.position = tag_bg.position + Vector2(8, 1)
    page.add_child(tag)
    var info := _label("Maak een kamer en geef de code aan je vrienden, of doe mee met hun code. De host " +
        "(wie de kamer maakte) kiest rechts het level en start de race voor iedereen. Nog in de testfase: " +
        "je rijdt door elkaar heen en er doen nog geen tegenstanders van de computer mee.", 17, Color("cfd3d6"))
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.custom_minimum_size = Vector2(780, 0)
    info.position = Vector2(LIST_X, Header.CONTENT_Y + 46.0)
    info.size = Vector2(780, 0)
    page.add_child(info)
    var y: float = Header.CONTENT_Y + 150.0
    var make := _card_button("Nieuwe kamer", _new_room)
    make.position = Vector2(LIST_X, y)
    make.custom_minimum_size = Vector2(220, 52)
    page.add_child(make)
    together_code = LineEdit.new()
    together_code.placeholder_text = "CODE"
    together_code.max_length = 4
    together_code.custom_minimum_size = Vector2(120, 52)
    together_code.position = Vector2(LIST_X + 250.0, y)
    together_code.add_theme_font_size_override("font_size", 24)
    together_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
    together_code.text_submitted.connect(func(_t): _join_room())
    page.add_child(together_code)
    var join := _card_button("Meedoen", _join_room)
    join.position = Vector2(LIST_X + 380.0, y)
    join.custom_minimum_size = Vector2(160, 52)
    page.add_child(join)
    together_leave = _card_button("Kamer verlaten", func():
        Game.net().close()
        _refresh_together())
    together_leave.position = Vector2(LIST_X + 570.0, y)
    together_leave.custom_minimum_size = Vector2(190, 52)
    page.add_child(together_leave)
    together_status = _label("", 24, Color.WHITE)
    together_status.position = Vector2(LIST_X, y + 80.0)
    page.add_child(together_status)
    together_players = _label("", 19, Color("cfd3d6"))
    together_players.position = Vector2(LIST_X, y + 124.0)
    page.add_child(together_players)
    # lobby rechts: level, autoregel en starten (alleen de host kan kiezen)
    lobby_box = Control.new()
    lobby_box.position = Vector2(860, Header.CONTENT_Y)
    lobby_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    page.add_child(lobby_box)
    var lh := _label("Race", 26, Color("f3df68"))
    lobby_box.add_child(lh)
    var ll := _label("Level", 18, Color("cfd3d6"))
    ll.position = Vector2(0, 50)
    lobby_box.add_child(ll)
    lobby_level = OptionButton.new()
    lobby_level.position = Vector2(0, 76)
    lobby_level.custom_minimum_size = Vector2(360, 44)
    lobby_level.add_theme_font_size_override("font_size", 18)
    for i in range(Game.LEVELS.size()):
        lobby_level.add_item(String(Game.LEVELS[i]["name"]), i)
        lobby_level.set_item_disabled(i, not Game.is_unlocked(i))
    lobby_level.item_selected.connect(func(idx: int):
        Game.lobby["level"] = lobby_level.get_item_id(idx)
        Game.send_lobby())
    lobby_box.add_child(lobby_level)
    var rl := _label("Auto's", 18, Color("cfd3d6"))
    rl.position = Vector2(0, 132)
    lobby_box.add_child(rl)
    lobby_rule = OptionButton.new()
    lobby_rule.position = Vector2(0, 158)
    lobby_rule.custom_minimum_size = Vector2(360, 44)
    lobby_rule.add_theme_font_size_override("font_size", 18)
    lobby_rule.add_item("Eigen garage (met upgrades)", 0)
    lobby_rule.add_item("Gelijke auto's (John Hatchback)", 1)
    lobby_rule.item_selected.connect(func(idx: int):
        Game.lobby["rule"] = "equal" if idx == 1 else "own"
        Game.send_lobby())
    lobby_box.add_child(lobby_rule)
    lobby_start = _card_button("Start de race", func(): Game.start_mp_race())
    lobby_start.position = Vector2(0, 230)
    lobby_start.custom_minimum_size = Vector2(360, 56)
    lobby_box.add_child(lobby_start)
    lobby_info = _label("", 17, Color("8d96a0"))
    lobby_info.position = Vector2(0, 296)
    lobby_info.custom_minimum_size = Vector2(360, 0)
    lobby_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lobby_box.add_child(lobby_info)
    # bijwerken als er iets verandert in de kamer, en elke seconde (ping)
    var net := Game.net()
    net.welcomed.connect(_refresh_together.unbind(3))
    net.joined.connect(_refresh_together.unbind(2))
    net.left.connect(_refresh_together.unbind(1))
    net.host_changed.connect(_refresh_together.unbind(1))
    net.disconnected.connect(_refresh_together)
    net.message.connect(_on_lobby_message)
    net.room_created.connect(_on_room_created)
    net.failed.connect(_on_net_failed)
    var timer := Timer.new()
    timer.wait_time = 1.0
    timer.autostart = true
    timer.timeout.connect(func():
        if together_page.visible:
            _refresh_together())
    page.add_child(timer)
    return page

func _on_lobby_message(_from: int, msg: Dictionary) -> void:
    if String(msg.get("t", "")) == "lobby":
        _refresh_together.call_deferred()

func _on_room_created(code: String) -> void:
    Game.net().join(code, Game.player_name())

func _on_net_failed(reason: String) -> void:
    toast.text = reason
    together_status.text = ""
    _refresh_together()

func _new_room() -> void:
    toast.text = ""
    together_status.text = "Kamer maken..."
    Game.net().new_room()

func _join_room() -> void:
    toast.text = ""
    var code := together_code.text.strip_edges().to_upper()
    # op de telefoon (web) het venstertje van de browser: daar komt het toetsenbord wel
    if code.length() != 4 and OS.has_feature("web") and DisplayServer.is_touchscreen_available():
        var r = JavaScriptBridge.eval("prompt(%s, %s)" % [JSON.stringify("Code van de kamer (4 letters):"), JSON.stringify("")], true)
        if r == null:
            return
        code = String(r).strip_edges().to_upper()
        together_code.text = code
    if code.length() != 4:
        toast.text = "Een kamercode heeft 4 letters."
        return
    together_status.text = "Verbinden met %s..." % code
    Game.net().join(code, Game.player_name())

func _refresh_together() -> void:
    if together_status == null:
        return
    var net := Game.net()
    together_leave.visible = Game.in_room()
    lobby_box.visible = Game.in_room()
    if Game.in_room():
        var host: bool = net.is_host()
        lobby_level.disabled = not host
        lobby_rule.disabled = not host
        lobby_start.visible = host
        lobby_level.select(lobby_level.get_item_index(int(Game.lobby["level"])))
        lobby_rule.select(1 if String(Game.lobby["rule"]) == "equal" else 0)
        lobby_info.text = ("Iedereen in de kamer start tegelijk. Je verdient prijzengeld, maar geen medailles." if host
            else "De host kiest het level en start de race.")
    if not Game.in_room():
        if not together_status.text.ends_with("..."):
            together_status.text = "Niet in een kamer."
        together_players.text = ""
        return
    together_status.text = "Kamer %s  ·  jij bent speler %d%s  ·  ping %d ms" % [net.code, net.my_id,
        " (host)" if net.is_host() else "", int(net.rtt_ms)]
    var lines: Array = []
    var ids: Array = net.players.keys()
    ids.sort()
    for id in ids:
        lines.append("%d.  %s%s%s" % [id, net.players[id], "  (host)" if id == net.host_id else "",
            "  ·  jij" if id == net.my_id else ""])
    together_players.text = "\n".join(lines)

func _label(text: String, size: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
