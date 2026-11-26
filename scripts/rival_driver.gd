extends Node
# Computercoureur voor een tegenstander. Zit als kind onder een ArcadeCar (ai = true) en
# bedient gas, rem en stuur. Volgt het ideale snelheidsprofiel van de race maal zijn
# eigen `skill`, stuurt naar een punt verderop in zijn rijstrook en wisselt van strook om
# langzamer verkeer en andere racers in te halen (op een gewone weg alleen als er geen
# tegenligger aankomt). Houdt ook zijn eigen ronde en afstand bij voor de stand.

var race              # race.gd
var car: ArcadeCar
var route
var driver_name := ""
var skill := 0.95     # fractie van de ideale snelheid
var lanes: Array = [] # mogelijke rijstrookafstanden (eerste = eigen strook)
var lane := 3.4
var lane_target := 3.4
var hint := 0
var s := 0.0
const COOL_SPEED := 13.0   # uitrijronde na de finish: ~47 km/u
var lap := 0          # aantal keer over de finishlijn
var finished := false
var finish_time := 0.0
var wobble := 0.0
var start_progress := 0.0
var stuck_timer := 0.0
var stuck_progress := 0.0
var resets := 0
var recoveries := 0
# Losrijden: staat hij met gas erop stil (neus tegen iets) of dwars/achterstevoren na een
# klap, dan steekt hij even achteruit met het stuur andersom en rijdt daarna weer door,
# zoals een mens zou doen. Pas als dat niet lukt, volgt na 4 s het terugzetten.
var route_offset := 0.0
var abort_t := 0.0
var queued_t := 0.0   # >0: staat netjes in de rij achter iemand (bv. verkeer voor rood)
var blocked_t := 0.0
var recover_t := 0.0
const RECOVER_TIME := 1.3
const BLOCKED_DELAY := 0.7
const WRONG_WAY_ANGLE := 110.0   # graden tussen de neus en de rijrichting van de weg
const LOOKAHEAD := 0.35   # seconden vooruit kijken in het snelheidsprofiel
# inhalen over de tegenrijbaan: zoveel ruimte tot een tegenligger (meter + seconden x eigen
# snelheid). Was 90 m + 2 s; iets brutaler, zodat ze in de stad niet eindeloos achter een
# auto blijven hangen terwijl jij er gewoon langs gaat.
var base_top := 0.0
var base_accel := 0.0
const ONCOMING_GAP := 60.0
const ONCOMING_T := 1.6

func setup(r, c: ArcadeCar, start_lane: float, lane_list: Array) -> void:
    race = r
    car = c
    route = r.level.route
    lanes = lane_list
    lane = start_lane
    lane_target = float(lane_list[0])
    var res: Array = route.nearest(car.global_position, 0)
    hint = res[1]
    s = res[2]
    start_progress = s
    wobble = randf_range(-0.6, 0.6)
    base_top = car.max_forward_speed
    base_accel = car.acceleration

func progress() -> float:
    return float(lap) * route.length + s

func _physics_process(delta: float) -> void:
    if race == null or car == null:
        return
    var res: Array = route.nearest(car.global_position, hint)
    hint = res[1]
    var ns: float = res[2]
    # over de finishlijn (s springt van het einde naar het begin) = nieuwe ronde
    if route.closed:
        if ns < s - route.length * 0.5:
            lap += 1
        elif ns > s + route.length * 0.5:
            lap -= 1
    s = ns
    route_offset = float(res[0])
    var off: bool = float(res[0]) > float(race.level.road_hw) + race.OFF_ROAD_MARGIN
    car.off_road = off
    car.surface_grip = race.OFF_GRIP if off else 1.0
    car.surface_speed = race.OFF_SPEED if off else 1.0

    # finishen op dezelfde plek als jij (de finishpoort, iets voor het begin van de route);
    # eerst telden ze pas ~10 m verder, waardoor ze ~0,2 s te laat finishten en je soms
    # een plaats hoger eindigde terwijl je er duidelijk achter zat
    if not finished and (lap >= race.laps or (lap == race.laps - 1 and s >= race.finish_s())):
        finished = true
        finish_time = race.race_clock
        race.on_rival_finished(self)
    if race.state == 0:   # 0 = aftellen
        car.ai_throttle = 0.0
        car.ai_brake = 0.0
        car.ai_steer = _steer_to(s + maxf(14.0, absf(car.drive_speed) * 0.8))
        return
    # Na de finish een rustige uitrijronde (zie COOL_SPEED) in de eigen strook. Vroeger
    # rolden ze uit tot stilstand midden op de weg: dan stond er vlak na de finish een rij
    # auto's waar jij in je laatste ronde niet langs kon (Simpelveld, op Moeilijk).

    # vastgelopen (tegen een muur, verkeerde kant op)? Na 4 s terugzetten op de weg, zoals R.
    stuck_timer += delta
    queued_t = maxf(0.0, queued_t - delta)
    if queued_t > 0.0:
        # in de rij wachten is geen vastzitten
        stuck_timer = 0.0
        stuck_progress = progress()
    if stuck_timer >= 4.0:
        # niet terugzetten als hij net weer goed op gang is (losgereden)
        var going: bool = car.drive_speed > 10.0 and (-car.global_transform.basis.z).dot(-route.basis_at(s).z) > 0.5
        if progress() - stuck_progress < 15.0 and not going:
            _reset_on_road()
        stuck_timer = 0.0
        stuck_progress = progress()

    if _recover(delta):
        return
    if finished:
        car.max_forward_speed = base_top
        car.acceleration = base_accel
    else:
        _catch_up()
    var v: float = absf(car.drive_speed)
    # snelheid: het ideale profiel houdt al rekening met remmen voor de volgende bocht,
    # dus alleen een klein stukje vooruit kijken (reactietijd). Vroeger was dat ~1,3 s:
    # dan reden ze een heel stuk voor elke bocht al op bochtsnelheid en verloren ze in
    # bochtige levels (Heerlen) veel tijd.
    var want: float = 99.0
    var n: int = race.profile.size()
    var k := 0.0
    while k < v * LOOKAHEAD + 4.0:
        want = minf(want, race.profile[posmod(int((s + k) / race.PROFILE_STEP), n)] * skill)
        k += race.PROFILE_STEP
    # in de slipstream kunnen ze op rechte stukken wat harder (net als jij)
    want *= 1.0 + car.SLIP_TOP * car.slipstream
    want = minf(want, _traffic_limit(v))
    if finished:
        want = minf(want, COOL_SPEED)
    abort_t = maxf(0.0, abort_t - delta)
    lane = move_toward(lane, lane_target, (2.6 + v * 0.06) * (1.8 if abort_t > 0.0 else 1.0) * delta)
    # ver naast de weg (na een klap): onder een flauwe hoek terug, anders schiet hij met
    # vaart dwars over de weg en aan de andere kant er weer af
    var off_by: float = maxf(0.0, route_offset - float(race.level.road_hw))
    car.ai_steer = _steer_to(s + maxf(14.0, v * 0.8) + off_by * 2.5)
    if off_by > 3.0:
        want = minf(want, 14.0 + 40.0 / (1.0 + off_by * 0.15))
    if v < want:
        car.ai_throttle = 1.0
        car.ai_brake = 0.0
    else:
        car.ai_throttle = 0.0
        car.ai_brake = clampf((v - want) / 6.0, 0.15, 1.0)

func _recover(delta: float) -> bool:
    var v: float = absf(car.drive_speed)
    var target_s: float = s + 14.0
    if recover_t > 0.0:
        recover_t -= delta
        # achteruit (rem vasthouden = achteruit zodra hij stilstaat), stuur andersom zodat de
        # neus naar de weg draait
        car.ai_throttle = 0.0
        # rustig achteruit: tot ~15 km/u, niet de volle 43
        car.ai_brake = 1.0 if car.drive_speed > -4.0 else 0.0
        car.ai_handbrake = false
        car.ai_steer = -_steer_to(target_s)
        if recover_t <= 0.0:
            blocked_t = 0.0
        return true
    if race.race_clock < 3.0:
        return false
    var fwd: Vector3 = -car.global_transform.basis.z
    var road: Vector3 = -route.basis_at(s).z
    var wrong_way: bool = rad_to_deg(absf(fwd.signed_angle_to(road, Vector3.UP))) > WRONG_WAY_ANGLE
    if queued_t > 0.0 and not wrong_way:
        blocked_t = 0.0
        return false
    if (car.ai_throttle > 0.0 and v < 1.5) or (wrong_way and v < 8.0):
        blocked_t += delta
    else:
        blocked_t = 0.0
    if blocked_t > BLOCKED_DELAY:
        recover_t = RECOVER_TIME
        recoveries += 1
        blocked_t = 0.0
        return true
    return false

func _steer_to(target_s: float) -> float:
    var target: Vector3 = route.pos_at(target_s) + route.right_at(target_s) * (lane + wobble)
    var to: Vector3 = target - car.global_position
    to.y = 0.0
    var fwd: Vector3 = -car.global_transform.basis.z
    var err: float = fwd.signed_angle_to(to.normalized(), Vector3.UP)
    return clampf(-err * 2.6, -1.0, 1.0)

# Kijkt naar racers en verkeer voor je. Wisselt van strook als dat veilig kan, anders
# aansluiten achter de voorganger. Geeft de maximale snelheid terug.
func _traffic_limit(v: float) -> float:
    var fwd: Vector3 = -car.global_transform.basis.z
    var right: Vector3 = car.global_transform.basis.x
    var limit: float = 99.0
    # op de tegenrijbaan aan het inhalen en er komt een tegenligger aan: afbreken en meteen
    # terug naar de eigen strook (desnoods even inhouden achter wie je inhaalde), in plaats
    # van op de tegenrijbaan te gaan remmen
    if lane_target < 0.0 and float(lanes[0]) > 0.0 and _oncoming_in(lane_target, v):
        lane_target = float(lanes[0])
        abort_t = 1.5
    if abort_t > 0.0:
        var beside: float = _beside_speed(float(lanes[0]))
        if beside >= 0.0:
            limit = minf(limit, beside - 4.0)
    var blocked := false
    for o in race.obstacles():
        if o == car:
            continue
        var rel: Vector3 = o.global_position - car.global_position
        var ahead: float = rel.dot(fwd)
        var side: float = rel.dot(right)
        if ahead > 0.0 and ahead < 18.0 + v * 0.9 and absf(side) < 2.3:
            blocked = true
            var other_v: float = _speed_of(o)
            if ahead < 14.0 and other_v < 3.0:
                queued_t = 0.6
            # aansluiten: niet sneller dan de voorganger als je er dichtbij zit
            limit = minf(limit, maxf(0.0, other_v + (ahead - 10.0) * 0.8))
    if blocked:
        # naar de strook waar je het hardst kunt, ook als daar verderop een (snellere)
        # auto rijdt; alleen de plek naast je moet vrij zijn. Zo blijf je niet eindeloos
        # hangen achter twee auto's die ongeveer naast elkaar rijden.
        var best_l: float = lane_target
        var best_v: float = limit + 2.0
        for l in lanes:
            if absf(float(l) - lane_target) < 0.5:
                continue
            var lv: float = _lane_speed(float(l), v)
            if lv > best_v:
                best_v = lv
                best_l = float(l)
        if best_l != lane_target:
            lane_target = best_l
            return minf(best_v, 99.0)
        return limit
    # terug naar de eigen strook als die vrij is
    if absf(lane_target - float(lanes[0])) > 0.5 and _lane_clear(float(lanes[0]), v):
        lane_target = float(lanes[0])
    return limit

# Komt er in strook l binnen de inhaalafstand een tegenligger aan?
func _oncoming_in(l: float, v: float) -> bool:
    var center: Vector3 = route.pos_at(s) + route.right_at(s) * l
    var fwd: Vector3 = route.dir_at(s)
    var right: Vector3 = route.right_at(s)
    for o in race.obstacles():
        if o == car or not (o.has_method("setup") and o.get("oncoming") == true):
            continue
        var rel: Vector3 = o.global_position - center
        if absf(rel.dot(right)) > 2.6:
            continue
        var ahead: float = rel.dot(fwd)
        if ahead > -5.0 and ahead < ONCOMING_GAP * 0.6 + v * ONCOMING_T:
            return true
    return false

# Snelheid van een auto in strook l vlak naast je (-1 als daar niemand rijdt).
func _beside_speed(l: float) -> float:
    var center: Vector3 = route.pos_at(s) + route.right_at(s) * l
    var fwd: Vector3 = route.dir_at(s)
    var right: Vector3 = route.right_at(s)
    for o in race.obstacles():
        if o == car:
            continue
        var rel: Vector3 = o.global_position - center
        if absf(rel.dot(right)) < 2.6 and absf(rel.dot(fwd)) < 7.0:
            return _speed_of(o)
    return -1.0

func _lane_clear(l: float, v: float) -> bool:
    # linkerstrook op een gewone weg = tegenrijbaan: alleen waar inhalen mag
    if l < 0.0 and not race.level.can_overtake(s):
        return false
    var center: Vector3 = route.pos_at(s) + route.right_at(s) * l
    var fwd: Vector3 = route.dir_at(s)
    var right: Vector3 = route.right_at(s)
    for o in race.obstacles():
        if o == car:
            continue
        var rel: Vector3 = o.global_position - center
        var ahead: float = rel.dot(fwd)
        var side: float = rel.dot(right)
        if absf(side) > 2.6:
            continue
        # tegenliggers op de inhaalstrook: ruim vooruit kijken
        var oncoming: bool = o.has_method("setup") and o.get("oncoming") == true
        var reach: float = (ONCOMING_GAP + v * ONCOMING_T) if oncoming else (25.0 + v * 0.6)
        if ahead > -10.0 and ahead < reach:
            return false
    return true

# Hoe hard je in strook l kunt: -1 als je er nu niet heen kunt (plek naast je bezet,
# tegenligger, inhaalverbod), anders de snelheid van de langzaamste voorganger daar.
func _lane_speed(l: float, v: float) -> float:
    if l < 0.0 and not race.level.can_overtake(s):
        return -1.0
    var center: Vector3 = route.pos_at(s) + route.right_at(s) * l
    var fwd: Vector3 = route.dir_at(s)
    var right: Vector3 = route.right_at(s)
    var best: float = 99.0
    for o in race.obstacles():
        if o == car:
            continue
        var rel: Vector3 = o.global_position - center
        var ahead: float = rel.dot(fwd)
        if absf(rel.dot(right)) > 2.6:
            continue
        var oncoming: bool = o.has_method("setup") and o.get("oncoming") == true
        if oncoming:
            if ahead > -10.0 and ahead < ONCOMING_GAP + v * ONCOMING_T:
                return -1.0
            continue
        if ahead > -6.0 and ahead < 6.0:
            return -1.0
        if ahead >= 7.0 and ahead < 25.0 + v * 0.9:
            best = minf(best, maxf(0.0, _speed_of(o) + (ahead - 10.0) * 0.8))
    return best

func _speed_of(o: Node) -> float:
    if o is ArcadeCar:
        return absf((o as ArcadeCar).drive_speed)
    var sp = o.get("speed")
    if sp != null:
        return -float(sp) if o.get("oncoming") == true else float(sp)
    return 0.0

func _reset_on_road() -> void:
    resets += 1
    lane = float(lanes[0])
    lane_target = lane
    var p: Vector3 = route.pos_at(s) + route.right_at(s) * lane + Vector3(0, 0.3, 0)
    car.global_transform = Transform3D(route.basis_at(s), p)
    car.drive_speed = 8.0
    car.slide = Vector3.ZERO
    car.velocity = Vector3.ZERO

# Inhaalhulp (race.catch_up_boost): ligt de speler voor, dan krijgt deze tegenstander wat
# extra topsnelheid en acceleratie, oplopend tot het maximum bij 150 m achterstand. Alleen
# vermogen, geen extra grip, dus in bochten blijven ze op hun eigen lijn.
func _catch_up() -> void:
    var k: float = race.catch_up_boost()
    if k <= 0.0 or base_top <= 0.0:
        return
    var gap: float = race.player_progress() - progress()
    var f: float = 1.0 + k * clampf(gap / 150.0, 0.0, 1.0)
    car.max_forward_speed = base_top * f
    car.acceleration = base_accel * f
