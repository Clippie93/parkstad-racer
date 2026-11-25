extends RefCounted
# Autocatalogus en upgrades. Een auto heeft een model (zie car_look.gd), een prijs en
# basiswaarden voor de rijfysica. Upgrades verhogen die per niveau (3 niveaus per soort).

const CARS := [
    {"id": "john", "name": "John Hatchback", "style": "hatch", "price": 0,
        "color": Color("c72d28"), "stripe": Color("f4f4ee"),
        "speed": 46.0, "accel": 13.0, "grip": 15.0, "brake": 30.0,
        "text": "Je eerste auto: wendbaar, maar niet de snelste."},
    {"id": "gt", "name": "Kirchroa GT", "style": "coupe", "price": 4000,
        "color": Color("1f5fae"), "stripe": Color("f4f4ee"),
        "speed": 50.0, "accel": 13.5, "grip": 15.2, "brake": 31.0,
        "text": "Lage coupé met een hogere topsnelheid."},
    {"id": "rally", "name": "Heuvelland Rally", "style": "sedan", "price": 7500,
        "color": Color("2e8b57"), "stripe": Color("f2c230"),
        "speed": 48.5, "accel": 15.0, "grip": 17.0, "brake": 33.0,
        "text": "Sedan met veel grip en sterke remmen: ideaal voor bochtige levels."},
    {"id": "super", "name": "Wilhelmina Super", "style": "coupe", "price": 15000,
        "color": Color("e07b28"), "stripe": Color("1a1a1a"),
        "speed": 55.0, "accel": 16.0, "grip": 16.5, "brake": 34.0,
        "text": "Snel en sterk; de achterkant breekt wel makkelijk uit."},
    {"id": "special", "name": "Parkstad Special", "style": "hatch", "price": 30000,
        "color": Color("f2c230"), "stripe": Color("1a1a1a"),
        "speed": 60.0, "accel": 18.0, "grip": 18.0, "brake": 36.0,
        "text": "De snelste auto van Parkstad. Voor de Buitenring."},
]

# Upgrades: per niveau een percentage op de basiswaarde.
const UPGRADES := [
    {"id": "motor", "name": "Motor", "stat": "speed", "step": 0.04, "text": "topsnelheid"},
    {"id": "turbo", "name": "Turbo", "stat": "accel", "step": 0.08, "text": "acceleratie"},
    {"id": "tyres", "name": "Banden", "stat": "grip", "step": 0.06, "text": "grip in bochten"},
    {"id": "brakes", "name": "Remmen", "stat": "brake", "step": 0.12, "text": "remkracht"},
]
const UPGRADE_LEVELS := 3
const UPGRADE_PRICES := [800, 1800, 3500]

const PAINTS := [Color("c72d28"), Color("1f5fae"), Color("2e8b57"), Color("f2c230"), Color("e07b28"),
    Color("7a3fa0"), Color("e8e6e0"), Color("8a1c2b"), Color("2fb5c8"), Color("e85d9c")]

static func car(id: String) -> Dictionary:
    for c in CARS:
        if c["id"] == id:
            return c
    return CARS[0]

# Upgrades zijn duurder voor duurdere auto's.
static func upgrade_price(car_id: String, level: int) -> int:
    var tier: float = 1.0 + float(car(car_id)["price"]) / 20000.0
    return int(round(float(UPGRADE_PRICES[level]) * tier / 50.0)) * 50
