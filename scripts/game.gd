extends Node
# Autoload "Game": lijst met levels, voortgang (beste tijden, medailles) en scènewissels.

const SAVE_PATH := "user://parkstad_progress.cfg"
# Automatische tests zetten PARKSTAD_SAVE naar een eigen bestand, zodat ze nooit aan je
# echte records komen.
var save_path: String = OS.get_environment("PARKSTAD_SAVE") if OS.get_environment("PARKSTAD_SAVE") != "" else SAVE_PATH
const MENU_SCENE := "res://scenes/menu.tscn"
const RACE_SCENE := "res://scenes/race.tscn"
const GARAGE_SCENE := "res://scenes/garage.tscn"
const Catalog = preload("res://scripts/cars_catalog.gd")

# Eén level per gemeente, met de Buitenring als finale. Levels zonder script zijn nog niet gebouwd.
const LEVELS := [
    {"id": "heerlen", "name": "Heerlen", "sub": "Mijnmuseum ON I  >  Pancratiusplein", "script": "res://scripts/levels/level_heerlen.gd"},
    {"id": "kerkrade", "name": "Kerkrade", "sub": "Nieuwstraat  >  Rolduc  >  Parkstad Limburg Stadion", "script": "res://scripts/levels/level_kerkrade.gd"},
    {"id": "landgraaf", "name": "Landgraaf", "sub": "Megaland / Pinkpop  >  SnowWorld", "script": "res://scripts/levels/level_landgraaf.gd"},
    {"id": "brunssum", "name": "Brunssum", "sub": "Brunssummerheide  >  Schachtwiel  >  Gregoriuskerk", "script": "res://scripts/levels/level_brunssum.gd"},
    {"id": "simpelveld", "name": "Simpelveld", "sub": "Miljoenenlijn  >  Huize Loreto  >  Station Simpelveld", "script": "res://scripts/levels/level_simpelveld.gd"},
    {"id": "voerendaal", "name": "Voerendaal", "sub": "Kasteel Puth  >  Kasteel Cortenbach", "script": "res://scripts/levels/level_voerendaal.gd"},
    {"id": "beekdaelen", "name": "Beekdaelen", "sub": "Schinveldse bossen  >  Kasteel Terborgh", "script": "res://scripts/levels/level_beekdaelen.gd"},
    {"id": "finale", "name": "Parkstad Finale", "sub": "De Buitenring: 3 ronden langs alle gemeenten", "script": "res://scripts/levels/level_finale.gd"},
]

const MEDAL_NAMES := ["", "BRONS", "ZILVER", "GOUD"]
const MEDAL_COLORS := [Color.WHITE, Color("c98a4b"), Color("d7dde2"), Color("f2c94c")]

var current_index := 0

# Versie van het spel (Project > Instellingen > application/config/version); staat klein
# naast de titel in het menu, zodat je ziet welke versie er live staat.
static func version() -> String:
    return String(ProjectSettings.get_setting("application/config/version", ""))
var _cfg := ConfigFile.new()

func _ready() -> void:
    _cfg.load(save_path)
    _migrate_slots()
    _migrate()
    _setup_audio()
    _set_tab_icon()
    process_mode = Node.PROCESS_MODE_ALWAYS

# ---------------------------------------------------------------- batterij
# Beeldjes per seconde: tijdens het racen 60 (of 30 met Batterij sparen); in menu's, de
# garage, het laadscherm, het pauzemenu en het eindscherm is 30 ruim genoeg. Telefoons met
# een 120 Hz-scherm zouden anders twee keer zoveel tekenen. Minder beeldjes = minder werk
# voor de grafische chip = koeler en zuiniger.
const RACE_FPS := 60
const SAVER_FPS := 30
const CALM_FPS := 30
var _fps_t := 0.0

func _process(delta: float) -> void:
    var fps: int = CALM_FPS
    var sc := get_tree().current_scene
    if sc != null and not get_tree().paused and "state" in sc and int(sc.get("state")) <= 1:
        var pn = sc.get("panel")
        if pn == null or not (pn as CanvasItem).visible:
            fps = SAVER_FPS if battery_saver() else RACE_FPS
    if Engine.max_fps != fps:
        Engine.max_fps = fps
    # in de browser het gemeten aantal beeldjes per seconde bijhouden (voor tests)
    _fps_t -= delta
    if _fps_t <= 0.0 and OS.has_feature("web"):
        _fps_t = 1.0
        JavaScriptBridge.eval("window.parkstadFps = %d" % Engine.get_frames_per_second(), true)

func battery_saver() -> bool:
    return bool(_cfg.get_value("settings", "battery_saver", false))

func set_battery_saver(on: bool) -> void:
    _cfg.set_value("settings", "battery_saver", on)
    _cfg.save(save_path)

# Icoon in het browsertabblad: Godot zet bij het opstarten zijn eigen logo neer (het
# projecticoon zit alleen als geïmporteerde textuur in het spel), dus zetten we hier
# zelf het Parkstad Racer-icoon terug.
func _set_tab_icon() -> void:
    if not OS.has_feature("web"):
        return
    var tex: Texture2D = load("res://assets/icon/icon_144.png")
    if tex == null:
        return
    var img: Image = tex.get_image()
    if img == null:
        return
    if img.is_compressed():
        img.decompress()
    img.resize(64, 64, Image.INTERPOLATE_LANCZOS)
    DisplayServer.set_icon(img)

# ---------------------------------------------------------------- geluid
# Drie geluidskanalen met eigen volume (instelbaar in het menu): muziek, effecten, motor.
# Ze staan vast in default_bus_layout.tres: in de webversie worden kanalen die pas tijdens
# het spelen worden aangemaakt niet doorgegeven aan de browser, en dan blijft het stil.
# Het aanmaken hieronder is alleen nog een vangnet.
const AUDIO_BUSES := {"Music": "Muziek", "SFX": "Effecten", "Motor": "Motor en banden"}
const AUDIO_DEFAULTS := {"Music": 0.6, "SFX": 0.8, "Motor": 0.6}
const MENU_MUSIC := "res://assets/menu_music.wav"
var music: AudioStreamPlayer

func _setup_audio() -> void:
    for bus in AUDIO_BUSES:
        if AudioServer.get_bus_index(bus) < 0:
            AudioServer.add_bus()
            var i: int = AudioServer.bus_count - 1
            AudioServer.set_bus_name(i, bus)
            AudioServer.set_bus_send(i, "Master")
        _apply_volume(bus)
    music = AudioStreamPlayer.new()
    music.bus = "Music"
    music.process_mode = Node.PROCESS_MODE_ALWAYS
    music.stream = load(MENU_MUSIC)   # loopt via de importinstelling (edit/loop_mode)
    add_child(music)

func volume(bus: String) -> float:
    return float(_cfg.get_value("settings", "volume_" + bus, AUDIO_DEFAULTS[bus]))

func set_volume(bus: String, v: float) -> void:
    _cfg.set_value("settings", "volume_" + bus, clampf(v, 0.0, 1.0))
    _cfg.save(save_path)
    _apply_volume(bus)

func _apply_volume(bus: String) -> void:
    var i: int = AudioServer.get_bus_index(bus)
    var v: float = volume(bus)
    AudioServer.set_bus_mute(i, v <= 0.001)
    AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))

# Aanraakknoppen in de race: "auto" (alleen met touchscreen), "on" of "off".
func touch_mode() -> String:
    return String(_cfg.get_value("settings", "touch", "auto"))

func set_touch_mode(mode: String) -> void:
    _cfg.set_value("settings", "touch", mode)
    _cfg.save(save_path)

# Soort aanraakbesturing: "stick" (joystick + knoppen, standaard sinds 20-11), "tap" (tikken) of "tilt" (kantelen).
# Moeilijkheid (Instellingen): 0 = Makkelijk, 1 = Normaal, 2 = Moeilijk. Geldt voor alle profielen.
const DIFFICULTIES := ["Makkelijk", "Normaal", "Moeilijk"]
func difficulty() -> int:
    return clampi(int(_cfg.get_value("settings", "difficulty", 1)), 0, 2)

func set_difficulty(d: int) -> void:
    _cfg.set_value("settings", "difficulty", clampi(d, 0, 2))
    _cfg.save(save_path)

# Grafische kwaliteit (Instellingen): "auto" (lager op telefoons en tablets), "high" of "low".
func graphics_mode() -> String:
    return String(_cfg.get_value("settings", "graphics", "auto"))

func set_graphics_mode(mode: String) -> void:
    _cfg.set_value("settings", "graphics", mode)
    _cfg.save(save_path)

func low_graphics() -> bool:
    match graphics_mode():
        "low": return true
        "high": return false
    return OS.has_feature("mobile") or OS.has_feature("web_ios") or OS.has_feature("web_android")

# Politie (Instellingen): aan of uit. Op Makkelijk komt er nooit politie.
func police_enabled() -> bool:
    return bool(_cfg.get_value("settings", "police", true))

func set_police_enabled(on: bool) -> void:
    _cfg.set_value("settings", "police", on)
    _cfg.save(save_path)

# Camerastandpunt in de race (Instellingen en pauzemenu).
const CAMERA_VIEWS := [["normal", "Achter"], ["far", "Achter, hoger en verder"], ["close", "Achter, dichtbij"], ["hood", "Bumper (geen auto in beeld)"]]

func camera_view() -> String:
    var v := String(_cfg.get_value("settings", "camera", "normal"))
    for c in CAMERA_VIEWS:
        if c[0] == v:
            return v
    return "normal"

func set_camera_view(v: String) -> void:
    _cfg.set_value("settings", "camera", v)
    _cfg.save(save_path)

func camera_view_name(v: String) -> String:
    for c in CAMERA_VIEWS:
        if c[0] == v:
            return String(c[1])
    return v

func touch_scheme() -> String:
    return String(_cfg.get_value("settings", "touch_scheme", "stick"))

func set_touch_scheme(mode: String) -> void:
    _cfg.set_value("settings", "touch_scheme", mode)
    _cfg.save(save_path)

func tilt_inverted() -> bool:
    return bool(_cfg.get_value("settings", "tilt_invert", false))

func set_tilt_inverted(on: bool) -> void:
    _cfg.set_value("settings", "tilt_invert", on)
    _cfg.save(save_path)

func play_menu_music() -> void:
    if music.stream != null and not music.playing:
        music.play()

func stop_music() -> void:
    music.stop()

# Oude opslag: de startauto heette eerst "sjeng", nu "john". Zet bezit, keuze, upgrades
# en lak één keer om, zodat er niets verloren gaat.
func _migrate() -> void:
    var changed := false
    var owned: Array = _cfg.get_value(_sec("profile"), "owned", [])
    if owned.has("sjeng"):
        owned.erase("sjeng")
        if not owned.has("john"):
            owned.insert(0, "john")
        _cfg.set_value(_sec("profile"), "owned", owned)
        changed = true
    if String(_cfg.get_value(_sec("profile"), "selected", "")) == "sjeng":
        _cfg.set_value(_sec("profile"), "selected", "john")
        changed = true
    if _cfg.has_section(_sec("upgrades")):
        for k in _cfg.get_section_keys(_sec("upgrades")):
            if String(k).begins_with("sjeng_"):
                _cfg.set_value(_sec("upgrades"), "john_" + String(k).substr(6), _cfg.get_value(_sec("upgrades"), k))
                _cfg.erase_section_key(_sec("upgrades"), k)
                changed = true
    if _cfg.has_section_key(_sec("paint"), "sjeng"):
        _cfg.set_value(_sec("paint"), "john", _cfg.get_value(_sec("paint"), "sjeng"))
        _cfg.erase_section_key(_sec("paint"), "sjeng")
        changed = true
    # Records van vóór de bochtfysica (19-11) zijn niet meer te halen: één keer alle beste
    # tijden wissen, in alle profielen. Medailles blijven staan (die spelen levels vrij).
    if int(_cfg.get_value("settings", "records_reset", 0)) < 1:
        for i in range(1, SLOTS + 1):
            if _cfg.has_section(_sec("best", i)):
                _cfg.erase_section(_sec("best", i))
        _cfg.set_value("settings", "records_reset", 1)
        changed = true
    if changed:
        _cfg.save(save_path)

# ---------------------------------------------------------------- profielen
# Er zijn 3 opslagplekken. Alles van een speler (geld, auto's, upgrades, lak, records,
# medailles, testmodus) staat in secties met het voorvoegsel "p<nr>_", bv. "p1_profile".
# Geluidsinstellingen en het actieve profiel staan in "settings" en gelden voor iedereen.
# In de browser (webexport) schrijft Godot user:// naar de IndexedDB van de site, dus dit
# bestand blijft daar ook gewoon bewaard.
const SLOTS := 3
const PROFILE_SECTIONS := ["profile", "best", "medal", "upgrades", "paint", "settings"]
var slot := 1

func _sec(name: String, i: int = -1) -> String:
    return "p%d_%s" % [slot if i < 0 else i, name]

func _save() -> void:
    _cfg.set_value(_sec("profile"), "last", int(Time.get_unix_time_from_system()))
    _cfg.save(save_path)

# Oude opslag (zonder profielen) wordt profiel 1, zodat er niets verloren gaat.
func _migrate_slots() -> void:
    var changed := false
    for name in PROFILE_SECTIONS:
        if not _cfg.has_section(name):
            continue
        for k in _cfg.get_section_keys(name):
            if name == "settings" and k != "test_mode":
                continue
            _cfg.set_value("p1_" + name, k, _cfg.get_value(name, k))
            _cfg.erase_section_key(name, k)
            changed = true
    if changed and not _cfg.has_section_key("p1_profile", "name"):
        _cfg.set_value("p1_profile", "name", "Speler 1")
    slot = int(_cfg.get_value("settings", "slot", 1))
    if not slot_exists(slot):
        for i in range(1, SLOTS + 1):
            if slot_exists(i):
                slot = i
                break
    if not slot_exists(slot):
        create_slot(1, "Speler 1")
        return
    if changed:
        _cfg.save(save_path)

func slot_exists(i: int) -> bool:
    return _cfg.has_section_key(_sec("profile", i), "name")

func profile_name(i: int = -1) -> String:
    return String(_cfg.get_value(_sec("profile", i), "name", ""))

# Samenvatting voor het profielscherm.
func slot_info(i: int) -> Dictionary:
    # alle medailles: per stad en per niveau telt elke medaille mee (jouw keuze, 25-11)
    var medals := [0, 0, 0, 0]
    for lv in LEVELS:
        for d in range(DIFFICULTIES.size()):
            medals[best_medal(String(lv["id"]), d, i)] += 1
    return {"name": profile_name(i), "money": int(_cfg.get_value(_sec("profile", i), "money", 0)),
        "gold": medals[3], "silver": medals[2], "bronze": medals[1],
        "last": int(_cfg.get_value(_sec("profile", i), "last", 0))}

func select_slot(i: int) -> void:
    if not slot_exists(i):
        return
    slot = i
    _cfg.set_value("settings", "slot", i)
    _cfg.save(save_path)

func _erase_slot(i: int) -> void:
    for name in PROFILE_SECTIONS:
        if _cfg.has_section(_sec(name, i)):
            _cfg.erase_section(_sec(name, i))

# Nieuw (leeg) profiel op plek i en meteen kiezen.
func create_slot(i: int, name: String) -> void:
    _erase_slot(i)
    _cfg.set_value(_sec("profile", i), "name", _clean_name(name, i))
    _cfg.set_value(_sec("profile", i), "owned", ["john"])
    _cfg.set_value(_sec("profile", i), "selected", "john")
    slot = i
    _cfg.set_value("settings", "slot", i)
    _save()

func rename_slot(i: int, name: String) -> void:
    if slot_exists(i):
        _cfg.set_value(_sec("profile", i), "name", _clean_name(name, i))
        _cfg.save(save_path)

# Wist een profiel. Was het het actieve profiel, dan wordt een ander gekozen (of een nieuw
# leeg profiel gemaakt als er geen meer over is).
func delete_slot(i: int) -> void:
    _erase_slot(i)
    if i == slot:
        for j in range(1, SLOTS + 1):
            if slot_exists(j):
                select_slot(j)
                return
        create_slot(1, "Speler 1")
        return
    _cfg.save(save_path)

func _clean_name(name: String, i: int) -> String:
    var n: String = name.strip_edges().substr(0, 16)
    return n if n != "" else "Speler %d" % i

func current_level() -> Dictionary:
    return LEVELS[current_index]

func is_built(i: int) -> bool:
    return String(LEVELS[i]["script"]) != ""

# Testmodus: alle gebouwde levels zijn speelbaar zonder eerst de vorige te halen.
func test_mode() -> bool:
    return bool(_cfg.get_value(_sec("settings"), "test_mode", false))

func set_test_mode(on: bool) -> void:
    _cfg.set_value(_sec("settings"), "test_mode", on)
    _save()

func is_unlocked(i: int) -> bool:
    if i == 0 or test_mode():
        return true
    # vrijspelen: in het vorige level in de top 3 eindigen (een medaille)
    return best_medal_any(String(LEVELS[i - 1]["id"])) > 0

# Tijden en medailles worden per moeilijkheid bewaard (sleutel "stad@0/1/2"). Resultaten
# van vóór die tijd (sleutel zonder @) tellen als Makkelijk: op welke moeilijkheid ze
# gereden zijn, weten we niet.
func _dkey(id: String, d: int) -> String:
    return "%s@%d" % [id, d]

func best_time(id: String, d: int = -1, i: int = -1) -> float:
    if d < 0:
        d = difficulty()
    var t := float(_cfg.get_value(_sec("best", i), _dkey(id, d), 0.0))
    if d == 0:
        var old := float(_cfg.get_value(_sec("best", i), id, 0.0))
        if old > 0.0 and (t <= 0.0 or old < t):
            t = old
    return t

func best_medal(id: String, d: int = -1, i: int = -1) -> int:
    if d < 0:
        d = difficulty()
    var m := int(_cfg.get_value(_sec("medal", i), _dkey(id, d), 0))
    if d == 0:
        m = maxi(m, int(_cfg.get_value(_sec("medal", i), id, 0)))
    return clampi(m, 0, 3)

func best_medal_any(id: String, i: int = -1) -> int:
    var m := 0
    for d in range(DIFFICULTIES.size()):
        m = maxi(m, best_medal(id, d, i))
    return m

# Geeft true terug als dit een nieuw record is (op de huidige moeilijkheid).
func record_finish(id: String, time: float, medal: int) -> bool:
    var d: int = difficulty()
    var old: float = best_time(id, d)
    var record: bool = old <= 0.0 or time < old
    if record:
        _cfg.set_value(_sec("best"), _dkey(id, d), time)
    if medal > best_medal(id, d):
        _cfg.set_value(_sec("medal"), _dkey(id, d), medal)
    _save()
    return record

var free_ride := false   # vrij rijden: geen tegenstanders, checkpoints, klok of geld

func start_level(i: int, free: bool = false) -> void:
    current_index = i
    free_ride = free
    stop_music()
    get_tree().paused = false
    get_tree().change_scene_to_file(RACE_SCENE)

func next_playable(i: int) -> int:
    var n: int = i + 1
    if n < LEVELS.size() and is_built(n) and is_unlocked(n):
        return n
    return -1

var menu_tab := "race"   # laatst gekozen tab in het menu

func go_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file(MENU_SCENE)


func garage() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file(GARAGE_SCENE)

# ---------------------------------------------------------------- profiel: geld en auto's
# Alles van de speler staat in de sectie "p<nr>_profile" van het actieve profiel.
func money() -> int:
    return int(_cfg.get_value(_sec("profile"), "money", 0))

func add_money(amount: int) -> void:
    _cfg.set_value(_sec("profile"), "money", maxi(0, money() + amount))
    _save()

func owned_cars() -> Array:
    return _cfg.get_value(_sec("profile"), "owned", ["john"])

func owns(car_id: String) -> bool:
    return owned_cars().has(car_id)

func selected_car() -> String:
    var c: String = String(_cfg.get_value(_sec("profile"), "selected", "john"))
    return c if owns(c) else "john"

func select_car(car_id: String) -> void:
    if owns(car_id):
        _cfg.set_value(_sec("profile"), "selected", car_id)
        _save()

# Prijs in de garage: in testmodus is alles gratis, zodat je elke auto en upgrade kunt
# uitproberen (tegenstanders, beloningen); je geld blijft dan gewoon staan.
func shop_price(price: int) -> int:
    return 0 if test_mode() else price

# Testmodus: alle upgrades van een auto weer op nul.
func reset_upgrades(car_id: String) -> void:
    for u in Catalog.UPGRADES:
        var k: String = "%s_%s" % [car_id, u["id"]]
        if _cfg.has_section_key(_sec("upgrades"), k):
            _cfg.erase_section_key(_sec("upgrades"), k)
    _save()

# Koopt een auto als er genoeg geld is; geeft true terug als het gelukt is.
func buy_car(car_id: String) -> bool:
    var price: int = shop_price(int(Catalog.car(car_id)["price"]))
    if owns(car_id) or money() < price:
        return false
    var list: Array = owned_cars().duplicate()
    list.append(car_id)
    _cfg.set_value(_sec("profile"), "owned", list)
    _cfg.set_value(_sec("profile"), "money", money() - price)
    _cfg.set_value(_sec("profile"), "selected", car_id)
    _save()
    return true

func upgrade_level(car_id: String, kind: String) -> int:
    return int(_cfg.get_value(_sec("upgrades"), "%s_%s" % [car_id, kind], 0))

func buy_upgrade(car_id: String, kind: String) -> bool:
    var lvl: int = upgrade_level(car_id, kind)
    if not owns(car_id) or lvl >= Catalog.UPGRADE_LEVELS:
        return false
    var price: int = shop_price(Catalog.upgrade_price(car_id, lvl))
    if money() < price:
        return false
    _cfg.set_value(_sec("upgrades"), "%s_%s" % [car_id, kind], lvl + 1)
    _cfg.set_value(_sec("profile"), "money", money() - price)
    _save()
    return true

func car_paint(car_id: String) -> Color:
    var c: Color = _cfg.get_value(_sec("paint"), car_id, Catalog.car(car_id)["color"])
    # de bijna-zwarte lak leek te veel op het asfalt en is uit de garage gehaald
    if c.is_equal_approx(Color("2b2b2e")):
        return Catalog.car(car_id)["color"]
    return c

func set_car_paint(car_id: String, c: Color) -> void:
    _cfg.set_value(_sec("paint"), car_id, c)
    _save()

# Rijwaarden van een auto inclusief upgrades.
func car_stats(car_id: String) -> Dictionary:
    var c: Dictionary = Catalog.car(car_id)
    var out := {"speed": float(c["speed"]), "accel": float(c["accel"]), "grip": float(c["grip"]), "brake": float(c["brake"])}
    for u in Catalog.UPGRADES:
        var lvl: int = upgrade_level(car_id, String(u["id"]))
        out[u["stat"]] = float(out[u["stat"]]) * (1.0 + float(u["step"]) * float(lvl))
    return out

static func format_money(n: int) -> String:
    var s := str(absi(n))
    var out := ""
    while s.length() > 3:
        out = "." + s.substr(s.length() - 3) + out
        s = s.substr(0, s.length() - 3)
    return ("-" if n < 0 else "") + "€ " + s + out

static func format_time(t: float) -> String:
    return "%02d:%05.2f" % [int(t / 60.0), fmod(t, 60.0)]
