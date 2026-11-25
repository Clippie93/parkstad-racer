extends Control
# Garage: auto's kopen en kiezen, upgrades kopen, lakkleur kiezen. Met een draaiend
# 3D-voorbeeld van de gekozen auto en balkjes voor de rijwaarden.
const Fit = preload("res://scripts/screen_fit.gd")
const MenuScroll = preload("res://scripts/menu_scroll.gd")
const Header = preload("res://scripts/menu_header.gd")
const Catalog = preload("res://scripts/cars_catalog.gd")

var view_id := ""            # auto die je bekijkt (hoeft niet van jou te zijn)
var car_list: GridContainer      # twee kolommen: 10 auto's passen zonder scrollen
var info_box: VBoxContainer
var preview_root: Node3D
var preview_car: ArcadeCar
var spin := 0.0
var toast: Label

# Maximale waarden voor de balkjes (snelste auto, volledig opgewaardeerd).
const MAX_STATS := {"speed": 75.0, "accel": 25.0, "grip": 24.0, "brake": 55.0}   # ruimte voor de Buitenring R met alle upgrades

func _ready() -> void:
    Fit.center(self)
    MenuScroll.attach(self)
    view_id = Game.selected_car()
    Header.build(self, "garage", func(id):
        Game.menu_tab = id
        if id != "garage":
            Game.go_menu())
    Game.play_menu_music()
    car_list = GridContainer.new()
    car_list.columns = 2
    car_list.position = Vector2(60, 162)
    car_list.size = Vector2(304, 0)
    car_list.add_theme_constant_override("h_separation", 6)
    car_list.add_theme_constant_override("v_separation", 6)
    add_child(car_list)

    # 3D-voorbeeld
    var svc := SubViewportContainer.new()
    svc.position = Vector2(380, 162)
    svc.size = Vector2(500, 330)
    svc.stretch = true
    add_child(svc)
    var sv := SubViewport.new()
    sv.own_world_3d = true
    sv.size = Vector2i(500, 330)
    svc.add_child(sv)
    preview_root = Node3D.new()
    sv.add_child(preview_root)
    _build_stage()

    info_box = VBoxContainer.new()
    info_box.position = Vector2(900, 162)
    info_box.size = Vector2(360, 0)
    info_box.add_theme_constant_override("separation", 6)
    add_child(info_box)

    toast = _label("", 20, Color("f3df68"))
    toast.position = Vector2(380, 510)
    toast.size = Vector2(500, 40)
    toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(toast)
    _refresh()

func _build_stage() -> void:
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("1b2430")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("d0d5df")
    env.environment.ambient_light_energy = 0.6
    env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment.tonemap_exposure = 0.6
    preview_root.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -30, 0)
    sun.light_energy = 0.9
    sun.shadow_enabled = true
    preview_root.add_child(sun)
    var floor := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 3.6
    cm.bottom_radius = 3.6
    cm.height = 0.1
    floor.mesh = cm
    var fm := StandardMaterial3D.new()
    fm.albedo_color = Color("3a3e44")
    floor.material_override = fm
    floor.position.y = -0.05
    preview_root.add_child(floor)
    var cam := Camera3D.new()
    cam.fov = 40.0
    preview_root.add_child(cam)
    cam.look_at_from_position(Vector3(4.2, 2.4, 5.6), Vector3(0, 0.6, 0))

func _show_preview() -> void:
    if preview_car != null:
        preview_car.queue_free()
    var info: Dictionary = Catalog.car(view_id)
    preview_car = ArcadeCar.new()
    preview_car.ai = true
    preview_car.car_style = String(info["style"])
    preview_car.body_color = Game.car_paint(view_id)
    preview_car.stripe_color = info["stripe"]
    preview_car.race_number = 1
    preview_root.add_child(preview_car)
    preview_car.set_physics_process(false)

func _process(delta: float) -> void:
    spin += delta * 0.5
    if preview_car != null:
        preview_car.rotation.y = spin

func _refresh() -> void:
    Header.refresh_cash(self)
    for c in car_list.get_children():
        c.queue_free()
    for info in Catalog.CARS:
        var id: String = String(info["id"])
        var b := Button.new()
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.custom_minimum_size = Vector2(149, 52)
        b.clip_text = true
        b.add_theme_font_size_override("font_size", 14)
        var status: String
        if id == Game.selected_car():
            status = "IN GEBRUIK"
        elif Game.owns(id):
            status = "in bezit"
        else:
            status = "gratis (testmodus)" if Game.test_mode() else Game.format_money(int(info["price"]))
        b.text = "%s\n%s" % [info["name"], status]
        if id == view_id:
            b.add_theme_color_override("font_color", Color("f3df68"))
        b.pressed.connect(_view.bind(id))
        car_list.add_child(b)
    _show_preview()
    _fill_info()

func _view(id: String) -> void:
    view_id = id
    toast.text = ""
    _refresh()

func _fill_info() -> void:
    for c in info_box.get_children():
        c.queue_free()
    var info: Dictionary = Catalog.car(view_id)
    var owned: bool = Game.owns(view_id)
    info_box.add_child(_label(String(info["name"]), 26, Color.WHITE))
    var t := _label(String(info["text"]), 15, Color("cfd3d6"))
    t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    t.custom_minimum_size = Vector2(360, 0)
    info_box.add_child(t)
    var st: Dictionary = Game.car_stats(view_id)
    for u in Catalog.UPGRADES:
        var stat: String = String(u["stat"])
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        var txt: String = String(u["text"])
        var name_l := _label(txt.substr(0, 1).to_upper() + txt.substr(1), 15, Color("cfd3d6"))
        name_l.custom_minimum_size = Vector2(120, 0)
        row.add_child(name_l)
        var bar := ProgressBar.new()
        bar.custom_minimum_size = Vector2(150, 18)
        bar.show_percentage = false
        bar.max_value = float(MAX_STATS[stat])
        bar.value = float(st[stat])
        row.add_child(bar)
        var val := _label("%d km/u" % roundi(float(st[stat]) * 3.6) if stat == "speed" else "%.1f" % float(st[stat]), 15, Color.WHITE)
        row.add_child(val)
        info_box.add_child(row)
    if not owned:
        var buy := Button.new()
        var price: int = Game.shop_price(int(info["price"]))
        buy.text = "Pakken (testmodus: gratis)" if Game.test_mode() else "Kopen voor %s" % Game.format_money(price)
        buy.custom_minimum_size = Vector2(360, 44)
        buy.add_theme_font_size_override("font_size", 19)
        buy.disabled = Game.money() < price
        buy.pressed.connect(_buy_car)
        info_box.add_child(buy)
        if buy.disabled:
            info_box.add_child(_label("Nog %s nodig. Win races en rij flitsers omver!" % Game.format_money(price - Game.money()), 14, Color("ef5a4f")))
        return
    if view_id != Game.selected_car():
        var sel := Button.new()
        sel.text = "Gebruik deze auto"
        sel.custom_minimum_size = Vector2(360, 40)
        sel.add_theme_font_size_override("font_size", 18)
        sel.pressed.connect(func():
            Game.select_car(view_id)
            _refresh())
        info_box.add_child(sel)
    info_box.add_child(_label("Upgrades", 20, Color("f3df68")))
    for u in Catalog.UPGRADES:
        var kind: String = String(u["id"])
        var lvl: int = Game.upgrade_level(view_id, kind)
        var b := Button.new()
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.custom_minimum_size = Vector2(360, 34)
        b.add_theme_font_size_override("font_size", 16)
        # niveau als "2/3": de bolletjes (● ○) zitten niet in het lettertype van de webversie
        var dots: String = "%d/%d" % [lvl, Catalog.UPGRADE_LEVELS]
        if lvl >= Catalog.UPGRADE_LEVELS:
            b.text = "%s  %s   max" % [u["name"], dots]
            b.disabled = true
        else:
            var price: int = Game.shop_price(Catalog.upgrade_price(view_id, lvl))
            b.text = "%s  %s   +%d%% %s   %s" % [u["name"], dots, roundi(float(u["step"]) * 100.0), u["text"], "gratis" if Game.test_mode() else Game.format_money(price)]
            b.disabled = Game.money() < price
            b.pressed.connect(_buy_upgrade.bind(kind))
        info_box.add_child(b)
    if Game.test_mode():
        var rs := Button.new()
        rs.text = "Upgrades terugzetten (testmodus)"
        rs.custom_minimum_size = Vector2(360, 30)
        rs.add_theme_font_size_override("font_size", 14)
        rs.pressed.connect(func():
            Game.reset_upgrades(view_id)
            toast.text = "Upgrades teruggezet"
            _refresh())
        info_box.add_child(rs)
    info_box.add_child(_label("Lakkleur", 18, Color("f3df68")))
    var paints := HBoxContainer.new()
    paints.add_theme_constant_override("separation", 4)
    for c in Catalog.PAINTS:
        var sw := Button.new()
        sw.custom_minimum_size = Vector2(30, 30)
        var sb := StyleBoxFlat.new()
        sb.bg_color = c
        sb.set_corner_radius_all(4)
        sw.add_theme_stylebox_override("normal", sb)
        var sh := sb.duplicate()
        sh.border_color = Color.WHITE
        sh.set_border_width_all(2)
        sw.add_theme_stylebox_override("hover", sh)
        sw.add_theme_stylebox_override("focus", sh)
        sw.pressed.connect(func():
            Game.set_car_paint(view_id, c)
            _refresh())
        paints.add_child(sw)
    info_box.add_child(paints)

func _buy_car() -> void:
    if Game.buy_car(view_id):
        toast.text = "Gekocht: %s!" % Catalog.car(view_id)["name"]
    _refresh()

func _buy_upgrade(kind: String) -> void:
    if Game.buy_upgrade(view_id, kind):
        toast.text = "Upgrade geïnstalleerd!"
    _refresh()

func _label(text: String, size: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
