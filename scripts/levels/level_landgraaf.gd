extends "res://scripts/levels/level_base.gd"
# Level 3: Landgraaf. Van Schaesberg langs Megaland, het Pinkpop-terrein, met de
# Wilhelminaberg en SnowWorld steeds in zicht; finish voor de ingang van SnowWorld.
# Het stratenplan is verzonnen en compact.
const LmSnow = preload("res://scripts/landmarks/landmark_snowworld.gd")
const LmPinkpop = preload("res://scripts/landmarks/landmark_pinkpop.gd")
const LmSchaesberg = preload("res://scripts/landmarks/landmark_schaesberg.gd")
const LmStrijthagen = preload("res://scripts/landmarks/landmark_strijthagen.gd")
const LmRimburg = preload("res://scripts/landmarks/landmark_watertoren_rimburg.gd")

const SNOW_POS := Vector3(-350, 0, -560)
const PINKPOP_POS := Vector3(-125, 0, -15)

func build() -> void:
    level_title = "LANDGRAAF"
    seed_value = 3741
    # rondje: voor het parkeerterrein van SnowWorld naar het oosten en terug naar Schaesberg
    route = Route.new([
        Vector3(0, 0, 400),
        Vector3(0, 0, -100),
        Vector3(-250, 0, -100),
        Vector3(-350, 0, -200),
        Vector3(-350, 0, -455),
        Vector3(150, 0, -455),
        Vector3(150, 0, 520),
        Vector3(0, 0, 520),
    ], [60.0, 80.0, 80.0, 60.0, 80.0, 80.0, 60.0], true)
    checkpoints = [
        {"at": Vector3(0, 0, 150), "name": "SCHAESBERG"},
        {"at": Vector3(-195, 0, -100), "name": "MEGALAND / PINKPOP"},
        {"at": Vector3(-350, 0, -300), "name": "WILHELMINABERG"},
        {"at": Vector3(-350, 0, -400), "name": "SNOWWORLD"},
        {"at": Vector3(0, 0, -455), "name": "SLOT SCHAESBERG"},
        {"at": Vector3(150, 0, -60), "name": "KASTEEL STRIJTHAGEN"},
        {"at": Vector3(150, 0, 370), "name": "WATERTOREN RIMBURG"},
    ]

    # Pinkpop-terrein links van de weg, podium met de rug naar het noorden
    place(LmPinkpop.new(), PINKPOP_POS, 180.0)
    exclusions.append(Rect2(PINKPOP_POS.x - 95, PINKPOP_POS.z - 60, 190, 105))   # ovale baan van Megaland
    # SnowWorld met de Wilhelminaberg; parkeerterrein voor de ingang
    place(LmSnow.new(), SNOW_POS)
    exclusions.append(Rect2(SNOW_POS.x - 215, SNOW_POS.z - 560, 430, 610))
    Kit.box(self, "SnowWorld parking", Vector3(SNOW_POS.x, 0.06, SNOW_POS.z + 58), Vector3(110, 0.1, 30), Color("44484c"))
    for x in range(-50, 51, 6):
        Kit.box(self, "Parking bay", Vector3(SNOW_POS.x + float(x), 0.12, SNOW_POS.z + 52), Vector3(0.15, 0.02, 10), LINE)

    # terugweg: oostwaarts links (zuidkant) de ruïne van Slot Schaesberg in de vijver;
    # daarna noordwaarts links Kasteel Strijthagen in de gracht en verderop in de velden de
    # Watertoren Rimburg
    place_beside(LmSchaesberg.new(), route.closest_s(Vector3(-60, 0, -455)), -1.0, 48.0, Vector2(48, 36))
    place_beside(LmStrijthagen.new(), route.closest_s(Vector3(150, 0, -150)), -1.0, 50.0, Vector2(46, 46))
    exclusions.append(Rect2(150, -262, 100, 70))      # open zicht op Strijthagen
    place_beside(LmRimburg.new(), route.closest_s(Vector3(150, 0, 300)), -1.0, 40.0, Vector2(40, 36))
    exclusions.append(Rect2(150, 200, 100, 66))       # weiland voor de watertoren

    finish_line(3)
    build_road()
    # woonwijken: rijtjes en twee-onder-een-kap, wat vrijstaand
    street_mix = {"row": 3, "semi": 3, "detached": 2, "mine": 1}
    build_streetscape()
    # Landgraaf: gemeentenaam in blauw, de wijk eronder in wit met blauwe letters
    town_sign("Landgraaf", 60.0, 1.0, "Sjaasberg", true, Color("e8c21e"))   # gele palen, zoals op de foto
    street_sign("MEGALAND  /  PINKPOP", Vector3(-11, 4.0, -20))
    street_sign("SNOWWORLD  /  WILHELMINABERG", route.pos_at(route.closest_s(Vector3(-350, 0, -240))) + Vector3(11, 4.0, 0))
