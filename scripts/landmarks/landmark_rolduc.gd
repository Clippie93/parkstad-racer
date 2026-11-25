extends Node3D
# Abdij Rolduc, Kerkrade. Naar foto's op Wikimedia Commons (luchtfoto, westtoren, poort, voorhof):
# - romaanse abdijkerk van bruingrijze zandsteen: westtoren met lisenen en rondboogfriezen,
#   gekoppelde galmgaten, barokke leien spits met lantaarn, bol en kruis; lagere westbouw
#   met leien schilddaken; schip met zadeldak en een achtkante vieringtoren
# - brede vleugels van rode baksteen (drie lagen) met witte schuiframen en leien schilddaken
#   met dakkapellen, rond een voorhof
# - poortgebouw met twee rondbogen (links deuren, rechts smeedijzeren hek) en het Mariabeeld
#   in een witte nis, koepeltorentjes; rood-witte luiken, hoektorens met barokke kappen en
#   de middenrisaliet met ROLDUC-bord naar jouw foto's (20-11)
# - voorhof met rond grasveld, beeldzuil, kroon-sculptuur en vlaggen
# Lokale ruimte: oorsprong = midden voor de toren, +Z = naar de voorhof en de straat.
# Afmetingen geschat; het complex is ingekort om in een level te passen.
const Kit = preload("res://scripts/build_kit.gd")

var stone: StandardMaterial3D
var wing_mat: StandardMaterial3D
var slate := Color("4b5056")
var white_stone := Color("e4e0d6")

func _ready() -> void:
    name = "Rolduc"
    stone = Kit.tex_mat("res://assets/kerk_rubble.png", Color("9c8a76"), 4.0)
    wing_mat = Kit.tex_mat_tiles("res://assets/rolduc_wing_shutters.png", Vector2(3.2, 4.0))
    _church()
    _wings()
    _gate()
    _forecourt()
    _corner_towers()
    _risalit()
    _apse()

# ---------------------------------------------------------------- daken
func _hip_roof(n: String, center: Vector3, width: float, length: float, rise: float, along_x := true) -> void:
    # schilddak: nok korter dan het grondvlak, schuine vlakken aan alle vier de kanten
    # width = dwars op de nok, length = langs de nok; along_x = nok langs X, anders langs Z
    var hw: float = length * 0.5
    var hd: float = width * 0.5
    var ridge: float = maxf(0.0, hw - hd)
    var a := Vector3(-hw, 0, -hd)
    var b := Vector3(hw, 0, -hd)
    var c := Vector3(hw, 0, hd)
    var d := Vector3(-hw, 0, hd)
    var r1 := Vector3(-ridge, rise, 0)
    var r2 := Vector3(ridge, rise, 0)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for tri in [[a, b, r2], [a, r2, r1], [d, r1, r2], [d, r2, c], [a, r1, d], [b, c, r2]]:
        for v in tri:
            st.add_vertex(v)
    st.generate_normals()
    var mi := MeshInstance3D.new()
    mi.name = n
    mi.mesh = st.commit()
    mi.material_override = Kit.two_sided_mat(slate)
    mi.position = center
    if not along_x:
        mi.rotation_degrees.y = 90.0
    add_child(mi)

# ---------------------------------------------------------------- kerk
func _church() -> void:
    var tw := 9.0
    var th := 31.0
    # westtoren
    Kit.box(self, "Tower", Vector3(0, th * 0.5, -4.5), Vector3(tw, th, 9.0), Color.WHITE, true, stone)
    for y in [12.0, 21.5]:
        Kit.box(self, "Tower ledge", Vector3(0, y, -4.5), Vector3(tw + 0.4, 0.35, 9.4), Color("8e7f6c"))
    Kit.box(self, "Tower cornice", Vector3(0, th + 0.2, -4.5), Vector3(tw + 0.6, 0.4, 9.6), Color("8e7f6c"))
    for yaw in [0.0, 90.0, -90.0, 180.0]:
        var out: Vector3 = Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
        var f := Kit.face(self, Vector3(0, 0, -4.5) + out * 4.5, yaw)
        # lisenen op de hoeken en rondboogfries onder elke lijst
        for x in [-4.1, 4.1]:
            Kit.box(f, "Lesene", Vector3(x, (12.0 + th) * 0.5, 0.12), Vector3(0.8, th - 12.0, 0.24), Color("9c8b76"))
        for yb in [20.6, th - 0.9]:
            for k in range(7):
                Kit.box(f, "Arch frieze", Vector3(-3.3 + float(k) * 1.1, yb, 0.12), Vector3(0.9, 0.3, 0.2), Color("9c8b76"))
        # gekoppelde galmgaten bovenin, smalle vensters halverwege
        for x in [-1.15, 1.15]:
            Kit.box(f, "Belfry opening", Vector3(x, 26.0, 0.05), Vector3(1.3, 3.6, 0.2), Color("1d1f22"))
            Kit.cyl(f, "Belfry arch", Vector3(x, 27.8, 0.05), 0.65, 0.65, 0.2, Color("1d1f22"), 12, "z")
        Kit.box(f, "Mid window", Vector3(0, 16.5, 0.05), Vector3(0.8, 2.4, 0.2), Color("1d1f22"))
        Kit.cyl(f, "Mid arch", Vector3(0, 17.7, 0.05), 0.4, 0.4, 0.2, Color("1d1f22"), 10, "z")
    # portaal in de westgevel
    var fr := Kit.face(self, Vector3(0, 0, 0), 0)
    Kit.box(fr, "Portal surround", Vector3(0, 2.4, 0.15), Vector3(3.4, 4.8, 0.3), Color("9c8b76"))
    Kit.box(fr, "Portal door", Vector3(0, 1.6, 0.32), Vector3(1.9, 3.2, 0.1), Color("3b2a20"))
    Kit.cyl(fr, "Portal arch", Vector3(0, 3.2, 0.32), 0.95, 0.95, 0.1, Color("3b2a20"), 12, "z")
    Kit.box(fr, "Portal window", Vector3(0, 8.0, 0.05), Vector3(1.0, 2.2, 0.2), Color("1d1f22"))
    # barokke spits: leien piramide, lantaarn, klokvormig kapje, naald, bol en kruis
    var top := th + 0.4
    Kit.pyramid(self, "Spire base", Vector3(0, top, -4.5), 4.7, 6.5, slate)
    Kit.cyl(self, "Lantern", Vector3(0, top + 7.4, -4.5), 1.25, 1.25, 2.8, Color("3c4046"), 8)
    for k in range(8):
        var a: float = float(k) * TAU / 8.0
        Kit.box(self, "Lantern opening", Vector3(sin(a) * 1.27, top + 7.4, -4.5 + cos(a) * 1.27), Vector3(0.35, 1.6, 0.35), Color("15171a"))
    Kit.cyl(self, "Bell cap", Vector3(0, top + 9.6, -4.5), 1.6, 0.45, 1.6, slate, 8)
    Kit.cyl(self, "Upper lantern", Vector3(0, top + 10.9, -4.5), 0.5, 0.5, 1.0, Color("3c4046"), 8)
    Kit.cyl(self, "Needle", Vector3(0, top + 13.0, -4.5), 0.55, 0.0, 3.2, slate, 8)
    Kit.cyl(self, "Orb", Vector3(0, top + 14.8, -4.5), 0.28, 0.28, 0.5, Color("c9a54a"), 10)
    Kit.cyl(self, "Cross post", Vector3(0, top + 15.8, -4.5), 0.06, 0.06, 1.6, Color("2a2a2a"), 6)
    Kit.box(self, "Cross bar", Vector3(0, top + 16.1, -4.5), Vector3(0.8, 0.08, 0.08), Color("2a2a2a"))
    # lagere westbouw naast de toren met schilddaken
    for sx in [-1.0, 1.0]:
        var cx: float = sx * 6.75
        Kit.box(self, "Westwork", Vector3(cx, 6.5, -4.0), Vector3(4.5, 13.0, 8.0), Color.WHITE, true, stone)
        _hip_roof("Westwork roof", Vector3(cx, 13.0, -4.0), 4.9, 8.4, 3.2, false)
        var wf := Kit.face(self, Vector3(cx, 0, 0), 0)
        Kit.box(wf, "Westwork window", Vector3(0, 9.0, 0.05), Vector3(0.7, 1.8, 0.2), Color("1d1f22"))
        Kit.box(wf, "Westwork window low", Vector3(0, 3.5, 0.05), Vector3(0.7, 1.6, 0.2), Color("1d1f22"))
    # schip met zadeldak, achtkante vieringtoren
    Kit.box(self, "Nave", Vector3(0, 8.5, -29.0), Vector3(15.0, 17.0, 40.0), Color.WHITE, true, stone)
    Kit.gable(self, "Nave roof", Vector3(0, 17.0, -29.0), 16.0, 40.6, 8.0, slate)
    Kit.cyl(self, "Crossing tower", Vector3(0, 25.5, -38.0), 3.6, 3.6, 5.0, Color("8e7f6c"), 8)
    Kit.cyl(self, "Crossing roof", Vector3(0, 30.5, -38.0), 4.0, 0.2, 5.0, slate, 8)
    Kit.cyl(self, "Crossing cross", Vector3(0, 34.0, -38.0), 0.05, 0.05, 2.0, Color("2a2a2a"), 6)

# ---------------------------------------------------------------- vleugels
func _wing(n: String, center: Vector3, size: Vector3, along_x: bool, dormer_side: float) -> void:
    Kit.box(self, n, center, size, Color.WHITE, true, wing_mat)
    var top: float = center.y + size.y * 0.5
    Kit.box(self, n + " cornice", Vector3(center.x, top + 0.15, center.z), Vector3(size.x + 0.5, 0.3, size.z + 0.5), white_stone)
    var depth: float = size.z if along_x else size.x
    var length: float = size.x if along_x else size.z
    _hip_roof(n + " roof", Vector3(center.x, top + 0.3, center.z), depth + 0.6, length + 0.6, 5.5, along_x)
    # dakkapellen aan de zichtzijde
    if dormer_side == 0.0:
        return
    var count: int = int((length - 8.0) / 6.4)
    for k in range(count):
        var t: float = -float(count - 1) * 3.2 + float(k) * 6.4
        var inset: float = depth * 0.5 - 1.6
        var p: Vector3
        if along_x:
            p = Vector3(center.x + t, top + 1.4, center.z + dormer_side * inset)
        else:
            p = Vector3(center.x + dormer_side * inset, top + 1.4, center.z + t)
        Kit.box(self, "Dormer", p, Vector3(1.4, 1.8, 1.4), white_stone)
        Kit.box(self, "Dormer glass", p + (Vector3(0, -0.1, dormer_side * 0.71) if along_x else Vector3(dormer_side * 0.71, -0.1, 0)), Vector3(0.9 if along_x else 0.04, 1.1, 0.04 if along_x else 0.9), Color("2f3a40"))
        Kit.gable(self, "Dormer roof", p + Vector3(0, 0.9, 0), 1.7, 1.7, 0.8, slate, not along_x)

func _wings() -> void:
    for sx in [-1.0, 1.0]:
        # vleugels links en rechts van de kerk (achter de voorhof)
        _wing("Main wing", Vector3(sx * 28.5, 6.0, -7.5), Vector3(37.0, 12.0, 13.0), true, 1.0)
        # zijvleugels langs de voorhof, tot achter de kerk
        _wing("Side wing", Vector3(sx * 53.5, 6.0, -1.0), Vector3(13.0, 12.0, 98.0), false, -sx)
        # lagere voorvleugels bij de poort
        _wing("Front wing", Vector3(sx * 36.0, 4.0, 52.0), Vector3(22.0, 8.0, 12.0), true, 1.0)
        # achtervleugel (kloosterpand) achter de kerk
        _wing("Back wing", Vector3(sx * 28.5, 6.0, -44.0), Vector3(37.0, 12.0, 12.0), true, 0.0)

# ---------------------------------------------------------------- poort
# Naar jouw Street View-foto (20-11): poortgebouw van bruinrode baksteen met twee grote
# rondbogen in lichte hardsteen met sluitstenen. Links houten deuren met een donkerrood
# bovenlicht, rechts een zwart smeedijzeren hek waardoor je de voorhof in kijkt. In het
# midden een witte nis met het Mariabeeld onder een halfrond met het opschrift
# VIRGO SINE LABE CONCEPTA AEDES HAS DEFENDE. Links een lagere muur met een klein deurtje.
const GATE_Z := 55.5
const GATE_H := 9.0
const ARCH_R := 1.8
const ARCH_SPRING := 4.2
const ARCH_X := 4.4

# Vulstuk tussen een halve cirkel en zijn omhullende rechthoek (de zwikken boven een
# boog), in face-ruimte op diepte z.
func _spandrel(f: Node3D, xc: float, spring: float, r: float, z: float, m: Material) -> void:
    var t: Array = []
    var n := 14
    var tl := Vector3(xc - r, spring + r, z)
    var tr := Vector3(xc + r, spring + r, z)
    for k in range(n):
        var a0: float = PI * float(k) / float(n)
        var a1: float = PI * float(k + 1) / float(n)
        var p0 := Vector3(xc + cos(a0) * r, spring + sin(a0) * r, z)
        var p1 := Vector3(xc + cos(a1) * r, spring + sin(a1) * r, z)
        var corner: Vector3 = tr if a1 <= PI * 0.5 + 0.001 else tl
        t.append_array([p0, p1, corner])
    t.append_array([tr, Vector3(xc, spring + r, z), tl])
    var mi := MeshInstance3D.new()
    mi.name = "Spandrel"
    mi.mesh = Kit._mesh_from(t, m)
    mi.material_override = m
    f.add_child(mi)

func _gate() -> void:
    var brick := Kit.tex_mat("res://assets/on_brick.png", Color("a8786a"), 3.0)
    var stone_c := Color("c9c5bb")
    var z := GATE_Z
    var half: float = ARCH_X + ARCH_R + 1.8      # halve breedte van het poortgebouw
    var top: float = ARCH_SPRING + ARCH_R
    # pijlers: buiten, midden (met de nis)
    for sx in [-1.0, 1.0]:
        var x0: float = ARCH_X + ARCH_R
        Kit.box(self, "Gate pier", Vector3(sx * (x0 + half) * 0.5, GATE_H * 0.5, z), Vector3(half - x0, GATE_H, 1.2), Color.WHITE, true, brick)
    var mid_w: float = (ARCH_X - ARCH_R) * 2.0
    Kit.box(self, "Gate middle", Vector3(0, GATE_H * 0.5, z), Vector3(mid_w, GATE_H, 1.2), Color.WHITE, true, brick)
    # boven de bogen
    for sx in [-1.0, 1.0]:
        Kit.box(self, "Gate lintel", Vector3(sx * ARCH_X, (top + GATE_H) * 0.5, z), Vector3(ARCH_R * 2.0, GATE_H - top, 1.2), Color.WHITE, false, brick)
    Kit.box(self, "Gate coping", Vector3(0, GATE_H + 0.15, z), Vector3(half * 2.0 + 0.3, 0.3, 1.5), Color("8e8a82"))
    Kit.box(self, "Gate plinth", Vector3(0, 0.3, z), Vector3(half * 2.0 + 0.1, 0.6, 1.3), Color("8e8a82"))
    for side in [1.0, -1.0]:
        var f := Kit.face(self, Vector3(0, 0, z + side * 0.6), 0.0 if side > 0.0 else 180.0)
        for sx in [-1.0, 1.0]:
            var xc: float = sx * ARCH_X * side
            _spandrel(f, xc, ARCH_SPRING, ARCH_R, 0.0, brick)
            if side < 0.0:
                continue
            # hardstenen boog met sluitsteen, neggen en kämpfer
            for k in range(13):
                var a: float = PI * float(k) / 12.0
                var b := Kit.box(f, "Arch stone", Vector3(xc + cos(a) * (ARCH_R + 0.25), ARCH_SPRING + sin(a) * (ARCH_R + 0.25), 0.08), Vector3(0.55, 0.5, 0.18), stone_c)
                b.rotation.z = a + PI * 0.5
            Kit.box(f, "Keystone", Vector3(xc, top + 0.45, 0.14), Vector3(0.7, 1.0, 0.24), stone_c)
            for jx in [-1.0, 1.0]:
                Kit.box(f, "Jamb", Vector3(xc + jx * (ARCH_R + 0.25), ARCH_SPRING * 0.5, 0.08), Vector3(0.5, ARCH_SPRING, 0.18), stone_c)
                Kit.box(f, "Impost", Vector3(xc + jx * (ARCH_R + 0.25), ARCH_SPRING, 0.12), Vector3(0.7, 0.3, 0.26), stone_c)
    # linker boog: houten deuren met donkerrood bovenlicht (in de doorgang)
    var lx: float = -ARCH_X
    Kit.cyl(self, "Fanlight", Vector3(lx, ARCH_SPRING, z), ARCH_R, ARCH_R, 0.2, Color("5a1f1c"), 20, "z")
    for k in range(6):
        var a: float = PI * (float(k) + 0.5) / 6.0
        Kit.beam(self, "Fanlight bar", Vector3(lx, ARCH_SPRING, z + 0.12), Vector3(lx + cos(a) * ARCH_R, ARCH_SPRING + sin(a) * ARCH_R, z + 0.12), 0.06, Color("2b1210"))
    Kit.box(self, "Gate doors", Vector3(lx, ARCH_SPRING * 0.5, z), Vector3(ARCH_R * 2.0, ARCH_SPRING, 0.25), Color("7a2e22"), true)
    for dx in [-0.9, 0.0, 0.9]:
        Kit.box(self, "Door plank line", Vector3(lx + dx, ARCH_SPRING * 0.5, z + 0.14), Vector3(0.05, ARCH_SPRING - 0.2, 0.03), Color("5c2018"))
    Kit.box(self, "Fanlight transom", Vector3(lx, ARCH_SPRING, z + 0.14), Vector3(ARCH_R * 2.0, 0.18, 0.1), Color("4a1a14"))
    # rechter boog: zwart smeedijzeren hek met gouden punten
    var rx: float = ARCH_X
    var iron := Color("1c1d1f")
    var bx: float = -ARCH_R + 0.15
    while bx < ARCH_R:
        var h: float = ARCH_SPRING + sqrt(maxf(0.0, ARCH_R * ARCH_R - bx * bx)) * 0.55 - 0.1
        Kit.box(self, "Gate bar", Vector3(rx + bx, h * 0.5, z), Vector3(0.05, h, 0.05), iron)
        Kit.box(self, "Gate spike", Vector3(rx + bx, h + 0.1, z), Vector3(0.08, 0.2, 0.08), Color("c9a54a"))
        bx += 0.16
    for y in [0.3, 1.6, 3.4]:
        Kit.box(self, "Gate rail", Vector3(rx, y, z), Vector3(ARCH_R * 2.0, 0.07, 0.07), iron)
    var fr := Kit.face(self, Vector3(0, 0, z + 0.6), 0)
    # middelste nis met Mariabeeld en het halfrond met opschrift
    Kit.box(fr, "Niche frame", Vector3(0, 2.8, 0.1), Vector3(2.5, 3.6, 0.2), stone_c)
    Kit.cyl(fr, "Niche frame top", Vector3(0, 4.6, 0.1), 1.25, 1.25, 0.2, stone_c, 20, "z")
    Kit.box(fr, "Niche", Vector3(0, 2.9, 0.18), Vector3(1.6, 3.2, 0.06), Color("a9b8c0"))
    Kit.cyl(fr, "Niche top", Vector3(0, 4.5, 0.18), 0.8, 0.8, 0.06, Color("a9b8c0"), 20, "z")
    Kit.box(fr, "Niche sill", Vector3(0, 1.05, 0.3), Vector3(2.8, 0.25, 0.4), stone_c)
    Kit.cyl(fr, "Mary pedestal", Vector3(0, 1.4, 0.35), 0.3, 0.35, 0.45, Color("eeeae0"), 10)
    Kit.cyl(fr, "Mary", Vector3(0, 2.6, 0.35), 0.24, 0.32, 2.0, Color("eeeae0"), 10)
    Kit.cyl(fr, "Mary head", Vector3(0, 3.75, 0.35), 0.15, 0.15, 0.32, Color("eeeae0"), 10)
    # halfrond boven de nis: stenen rand, wit veld met het opschrift
    var tc := Vector3(0, 5.0, 0.12)
    _half_disc(fr, tc, 2.35, stone_c)
    _half_disc(fr, tc + Vector3(0, 0.12, 0.04), 2.05, Color("ece8de"))
    Kit.box(fr, "Tympanum base", tc + Vector3(0, 0.0, 0.02), Vector3(4.9, 0.25, 0.22), stone_c)
    Kit.label(fr, "VIRGO SINE LABE CONCEPTA\nAEDES HAS DEFENDE", Vector3(0, 5.95, 0.24), 0.0042, Color("3a3936"), 64)
    # lagere muren naar de koepeltorentjes, links met een klein rondboogdeurtje
    for sx in [-1.0, 1.0]:
        var w: float = 25.0 - half
        Kit.box(self, "Gate wall", Vector3(sx * (half + w * 0.5), 2.75, z), Vector3(w, 5.5, 1.0), Color.WHITE, true, brick)
        Kit.box(self, "Wall coping", Vector3(sx * (half + w * 0.5), 5.6, z), Vector3(w, 0.2, 1.2), Color("8e8a82"))
    var dw := Kit.face(self, Vector3(-half - 3.0, 0, z + 0.5), 0)
    Kit.box(dw, "Small door", Vector3(0, 1.1, 0.04), Vector3(1.1, 2.2, 0.06), Color("6a2a1e"))
    Kit.cyl(dw, "Small door arch", Vector3(0, 2.2, 0.04), 0.55, 0.55, 0.06, Color("6a2a1e"), 12, "z")
    Kit.box(dw, "Small door frame", Vector3(0, 1.2, 0.02), Vector3(1.5, 2.6, 0.04), stone_c)
    # koepeltorentjes aan de uiteinden van de poortmuur
    for sx in [-1.0, 1.0]:
        var p := Vector3(sx * 25.0, 0, z)
        Kit.cyl(self, "Turret", p + Vector3(0, 4.5, 0), 1.9, 1.9, 9.0, Color.WHITE, 12, "y", true, brick)
        Kit.cyl(self, "Turret cornice", p + Vector3(0, 9.1, 0), 2.1, 2.1, 0.25, white_stone, 12)
        Kit.cyl(self, "Turret dome", p + Vector3(0, 10.0, 0), 2.0, 1.0, 1.6, slate, 12)
        Kit.cyl(self, "Turret onion", p + Vector3(0, 11.3, 0), 1.0, 0.1, 1.2, slate, 12)
        Kit.cyl(self, "Turret spike", p + Vector3(0, 12.4, 0), 0.08, 0.02, 1.2, Color("2a2a2a"), 6)

# Halve schijf (bovenste helft) in face-ruimte, middelpunt c.
func _half_disc(f: Node3D, c: Vector3, r: float, color: Color) -> void:
    var t: Array = []
    var n := 20
    for k in range(n):
        var a0: float = PI * float(k) / float(n)
        var a1: float = PI * float(k + 1) / float(n)
        t.append_array([c, c + Vector3(cos(a0) * r, sin(a0) * r, 0), c + Vector3(cos(a1) * r, sin(a1) * r, 0)])
    var mi := MeshInstance3D.new()
    mi.name = "Half disc"
    mi.mesh = Kit._mesh_from(t, Kit._two_sided(color))
    f.add_child(mi)

# ---------------------------------------------------------------- hoektorens
# Vierkante hoektorens met een barokke leien kap (klokvorm, lantaarn, uitje en naald),
# zoals de toren links op je foto van de voorhof.
func _corner_towers() -> void:
    for sx in [-1.0, 1.0]:
        var p := Vector3(sx * 53.5, 0, 46.0)
        var s := 10.0
        var h := 15.0
        Kit.box(self, "Corner tower", p + Vector3(0, h * 0.5, 0), Vector3(s, h, s), Color.WHITE, true, wing_mat)
        Kit.box(self, "Corner tower cornice", p + Vector3(0, h + 0.15, 0), Vector3(s + 0.6, 0.3, s + 0.6), white_stone)
        Kit.pyramid(self, "Corner tower roof", p + Vector3(0, h + 0.3, 0), s * 0.5 + 0.3, 2.6, slate)
        _sphere(p + Vector3(0, h + 4.6, 0), Vector3(3.6, 3.4, 3.6), slate)
        Kit.cyl(self, "Corner tower neck", p + Vector3(0, h + 3.0, 0), 2.6, 2.2, 1.0, slate, 12)
        Kit.cyl(self, "Corner lantern", p + Vector3(0, h + 7.7, 0), 1.0, 1.0, 1.8, Color("3c4046"), 8)
        for k in range(8):
            var a: float = float(k) * TAU / 8.0
            Kit.box(self, "Corner lantern opening", p + Vector3(sin(a) * 1.02, h + 7.7, cos(a) * 1.02), Vector3(0.3, 1.1, 0.3), Color("15171a"))
        _sphere(p + Vector3(0, h + 9.1, 0), Vector3(1.2, 1.3, 1.2), slate)
        Kit.cyl(self, "Corner needle", p + Vector3(0, h + 10.6, 0), 0.25, 0.02, 2.0, slate, 8)
        Kit.cyl(self, "Corner vane", p + Vector3(0, h + 12.1, 0), 0.04, 0.04, 1.2, Color("2a2a2a"), 6)

func _sphere(pos: Vector3, size: Vector3, color: Color) -> void:
    var mi := MeshInstance3D.new()
    mi.name = "Bulb"
    var sm := SphereMesh.new()
    sm.radius = 0.5
    sm.height = 1.0
    sm.radial_segments = 16
    sm.rings = 8
    mi.mesh = sm
    mi.material_override = Kit.mat(color)
    mi.scale = size
    mi.position = pos
    add_child(mi)

# Middenrisaliet van de linker hoofdvleugel: uitspringende gevel met een gebogen top,
# stenen omlijsting, balkonnetje boven de ingang en het rode ROLDUC-bord.
func _risalit() -> void:
    var c := Vector3(-28.5, 0, -0.4)
    var w := 8.0
    var h := 13.5
    Kit.box(self, "Risalit", c + Vector3(0, h * 0.5, 0), Vector3(w, h, 2.4), Color.WHITE, true, wing_mat)
    var f := Kit.face(self, c + Vector3(0, 0, 1.2), 0)
    Kit.cyl(f, "Risalit top", Vector3(0, h - 1.2, -1.2), w * 0.5 + 0.2, w * 0.5 + 0.2, 2.4, Color.WHITE, 24, "z", false, wing_mat)
    # stenen rand langs de gebogen top (alleen het deel boven de gevel)
    var rr: float = w * 0.5 + 0.35
    for k in range(15):
        var ang: float = deg_to_rad(lerpf(17.0, 163.0, float(k) / 14.0))
        var st := Kit.box(f, "Risalit top rim", Vector3(cos(ang) * rr, h - 1.2 + sin(ang) * rr, 0.05), Vector3(0.95, 0.35, 0.3), white_stone)
        st.rotation.z = ang + PI * 0.5
    Kit.cyl(f, "Risalit crest", Vector3(0, h + 0.8, 0.2), 0.9, 0.9, 0.15, Color("8e8a82"), 14, "z")
    for x in [-w * 0.5, w * 0.5]:
        Kit.box(f, "Risalit quoin", Vector3(x, h * 0.5 - 0.6, 0.06), Vector3(0.5, h - 1.2, 0.12), Color("8a6a5c"))
    Kit.box(f, "Risalit sign", Vector3(0, 8.6, 0.12), Vector3(3.2, 0.8, 0.12), Color("a3161f"))
    Kit.label(f, "ROLDUC", Vector3(0, 8.6, 0.2), 0.009, Color("f1e3c0"), 64)
    Kit.box(f, "Risalit door frame", Vector3(0, 1.7, 0.08), Vector3(2.4, 3.4, 0.16), white_stone)
    Kit.box(f, "Risalit door", Vector3(0, 1.5, 0.17), Vector3(1.6, 3.0, 0.06), Color("3a2a22"))
    Kit.box(f, "Balcony", Vector3(0, 3.7, 0.6), Vector3(2.8, 0.2, 1.2), Color("8e8a82"))
    for k in range(9):
        Kit.box(f, "Balcony bar", Vector3(-1.3 + float(k) * 0.325, 4.2, 1.15), Vector3(0.04, 0.9, 0.04), Color("222222"))
    Kit.box(f, "Balcony rail", Vector3(0, 4.65, 1.15), Vector3(2.8, 0.06, 0.06), Color("222222"))

# Halfronde apsis met kegeldak achter het schip (oostkant van de kerk).
func _apse() -> void:
    var c := Vector3(0, 0, -49.0)
    Kit.cyl(self, "Apse", c + Vector3(0, 7.0, 0), 6.5, 6.5, 14.0, Color.WHITE, 20, "y", true, stone)
    Kit.cyl(self, "Apse cornice", c + Vector3(0, 14.1, 0), 6.9, 6.9, 0.3, Color("8e7f6c"), 20)
    Kit.cyl(self, "Apse roof", c + Vector3(0, 16.2, 0), 7.0, 0.3, 4.0, slate, 20)
    for k in range(5):
        var a: float = PI * (0.15 + 0.7 * float(k) / 4.0)
        var p: Vector3 = c + Vector3(cos(a) * 6.55, 0, -sin(a) * 6.55)
        var win := Kit.box(self, "Apse window", p + Vector3(0, 8.5, 0), Vector3(0.9, 3.0, 0.2), Color("1d1f22"))
        win.rotation.y = -a + PI * 0.5
        var arch := Kit.cyl(self, "Apse window arch", p + Vector3(0, 10.0, 0), 0.45, 0.45, 0.2, Color("1d1f22"), 10, "z")
        arch.rotation.y = -a + PI * 0.5

# ---------------------------------------------------------------- voorhof
func _forecourt() -> void:
    Kit.box(self, "Forecourt gravel", Vector3(0, 0.05, 27.0), Vector3(94.0, 0.1, 56.0), Color("a69c88"))
    var lawn := Vector3(0, 0, 27.0)
    Kit.cyl(self, "Flower ring", lawn + Vector3(0, 0.13, 0), 11.0, 11.0, 0.12, Color("b4485e"), 32)
    Kit.cyl(self, "Lawn", lawn + Vector3(0, 0.16, 0), 10.0, 10.0, 0.14, Color("5f8a45"), 32)
    # beeldzuil midden op het gras
    Kit.box(self, "Statue plinth", lawn + Vector3(0, 1.0, 0), Vector3(2.4, 2.0, 2.4), white_stone, true)
    Kit.cyl(self, "Statue column", lawn + Vector3(0, 4.2, 0), 0.6, 0.55, 4.4, white_stone, 12)
    Kit.box(self, "Statue capital", lawn + Vector3(0, 6.55, 0), Vector3(1.4, 0.3, 1.4), white_stone)
    Kit.cyl(self, "Statue figure", lawn + Vector3(0, 7.6, 0), 0.35, 0.3, 1.8, Color("d8d3c8"), 10)
    Kit.cyl(self, "Statue head", lawn + Vector3(0, 8.7, 0), 0.17, 0.17, 0.35, Color("d8d3c8"), 10)
    # kroon op een stenen zuil
    var cp := Vector3(14.0, 0, 30.0)
    Kit.box(self, "Crown pillar", cp + Vector3(0, 2.0, 0), Vector3(0.9, 4.0, 0.9), Color("8f9193"), true)
    Kit.cyl(self, "Crown band", cp + Vector3(0, 4.4, 0), 0.9, 1.2, 0.8, Color("4f8c84"), 16)
    for k in range(5):
        var a: float = float(k) * TAU / 5.0
        Kit.cyl(self, "Crown point", cp + Vector3(cos(a) * 1.1, 5.2, sin(a) * 1.1), 0.16, 0.05, 0.9, Color("c9a54a"), 6)
    # vlaggen
    var flags := [Color("ae1c28"), Color("1f4fa0"), Color("e5c22a")]
    for k in range(3):
        var fp := Vector3(20.0 + float(k) * 2.5, 0, 6.0)
        Kit.cyl(self, "Flagpole", fp + Vector3(0, 5.0, 0), 0.07, 0.05, 10.0, Color("eeeeee"), 6)
        Kit.box(self, "Flag", fp + Vector3(0, 9.0, 0.75), Vector3(0.03, 1.2, 1.5), flags[k])
