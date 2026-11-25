extends CharacterBody3D
class_name ArcadeCar
const CarLook = preload("res://scripts/car_look.gd")
const TrafficCar = preload("res://scripts/traffic_car.gd")

# Arcade physics: easy to tune without relying on a wheel simulator.
@export var max_forward_speed := 46.0 # m/s (~166 km/u)
@export var max_reverse_speed := 12.0
@export var acceleration := 13.0   # m/s² bij lage snelheid; neemt af richting topsnelheid
@export var braking := 30.0
@export var drag := 9.0
@export var turn_strength := 1.8
# Bochtfysica: maximale zijwaartse versnelling (grip) in m/s². Een bocht met straal R kun je
# dus nemen met hooguit sqrt(grip * R) m/s; sneller en de auto glijdt naar buiten.
@export var grip := 15.0
@export var oversteer := 2.1       # de neus mag zoveel verder draaien dan de grip: de achterkant breekt uit
@export var align := 2.0           # grip achter draait de neus terug naar de rijrichting (stabiliteit)
@export var handbrake_align := 0.5 # met de handrem nauwelijks terugstellend: de achterkant zwaait uit
@export var slide_grip := 0.85     # grip terwijl je al glijdt (iets lager: een drift houdt aan)
@export var scrub := 0.22          # snelheidsverlies door glijden
@export var handbrake_grip := 0.22 # grip met de handrem: geblokkeerde achterwielen, de achterkant breekt uit
const HANDBRAKE_DECEL := 11.0      # m/s² afremmen met de handrem (geblokkeerde achterwielen)
const DONUT_MAX := 14.0            # tot deze snelheid (m/s) draai je donuts met gas + handrem + sturen
const DONUT_SPEED := 7.0           # zo hard schuift de auto rond tijdens een donut
const DONUT_YAW := 2.8             # draaisnelheid van een donut (rad/s)
const CAMERA_EYE := Vector3(0.0, 4.5, 10.5)
const CAMERA_ROAD_TARGET := Vector3(0.0, 1.2, -9.0)
const CAMERA_CAR_TARGET := Vector3(0.0, 0.65, 0.0)
const CAMERA_PIVOT := Vector3(0.0, 1.65, 0.0)
const CAMERA_STUCK_SPEED := 2.0
const CAMERA_STUCK_DELAY := 0.22
const CAMERA_RETURN_SPEED := 2.4
# De camera draait met vertraging mee met de auto (per seconde dit deel van het verschil,
# exponentieel). In een normale bocht loopt hij een paar graden achter; een plotselinge draai
# door een botsing of spin volgt hij rustig, in plaats van mee het gebouw in te zwiepen.
const CAMERA_YAW_RATE := 6.0
const BUMP_MIN_SPEED := 8.0

var drive_speed := 0.0
var steer_state := 0.0             # geleidelijk ingestuurde stuuruitslag (-1..1)
@export var steer_rate := 4.5      # hoe snel het stuur naar vol uitslag gaat (per seconde)
var slide := Vector3.ZERO          # zijwaartse (glij)snelheid, wereldcoördinaten
var controls_enabled := true
signal bumped(power: float)
var bump_count := 0   # aantal botsingen (voor de race-statistiek)
var start_transform: Transform3D   # R zet de auto hier terug (het laatste checkpoint)
var camera: Camera3D
var camera_query: PhysicsShapeQueryParameters3D
var camera_fraction := 1.0
var camera_obstruction_time := 0.0
var camera_yaw := 0.0
# Huidig camerastandpunt (Game.camera_view): oog, kijkpunt op de weg, draaivertraging.
var cam_eye := CAMERA_EYE
var cam_road_target := CAMERA_ROAD_TARGET
var cam_yaw_rate := CAMERA_YAW_RATE
var cam_hood := false
# Op de telefoon staat de snelheidsmeter onderin het midden: dan kijkt de camera iets meer
# omlaag (per standpunt zoveel meter lager kijkpunt), zodat de auto erboven in beeld staat.
var cam_raise := false
var cam_raise_drop := 0.0
const CAMERA_RAISE := {"normal": 1.0, "far": 0.0, "close": 1.6, "hood": 0.0}
const CAMERA_PRESETS := {
    "normal": [Vector3(0.0, 4.5, 10.5), Vector3(0.0, 1.2, -9.0), 6.0],
    "far": [Vector3(0.0, 7.0, 15.5), Vector3(0.0, 1.0, -12.0), 5.0],
    "close": [Vector3(0.0, 3.0, 7.0), Vector3(0.0, 1.3, -8.0), 7.0],
    "hood": [Vector3(0.0, 1.45, -1.2), Vector3(0.0, 1.25, -20.0), 0.0],
}

func set_camera_view(v: String) -> void:
    var p: Array = CAMERA_PRESETS.get(v, CAMERA_PRESETS["normal"])
    cam_eye = p[0]
    cam_road_target = p[1]
    cam_yaw_rate = float(p[2])
    cam_hood = v == "hood"
    cam_raise_drop = float(CAMERA_RAISE.get(v, 0.0))
    camera_fraction = 1.0
    camera_obstruction_time = 0.0
    camera_yaw = global_rotation.y
var camera_last_pos := Vector3.INF
# Ondergrond, gezet door de race: 1.0 = asfalt; naast de weg minder grip en topsnelheid.
var surface_grip := 1.0
# Slipstream (0..1): vlak achter een andere auto heb je minder luchtweerstand, dus wat meer
# topsnelheid en acceleratie. Wordt door race.gd bijgehouden.
var slipstream := 0.0
const SLIP_TOP := 0.10      # +10% topsnelheid bij vol slipstream
const SLIP_COAST := 2.0     # m/s2 snelheidsverlies boven de topsnelheid na de slipstream
const SLIP_ACCEL := 0.7     # +70% acceleratie (vooral merkbaar vlak onder de topsnelheid)
var slipstream_top_bonus := SLIP_TOP
var slipstream_coast := SLIP_COAST
var surface_speed := 1.0
var off_road := false
# Hoe hard de banden slippen (0..1): zijwaarts glijden, een donut of de handrem op snelheid.
# Voor het piepgeluid (car_audio.gd) en de bandenrook.
var skid := 0.0
var donut_now := false
var smoke: Array[CPUParticles3D] = []
# Computerauto: dan komen gas/rem/sturen van een RivalDriver in plaats van het toetsenbord.
var ai := false
var ai_throttle := 0.0
var ai_brake := 0.0
var ai_steer := 0.0
var ai_handbrake := false
var body_color := Color("c72d28")
var stripe_color := Color("f4f4ee")
var car_style := "hatch"       # hatch, coupe of sedan (zie car_look.gd)
var race_number := 1

func _ready() -> void:
    start_transform = global_transform
    _make_visuals()
    if ai:
        return
    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.current = true
    camera.fov = 72.0
    # near niet te klein: anders is de diepte op telefoons te grof en gaan vlakken die
    # vlak boven elkaar liggen knipperen
    camera.near = 0.5
    camera.far = 2500.0
    # lokaal richten (achter en boven de auto, kijkend naar een punt voor de auto), zodat
    # de camera goed staat waar en hoe de auto ook start
    # los van de draaiing van de auto (top_level): _update_camera zet hem elke frame zelf neer
    camera.top_level = true
    camera_yaw = global_rotation.y
    set_camera_view(Game.camera_view())
    add_child(camera)
    camera.global_transform = Transform3D(Basis(Vector3.UP, camera_yaw) * Basis.looking_at(cam_road_target - cam_eye), global_transform * cam_eye)

    # Een bol houdt ook de beeldranden vrij wanneer de camera dichterbij komt.
    var clearance := SphereShape3D.new()
    clearance.radius = 0.9
    camera_query = PhysicsShapeQueryParameters3D.new()
    camera_query.shape = clearance
    camera_query.collision_mask = collision_mask
    camera_query.exclude = [get_rid()]

func _update_camera(delta: float) -> void:
    var space := get_world_3d().direct_space_state
    # weggezet (reset, checkpoint): de camera springt mee in plaats van rond te zwaaien
    if camera_last_pos.distance_to(global_position) > 15.0:
        camera_yaw = global_rotation.y
    camera_last_pos = global_position
    if cam_hood:
        # motorkap: vast op de auto, geen vertraging en geen muurcontrole
        camera_yaw = global_rotation.y
        camera.global_transform = global_transform * Transform3D(Basis.looking_at(cam_road_target - cam_eye), cam_eye)
        return
    camera_yaw += wrapf(global_rotation.y - camera_yaw, -PI, PI) * (1.0 - exp(-cam_yaw_rate * delta))
    var cam_basis := Basis(Vector3.UP, camera_yaw)
    var pivot: Vector3 = global_position + cam_basis * CAMERA_PIVOT
    camera_query.transform = Transform3D(Basis.IDENTITY, pivot)
    var follow_offset := cam_eye - CAMERA_PIVOT
    camera_query.motion = cam_basis * follow_offset
    var clearance_fraction := space.cast_motion(camera_query)[0]

    # Gebruik de werkelijke beweging: bij een botsing kan de auto gas geven en toch vaststaan.
    var movement := get_real_velocity()
    var ground_speed_squared := Vector2(movement.x, movement.z).length_squared()
    if clearance_fraction < 1.0 and ground_speed_squared < CAMERA_STUCK_SPEED * CAMERA_STUCK_SPEED:
        camera_obstruction_time += delta
    else:
        camera_obstruction_time = 0.0

    if camera_obstruction_time >= CAMERA_STUCK_DELAY and clearance_fraction < camera_fraction:
        camera_fraction = clearance_fraction
    elif clearance_fraction > camera_fraction:
        camera_fraction = move_toward(camera_fraction, clearance_fraction, CAMERA_RETURN_SPEED * delta)

    var offset := follow_offset * camera_fraction
    var lift := 2.3 * (1.0 - smoothstep(0.12, 0.42, camera_fraction))
    if lift > 0.0:
        # Bij weinig ruimte achter de auto houdt een hogere kijkhoek de auto in beeld.
        offset.y += lift
        camera_query.motion = cam_basis * offset
        offset *= space.cast_motion(camera_query)[0]

    var eye := CAMERA_PIVOT + offset
    var road_focus := smoothstep(0.28, 1.0, camera_fraction)
    var road_t: Vector3 = cam_road_target - Vector3(0, cam_raise_drop if cam_raise else 0.0, 0)
    var target := CAMERA_CAR_TARGET.lerp(road_t, road_focus)
    # Het kleine achterwaartse verschil geeft ook recht boven de auto een stabiele horizon.
    var view_direction := target - eye
    view_direction.z = minf(view_direction.z, -0.01)
    camera.global_transform = Transform3D(cam_basis * Basis.looking_at(view_direction), global_position + cam_basis * eye)

func reset_to_start() -> void:
    global_transform = start_transform
    drive_speed = 0.0
    slide = Vector3.ZERO
    velocity = Vector3.ZERO
    slipstream = 0.0
    camera_yaw = global_rotation.y

# Acceleratie bij snelheid v: krachtig uit stilstand, slap vlak onder de topsnelheid.
func accel_at(v: float) -> float:
    var f: float = clampf(v / max_forward_speed, 0.0, 1.0)
    return acceleration * maxf(0.2, 1.0 - 0.75 * f * f)

# Hoogste snelheid waarmee een bocht met kromming k (1/m) te nemen is, op asfalt.
func corner_speed(k: float) -> float:
    if k < 0.0001:
        return max_forward_speed
    return minf(max_forward_speed, sqrt(grip / k))

func _physics_process(delta: float) -> void:
    if not ai and Input.is_action_just_pressed("reset_car"):
        reset_to_start()
        camera_fraction = 1.0
        camera_obstruction_time = 0.0
        camera_yaw = global_rotation.y
        _update_camera(delta)
        return

    var throttle: float = ai_throttle if ai else Input.get_action_strength("accelerate")
    var reverse: float = ai_brake if ai else Input.get_action_strength("brake")
    var steer_in: float = ai_steer if ai else Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
    # toetsenbord = meteen vol; geleidelijk insturen voelt als een echt stuur
    var rate: float = steer_rate * (2.0 if absf(steer_in) < absf(steer_state) or signf(steer_in) != signf(steer_state) else 1.0)
    steer_state = move_toward(steer_state, steer_in, rate * delta)
    var steer: float = steer_state
    var handbrake: bool = ai_handbrake if ai else Input.is_action_pressed("handbrake")
    # handrem = achterwielen blokkeren: dan helpt gas niet (ook niet het automatische gas op
    # de telefoon), de auto remt af en de achterkant breekt uit.
    # Behalve bij lage snelheid met gas en stuur erbij: dan duwt de motor de achterkant rond
    # en draai je donuts.
    var donut: bool = handbrake and throttle > 0.0 and absf(steer_state) > 0.3 and absf(drive_speed) < DONUT_MAX
    if handbrake and not donut:
        throttle = 0.0
    if not controls_enabled:
        # aftellen of finish: de auto rolt uit
        throttle = 0.0
        reverse = 0.0
        handbrake = true

    var top: float = max_forward_speed * surface_speed * (1.0 + slipstream_top_bonus * slipstream)
    var v: float = absf(drive_speed)
    if throttle > 0.0:
        if drive_speed < top:
            drive_speed = move_toward(drive_speed, top, accel_at(v) * (1.0 + SLIP_ACCEL * slipstream) * throttle * delta)
    elif reverse > 0.0:
        if drive_speed > 1.0:
            drive_speed = move_toward(drive_speed, 0.0, braking * reverse * delta)
        else:
            drive_speed = move_toward(drive_speed, -max_reverse_speed, acceleration * 0.6 * delta)
    else:
        drive_speed = move_toward(drive_speed, 0.0, drag * delta)
    # naast de weg: flink afremmen tot de lagere topsnelheid. Op de weg sneller dan je
    # topsnelheid (net uit de slipstream gedoken): rustig uitlopen, zoals door luchtweerstand.
    if drive_speed > top:
        drive_speed = move_toward(drive_speed, top, (30.0 if surface_speed < 1.0 else slipstream_coast) * delta)
    if donut:
        # de motor houdt de achterwielen aan het slippen: een vaste, lage rondjessnelheid
        drive_speed = move_toward(drive_speed, DONUT_SPEED, acceleration * throttle * delta)
    elif handbrake:
        drive_speed = move_toward(drive_speed, 0.0, HANDBRAKE_DECEL * delta)
    v = absf(drive_speed)

    # Sturen. Forward faces -Z; reverse steering flips direction naturally.
    var g: float = grip * surface_grip
    # totale snelheid (vooruit + glijden): anders mag een glijdende auto steeds harder draaien
    var v_tot: float = sqrt(v * v + slide.length_squared())
    var speed_factor: float = clamp(v_tot / 10.0, 0.0, 1.0)
    var reverse_sign := -1.0 if drive_speed < -0.5 else 1.0
    var yaw: float = turn_strength * speed_factor * (2.3 if handbrake else 1.0)
    if v_tot > 1.0:
        # de neus mag verder draaien dan de banden kunnen volgen: dan breekt de achterkant uit
        yaw = minf(yaw, g * oversteer * (2.4 if handbrake else 1.0) / v_tot)
    if donut:
        yaw = maxf(yaw, DONUT_YAW * throttle)
    var turn: float = -steer * yaw * reverse_sign
    # Terugstellen: de achterbanden trekken de neus richting de rijrichting. Hoe verder je
    # instuurt boven de grip, hoe groter de driftwinkel waarop dit evenwicht ligt.
    var cur_vel: Vector3 = -global_transform.basis.z * drive_speed + slide
    if v_tot > 3.0 and drive_speed > 0.0 and not donut:
        var beta: float = (-global_transform.basis.z).signed_angle_to(cur_vel, Vector3.UP)
        turn += beta * (handbrake_align if handbrake else align) * speed_factor
    var old_vel: Vector3 = -global_transform.basis.z * drive_speed + slide
    rotate_y(turn * delta)

    # De snelheid volgt de nieuwe neusrichting zover de grip het toelaat; de rest is glijden.
    var forward := -global_transform.basis.z
    var v_fwd: float = old_vel.dot(forward)
    var lat: Vector3 = old_vel - forward * v_fwd
    lat.y = 0.0
    var lat_len: float = lat.length()
    var g_lat: float = g
    if handbrake:
        g_lat *= handbrake_grip
    elif lat_len > 2.5:
        g_lat *= slide_grip
    var grip_step: float = g_lat * delta
    if lat_len <= grip_step:
        lat = Vector3.ZERO
    else:
        lat = lat * ((lat_len - grip_step) / lat_len)
        # glijden kost snelheid
        v_fwd = move_toward(v_fwd, 0.0, minf(lat_len, 14.0) * scrub * delta * 3.0)
    drive_speed = v_fwd
    slide = lat
    var sk: float = clampf((slide.length() - 2.5) / 6.0, 0.0, 1.0)
    if donut:
        sk = maxf(sk, 0.85 * throttle)
    elif handbrake and absf(drive_speed) > 5.0:
        sk = maxf(sk, 0.6)
    if off_road:
        sk *= 0.3
    skid = sk
    donut_now = donut
    if not ai:
        # alleen rook als de auto echt beweegt (anders blijven er wolkjes bij de wielen hangen)
        var moving: float = Vector2(velocity.x, velocity.z).length()
        _smoke(sk > 0.35 and moving > 5.0 and not off_road)

    velocity.x = forward.x * drive_speed + slide.x
    velocity.z = forward.z * drive_speed + slide.z
    velocity.y = -1.0 if is_on_floor() else velocity.y - 20.0 * delta
    move_and_slide()
    if camera != null:
        _update_camera(delta)
    _resolve_collisions(forward)

# Botsingen: per contact alleen de snelheid de muur (of auto) in wegnemen, met een kleine
# terugstuit tegen muren. Langs het oppervlak verlies je weinig bij een schampende botsing en
# veel bij een frontale. Bij het schampen van een muur draait de neus mee met de muur, zodat
# je erlangs schuurt in plaats van vast te plakken. Tegen auto's telt de snelheid ten
# opzichte van die auto: achterop een even snelle auto tikken kost (bijna) niets.
const WALL_BOUNCE := 0.15       # deel van de inslagsnelheid dat terugstuit (muren)
const WALL_BOUNCE_MAX := 3.0    # m/s
const WALL_ALIGN := 0.35
const WALL_FRICTION := 0.6      # snelheidsverlies langs de muur per m/s inslag
const CAR_FRICTION := 0.25        # deel van de hoek met de muur dat de neus per contact meedraait
# Schuren langs een rij losse gebouwen/muren die een paar cm verspringen: de neus bleef dan
# achter de hoek van het volgende blok haken en de auto stond in één klap stil of werd naar
# achteren geduwd (stotter). Steekt zo'n hoek minder dan STEP_OUT_MAX uit de muur waar je net
# langs schuurde, dan stapt de auto er opzij overheen in plaats van erop vast te lopen.
# Twee auto's naast elkaar: minder dan zoveel graden verschil in richting en zijwaarts verder
# dan zoveel meter uit elkaar (breedte ~1,85 m) telt als zijkant tegen zijkant.
const SIDE_BY_SIDE_ANGLE := 35.0
const SIDE_BY_SIDE_LAT := 1.3
const SIDE_BY_SIDE_LON := 3.6   # verder voor/achter (lengte ~3,85 m) is een tik achterop
const STEP_OUT_MAX := 0.4       # m
const STEP_OUT_MEMORY := 12     # frames dat de laatste muur onthouden wordt
var wall_n := Vector3.ZERO      # normaal en een punt van de muur waar je langs schuurt
var wall_p := Vector3.ZERO
var wall_age := 999
func _resolve_collisions(forward: Vector3) -> void:
    var impact_speed := 0.0
    var motion: Vector3 = forward * drive_speed + slide
    motion.y = 0.0
    var touched := false
    var turned := false
    var step_out := 0.0
    var side_wall := false
    wall_age += 1
    for i in get_slide_collision_count():
        var hit := get_slide_collision(i)
        var normal := hit.get_normal()
        if absf(normal.y) >= 0.35:
            continue
        var n := Vector3(normal.x, 0.0, normal.z).normalized()
        var other := hit.get_collider()
        var is_car: bool = other is ArcadeCar or other is TrafficCar
        var ov := Vector3.ZERO
        if other is CharacterBody3D:
            ov = other.velocity
        else:
            ov = hit.get_collider_velocity()
        ov.y = 0.0
        if not is_car:
            var along: float = absf(n.dot(forward))
            if along < 0.5:
                # zijkant tegen een muur: onthouden
                wall_n = n
                wall_p = hit.get_position()
                wall_age = 0
                side_wall = true
            elif wall_age <= STEP_OUT_MEMORY and drive_speed > 4.0 and n.dot(forward) < -0.3 and n.dot(wall_n) < 0.6:
                # hoek van het volgende blok vlak naast de muur: kleine uitstulping?
                var prot: float = (hit.get_position() - wall_p).dot(wall_n)
                if prot > -0.05 and prot < STEP_OUT_MAX:
                    step_out = maxf(step_out, prot + 0.04)
                    continue
        if is_car and other is Node3D:
            # Naast elkaar (zijkant tegen zijkant, ongeveer dezelfde kant op): alleen opzij
            # duwen. De botsrichting van twee schuine dozen kreeg anders een stuk naar voren
            # of achteren mee (de hoek of schuine flank van de ander), waardoor de sneller
            # rijdende auto bij elk tikje een ruk naar achteren kreeg en de ander naar voren.
            var fw: Vector3 = Vector3(forward.x, 0.0, forward.z).normalized()
            var rt := Vector3(-fw.z, 0.0, fw.x)
            var d: Vector3 = (other as Node3D).global_position - global_position
            var lat: float = d.dot(rt)
            var ofw: Vector3 = -(other as Node3D).global_transform.basis.z
            ofw.y = 0.0
            var same_way: bool = ofw.length() > 0.1 and absf(fw.signed_angle_to(ofw.normalized(), Vector3.UP)) < deg_to_rad(SIDE_BY_SIDE_ANGLE)
            var lon: float = d.dot(fw)
            if same_way and absf(lat) > SIDE_BY_SIDE_LAT and absf(lon) < SIDE_BY_SIDE_LON:
                n = -rt * signf(lat)
        var rel: Vector3 = motion - ov
        var into: float = -rel.dot(n)
        if into <= 0.0:
            continue
        touched = true
        impact_speed = maxf(impact_speed, into)
        var head_on: float = clampf(into / maxf(rel.length(), 0.1), 0.0, 1.0)
        var bounce: float = 0.0 if is_car else minf(into * WALL_BOUNCE, WALL_BOUNCE_MAX)
        if other is ArcadeCar:
            # een andere racer geeft mee: allebei de helft (achterop: hij wordt geduwd,
            # opzij: hij schuift een stukje mee)
            other.push(-n * into * 0.5)
            motion += n * into * 0.5
            # schuren: wrijving op het snelheidsverschil langs elkaar, ook gedeeld (de
            # snellere wordt iets afgeremd, de langzamere iets meegetrokken)
            var tr: Vector3 = rel - n * rel.dot(n)
            var trl: float = tr.length()
            if trl > 0.01:
                var fr: float = minf(trl, CAR_FRICTION * into)
                motion -= tr / trl * fr * 0.5
                other.push(tr / trl * fr * 0.5)
            continue
        else:
            motion += n * (into + bounce)
        var nn: float = motion.dot(n)
        var tang: Vector3 = motion - n * nn
        # wrijving langs het oppervlak, evenredig met hoe hard je erin stoot (niet per frame)
        var tl: float = tang.length()
        if tl > 0.01:
            tang *= maxf(0.0, tl - (CAR_FRICTION if is_car else WALL_FRICTION) * into) / tl
        motion = tang + n * nn
        if not is_car and not turned and head_on < 0.7 and tang.length() > 3.0 and tang.dot(forward) > 0.0:
            rotate_y(forward.signed_angle_to(tang.normalized(), Vector3.UP) * WALL_ALIGN)
            turned = true
    if step_out > 0.0:
        global_position += wall_n * step_out
        wall_p += wall_n * step_out
    if touched:
        var f := -global_transform.basis.z
        drive_speed = motion.dot(f)
        slide = motion - f * drive_speed
        slide.y = 0.0

    if impact_speed > BUMP_MIN_SPEED:
        bump_count += 1
        bumped.emit(impact_speed)

# Snelheidsverandering van buitenaf (geduwd door een andere auto).
func push(dv: Vector3) -> void:
    var f := -global_transform.basis.z
    var m: Vector3 = f * drive_speed + slide + Vector3(dv.x, 0.0, dv.z)
    drive_speed = m.dot(f)
    slide = m - f * drive_speed
    slide.y = 0.0

func speed_kmh() -> int:
    return roundi(abs(drive_speed) * 3.6)

func _make_visuals() -> void:
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.85, 1.25, 3.85)
    collider.shape = shape
    # onderkant van het botsblok op de wielonderkant (lokaal y = 0; blok 1,25 hoog), zodat de wielen
    # op het asfalt staan en er niet 22 cm in wegzakken
    collider.position.y = 0.6
    add_child(collider)
    CarLook.build(self, body_color, stripe_color, car_style, race_number)

func _box(n: String, size: Vector3, pos: Vector3, mat: Material) -> void:
    var node := MeshInstance3D.new()
    node.name = n
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = mat
    add_child(node)

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 1.0
    return m

# Bandenrook achter de achterwielen (alleen bij jouw auto): wit-grijze wolkjes die in de
# wereld blijven hangen, groter worden en vervagen.
func _smoke(on: bool) -> void:
    if smoke.is_empty():
        if not on:
            return
        var st: Dictionary = CarLook.STYLES.get(car_style, CarLook.STYLES["hatch"])
        var rz: float = float(st["wheel_z"][1])
        var mat := ShaderMaterial.new()
        mat.shader = load("res://scripts/tyre_smoke.gdshader")
        var quad := QuadMesh.new()
        quad.size = Vector2(1.6, 1.6)
        quad.material = mat
        var ramp := Gradient.new()
        ramp.set_color(0, Color(1, 1, 1, 0.5))
        ramp.set_color(1, Color(1, 1, 1, 0.0))
        ramp.add_point(0.55, Color(1, 1, 1, 0.18))
        var grow := Curve.new()
        grow.add_point(Vector2(0, 0.5))
        grow.add_point(Vector2(1, 2.4))
        for x in [-0.84, 0.84]:
            var p := CPUParticles3D.new()
            p.name = "Tyre smoke"
            p.mesh = quad
            p.amount = 10 if Game.low_graphics() else 18
            p.lifetime = 0.85
            p.local_coords = false
            p.emitting = false
            p.position = Vector3(x, 0.5, rz + 0.25)
            # rook werpt geen schaduw (anders donkere halve cirkels op het asfalt)
            p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            p.direction = Vector3(0, 1, 0.4)
            p.spread = 35.0
            p.initial_velocity_min = 1.2
            p.initial_velocity_max = 2.4
            p.gravity = Vector3(0, 2.2, 0)
            p.damping_min = 0.8
            p.damping_max = 1.4
            p.scale_amount_min = 0.9
            p.scale_amount_max = 1.4
            p.scale_amount_curve = grow
            p.color_ramp = ramp
            add_child(p)
            smoke.append(p)
    for p in smoke:
        if p.emitting != on:
            p.emitting = on
