extends "res://scripts/levels/level_base.gd"
# Level 6: Voerendaal, de kastelengemeente. Over het heuvelland langs de schuren en muren
# van Kasteel Puth, bij het bord Voerendaal/Voelender het dorp in, finish bij Kasteel
# Cortenbach in de gracht. Het stratenplan is verzonnen en compact.
const LmCortenbach = preload("res://scripts/landmarks/landmark_cortenbach.gd")
const LmPuth = preload("res://scripts/landmarks/landmark_puth.gd")
const LmMolen = preload("res://scripts/landmarks/landmark_molen_vrouweheide.gd")
const LmStation = preload("res://scripts/landmarks/landmark_station_klimmen.gd")

const VILLAGE_Z := 300.0
const PUTH_POS := Vector3(-34, 0, 560)
const CORTENBACH_POS := Vector3(-300, 0, 8)
# terugweg: molen halverwege de weg naar het noorden, station op het laatste stuk (oostwaarts)
const MOLEN_Z := 400.0
const STATION_ROAD := Vector3(-320, 0, 860)

func build() -> void:
    level_title = "VOERENDAAL"
    seed_value = 6367
    # rondje: na Cortenbach naar het westen en over het heuvelland terug
    route = Route.new([
        Vector3(0, 0, 720),
        Vector3(0, 0, 380),
        Vector3(-80, 0, 260),
        Vector3(-80, 0, 40),
        Vector3(-460, 0, 40),
        Vector3(-460, 0, 860),
        Vector3(0, 0, 860),
    ], [70.0, 70.0, 60.0, 70.0, 80.0, 70.0], true)
    checkpoints = [
        {"at": Vector3(0, 0, 470), "name": "KASTEEL PUTH"},
        {"at": Vector3(-80, 0, 180), "name": "VOERENDAAL"},
        {"at": Vector3(-300, 0, 40), "name": "KASTEEL CORTENBACH"},
        {"at": Vector3(-460, 0, MOLEN_Z), "name": "MOLEN VROUWEHEIDE"},
        {"at": STATION_ROAD, "name": "STATION KLIMMEN-RANSDAAL"},
    ]
    traffic_cars = 10

    exclusions.append(Rect2(-600, VILLAGE_Z, 1000, 700))   # buiten het dorp: heuvelland
    place(LmPuth.new(), PUTH_POS, 90.0)
    var puth_rect := Rect2(PUTH_POS.x - 62, PUTH_POS.z - 42, 65, 84)
    exclusions.append(puth_rect)
    hard_exclusions.append(puth_rect)
    place(LmCortenbach.new(), CORTENBACH_POS)
    exclusions.append(Rect2(CORTENBACH_POS.x - 45, CORTENBACH_POS.z - 60, 90, 78))
    # terugweg over het heuvelland (x = -460, naar het noorden), rechts van de weg: eerst
    # de molen op de Vrouweheide op een heuveltje, verderop station Klimmen-Ransdaal
    var molen: Node3D = place_beside(LmMolen.new(), route.closest_s(Vector3(-460, 0, MOLEN_Z)), 1.0, 32.0, Vector2(1, 1))
    exclude_local(molen, Rect2(-26, -28, 52, 50))
    var station: Node3D = place_beside(LmStation.new(), route.closest_s(STATION_ROAD), 1.0, 22.0, Vector2(1, 1))
    exclude_local(station, Rect2(-62, -22, 124, 34))

    finish_line(3)
    build_road()
    # heuvellanddorp: hoeves en vrijstaande huizen
    street_mix = {"farm": 3, "detached": 3, "semi": 1}
    build_streetscape()
    countryside(Rect2(-600, VILLAGE_Z + 10, 1000, 640), 11, 1200.0)
    town_board(route.closest_s(Vector3(-50, 0, VILLAGE_Z - 20)), 1.0, Color("e8c21e"), [["name", ["Voerendaal", "Voelender"]], ["limit", "50", "welkom !"], ["bars", 2]])   # naar jouw foto (Putterweg)
    street_sign("KASTEEL PUTH", Vector3(11, 4.0, 640))
    street_sign("KASTEEL CORTENBACH", Vector3(-175, 4.0, 51))
