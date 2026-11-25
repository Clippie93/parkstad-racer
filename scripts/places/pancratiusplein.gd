extends Node3D
# Pancratiusplein, Heerlen: plein met doorrit, Pancratiuskerk links, Glaspaleis rechts.
# Oorsprong = midden van het plein; de doorrit loopt langs Z, de toegangsweg komt van +Z.
# Gebruikt door het Heerlen-level.
const Kit = preload("res://scripts/build_kit.gd")
const LmKerk = preload("res://scripts/landmarks/landmark_pancratiuskerk.gd")
const LmGlas = preload("res://scripts/landmarks/landmark_glaspaleis.gd")

const SIDEWALK := Color("9b9a90")
const ROAD_GRAY := Color("353940")

func _ready() -> void:
    name = "Pancratiusplein"
    Kit.box(self, "Square paving", Vector3(0, 0.11, 0), Vector3(94, 0.18, 72), SIDEWALK)
    Kit.box(self, "Square paving east", Vector3(51, 0.11, 0), Vector3(8, 0.18, 72), SIDEWALK)
    Kit.box(self, "Driveway", Vector3(0, 0.225, 0), Vector3(13, 0.05, 72), ROAD_GRAY)
    # bestrating voor de trap van het Glaspaleis-terras (achterkant)
    Kit.box(self, "Square paving terrace", Vector3(36, 0.11, -40), Vector3(26, 0.18, 8), SIDEWALK)
    for z in [-34.0, -26.0, -18.0]:
        Kit.box(self, "Paving band", Vector3(0, 0.235, z), Vector3(89, 0.025, 0.38), Color("c6bdb0"))
    var kerk: Node3D = LmKerk.new()
    kerk.position = Vector3(-26, 0.2, 13)
    add_child(kerk)
    var glas: Node3D = LmGlas.new()
    glas.position = Vector3(37, 0.2, -12)
    add_child(glas)
    for x in [-43.0, 26.0]:
        Kit.facade_block(self, "Square facade", Vector3(x, 0, 30), Vector2(19, 11), 5,
            Kit.tex_mat("res://assets/town_facade.png", Color.WHITE, 14.0))
