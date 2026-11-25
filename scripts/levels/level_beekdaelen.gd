extends "res://scripts/levels/level_base.gd"
# Level 7: Beekdaelen. Start in de Schinveldse bossen, waar een AWACS-vliegtuig laag
# overkomt, langs een wegkruis met knotbomen het heuvelland en het dorp in, finish bij
# Kasteel Terborgh in Schinnen. Het stratenplan is verzonnen en compact.
const LmTerborgh = preload("res://scripts/landmarks/landmark_terborgh.gd")
const Awacs = preload("res://scripts/landmarks/awacs.gd")
const LmAlfa = preload("res://scripts/landmarks/landmark_alfa.gd")
const LmAmstenrade = preload("res://scripts/landmarks/landmark_amstenrade.gd")
const LmNonke = preload("res://scripts/landmarks/landmark_nonke_buusjke.gd")

const FOREST_Z := 420.0          # ten noorden hiervan: bos
const VILLAGE_Z := 230.0         # tussen dorp en bos: heuvelland
const TERBORGH_POS := Vector3(-200, 0, 60)
const ALFA_Z := 300.0           # terugweg (x = -380): beter verdeeld over de hele weg
const AMSTENRADE_Z := 680.0
const NONKE_ROAD := Vector3(-220, 0, 920)   # in de Schinveldse bossen, op het laatste stuk
const AWACS_S := 170.0           # hier komt de AWACS over de weg (vlak na de start)

func build() -> void:
    level_title = "BEEKDAELEN"
    seed_value = 6361
    # rondje: na Terborgh naar het westen en door het bos terug
    route = Route.new([
        Vector3(0, 0, 780),
        Vector3(0, 0, 440),
        Vector3(60, 0, 320),
        Vector3(60, 0, 80),
        Vector3(-380, 0, 80),
        Vector3(-380, 0, 920),
        Vector3(0, 0, 920),
    ], [80.0, 80.0, 60.0, 70.0, 80.0, 70.0], true)
    checkpoints = [
        {"at": Vector3(0, 0, 600), "name": "SCHINVELDSE BOSSEN"},
        {"at": Vector3(60, 0, 280), "name": "WEGKRUIS"},
        {"at": Vector3(-200, 0, 80), "name": "KASTEEL TERBORGH"},
        {"at": Vector3(-380, 0, ALFA_Z), "name": "ALFA BROUWERIJ"},
        {"at": Vector3(-380, 0, AMSTENRADE_Z), "name": "KASTEEL AMSTENRADE"},
        {"at": NONKE_ROAD, "name": "NONKE BUUSJKE"},
    ]
    traffic_cars = 10

    exclusions.append(Rect2(-400, VILLAGE_Z, 800, 800))   # bos en heuvelland: geen huizen
    # aanvliegroute van de vliegbasis: een open grasstrook door het bos, langs de baan van
    # de AWACS (moet vóór forest() bekend zijn)
    _approach_strip(AWACS_S)
    place(LmTerborgh.new(), TERBORGH_POS)
    # ruim vrijhouden zodat je het kasteel al van ver ziet liggen
    exclusions.append(Rect2(TERBORGH_POS.x - 62, TERBORGH_POS.z - 70, 132, 84))
    var cross_rect := Rect2(66, 270, 16, 20)
    # terugweg (x = -380, naar het noorden), rechts van de weg: de Alfa-brouwerij aan de
    # rand van het dorp, Kasteel Amstenrade in het heuvelland, Nonke Buusjke in het bos
    var alfa: Node3D = place_beside(LmAlfa.new(), route.closest_s(Vector3(-380, 0, ALFA_Z)), 1.0, 19.0, Vector2(1, 1))
    exclude_local(alfa, Rect2(-32, -48, 64, 58))
    var amst: Node3D = place_beside(LmAmstenrade.new(), route.closest_s(Vector3(-380, 0, AMSTENRADE_Z)), 1.0, 34.0, Vector2(1, 1))
    exclude_local(amst, Rect2(-34, -30, 68, 60))
    var nonke: Node3D = place_beside(LmNonke.new(), route.closest_s(NONKE_ROAD), 1.0, 26.0, Vector2(1, 1))
    exclude_local(nonke, Rect2(-24, -26, 48, 48))   # tot aan de weg: geen struikenrand ervoor
    hard_exclusions.append(cross_rect)

    finish_line(3)
    build_road()
    # dorpen tussen de bossen: vrijstaand, hoeves en twee-onder-een-kap
    street_mix = {"detached": 3, "farm": 2, "semi": 2}
    build_streetscape()
    forest(Rect2(-400, FOREST_Z, 800, 600), 260.0, 3)
    countryside(Rect2(-400, VILLAGE_Z, 800, FOREST_Z - VILLAGE_Z), 7)
    wayside_cross(Vector3(74, 0, 280), -90.0)
    # Beekdaelen heeft per kern een eigen bord; het dorp hier is Schinnen (naar jouw foto)
    town_board(route.closest_s(Vector3(60, 0, VILLAGE_Z + 10)), 1.0, Color("e8c21e"), [["name", ["Schinnen", "Sjènne"], true], ["zone", "30"], ["strip", "Welkom", Color("2f7a6a")], ["bars", 1]])
    street_sign("SCHINVELDSE BOSSEN", Vector3(-11, 4.0, 760))
    street_sign("KASTEEL TERBORGH", Vector3(49, 4.0, 120))

    # AWACS: laag over het bos, dwars over de route, en terug in een lus
    var plane: Node3D = Awacs.new()
    add_child(plane)
    plane.cross_route(route, AWACS_S, 38.0, 6.0)   # ~150 m voor de start schuin over de weg

# Naderingslichten van de vliegbasis Geilenkirchen (de basis zelf ligt net over de grens):
# een open grasstrook door het bos langs de aanvliegroute, met een rij slanke grijze masten
# met een lampkopje en om de drie masten een dwarsbalk met lampen. Vlak bij de weg geen
# masten. De strook moet vóór forest() worden aangelegd.
func _approach_strip(s: float) -> void:
    var c: Vector3 = route.pos_at(s)
    var d: Vector3 = Awacs.approach_dir(route, s)
    # alleen binnen het bos (tussen FOREST_Z en de noordrand)
    var u0: float = (FOREST_Z + 20.0 - c.z) / d.z
    var u1: float = (FOREST_Z + 590.0 - c.z) / d.z
    var a: Vector3 = c + d * u0
    var b: Vector3 = c + d * u1
    clear_strips.append([a, b, 30.0])
    var n := Vector3(-d.z, 0, d.x)
    var yaw: float = atan2(d.x, d.z)
    var grass := Kit.box(self, "Approach strip", (a + b) * 0.5 + Vector3(0, 0.008, 0), Vector3(56.0, 0.004, u1 - u0), Color("5f8a45"))
    grass.rotation.y = yaw
    var k := 0
    var u := u0 + 10.0
    while u <= u1 - 10.0:
        var p: Vector3 = c + d * u
        var near_road: bool = route.distance_to(p) < 16.0
        var inside: bool = absf(p.x) < 395.0
        if inside and not near_road:
            var h: float = 7.0 + absf(u) * 0.004
            Kit.cyl(self, "Approach light mast", p + Vector3(0, h * 0.5, 0), 0.11, 0.08, h, Color("8c9398"), 8, "y", true)
            Kit.box(self, "Approach light", p + Vector3(0, h + 0.08, 0), Vector3(0.3, 0.16, 0.3), Color("e8e4c8"))
            if k % 3 == 0:
                var bar := Kit.box(self, "Approach light bar", p + Vector3(0, h - 0.1, 0), Vector3(3.2, 0.12, 0.12), Color("8c9398"))
                bar.rotation.y = yaw
                for j in range(5):
                    Kit.box(self, "Approach light", p + n * (-1.4 + float(j) * 0.7) + Vector3(0, h + 0.05, 0), Vector3(0.2, 0.16, 0.2), Color("e8e4c8"))
        k += 1
        u += 30.0
