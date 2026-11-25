extends Node3D
# Parkstad Limburg Stadion, Kerkrade (2000, architect Jan Dautzenberg).
# Opgebouwd naar luchtfoto's, Street View en de kaart. Rechtsom vanaf de rotonde:
#   +Z  hoofdgevel: beige baksteen met donkere banden, hoger middendeel met glazen koepel
#   hoek 7, +X  Fair Play / Basic-Fit: beige/donker gestreept, getrapt 4-5-6 lagen
#   hoek 5/6, -Z  Fletcher-hotelzijde: vleugels met lamellen, donkerbruin entreedeel, glazen dakopbouw
#   hoek 3/4, -X  Albert Heijn XL: beige/donker gestreept, drie donkere tongewelven, glazen trappenhuizen
#   hoek 2 met grijze Music Dome-hal, terug naar de hoofdgevel
# Hoeken: open betonnen hoek van de tribune (gebogen kolommen, grijze gevelband, schuine
# tribune-onderkant, toegangshekken). De witte vakwerkmast staat op die betonhoek op
# dakhoogte, steekt door de top van de witte tent en leunt ver naar binnen over het veld.
# Maten zijn geschat, niet opgemeten (veld wel echt: 105 x 68 m).
# Lokale ruimte: oorsprong = middelpunt veld.
const Kit = preload("res://scripts/build_kit.gd")

const PITCH_X := 105.0
const PITCH_Z := 68.0
const STAND_D := 20.0
const BACK_Z := 56.0      # achterkant lange tribune
const BACK_X := 74.5      # achterkant korte tribune
const FRONT_Z := 62.0     # voorvlak hoofdgevel
const FLOOR_H := 4.4
const WING_H := 17.6      # 4 verdiepingen
const CENTER_H := 22.0    # 5 verdiepingen
const BLOCK_X := 64.0     # lange gebouwen lopen tot hier, daarna de betonhoek
const BLOCK_Z := 48.0     # korte gebouwen lopen tot hier
const CORNER_X := 78.0    # betonhoek loopt schuin van (BLOCK_X, FRONT_Z) naar (CORNER_X, BLOCK_Z)
const LEVEL := 3.6        # verdiepingshoogte zijgebouwen
const ROOF_Y := 23.5
const CORNER_TOP := 21.0  # bovenkant betonhoek = voet van de mast
const TENT_LOW := 21.0
const TENT_TOP := 32.0

var brick := Color("c4aa70")
var band := Color("2b2522")
var dark_brick := Color("4a3a32")
var concrete := Color("9d9b94")
var white := Color("eef0ee")
var steel := Color("d9dcda")
var mast_white := Color("f2f3f1")
var grey := Color("9a9e9c")
var yellow := Color("f0c52a")
var glass_c := Color("40596a")

func _ready() -> void:
    name = "ParkstadLimburgStadion"
    _pitch()
    _stands()
    _roofs()
    _office_block()
    _fairplay_block()
    _hotel_block()
    _market_block()
    _corners()

# ---------------------------------------------------------------- veld en tribunes

func _pitch() -> void:
    var grass := Color("3f8a4a")
    Kit.box(self, "Pitch", Vector3(0, 0.12, 0), Vector3(PITCH_X, 0.24, PITCH_Z), grass)
    var line := Color("e8efe4")
    Kit.box(self, "Halfway", Vector3(0, 0.26, 0), Vector3(0.25, 0.04, PITCH_Z), line)
    Kit.cyl(self, "Centre circle", Vector3(0, 0.27, 0), 9.15, 9.15, 0.02, line, 32)
    Kit.cyl(self, "Centre grass", Vector3(0, 0.285, 0), 8.9, 8.9, 0.02, grass, 32)
    for s in [-1.0, 1.0]:
        Kit.box(self, "Box side", Vector3(s * (PITCH_X * 0.5 - 16.5), 0.26, 0), Vector3(0.25, 0.04, 40.3), line)
        Kit.box(self, "Box top", Vector3(s * (PITCH_X * 0.5 - 8.25), 0.26, 20.15), Vector3(16.5, 0.04, 0.25), line)
        Kit.box(self, "Box bottom", Vector3(s * (PITCH_X * 0.5 - 8.25), 0.26, -20.15), Vector3(16.5, 0.04, 0.25), line)
        Kit.box(self, "Goal", Vector3(s * (PITCH_X * 0.5 + 0.1), 1.2, 0), Vector3(0.2, 2.4, 7.3), Color("f4f4f0"))

func _stands() -> void:
    var seats := Color("c9a21e")
    var wall := Color("8f9391")
    # lange tribunes stoppen waar de schuine betonhoek begint
    Kit.wedge(self, "Stand south", Vector3(0, 0, PITCH_Z * 0.5 + 2.0 + STAND_D * 0.5), 140.0, STAND_D, 3.0, 21.0, seats, wall)
    var n := Kit.wedge(self, "Stand north", Vector3(0, 0, -(PITCH_Z * 0.5 + 2.0 + STAND_D * 0.5)), 140.0, STAND_D, 3.0, 21.0, seats, wall)
    n.rotation_degrees.y = 180.0
    var ex: float = PITCH_X * 0.5 + 2.0 + STAND_D * 0.5
    var e := Kit.wedge(self, "Stand east", Vector3(ex, 0, 0), 72.0, STAND_D, 3.0, 21.0, seats, wall)
    e.rotation_degrees.y = 90.0
    var w := Kit.wedge(self, "Stand west", Vector3(-ex, 0, 0), 72.0, STAND_D, 3.0, 21.0, seats, wall)
    w.rotation_degrees.y = -90.0
    # zwarte zitblokken in de lange tribunes: het geel/zwarte blokkenpatroon uit de foto
    var slope: float = rad_to_deg(atan2(18.0, STAND_D))
    for z0 in [1.0, -1.0]:
        for k in range(4):
            var t: float = 0.12 + float(k) * 0.22
            var y: float = lerpf(3.0, 21.0, t) + 0.07
            var z: float = (PITCH_Z * 0.5 + 2.0 + STAND_D * t) * z0
            for i in range(-6, 7):
                if (i + k) % 2 != 0:
                    continue
                var blk := Kit.box(self, "Seat block", Vector3(float(i) * 9.4, y, z), Vector3(8.2, 0.12, 3.2), Color("2a2d31"))
                blk.rotation_degrees.x = slope * (-1.0 if z0 > 0.0 else 1.0)

# ---------------------------------------------------------------- daken

func _roofs() -> void:
    # (yaw, breedte van de tribune, afstand van het veldmidden tot het dakmidden, dakdiepte)
    _stand_roof(0.0, 130.0, 46.0, 22.0)
    _stand_roof(180.0, 130.0, 46.0, 22.0)
    _stand_roof(90.0, 66.0, 64.5, 22.0)
    _stand_roof(-90.0, 66.0, 64.5, 22.0)

func _stand_roof(yaw: float, span: float, zc: float, depth: float) -> void:
    var holder := Node3D.new()
    holder.name = "Roof holder"
    holder.rotation_degrees.y = yaw
    add_child(holder)
    var count: int = int(round(span / 9.4))
    var w: float = span / float(count)
    var tilt := -9.0   # achterkant (+Z lokaal) hoger dan de veldzijde
    for i in range(count):
        var x: float = -span * 0.5 + (float(i) + 0.5) * w
        var v := Kit.vault(holder, "Roof vault", Vector3(x, ROOF_Y, zc), w - 0.6, depth, 3.4, Kit.two_sided_mat(white))
        v.rotation_degrees.x = tilt
    var back_y: float = ROOF_Y + sin(deg_to_rad(-tilt)) * depth * 0.5
    var back_z: float = zc + depth * 0.5
    for i in range(count + 1):
        var x: float = -span * 0.5 + float(i) * w
        var rib := Kit.box(holder, "Roof truss", Vector3(x, ROOF_Y, zc), Vector3(0.55, 0.9, depth + 0.6), steel)
        rib.rotation_degrees.x = tilt
        Kit.box(holder, "Roof column", Vector3(x, 12.5, back_z), Vector3(0.7, 25.0, 0.7), grey)
        if i % 2 == 0:
            var strut_a := Vector3(x, 24.2, zc - depth * 0.5 + 1.0)
            var strut_b := Vector3(x, 21.5, zc - depth * 0.5 + 1.0)
            Kit.beam(holder, "Roof hanger", strut_a, strut_b, 0.25, steel)
            # witte driehoeksspanten die boven de buitengevel uitsteken
            var peak := Vector3(x, back_y + 3.2, back_z - 1.0)
            var l := Vector3(x - 1.8, back_y, back_z - 1.0)
            var r := Vector3(x + 1.8, back_y, back_z - 1.0)
            var back := Vector3(x, back_y, back_z - 4.0)
            Kit.beam(holder, "Roof A-frame", l, peak, 0.22, mast_white)
            Kit.beam(holder, "Roof A-frame", r, peak, 0.22, mast_white)
            Kit.beam(holder, "Roof A-frame", l, r, 0.18, mast_white)
            Kit.beam(holder, "Roof A-frame", back, peak, 0.18, mast_white)

# ---------------------------------------------------------------- hoofdgevel (+Z, rotonde)

func _office_block() -> void:
    var tiles := Kit.tex_mat_tiles("res://assets/pls_office.png", Vector2(4.0, FLOOR_H))
    var mid_z: float = (BACK_Z + FRONT_Z) * 0.5
    var wide: float = BLOCK_X * 2.0
    Kit.box(self, "Office wings", Vector3(0, WING_H * 0.5, mid_z), Vector3(wide, WING_H, FRONT_Z - BACK_Z), brick, true, tiles)
    # middendeel springt 15 cm voor en achter uit: geen gedeeld vlak met de vleugels
    Kit.box(self, "Office centre", Vector3(0, CENTER_H * 0.5, mid_z), Vector3(56.0, CENTER_H, FRONT_Z - BACK_Z + 0.3), brick, true, tiles)
    Kit.box(self, "Wing parapet", Vector3(0, WING_H + 0.25, mid_z), Vector3(wide, 0.5, FRONT_Z - BACK_Z + 0.4), band)
    Kit.box(self, "Centre parapet", Vector3(0, CENTER_H + 0.25, mid_z), Vector3(56.0, 0.5, FRONT_Z - BACK_Z + 0.4), band)
    var f := Kit.face(self, Vector3(0, 0, FRONT_Z), 0.0)
    _entrance(f)
    # losse letters op het dak naast de glazen koepel
    var dark := Color("3a3f45")
    Kit.label(self, "PARKSTAD", Vector3(-27.0, CENTER_H + 2.2, FRONT_Z - 2.2), 0.026, dark, 100)
    Kit.label(self, "LIMBURG", Vector3(27.0, CENTER_H + 2.2, FRONT_Z - 2.2), 0.026, dark, 100)
    Kit.vault(self, "Glass vault", Vector3(0, CENTER_H + 0.5, FRONT_Z - 3.0), 26.0, 8.0, 3.8, Kit.glass_two_sided(Color("6f9c8a")))
    Kit.tex_panel(self, "Club emblem", Vector3(0, CENTER_H + 2.8, FRONT_Z + 0.9), Vector2(4.4, 4.4), "res://assets/roda_crest_06.png")
    for x in [-14.5, 14.5]:
        Kit.box(self, "Flagpole", Vector3(x, 5.5, FRONT_Z + 4.0), Vector3(0.2, 11.0, 0.2), Color("d9d9d2"))
        Kit.box(self, "Flag", Vector3(x + 1.0, 10.0, FRONT_Z + 4.0), Vector3(2.0, 1.4, 0.08), yellow)

func _entrance(f: Node3D) -> void:
    Kit.box(f, "Entrance glass", Vector3(0, 8.0, 0.25), Vector3(26.0, 16.0, 0.5), Color("22333f"), false, Kit.glass_mat(Color("2c4658")))
    for i in range(-5, 6):
        Kit.box(f, "Entrance mullion", Vector3(float(i) * 2.4, 8.0, 0.6), Vector3(0.16, 16.0, 0.16), Color("1c1f22"))
    Kit.box(f, "Stadion sign box", Vector3(0, 16.7, 0.6), Vector3(13.0, 1.9, 0.5), band)
    Kit.label(f, "STADION", Vector3(0, 16.7, 0.9), 0.02, yellow, 100)
    Kit.box(f, "LED screen", Vector3(0, 9.4, 0.7), Vector3(13.0, 8.4, 0.2), Color("7f93a6"), false, Kit.mat(Color("7f93a6"), 0.25))
    Kit.box(f, "Doors", Vector3(0, 1.8, 0.65), Vector3(18.0, 3.4, 0.15), Color("14202a"))

# ---------------------------------------------------------------- Fair Play / Basic-Fit (+X)

func _fairplay_block() -> void:
    # beige/donker gestreept, getrapt: 4 lagen aan de uiteinden, 5 daarbinnen, 6 in het midden
    var tiles := Kit.tex_mat_tiles("res://assets/pls_market.png", Vector2(4.0, LEVEL))
    var depth: float = 9.0
    var cx: float = BACK_X + depth * 0.5
    var face_x: float = BACK_X + depth
    # losse, niet-overlappende stukken: (van z, tot z, lagen)
    for seg in [[-BLOCK_Z, -32.0, 4], [-32.0, -13.0, 5], [-13.0, 13.0, 6], [13.0, 32.0, 5], [32.0, BLOCK_Z, 4]]:
        var z0: float = seg[0]
        var z1: float = seg[1]
        var h: float = float(seg[2]) * LEVEL
        var zc: float = (z0 + z1) * 0.5
        Kit.box(self, "Fair Play block", Vector3(cx, h * 0.5, zc), Vector3(depth, h, z1 - z0), brick, true, tiles)
        Kit.box(self, "Fair Play parapet", Vector3(cx, h + 0.2, zc), Vector3(depth + 0.3, 0.4, z1 - z0 + 0.3), band)
    # donkere leien dakopbouw op het middendeel
    Kit.box(self, "Slate top", Vector3(cx - 0.5, 6.0 * LEVEL + 1.4, 0), Vector3(depth - 2.0, 2.8, 20.0), Color("3a3d40"))
    # glazen pui; paarse kolommen alleen bij het casino aan de kant van hoek 7
    Kit.box(self, "Fair Play shop front", Vector3(face_x + 0.1, 3.0, 0), Vector3(0.3, 6.0, BLOCK_Z * 2.0 - 4.0),
        Color("22333f"), false, Kit.glass_mat(glass_c))
    for i in range(6):
        Kit.box(self, "Purple column", Vector3(face_x + 0.5, 3.2, 20.0 + float(i) * 5.0), Vector3(0.35, 6.4, 0.35), Color("6c5a8a"))
    for i in range(-5, 4):
        Kit.box(self, "Shop pier", Vector3(face_x + 0.4, 3.0, float(i) * 5.0), Vector3(0.5, 6.0, 1.2), brick)

# ---------------------------------------------------------------- hotelzijde (-Z)

func _hotel_block() -> void:
    var louvre := Kit.tex_mat_tiles("res://assets/pls_louvre.png", Vector2(4.0, LEVEL))
    var hotel := Kit.tex_mat_tiles("res://assets/pls_hotel.png", Vector2(4.0, LEVEL))
    var banded := Kit.tex_mat_tiles("res://assets/pls_market.png", Vector2(4.0, LEVEL))
    var depth: float = 7.0
    var cz: float = -(BACK_Z + depth * 0.5)
    var face_z: float = -(BACK_Z + depth)
    var body_h: float = 5.0 * LEVEL
    var glass_m := Kit.glass_mat(glass_c)
    # vleugels: glas achter lamellen
    Kit.box(self, "Hotel wings", Vector3(0, body_h * 0.5, cz), Vector3(BLOCK_X * 2.0, body_h, depth), dark_brick, true, louvre)
    # donkerbruine kopse blokken met beige banden, uitkragend
    for sx in [-1.0, 1.0]:
        # kopblok steekt 0,3 m buiten de vleugel uit, zodat de zijvlakken niet samenvallen
        Kit.box(self, "Hotel end block", Vector3(sx * (BLOCK_X - 4.85), body_h * 0.5 + 0.3, face_z - 0.8),
            Vector3(10.3, body_h + 0.6, 1.6), dark_brick, false, banded)
        Kit.box(self, "End parapet", Vector3(sx * (BLOCK_X - 4.85), body_h + 0.75, cz - 0.8), Vector3(10.6, 0.3, depth + 1.9), band)
    # entreedeel: donkerbruin, beige borstweringen, hoog glazen atrium
    var ch: float = 6.0 * LEVEL
    # 2 m voor de gevel uit, achterkant 0,3 m binnen die van de vleugels
    var ent_back: float = -(BACK_Z + 0.3)
    var ent_front: float = face_z - 2.0
    Kit.box(self, "Hotel entrance block", Vector3(0, ch * 0.5, (ent_back + ent_front) * 0.5), Vector3(28.0, ch, ent_back - ent_front),
        dark_brick, true, hotel)
    var front: float = face_z - 2.0
    Kit.box(self, "Atrium", Vector3(-7.0, ch * 0.5 + 2.0, front - 0.15), Vector3(10.0, ch - 4.0, 0.4), glass_c, false, glass_m)
    for i in range(-2, 3):
        Kit.box(self, "Atrium mullion", Vector3(-7.0 + float(i) * 2.4, ch * 0.5 + 2.0, front - 0.4), Vector3(0.14, ch - 4.0, 0.1), Color("1c1f22"))
    for j in range(2, 6):
        Kit.box(self, "Atrium transom", Vector3(-7.0, float(j) * LEVEL, front - 0.4), Vector3(10.0, 0.14, 0.1), Color("1c1f22"))
    Kit.box(self, "Entrance roof", Vector3(0, ch + 0.25, face_z + depth * 0.5 - 1.0), Vector3(28.6, 0.5, depth + 2.6), band)
    # teruggezette glazen dakopbouw met overstekend plat dak
    Kit.box(self, "Hotel penthouse", Vector3(0, body_h + 1.6, cz + 1.0), Vector3(96.0, 3.2, depth - 2.5), glass_c, false, glass_m)
    Kit.box(self, "Penthouse roof", Vector3(0, body_h + 3.4, cz + 0.4), Vector3(98.0, 0.35, depth + 0.4), Color("e4e4e0"))
    # winkelpui met beige penanten
    Kit.box(self, "Shop fronts", Vector3(0, 2.4, face_z - 0.15), Vector3(BLOCK_X * 2.0 - 20.0, 4.8, 0.3), glass_c, false, glass_m)
    for i in range(-6, 7):
        if absi(i) <= 1:
            continue
        Kit.box(self, "Shop pier", Vector3(float(i) * 8.0, 2.4, face_z - 0.4), Vector3(1.3, 4.8, 0.5), brick)

# ---------------------------------------------------------------- Albert Heijn-zijde (-X)

func _market_block() -> void:
    var tiles := Kit.tex_mat_tiles("res://assets/pls_market.png", Vector2(4.0, LEVEL))
    var depth: float = 19.5
    var h: float = 6.0 * LEVEL
    var cx: float = -(BACK_X + depth * 0.5)
    var face_x: float = -(BACK_X + depth)
    var glass_m := Kit.glass_mat(glass_c)
    Kit.box(self, "Market block", Vector3(cx, h * 0.5, 0), Vector3(depth, h, BLOCK_Z * 2.0), brick, true, tiles)
    Kit.box(self, "Market parapet", Vector3(cx, h + 0.25, 0), Vector3(depth + 0.4, 0.5, BLOCK_Z * 2.0 + 0.4), brick)
    Kit.box(self, "Market shop front", Vector3(face_x - 0.15, 2.2, 0), Vector3(0.3, 4.4, BLOCK_Z * 2.0 - 12.0), glass_c, false, glass_m)
    # glazen trappenhuizen aan beide uiteinden
    for sz in [-1.0, 1.0]:
        Kit.box(self, "Stair tower", Vector3(face_x - 0.3, h * 0.5, sz * (BLOCK_Z - 3.5)), Vector3(0.8, h, 3.6), glass_c, false, glass_m)
        Kit.box(self, "Stair tower end", Vector3(cx + 3.0, h * 0.5, sz * (BLOCK_Z + 0.3)), Vector3(3.6, h, 0.8), glass_c, false, glass_m)
    # drie donkere tongewelven op het dak, as haaks op de gevel
    for z in [-10.4, 0.0, 10.4]:
        Kit.cyl(self, "Roof barrel", Vector3(cx - 1.5, h, z), 4.8, 4.8, 15.0, Color("3a3f44"), 24, "x")
    # grijze hallen tegen de hoeken (Music Dome bij hoek 2)
    for sz in [-1.0, 1.0]:
        var hall_h: float = 13.0
        var hall_c := Vector3(-(CORNER_X + 94.0) * 0.5, hall_h * 0.5, sz * (BLOCK_Z + 5.5))
        Kit.box(self, "Corner hall", hall_c, Vector3(94.0 - CORNER_X, hall_h, 11.0), Color("a9adb0"), true)
        Kit.box(self, "Hall glazing", hall_c + Vector3(0, -2.5, sz * 5.55), Vector3(94.0 - CORNER_X - 2.0, 5.0, 0.2), glass_c, false, glass_m)

# ---------------------------------------------------------------- hoeken

func _corners() -> void:
    var gates := {Vector2(1, 1): "7", Vector2(1, -1): "5/6", Vector2(-1, -1): "3/4", Vector2(-1, 1): "2"}
    for sx in [-1.0, 1.0]:
        for sz in [-1.0, 1.0]:
            _corner(sx, sz, gates[Vector2(sx, sz)])

func _corner(sx: float, sz: float, gate: String) -> void:
    # Open betonnen hoek van de tribune, schuin tussen de twee gebouwen. Lokaal: +X langs de gevel, +Z naar buiten.
    var p1 := Vector3(sx * BLOCK_X, 0.0, sz * FRONT_Z)
    var p2 := Vector3(sx * CORNER_X, 0.0, sz * BLOCK_Z)
    var length: float = p1.distance_to(p2)
    var out: Vector3 = Vector3(p2.z - p1.z, 0.0, p1.x - p2.x).normalized()
    if out.dot(Vector3(sx, 0.0, sz)) < 0.0:
        out = -out
    var c := Node3D.new()
    c.name = "Corner " + gate
    c.position = (p1 + p2) * 0.5
    c.rotation.y = atan2(out.x, out.z)
    add_child(c)
    var hw: float = length * 0.5
    Kit.box(c, "Concourse back wall", Vector3(0, 4.3, -7.0), Vector3(length, 8.6, 0.6), Color("3b3f42"), true)
    Kit.box(c, "Concourse slab", Vector3(0, 8.9, -3.5), Vector3(length, 0.8, 7.4), concrete)
    Kit.box(c, "Grey cladding", Vector3(0, 11.4, -2.6), Vector3(length, 4.2, 0.4), Color("c9cccd"))
    Kit.box(c, "Cladding windows", Vector3(0, 10.5, -2.35), Vector3(length - 2.0, 1.1, 0.2), glass_c, false, Kit.glass_mat(glass_c))
    Kit.box(c, "Concrete band", Vector3(0, 14.1, -2.2), Vector3(length, 1.2, 0.9), concrete)
    # schuine onderkant van de tribune boven de omloop, daalt naar het veld toe
    var rake := Kit.box(c, "Stand underside", Vector3(0, 17.6, -6.0), Vector3(length, 0.8, 17.4), concrete)
    rake.rotation.x = -atan2(7.0, 15.8)
    Kit.box(c, "Edge beam", Vector3(0, CORNER_TOP - 0.6, 2.6), Vector3(length + 2.0, 1.2, 1.0), concrete)
    Kit.box(c, "Top railing", Vector3(0, CORNER_TOP + 0.5, 2.6), Vector3(length + 2.0, 1.0, 0.15), steel)
    # gebogen betonkolommen: recht omhoog en dan naar buiten krullend tot de dakrand
    for i in range(4):
        var x: float = lerpf(-hw + 1.5, hw - 1.5, float(i) / 3.0)
        var pts := [Vector3(x, 0, -1.0), Vector3(x, 7.0, -0.8), Vector3(x, 11.5, -0.1), Vector3(x, 15.5, 1.1), Vector3(x, 18.5, 2.3), Vector3(x, CORNER_TOP - 0.6, 2.6)]
        for k in range(pts.size() - 1):
            Kit.beam(c, "Curved column", pts[k], pts[k + 1], 1.0, concrete)
        Kit.beam(c, "White strut", Vector3(x, 12.0, 0.6), Vector3(x + 2.5, 19.0, -6.0), 0.3, white)
        Kit.beam(c, "White strut", Vector3(x, 15.0, 1.1), Vector3(x - 2.0, 20.5, -3.0), 0.25, white)
    # toegangshekken en het groene ingangsnummer
    Kit.box(c, "Gate fence", Vector3(0, 1.3, -1.2), Vector3(length - 3.0, 2.6, 0.15), Color("b5b8ba"))
    Kit.cyl(c, "Gate sign", Vector3(0, 7.0, 0.95), 0.8, 0.8, 0.1, Color("2f9a4a"), 20, "z")
    Kit.label(c, gate, Vector3(0, 7.0, 1.05), 0.012, Color.WHITE, 64)
    # vakwerkmast op de betonhoek, ver naar binnen leunend
    var foot: Vector3 = c.position + out * 1.5 + Vector3(0, CORNER_TOP + 0.4, 0)
    var top: Vector3 = foot - out * 23.0 + Vector3(0, 32.0, 0)
    Kit.box(self, "Mast platform", foot + Vector3(0, -0.2, 0), Vector3(5.5, 0.4, 5.5), steel)
    Kit.box(self, "Mast ladder cage", foot + out * 2.2 + Vector3(0, -5.0, 0), Vector3(1.0, 10.0, 1.0), mast_white)
    _floodlight_mast(foot, top)
    # witte tent hangt met zijn top aan de mast
    var apex: Vector3 = foot.lerp(top, (TENT_TOP - foot.y) / (top.y - foot.y))
    var tent_c := Vector3(apex.x, 0.0, apex.z)
    Kit.cyl(self, "Tent", tent_c + Vector3(0, (TENT_LOW + TENT_TOP) * 0.5, 0), 12.0, 1.6, TENT_TOP - TENT_LOW,
        Color("ece8dc"), 20, "y", false, Kit.two_sided_mat(Color("ece8dc")))
    var hang: Vector3 = foot.lerp(top, 0.75)
    for k in range(4):
        var ang: float = TAU * (float(k) + 0.5) / 4.0
        var rim := tent_c + Vector3(cos(ang) * 11.5, TENT_LOW + 0.9, sin(ang) * 11.5)
        Kit.beam(self, "Tent cable", hang, rim, 0.1, steel)

func _floodlight_mast(a: Vector3, b: Vector3) -> void:
    # Wit driehoeksspant, breed aan de voet, met bovenaan een lampenrek dat op het veld gericht is.
    var axis: Vector3 = (b - a).normalized()
    var helper: Vector3 = Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT
    var u: Vector3 = axis.cross(helper).normalized()
    var v: Vector3 = axis.cross(u).normalized()
    var segs := 10
    var prev: Array = []
    for k in range(segs + 1):
        var t: float = float(k) / float(segs)
        var r: float = lerpf(2.6, 1.0, t)
        var c: Vector3 = a.lerp(b, t)
        var ring: Array = []
        for i in range(3):
            var ang: float = TAU * float(i) / 3.0
            ring.append(c + u * cos(ang) * r + v * sin(ang) * r)
        if k > 0:
            for i in range(3):
                Kit.beam(self, "Mast chord", prev[i], ring[i], 0.4, mast_white)
                Kit.beam(self, "Mast diagonal", prev[i], ring[(i + 1) % 3], 0.16, mast_white)
        for i in range(3):
            Kit.beam(self, "Mast ring", ring[i], ring[(i + 1) % 3], 0.16, mast_white)
        prev = ring
    var head := Node3D.new()
    head.name = "Floodlight head"
    head.position = b
    head.rotation.y = atan2(-b.x, -b.z)
    add_child(head)
    var tilt := Node3D.new()
    tilt.rotation_degrees.x = 28.0
    head.add_child(tilt)
    Kit.box(tilt, "Lamp frame", Vector3(0, 0, 0), Vector3(8.0, 4.8, 0.7), Color("5b6166"))
    for ix in range(-3, 4):
        for iy in range(-1, 2):
            Kit.box(tilt, "Lamp cell", Vector3(float(ix) * 1.05, float(iy) * 1.4, 0.42), Vector3(0.9, 1.0, 0.2),
                Color("fff4c6"), false, Kit.mat(Color("fff4c6"), 1.4))
    Kit.box(head, "Lamp walkway", Vector3(0, -2.8, -0.8), Vector3(8.6, 0.25, 1.6), mast_white)
    Kit.box(head, "Lamp arm", Vector3(0, -1.6, -0.6), Vector3(0.5, 3.2, 0.5), mast_white)
