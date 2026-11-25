extends "res://scripts/levels/level_base.gd"
# Level 1: Heerlen. Van Heerlen-Noord langs het Mijnmuseum (ON I) het centrum in,
# finish op het Pancratiusplein tussen de Pancratiuskerk en het Glaspaleis.
# Het stratenplan is verzonnen en compact; alleen de gebouwen zijn naar foto's.
const LmOn = preload("res://scripts/landmarks/landmark_on.gd")
const Plein = preload("res://scripts/places/pancratiusplein.gd")
const LmHoensbroek = preload("res://scripts/landmarks/landmark_hoensbroek.gd")
const LmMaan = preload("res://scripts/landmarks/landmark_maankwartier.gd")

const ON_POS := Vector3(-80, 0, -476)
const PLEIN := Vector3(-480, 0, -800)

func build() -> void:
    level_title = "HEERLEN"
    seed_value = 6411
    # Moeilijk: hier won je te makkelijk (jouw testritten 20-11); in de stad verliezen de
    # tegenstanders veel tijd achter verkeer, dus extra sterkte en een sterkere inhaalhulp
    hard_boost = 1.06
    hard_catch_up = 0.2
    # rondje: over het Pancratiusplein naar het zuiden en via de westkant terug naar de start
    route = Route.new([
        Vector3(0, 0, 150),
        Vector3(0, 0, -150),
        Vector3(50, 0, -260),
        Vector3(50, 0, -440),
        Vector3(-200, 0, -440),
        Vector3(-300, 0, -500),
        Vector3(-480, 0, -500),
        Vector3(-480, 0, -950),
        Vector3(-640, 0, -950),
        Vector3(-640, 0, 330),
        Vector3(0, 0, 330),
    ], [60.0, 60.0, 45.0, 80.0, 80.0, 45.0, 60.0, 80.0, 80.0, 60.0], true)
    checkpoints = [
        {"at": Vector3(-125, 0, -440), "name": "MIJNMUSEUM ON I"},
        {"at": Vector3(-395, 0, -500), "name": "CENTRUM"},
        {"at": PLEIN + Vector3(0, 0, -4), "name": "PANCRATIUSPLEIN"},
        {"at": Vector3(-640, 0, -500), "name": "MAANKWARTIER"},
        {"at": Vector3(-640, 0, 215), "name": "KASTEEL HOENSBROEK"},
        # terug in Heerlen-Noord: vult het lange laatste stuk naar de finish
        {"at": route.pos_at(3370.0), "name": "HEERLEN-NOORD"},
    ]

    # Mijnmuseum: schachtgebouw met de voorkant naar de weg.
    place(LmOn.new(), ON_POS)
    exclude_box(ON_POS, Vector3(-23, 0, -11), Vector3(53, 0, 21))
    # Pancratiusplein met kerk en Glaspaleis.
    place(Plein.new(), PLEIN)
    exclusions.append(Rect2(PLEIN.x - 60, PLEIN.z - 70, 125, 115))

    # Terugweg (westkant), rechts van de weg: eerst het Maankwartier (in het echt bij het
    # station, vlak bij het centrum), later Kasteel Hoensbroek (ten noorden van Heerlen),
    # vlak voor de bocht terug naar Heerlen-Noord.
    place_beside(LmMaan.new(), route.closest_s(Vector3(-640, 0, -600)), 1.0, 58.0, Vector2(58, 84))
    exclusions.append(Rect2(-800, -772, 160, 92))     # stationsplein ervoor (open zicht)
    # Hoensbroek ligt achter een grasveld met bomen, met de hoofdburcht in de gracht
    place_beside(LmHoensbroek.new(), route.closest_s(Vector3(-640, 0, 120)), 1.0, 80.0, Vector2(80, 78))
    # open grasveld vóór het kasteel (geen huizen), zodat je het al van ver ziet liggen
    exclusions.append(Rect2(-800, -40, 160, 85))

    finish_line(2)   # lange ronde: 2 ronden
    build_road()
    # stad: winkelpanden en flats, met wat rijtjes ertussen
    street_mix = {"shop": 4, "flat": 3, "row": 2, "semi": 1}
    murals = 0.7          # Heerlen staat bekend om zijn muurschilderingen
    build_streetscape()
    town_board(70.0, 1.0, Color("e8c21e"), [["name", ["Heerlen", "Heële"]], ["bars", 2]])   # naar jouw foto (Valkenburgerweg)
    # bord pas na de bocht, vlak voor het museum (dat rechts van de weg ligt)
    street_sign("ON I  /  MIJNMUSEUM", Vector3(-8, 4.0, -451))
    street_sign("CENTRUM  /  PANCRATIUSPLEIN", route.pos_at(route.closest_s(Vector3(-430, 0, -500))) + Vector3(0, 4.0, 11))
