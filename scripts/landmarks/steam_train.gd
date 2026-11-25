extends Node3D
# Stoomtrein van de Miljoenenlijn (ZLSM), naar jouw foto's (20-11): zwarte stoomlocomotief
# met rode biezen en wielen, tender en drie crème-rode rijtuigen. Rijdt over een recht
# spoor langs -Z en remt af voor het station.
# setup(start_z, stop_z, speed): begint bij start_z, staat stil bij stop_z.
const Kit = preload("res://scripts/build_kit.gd")

var stop_z := 0.0
var speed := 16.0
var cur := 16.0
# Rondjes (Simpelveld): de trein rijdt over een gesloten lus: het oostspoor langs het
# station (lokaal x = 0, naar -Z), een bocht naar het westspoor (x = -2r, terug naar +Z)
# en een bocht terug. Na het station staat hij even stil, rijdt dan de lus rond en wacht
# aan het noordeinde van het westspoor tot trigger() true geeft; dan rijdt hij weer het
# oostspoor op, zodat je hem elke ronde inhaalt.
# 0 = naar het station, 1 = stilstaan, 2 = rondrijden, 3 = wachten op trigger
const WEST_SPEED := 32.0
var state := 0
var looping := false
var z_top := 0.0
var z_bot := 0.0
var loop_r := 60.0
var s_head := 0.0
var s_stop := 0.0
var s_wait := 0.0
var dwell := 12.0
var wait_t := 0.0
var trigger: Callable
var smoke: Array[MeshInstance3D] = []
var puff_t := 0.0
var cars: Array = []        # [groep, afstand achter de kop]
var _g: Node3D
# geluid: een opname van een rijdende stoomlocomotief als loop (MeijstroAudio, freesound,
# CC BY 4.0, zie de uitleg). Bij LOOP_SPEED (zijn gewone snelheid langs de weg) klinkt hij
# zoals opgenomen; langzamer rijden = lager en trager. Stilstaan = stil.
const LOOP_SPEED := 20.0
var steam: AudioStreamPlayer3D
# fluit (gadzooks, freesound, CC0): bij vertrek uit het station, als hij weer op het spoor
# langs de weg komt en (Finale) als hij gaat remmen voor het station
var whistle: AudioStreamPlayer3D
var last_state := -1
var whistled := false
var start_whistle := 2.0    # na zoveel seconden één keer fluiten bij het begin van het level

func setup(start_z: float, stop_at: float, v: float) -> void:
    position.z = start_z
    stop_z = stop_at
    speed = v
    cur = v

# top/bot: z van het noord- en zuideinde van de rechte stukken, r: straal van de bochten.
func loop(top: float, bot: float, r: float, stop_time: float, when: Callable) -> void:
    looping = true
    z_top = top
    z_bot = bot
    loop_r = r
    dwell = stop_time
    trigger = when
    s_head = z_top - position.z
    s_stop = z_top - stop_z
    s_wait = 2.0 * (z_top - z_bot) + PI * r
    position.z = 0.0
    _place_cars()

func loop_length() -> float:
    return 2.0 * (z_top - z_bot) + 2.0 * PI * loop_r

# Positie en rijrichting op de lus, in lokale ruimte van de trein.
static func loop_pose(s: float, top: float, bot: float, r: float) -> Array:
    var straight: float = top - bot
    var arc: float = PI * r
    s = fposmod(s, 2.0 * straight + 2.0 * arc)
    if s < straight:
        return [Vector3(0, 0, top - s), Vector3(0, 0, -1)]
    s -= straight
    if s < arc:
        var a: float = s / r
        return [Vector3(-r + r * cos(a), 0, bot - r * sin(a)), Vector3(-sin(a), 0, -cos(a))]
    s -= arc
    if s < straight:
        return [Vector3(-2.0 * r, 0, bot + s), Vector3(0, 0, 1)]
    s -= straight
    var b: float = s / r
    return [Vector3(-r - r * cos(b), 0, top + r * sin(b)), Vector3(sin(b), 0, cos(b))]

func _place_cars() -> void:
    for c in cars:
        var pr: Array = loop_pose(s_head - float(c[1]), z_top, z_bot, loop_r)
        c[0].position = pr[0]
        c[0].basis = Basis.looking_at(pr[1], Vector3.UP)

func _ready() -> void:
    name = "Steam train"
    # elke wagen is een eigen groep, zodat de trein netjes door de bochten van de lus rijdt
    _g = _car("Loco", 0.0, -7.9, 7.4)
    _loco()
    _tender()
    # rijtuigen: crème bovenkant met een rode onderkant en een rond grijs dak
    for k in range(3):
        var z: float = 14.6 + float(k) * 12.7
        _g = _car("Coach", z, -6.2, 6.0)
        _coach(z)
    _sound()

func _sound() -> void:
    steam = AudioStreamPlayer3D.new()
    steam.stream = load("res://assets/steam_train_loop.wav")
    # een stoomtrein hoor je van ver: zacht afnemend en tot ruim een kilometer
    steam.unit_size = 55.0
    steam.max_distance = 1200.0
    steam.volume_db = -80.0
    steam.bus = "SFX"
    steam.position = Vector3(0, 3.0, -4.0)
    (cars[0][0] as Node3D).add_child(steam)
    whistle = AudioStreamPlayer3D.new()
    # vijf losse tooten uit "Steam train whistles; pulls out" (craigsmith, freesound, CC0);
    # elke keer een andere, nooit twee keer dezelfde achter elkaar
    var toots := AudioStreamRandomizer.new()
    toots.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
    toots.random_pitch = 1.0
    for i in range(5):
        toots.add_stream(i, load("res://assets/steam_whistle_%d.wav" % (i + 1)))
    whistle.stream = toots
    whistle.unit_size = 70.0
    whistle.max_distance = 1500.0
    whistle.volume_db = 2.0
    whistle.bus = "SFX"
    whistle.position = Vector3(0, 3.7, -1.2)
    (cars[0][0] as Node3D).add_child(whistle)

func _sound_step(delta: float) -> void:
    if steam == null:
        return
    var target_db := -80.0
    if cur > 0.3:
        steam.pitch_scale = clampf(cur / LOOP_SPEED, 0.55, 1.5)
        # optrekken vanuit stilstand: geleidelijk harder
        target_db = 2.0 + linear_to_db(clampf(cur / 6.0, 0.05, 1.0))
        if not steam.playing:
            steam.play(randf() * steam.stream.get_length())
    steam.volume_db = move_toward(steam.volume_db, target_db, 40.0 * delta)
    if steam.playing and cur <= 0.3 and steam.volume_db <= -60.0:
        steam.stop()
    if start_whistle > 0.0:
        start_whistle -= delta
        if start_whistle <= 0.0:
            whistle.play()
    if looping and state != last_state:
        if (last_state == 1 and state == 2) or (last_state == 3 and state == 0):
            whistle.play()
    last_state = state
    if not looping and not whistled and cur > 0.0 and position.z - stop_z < 140.0:
        whistled = true
        whistle.play()

# Groep voor één wagen met een eigen botsvorm (de auto rijdt niet meer door de trein heen).
func _car(n: String, anchor: float, z_front: float, z_back: float) -> Node3D:
    var body := AnimatableBody3D.new()
    body.name = n
    body.sync_to_physics = false
    body.position = Vector3(0, 0, anchor)
    var cs := CollisionShape3D.new()
    var sh := BoxShape3D.new()
    sh.size = Vector3(2.8, 3.6, z_back - z_front)
    cs.shape = sh
    cs.position = Vector3(0, 2.0, (z_front + z_back) * 0.5)
    body.add_child(cs)
    add_child(body)
    cars.append([body, anchor])
    return body

# Locomotief naar jouw foto's (20-11): zwart met rode biezen, rode wielen, rode bufferbalk
# met een rode baanschuiver, een grote koplamp boven op de rookkast. Front naar -Z.
func _loco() -> void:
    var black := Color("1a1b1d")
    var red := Color("b3202a")
    var steel := Color("8a8d90")
    var by := 2.45
    Kit.cyl(_g, "Boiler", Vector3(0, by, -3.6), 0.95, 0.95, 5.6, black, 18, "z")
    for z in [-5.6, -4.0, -2.4, -1.0]:
        Kit.cyl(_g, "Boiler band", Vector3(0, by, z), 0.97, 0.97, 0.06, Color("3a3b3e"), 18, "z")
    Kit.cyl(_g, "Smokebox", Vector3(0, by, -6.75), 1.02, 1.02, 0.9, Color("232427"), 18, "z")
    Kit.cyl(_g, "Smokebox door", Vector3(0, by, -7.22), 0.82, 0.82, 0.08, Color("2c2d30"), 18, "z")
    Kit.cyl(_g, "Door hub", Vector3(0, by, -7.28), 0.12, 0.12, 0.06, steel, 10, "z")
    Kit.box(_g, "Door strap", Vector3(0, by - 0.25, -7.27), Vector3(1.1, 0.06, 0.03), steel)
    # hoge schoorsteen die bovenaan iets uitloopt
    Kit.cyl(_g, "Chimney", Vector3(0, 3.85, -5.9), 0.3, 0.27, 1.1, black, 14)
    Kit.cyl(_g, "Chimney lip", Vector3(0, 4.5, -5.9), 0.38, 0.3, 0.22, black, 14)
    for dz in [-4.0, -2.4]:
        Kit.cyl(_g, "Dome", Vector3(0, 3.6, dz), 0.42, 0.52, 0.7, black, 14)
        var cap := MeshInstance3D.new()
        var cm := SphereMesh.new()
        cm.radius = 0.42
        cm.height = 0.42
        cm.is_hemisphere = true
        cap.mesh = cm
        cap.material_override = Kit.mat(black)
        cap.position = Vector3(0, 3.95, dz)
        _g.add_child(cap)
    Kit.cyl(_g, "Whistle", Vector3(0, 3.65, -1.2), 0.06, 0.06, 0.5, Color("c9a34a"), 6)
    # grote koplamp boven op de rookkast
    Kit.cyl(_g, "Headlamp", Vector3(0.35, 3.95, -6.85), 0.32, 0.28, 0.5, black, 14, "z")
    Kit.cyl(_g, "Headlamp glass", Vector3(0.35, 3.95, -7.11), 0.26, 0.26, 0.04, Color("fff3c2"), 14, "z")
    Kit.box(_g, "Headlamp bracket", Vector3(0.35, 3.55, -6.85), Vector3(0.3, 0.3, 0.3), black)
    # loopbord met rode rand, bufferbalk, buffers en baanschuiver
    Kit.box(_g, "Running board", Vector3(0, 1.4, -2.7), Vector3(2.7, 0.1, 9.2), black)
    for x in [-1.35, 1.35]:
        Kit.box(_g, "Running board edge", Vector3(x, 1.36, -2.7), Vector3(0.03, 0.12, 9.2), red)
    Kit.box(_g, "Buffer beam", Vector3(0, 1.15, -7.35), Vector3(2.7, 0.55, 0.25), red)
    for x in [-0.85, 0.85]:
        Kit.cyl(_g, "Buffer", Vector3(x, 1.15, -7.65), 0.16, 0.16, 0.4, Color("2a2b2e"), 10, "z")
        Kit.cyl(_g, "Buffer head", Vector3(x, 1.15, -7.88), 0.24, 0.24, 0.05, steel, 12, "z")
        # lampen op de bufferbalk, met een rode ring erboven
        Kit.cyl(_g, "Front lamp", Vector3(x * 1.05, 1.75, -7.3), 0.2, 0.18, 0.3, black, 12, "z")
        Kit.cyl(_g, "Front lamp glass", Vector3(x * 1.05, 1.75, -7.46), 0.16, 0.16, 0.03, Color("fff3c2"), 12, "z")
        Kit.cyl(_g, "Lamp ring", Vector3(x * 1.05, 2.1, -7.3), 0.1, 0.1, 0.04, red, 10, "z")
        # twee losse rode baanschuivers, één voor elke rail
        var plough := Kit.box(_g, "Plough", Vector3(x * 0.72, 0.42, -7.6), Vector3(0.75, 0.6, 0.08), red)
        plough.rotation = Vector3(-0.3, x * 0.5, 0.0)
    Kit.box(_g, "Coupling hook", Vector3(0, 1.1, -7.6), Vector3(0.12, 0.12, 0.35), steel)
    # cilinders voor, drie rode drijfwielen, drijf- en koppelstangen
    for x in [-1.0, 1.0]:
        Kit.cyl(_g, "Cylinder", Vector3(x * 1.15, 1.15, -5.9), 0.38, 0.38, 1.2, black, 12, "z")
        # klein voorloopwiel en vier grote drijfwielen: zwarte spaken, rode band
        Kit.cyl(_g, "Pony wheel", Vector3(x * 0.85, 0.45, -6.2), 0.45, 0.45, 0.1, red, 14, "x")
        Kit.cyl(_g, "Pony wheel centre", Vector3(x * 0.88, 0.45, -6.2), 0.36, 0.36, 0.1, black, 14, "x")
        for z in [-4.5, -2.95, -1.4, 0.15]:
            Kit.cyl(_g, "Driving wheel tyre", Vector3(x * 0.86, 0.75, z), 0.75, 0.75, 0.1, red, 20, "x")
            Kit.cyl(_g, "Driving wheel", Vector3(x * 0.89, 0.75, z), 0.64, 0.64, 0.1, Color("202123"), 20, "x")
            for k in range(4):
                var sp := Kit.box(_g, "Spoke", Vector3(x * 0.95, 0.75, z), Vector3(0.03, 1.22, 0.07), Color("3a3b3e"))
                sp.rotation.x = float(k) * PI / 4.0
            Kit.cyl(_g, "Wheel hub", Vector3(x * 0.97, 0.75, z), 0.16, 0.16, 0.06, red, 10, "x")
        Kit.box(_g, "Coupling rod", Vector3(x * 1.02, 0.9, -2.2), Vector3(0.07, 0.12, 4.8), steel)
        Kit.beam(_g, "Connecting rod", Vector3(x * 1.1, 1.15, -5.3), Vector3(x * 1.1, 0.9, -2.95), 0.09, steel)
        # rode bies langs het frame boven de wielen
        Kit.box(_g, "Frame lining", Vector3(x * 1.36, 1.55, -2.7), Vector3(0.03, 0.06, 9.2), red)
        Kit.box(_g, "Frame", Vector3(x * 1.3, 1.25, -3.2), Vector3(0.1, 0.5, 8.2), black)
    # cabine met ramen en een licht gebogen dak
    Kit.box(_g, "Cab", Vector3(0, 2.75, 1.0), Vector3(2.7, 2.7, 2.6), black)
    var roof := Kit.cyl(_g, "Cab roof", Vector3(0, 4.05, 1.0), 1.6, 1.6, 3.0, Color("26272a"), 16, "z")
    roof.scale = Vector3(1.0, 1.0, 0.18)
    for x in [-1.36, 1.36]:
        Kit.box(_g, "Cab window", Vector3(x, 3.35, 1.4), Vector3(0.04, 0.75, 0.9), Color("3c4448"))
        Kit.box(_g, "Cab lining", Vector3(x * 1.005, 2.0, 1.0), Vector3(0.03, 0.05, 2.4), red)
        Kit.box(_g, "Cab lining", Vector3(x * 1.005, 2.0 + 0.6, 1.0 + 1.15), Vector3(0.03, 1.2, 0.05), red)
        Kit.box(_g, "Cab lining", Vector3(x * 1.005, 2.0 + 0.6, 1.0 - 1.15), Vector3(0.03, 1.2, 0.05), red)
        Kit.box(_g, "Cab number", Vector3(x * 1.01, 2.6, 0.6), Vector3(0.03, 0.35, 0.6), Color("c9a34a"))
        # rond raampje in de voorwand van de cabine, naast de ketel
        Kit.cyl(_g, "Cab spectacle", Vector3(x * 0.78, 3.5, -0.31), 0.24, 0.24, 0.04, Color("c9a34a"), 14, "z")
        Kit.cyl(_g, "Cab spectacle glass", Vector3(x * 0.78, 3.5, -0.33), 0.19, 0.19, 0.04, Color("3c4448"), 14, "z")
    Kit.box(_g, "Cab floor", Vector3(0, 1.3, 1.0), Vector3(2.7, 0.2, 2.6), black)

func _tender() -> void:
    var black := Color("1a1b1d")
    var red := Color("b3202a")
    Kit.box(_g, "Tender", Vector3(0, 2.2, 5.1), Vector3(2.6, 2.0, 4.2), black)
    Kit.box(_g, "Tender frame", Vector3(0, 1.1, 5.1), Vector3(2.5, 0.3, 4.4), black)
    var coal := Kit.cyl(_g, "Coal", Vector3(0, 3.2, 4.8), 1.2, 1.2, 3.4, Color("101011"), 10, "z")
    coal.scale = Vector3(0.95, 1.0, 0.3)
    for x in [-1.31, 1.31]:
        Kit.box(_g, "Tender lining", Vector3(x, 2.2, 5.1), Vector3(0.03, 1.6, 3.8), red)
        Kit.box(_g, "Tender panel", Vector3(x * 1.01, 2.2, 5.1), Vector3(0.03, 1.45, 3.65), black)
        for z in [3.8, 5.1, 6.4]:
            Kit.cyl(_g, "Tender wheel", Vector3(x * 0.85, 0.5, z), 0.5, 0.5, 0.1, red, 14, "x")
            Kit.cyl(_g, "Tender wheel centre", Vector3(x * 0.88, 0.5, z), 0.41, 0.41, 0.1, Color("202123"), 14, "x")
    Kit.box(_g, "Tender buffer beam", Vector3(0, 1.15, 7.25), Vector3(2.6, 0.5, 0.2), red)

# Rijtuig: rode onderkast, crème vensterband en bovenkant, rond grijs dak, deuren aan
# de uiteinden, zwart onderstel met twee draaistellen en een harmonica naar het volgende.
func _coach(z0: float) -> void:
    var z := 0.0
    var cream := Color("e8dcae")
    var red := Color("9e1f26")
    var ln := 12.0
    Kit.box(_g, "Coach lower", Vector3(0, 1.55, z), Vector3(2.8, 1.1, ln), red)
    Kit.box(_g, "Coach upper", Vector3(0, 2.75, z), Vector3(2.8, 1.3, ln), cream)
    var roof := Kit.cyl(_g, "Coach roof", Vector3(0, 3.4, z), 1.45, 1.45, ln + 0.1, Color("5a5d60"), 18, "z")
    roof.scale = Vector3(1.0, 1.0, 0.32)
    Kit.box(_g, "Underframe", Vector3(0, 0.9, z), Vector3(2.5, 0.25, ln - 0.6), Color("1f1f21"))
    for x in [-1.41, 1.41]:
        Kit.box(_g, "Coach stripe", Vector3(x, 2.08, z), Vector3(0.03, 0.06, ln), Color("c9a34a"))
        for w in range(7):
            Kit.box(_g, "Coach window", Vector3(x, 2.85, z - 4.2 + float(w) * 1.4), Vector3(0.04, 0.75, 1.05), Color("2c3438"))
        for e in [-1.0, 1.0]:
            Kit.box(_g, "Coach door", Vector3(x * 1.002, 2.15, z + e * 5.3), Vector3(0.04, 2.0, 0.8), Color("8a1b21"))
            Kit.box(_g, "Coach door window", Vector3(x * 1.006, 2.85, z + e * 5.3), Vector3(0.04, 0.6, 0.5), Color("2c3438"))
        for bz in [-4.3, 4.3]:
            for d in [-0.8, 0.8]:
                Kit.cyl(_g, "Bogie wheel", Vector3(x * 0.78, 0.45, z + bz + d), 0.42, 0.42, 0.12, Color("2a2a2a"), 12, "x")
            Kit.box(_g, "Bogie frame", Vector3(x * 0.85, 0.55, z + bz), Vector3(0.12, 0.3, 2.4), Color("1f1f21"))
    Kit.box(_g, "Gangway", Vector3(0, 2.4, z - ln * 0.5 - 0.35), Vector3(1.4, 2.2, 0.7), Color("1f1f21"))

    # rookpluimen
    var puff := SphereMesh.new()
    puff.radius = 1.0
    puff.height = 2.0
    puff.radial_segments = 10
    puff.rings = 5
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.85, 0.85, 0.86, 0.75)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    for k in range(5):
        var mi := MeshInstance3D.new()
        mi.mesh = puff
        mi.material_override = m
        cars[0][0].add_child(mi)
        smoke.append(mi)
    _place_smoke()

func _place_smoke() -> void:
    for k in range(smoke.size()):
        var t: float = fmod(puff_t + float(k) / float(smoke.size()), 1.0)
        var s: float = 0.6 + t * 1.8
        smoke[k].scale = Vector3(s, s, s)
        # rook drijft omhoog en blijft achter de schoorsteen hangen als de trein rijdt
        smoke[k].position = Vector3(0, 4.5 + t * 4.0, -5.9 + t * cur * 0.35)

func _physics_process(delta: float) -> void:
    if looping:
        _loop_step(delta)
    elif position.z > stop_z:
        # vast spoor (Finale): rijden tot stop_z en daar blijven staan
        var left: float = position.z - stop_z
        cur = speed if left > 140.0 else maxf(2.0, speed * left / 140.0)
        position.z = maxf(stop_z, position.z - cur * delta)
    else:
        cur = 0.0
    puff_t = fmod(puff_t + delta * (0.6 if cur > 0.0 else 0.25), 1.0)
    _place_smoke()
    _sound_step(delta)

func _loop_step(delta: float) -> void:
    var L: float = loop_length()
    match state:
        0:
            var left: float = fposmod(s_stop - s_head, L)
            if left > 0.05 and left < L - 1.0:
                # afremmen op de laatste 140 m voor het station
                cur = move_toward(cur, speed if left > 140.0 else maxf(2.0, speed * left / 140.0), 3.0 * delta)
                s_head += minf(cur * delta, left)
            else:
                cur = 0.0
                state = 1
                wait_t = dwell
        1:
            cur = 0.0
            wait_t -= delta
            if wait_t <= 0.0:
                state = 2
        2:
            # op het westspoor (ver van de weg) mag hij flink doorrijden
            var straight: float = z_top - z_bot
            var on_west: bool = s_head > straight + PI * loop_r + 20.0
            var left: float = s_wait - s_head
            var target: float = WEST_SPEED if on_west else speed
            if on_west and left < 160.0:
                target = maxf(2.0, WEST_SPEED * left / 160.0)
            cur = move_toward(cur, target, 3.0 * delta)
            s_head += minf(cur * delta, maxf(left, 0.0))
            if left <= 0.05:
                state = 3
                cur = 0.0
        3:
            cur = 0.0
            if trigger.is_valid() and bool(trigger.call()):
                state = 0
    s_head = fposmod(s_head, L)
    _place_cars()
