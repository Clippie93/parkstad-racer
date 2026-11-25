extends Node3D
# Fietser op het fietspad: rijdt in de richting van zijn kant van de weg (rechts mee, links
# tegen de rijrichting in), trapt, en volgt de route rond. Raak je er een, dan valt hij
# om (en kost het je snelheid); na een paar seconden staat hij weer op en fietst verder.
const Kit = preload("res://scripts/build_kit.gd")

var route
var level
var s := 0.0
var speed := 5.0
var side := 1.0           # 1 = rechterfietspad (mee), -1 = linkerfietspad (tegemoet)
var offset := 8.4
var legs: Array[Node3D] = []
var crank := 0.0
var fall := 0.0           # hoek waarmee hij omligt (0 = rechtop)
var down_time := 0.0      # hoe lang hij nog blijft liggen
var check_t := 0.0        # tijd tot de volgende controle of er iets op het fietspad staat
var query: PhysicsShapeQueryParameters3D

func setup(lv, start_s: float, v: float, on_side: float, shirt: Color, bike: Color) -> void:
    level = lv
    route = lv.route
    s = start_s
    speed = v
    side = on_side
    offset = lv.road_hw + lv.CURB_W + lv.BIKE_W * 0.5
    _build(shirt, bike)
    _apply()

func _build(shirt: Color, bike: Color) -> void:
    name = "Cyclist"
    var dark := Color("1f2226")
    # fiets: twee wielen (dunne cilinders langs X), frame, stuur, zadel
    for z in [-0.55, 0.55]:
        Kit.cyl(self, "Wheel", Vector3(0, 0.35, z), 0.35, 0.35, 0.05, dark, 14, "x")
    Kit.beam(self, "Frame", Vector3(0, 0.38, 0.55), Vector3(0, 0.75, -0.25), 0.05, bike)
    Kit.beam(self, "Frame", Vector3(0, 0.38, -0.55), Vector3(0, 0.75, -0.25), 0.05, bike)
    Kit.beam(self, "Frame", Vector3(0, 0.4, 0.05), Vector3(0, 0.85, 0.25), 0.05, bike)
    Kit.box(self, "Handlebar", Vector3(0, 0.95, -0.42), Vector3(0.5, 0.04, 0.04), dark)
    Kit.box(self, "Saddle", Vector3(0, 0.9, 0.25), Vector3(0.14, 0.05, 0.24), dark)
    Kit.box(self, "Rear rack", Vector3(0, 0.72, 0.55), Vector3(0.22, 0.04, 0.4), dark)
    # fietser: rechtop, Nederlandse stijl
    Kit.box(self, "Torso", Vector3(0, 1.28, 0.12), Vector3(0.38, 0.62, 0.24), shirt)
    Kit.cyl(self, "Head", Vector3(0, 1.72, 0.08), 0.12, 0.12, 0.24, Color("e3b897"), 10)
    Kit.box(self, "Arms", Vector3(0, 1.2, -0.12), Vector3(0.44, 0.1, 0.5), shirt).rotation_degrees.x = 25.0
    for x in [-0.1, 0.1]:
        var hip := Node3D.new()
        hip.position = Vector3(x, 0.95, 0.2)
        add_child(hip)
        Kit.box(hip, "Leg", Vector3(0, -0.28, -0.08), Vector3(0.12, 0.58, 0.12), Color("2b3a55"))
        legs.append(hip)
    # aanraakzone: een auto die hier doorheen rijdt, raakt de fietser
    var area := Area3D.new()
    var cs := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.7, 1.8, 1.7)
    cs.shape = box
    cs.position.y = 0.9
    area.add_child(cs)
    add_child(area)
    area.body_entered.connect(_on_hit)

func _on_hit(body: Node3D) -> void:
    if not (body is ArcadeCar) or down_time > 0.0 or not visible:
        return
    if absf(body.drive_speed) < 3.0:
        return
    down_time = 4.0
    body.drive_speed *= 0.8
    body.bumped.emit(absf(body.drive_speed))
    if not body.ai:
        var race := get_tree().current_scene
        if race != null and race.has_method("cyclist_hit"):
            race.cyclist_hit()

func _process(delta: float) -> void:
    if route == null:
        return
    if down_time > 0.0:
        # omgevallen: liggen, daarna weer overeind komen
        down_time -= delta
        fall = move_toward(fall, 1.45 if down_time > 0.8 else 0.0, delta * 4.0)
        _apply()
        return
    fall = move_toward(fall, 0.0, delta * 4.0)
    check_t -= delta
    s = fposmod(s + side * speed * delta, route.length) if route.closed else clampf(s + side * speed * delta, 0.0, route.length)
    crank += speed * delta * 2.2
    for i in range(legs.size()):
        legs[i].rotation.x = sin(crank + float(i) * PI) * 0.45
    _apply()

func _apply() -> void:
    var p: Vector3 = route.pos_at(s) + route.right_at(s) * side * offset
    var b: Basis = route.basis_at(s)
    if side < 0.0:
        b = b.rotated(Vector3.UP, PI)
    # omvallen = kantelen om de rijrichting, weg van de weg
    transform = Transform3D(b * Basis(Vector3(0, 0, 1), -fall), p + Vector3(0, 0.07, 0))
    # niet door gebouwen fietsen: alleen waar echt iets op het fietspad staat (een muur, een
    # gebouw) is hij even onzichtbaar. Vroeger gold dat voor het hele terrein rond een
    # bezienswaardigheid, ook waar het fietspad gewoon vrij is.
    if check_t <= 0.0 and is_inside_tree():
        check_t = 0.2
        visible = not _blocked(p)

func _blocked(p: Vector3) -> bool:
    if query == null:
        var box := BoxShape3D.new()
        box.size = Vector3(0.5, 1.2, 1.2)
        query = PhysicsShapeQueryParameters3D.new()
        query.shape = box
        query.collide_with_areas = false
    query.transform = Transform3D(global_transform.basis.orthonormalized(), p + Vector3(0, 1.0, 0))
    for r in get_world_3d().direct_space_state.intersect_shape(query, 4):
        if r["collider"] is StaticBody3D:
            return true
    return false
