extends Node3D
# Nederlandse flitspaal: grijze zuil met een grote kast bovenop en gele reflectiestrepen,
# op de band naast de rijbaan. Rij je er meer dan 10 km/u te hard langs, dan flitst hij.
# Rij je hem omver (net als in A2 Racer), dan valt hij om en krijg je extra tijd.
# Lokaal: +Z kijkt naar het aankomende verkeer, de weg ligt aan lokaal -X.
const Kit = preload("res://scripts/build_kit.gd")
const KNOCK_BONUS := 5.0

var race
var limit := 50.0
var flash: OmniLight3D
var flash_t := 0.0
var pivot: Node3D          # alles wat omvalt
var fall_t := -1.0
var fall_axis := Vector3.RIGHT
var down := false

func setup(r, limit_kmh: float, reach: float) -> void:
    race = r
    limit = limit_kmh
    name = "Speed camera"
    pivot = Node3D.new()
    add_child(pivot)
    var grey := Color("7f8a92")
    Kit.box(pivot, "Camera base", Vector3(0, 0.15, 0), Vector3(0.7, 0.3, 0.7), Color("5d6266"))
    Kit.box(pivot, "Camera column", Vector3(0, 1.5, 0), Vector3(0.45, 2.7, 0.45), grey)
    Kit.box(pivot, "Camera cabinet", Vector3(0, 3.3, 0), Vector3(0.8, 1.2, 0.75), grey)
    for y in [0.9, 1.6, 2.3]:
        Kit.box(pivot, "Reflective band", Vector3(0, y, 0), Vector3(0.47, 0.14, 0.47), Color("f2c230"))
    Kit.box(pivot, "Camera lens", Vector3(0, 3.55, 0.38), Vector3(0.36, 0.26, 0.03), Color("15171a"))
    Kit.box(pivot, "Flash window", Vector3(0, 3.1, 0.38), Vector3(0.3, 0.16, 0.03), Color("e6ebee"))
    flash = OmniLight3D.new()
    flash.position = Vector3(0, 3.1, 0.8)
    flash.omni_range = 26.0
    flash.light_energy = 0.0
    flash.light_color = Color("f4f6ff")
    pivot.add_child(flash)
    # meetstrook dwars over de rijbaan, net voorbij de paal
    var area := _area(Vector3(reach, 4.0, 3.0), Vector3(-reach * 0.5, 2.0, -2.0))
    area.body_entered.connect(_on_measure)
    # botsstrook rond de paal: omrijden
    var hit := _area(Vector3(1.6, 3.0, 1.6), Vector3(0, 1.5, 0))
    hit.body_entered.connect(_on_hit)

func _area(size: Vector3, pos: Vector3) -> Area3D:
    var area := Area3D.new()
    var cs := CollisionShape3D.new()
    var sh := BoxShape3D.new()
    sh.size = size
    cs.shape = sh
    cs.position = pos
    area.add_child(cs)
    add_child(area)
    return area

func _on_measure(body: Node3D) -> void:
    if down or not (body is ArcadeCar):
        return
    var kmh: int = body.speed_kmh()
    # voor het flitsklassement: iedereen meten (tegenstanders zonder flits en zonder boete)
    if race != null and race.has_method("camera_measured"):
        race.camera_measured(self, body, kmh, kmh > int(limit) + 10)
    if body.ai:
        return
    if kmh > int(limit) + 10:
        flash_t = 0.18
        if race != null and race.has_method("speeding_fine"):
            race.speeding_fine(kmh, int(limit))

func _on_hit(body: Node3D) -> void:
    if down or not (body is ArcadeCar):
        return
    down = true
    fall_t = 0.0
    # omvallen in de rijrichting van de auto
    var dir: Vector3 = Vector3(body.velocity.x, 0, body.velocity.z)
    if dir.length() < 0.5:
        dir = -body.global_transform.basis.z
    dir = (global_transform.basis.inverse() * dir.normalized())
    fall_axis = Vector3.UP.cross(dir).normalized()
    if race != null and race.has_method("camera_destroyed"):
        race.camera_destroyed(self, body)
    if not body.ai and race != null and race.has_method("camera_knocked"):
        race.camera_knocked(KNOCK_BONUS)

func _process(delta: float) -> void:
    if flash_t > 0.0:
        flash_t -= delta
        flash.light_energy = 9.0 if flash_t > 0.0 else 0.0
    if fall_t >= 0.0 and fall_t < 1.0:
        fall_t = minf(1.0, fall_t + delta * 4.0)
        # weggeslagen: meteen snel, op het eind afremmend tot plat op de grond (in een kwart
        # seconde, zodat je het ook bij hoge snelheid nog ziet gebeuren)
        var a: float = (1.0 - (1.0 - fall_t) * (1.0 - fall_t)) * deg_to_rad(84.0)
        pivot.transform = Transform3D(Basis(fall_axis, a), Vector3.ZERO)
