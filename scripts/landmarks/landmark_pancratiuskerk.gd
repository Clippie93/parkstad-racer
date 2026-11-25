extends Node3D
# Sint-Pancratiuskerk, Heerlen. Naar Street View-foto's:
#  - romaanse westtoren van mergel/kalksteen in vier versprongen geledingen met schuine
#    waterlijsten; onderaan breuksteen met donkere stenen, bovenin lichtere hardsteen;
#    galmgaten in paren, spitse leien naaldspits met uurwerken en kruis
#  - ronde traptoren met kegeldak in de hoek tussen toren en zijbeuk, onderaan rode baksteen
#  - rode deur met stenen boog in de zijgevel van de toren (+X)
#  - driebeukig schip: lage zijbeuken met lessenaarsdak en consoles, lichtbeuk met
#    rondboogfries, leien zadeldak met kleine dakkapellen
#  - vieringtoren met piramidedak en dakkapellen, dwarspand met drie hoge vensters en een
#    portaal met zuiltjes en rode deur, koor met halfronde apsis
#  - beeld van P.J. Savelberg op zwarte sokkel bij de traptoren
# Maten zijn geschat. Lokale ruimte: oorsprong = midden van de torenvoorgevel,
# +Z naar het plein, de kerk loopt in -Z richting het koor.
const Kit = preload("res://scripts/build_kit.gd")

const NAVE_Z0 := -11.0
const NAVE_Z1 := -38.0
const NAVE_HW := 4.5      # halve breedte middenschip
const NAVE_EAVE := 15.0
const AISLE_HW := 9.5
const AISLE_EAVE := 7.5
const CROSS_Z := -42.5
const CHOIR_Z1 := -55.0

var rubble: StandardMaterial3D
var ashlar: StandardMaterial3D
var rubble_2s: StandardMaterial3D
var trim := Color("e2d8bf")
var slate := Color("41464c")
var glass := Color("2f3438")
var red_door := Color("a3281f")

func _ready() -> void:
    name = "Pancratiuskerk"
    rubble = Kit.tex_mat_tiles("res://assets/kerk_rubble.png", Vector2(4.0, 4.0))
    ashlar = Kit.tex_mat_tiles("res://assets/kerk_ashlar.png", Vector2(4.0, 4.0))
    # topgevel-prisma's hebben naar binnen gewonden eindvlakken: tweezijdig tekenen
    rubble_2s = rubble.duplicate()
    rubble_2s.cull_mode = BaseMaterial3D.CULL_DISABLED
    _tower()
    _stair_turret(Vector3(5.6, 0.0, -12.2))
    _nave()
    _crossing_and_transept()
    _choir()
    _statue(Vector3(12.0, 0.0, -12.5))
    _hedge_fence()
    Kit.box(self, "Door steps", Vector3(7.0, 0.12, -5.0), Vector3(3.0, 0.24, 7.0), Color("b9b4a8"))

# ---------------------------------------------------------------- hulpvormen

func _arch(parent: Node3D, n: String, x: float, yb: float, w: float, h: float, z: float, thick: float, color: Color) -> void:
    var r: float = w * 0.5
    var straight: float = maxf(h - r, 0.1)
    Kit.box(parent, n, Vector3(x, yb + straight * 0.5, z), Vector3(w, straight, thick), color)
    Kit.cyl(parent, n + " top", Vector3(x, yb + straight, z), r, r, thick, color, 16, "z")

func _window(f: Node3D, x: float, yb: float, w: float, h: float) -> void:
    # rondboogvenster: lichte stenen omlijsting, donker glas in lood, dorpel
    _arch(f, "Window surround", x, yb - 0.1, w + 0.4, h + 0.25, 0.05, 0.1, trim)
    _arch(f, "Window glass", x, yb, w, h, 0.14, 0.06, glass)
    Kit.box(f, "Window sill", Vector3(x, yb - 0.15, 0.18), Vector3(w + 0.6, 0.2, 0.36), trim)

func _face(pos: Vector3, yaw: float) -> Node3D:
    return Kit.face(self, pos, yaw)

func _pitched_roof(center: Vector3, width: float, length: float, rise: float, along_x: bool, gable_mat: Material) -> void:
    # leien zadeldak uit twee platen; daaronder een stenen prisma voor de topgevels
    var holder := Node3D.new()
    holder.name = "Roof"
    holder.position = center
    if along_x:
        holder.rotation_degrees.y = 90.0
    add_child(holder)
    var hw: float = width * 0.5
    var ang: float = atan2(rise, hw)
    var s: float = sqrt(hw * hw + rise * rise)
    for side in [-1.0, 1.0]:
        var slab := Kit.box(holder, "Slate slab", Vector3(side * hw * 0.5, rise * 0.5 + 0.12, 0), Vector3(s + 0.5, 0.25, length + 0.6), slate)
        slab.rotation.z = -side * ang
    var gable := Kit.gable(holder, "Gable wall", Vector3.ZERO, width - 0.2, length, rise - 0.1, slate)
    gable.material_override = gable_mat

# ---------------------------------------------------------------- toren

func _tower() -> void:
    var tz := -5.5
    # (breedte, onder, boven, materiaal)
    var stages: Array = [[11.0, 0.0, 11.0, rubble], [10.4, 11.0, 22.0, rubble], [10.0, 22.0, 29.0, ashlar], [9.6, 29.0, 35.6, ashlar]]
    Kit.box(self, "Tower plinth", Vector3(0, 0.45, tz), Vector3(11.8, 0.9, 11.8), Color("b7ad94"), true, rubble)
    for st in stages:
        var w: float = st[0]
        var y0: float = st[1]
        var y1: float = st[2]
        Kit.box(self, "Tower stage", Vector3(0, (y0 + y1) * 0.5, tz), Vector3(w, y1 - y0, w), trim, true, st[3])
        if y0 > 0.0:
            # schuine waterlijst bij de versprongen geleding
            Kit.box(self, "Tower ledge", Vector3(0, y0 - 0.1, tz), Vector3(w + 0.9, 0.4, w + 0.9), trim)
    Kit.box(self, "Tower cornice", Vector3(0, 35.85, tz), Vector3(10.4, 0.5, 10.4), trim)
    # spits: uitlopende voet en een slanke leien piramide
    var flare := Kit.cyl(self, "Spire flare", Vector3(0, 36.7, tz), 5.5 * sqrt(2.0), 4.6 * sqrt(2.0), 1.2, slate, 4)
    flare.rotation_degrees.y = 45.0
    Kit.pyramid(self, "Spire", Vector3(0, 37.3, tz), 4.6, 18.5, slate)
    Kit.box(self, "Cross post", Vector3(0, 57.0, tz), Vector3(0.16, 2.6, 0.16), Color("c9a64a"))
    Kit.box(self, "Cross bar", Vector3(0, 57.5, tz), Vector3(1.1, 0.14, 0.14), Color("c9a64a"))
    Kit.cyl(self, "Cross ball", Vector3(0, 55.9, tz), 0.3, 0.3, 0.5, Color("c9a64a"), 10)
    for entry in [[Vector3(0, 0, 1), 0.0], [Vector3(1, 0, 0), 90.0], [Vector3(0, 0, -1), 180.0], [Vector3(-1, 0, 0), -90.0]]:
        var dir: Vector3 = entry[0]
        var yaw: float = entry[1]
        # uurwerk in een kapelletje op elk vlak van de spits
        var clock := _face(Vector3(0, 0, tz) + dir * 3.9, yaw)
        Kit.box(clock, "Clock dormer", Vector3(0, 39.6, -0.2), Vector3(2.0, 2.4, 1.2), slate)
        Kit.cyl(clock, "Clock dial", Vector3(0, 39.6, 0.43), 0.85, 0.85, 0.06, Color("2b2b2b"), 24, "z")
        Kit.cyl(clock, "Clock ring", Vector3(0, 39.6, 0.47), 0.8, 0.8, 0.04, Color("b8913c"), 24, "z")
        Kit.cyl(clock, "Clock face", Vector3(0, 39.6, 0.5), 0.62, 0.62, 0.04, Color("2b2b2b"), 24, "z")
        var hand := Kit.box(clock, "Clock hand", Vector3(0.18, 39.75, 0.55), Vector3(0.08, 0.6, 0.03), Color("d6b356"))
        hand.rotation_degrees.z = -35.0
        Kit.box(clock, "Clock hand", Vector3(-0.2, 39.6, 0.55), Vector3(0.45, 0.08, 0.03), Color("d6b356"))
        # galmgaten: twee rondbogen per vlak
        var bel := _face(Vector3(0, 0, tz) + dir * 4.8, yaw)
        for x in [-1.25, 1.25]:
            _arch(bel, "Belfry surround", x, 30.6, 1.5, 3.6, 0.05, 0.1, trim)
            _arch(bel, "Belfry opening", x, 30.8, 1.05, 3.1, 0.14, 0.06, Color("1e1d1b"))
            for k in range(3):
                Kit.box(bel, "Louvre", Vector3(x, 31.4 + float(k) * 0.6, 0.2), Vector3(1.0, 0.08, 0.05), Color("5a554c"))
        # schietgleuven
        var mid := _face(Vector3(0, 0, tz) + dir * 5.0, yaw)
        Kit.box(mid, "Slit", Vector3(0, 25.2, 0.03), Vector3(0.25, 1.4, 0.08), Color("1e1d1b"))
        var low := _face(Vector3(0, 0, tz) + dir * 5.2, yaw)
        Kit.box(low, "Slit", Vector3(1.8, 18.5, 0.03), Vector3(0.25, 1.6, 0.08), Color("1e1d1b"))
    # zijgevel (+X): rondboogvenster en de rode deur
    var side2 := _face(Vector3(5.2, 0, tz), 90.0)
    _window(side2, 1.2, 13.4, 1.6, 3.4)
    var side1 := _face(Vector3(5.5, 0, tz), 90.0)
    _arch(side1, "Portal arch", -0.5, 0.0, 3.6, 5.4, 0.08, 0.16, trim)
    _arch(side1, "Portal recess", -0.5, 0.0, 2.8, 4.8, 0.2, 0.06, Color("6b6150"))
    Kit.box(side1, "Red door", Vector3(-0.5, 1.9, 0.26), Vector3(2.2, 3.8, 0.06), red_door)
    Kit.box(side1, "Door split", Vector3(-0.5, 1.9, 0.3), Vector3(0.06, 3.8, 0.03), Color("5e1712"))
    Kit.box(side1, "Lantern", Vector3(-3.3, 4.6, 0.2), Vector3(0.35, 0.55, 0.35), Color("2a2a28"))

func _stair_turret(c: Vector3) -> void:
    var h := 22.0
    var r := 1.8
    Kit.cyl(self, "Stair turret", c + Vector3(0, h * 0.5, 0), r, r, h, trim, 10, "y", true, ashlar)
    Kit.cyl(self, "Turret brick base", c + Vector3(0, 1.3, 0), r + 0.06, r + 0.06, 2.6, Color("8c4a3a"), 10)
    Kit.cyl(self, "Turret plinth", c + Vector3(0, 0.35, 0), r + 0.12, r + 0.12, 0.7, Color("b7ad94"), 10)
    for y in [8.2, 15.0]:
        Kit.cyl(self, "Turret band", c + Vector3(0, y, 0), r + 0.15, r + 0.15, 0.35, trim, 10)
    Kit.cyl(self, "Turret cornice", c + Vector3(0, h, 0), r + 0.25, r + 0.25, 0.3, trim, 10)
    Kit.cyl(self, "Turret roof", c + Vector3(0, h + 2.4, 0), r + 0.35, 0.05, 4.6, slate, 10)
    var f := _face(c + Vector3(r, 0, 0), 90.0)
    for y in [11.0, 17.5]:
        Kit.box(f, "Turret slit", Vector3(0, y, 0.05), Vector3(0.25, 1.2, 0.1), Color("1e1d1b"))

# ---------------------------------------------------------------- schip

func _nave() -> void:
    var nlen: float = NAVE_Z0 - NAVE_Z1 + 0.4
    var zc: float = (NAVE_Z0 + NAVE_Z1 - 0.4) * 0.5
    Kit.box(self, "Nave", Vector3(0, NAVE_EAVE * 0.5, zc), Vector3(NAVE_HW * 2.0, NAVE_EAVE, nlen), trim, true, rubble)
    # dak eindigt 0,5 m achter de toren (geen gedeeld vlak met de torengevel)
    _pitched_roof(Vector3(0, NAVE_EAVE, zc - 0.25), NAVE_HW * 2.0 + 1.0, nlen - 0.5, 6.5, false, rubble_2s)
    var aisle_w: float = AISLE_HW - NAVE_HW + 0.2
    var lean_dx: float = AISLE_HW + 0.4 - NAVE_HW
    var lean_dy: float = 2.8
    var bays: Array = [-14.5, -19.5, -24.5, -29.5, -34.5]
    for s in [-1.0, 1.0]:
        Kit.box(self, "Aisle", Vector3(s * (AISLE_HW - aisle_w * 0.5), AISLE_EAVE * 0.5, zc), Vector3(aisle_w, AISLE_EAVE, nlen), trim, true, rubble)
        # lessenaarsdak tegen de lichtbeuk
        var slope: float = sqrt(lean_dx * lean_dx + lean_dy * lean_dy)
        var lean := Kit.box(self, "Aisle roof", Vector3(s * (NAVE_HW + lean_dx * 0.5), AISLE_EAVE + lean_dy * 0.5 + 0.12, zc),
            Vector3(slope + 0.2, 0.25, nlen + 0.4), slate)
        lean.rotation.z = -s * atan2(lean_dy, lean_dx)
        var yaw: float = 90.0 if s > 0.0 else -90.0
        var outer := _face(Vector3(s * AISLE_HW, 0, 0), yaw)
        var clere := _face(Vector3(s * NAVE_HW, 0, 0), yaw)
        var sgn: float = -s    # lokale x = -s * wereld-z
        Kit.box(outer, "Aisle plinth", Vector3(sgn * zc, 0.4, 0.08), Vector3(nlen, 0.8, 0.16), Color("b7ad94"))
        for z in bays:
            var lx: float = sgn * z
            _window(outer, lx, 2.6, 1.3, 2.9)
            _window(clere, lx, 11.2, 1.1, 2.3)
        # consoles onder de goot van de zijbeuk en rondboogfries onder de goot van het schip
        var n := int(nlen)
        for k in range(n):
            var lz: float = sgn * (NAVE_Z0 - 0.5 - float(k) * nlen / float(n))
            Kit.box(outer, "Corbel", Vector3(lz, AISLE_EAVE - 0.25, 0.15), Vector3(0.25, 0.3, 0.3), trim)
            _arch(clere, "Frieze arch", lz, NAVE_EAVE - 1.3, 0.55, 0.8, 0.05, 0.1, Color("b1a684"))
        Kit.box(clere, "Nave cornice", Vector3(sgn * zc, NAVE_EAVE - 0.2, 0.15), Vector3(nlen, 0.4, 0.3), trim)
        Kit.box(outer, "Aisle cornice", Vector3(sgn * zc, AISLE_EAVE - 0.05, 0.2), Vector3(nlen, 0.15, 0.4), trim)
        # kleine dakkapellen op het schip
        for z in [-18.0, -30.0]:
            var d := Node3D.new()
            d.name = "Dormer"
            d.position = Vector3(s * 2.6, NAVE_EAVE + 2.8, z)
            d.rotation_degrees.y = yaw
            add_child(d)
            Kit.box(d, "Dormer body", Vector3(0, 0, 0), Vector3(1.1, 1.2, 1.4), slate)
            Kit.box(d, "Dormer shutter", Vector3(0, -0.05, 0.72), Vector3(0.5, 0.7, 0.05), Color("b03a2e"))
            Kit.box(d, "Dormer frame", Vector3(0, -0.05, 0.71), Vector3(0.75, 0.9, 0.04), Color("eeeeea"))
            Kit.gable(d, "Dormer roof", Vector3(0, 0.6, 0), 1.4, 1.6, 0.6, slate)

# ---------------------------------------------------------------- viering, dwarspand

func _crossing_and_transept() -> void:
    var depth := 9.0
    var arm := 13.0
    Kit.box(self, "Transept", Vector3(0, NAVE_EAVE * 0.5, CROSS_Z), Vector3(arm * 2.0, NAVE_EAVE, depth), trim, true, rubble)
    _pitched_roof(Vector3(0, NAVE_EAVE, CROSS_Z), depth + 1.0, arm * 2.0, 6.5, true, rubble_2s)
    for s in [-1.0, 1.0]:
        var f := _face(Vector3(s * arm, 0, CROSS_Z), 90.0 if s > 0.0 else -90.0)
        Kit.box(f, "Transept plinth", Vector3(0, 0.4, 0.08), Vector3(depth, 0.8, 0.16), Color("b7ad94"))
        # drie hoge vensters in nissen
        for x in [-2.3, 0.0, 2.3]:
            _arch(f, "Window niche", x, 7.6, 2.0, 6.4, 0.05, 0.1, Color("b1a684"))
            _arch(f, "Window glass", x, 7.9, 1.4, 5.6, 0.14, 0.06, glass)
        Kit.box(f, "Gable sill", Vector3(0, 7.5, 0.2), Vector3(7.4, 0.25, 0.4), trim)
        Kit.box(f, "Gable vent", Vector3(0, 18.6, 0.06), Vector3(0.6, 1.0, 0.12), Color("1e1d1b"))
        # portaal met zadeldakje, zuiltjes en rode deur
        Kit.box(f, "Porch", Vector3(0, 3.0, 1.0), Vector3(5.2, 6.0, 2.0), trim, true, rubble)
        var porch_roof := Node3D.new()
        porch_roof.position = Vector3(0, 6.0, 1.0)
        f.add_child(porch_roof)
        for side in [-1.0, 1.0]:
            var slab := Kit.box(porch_roof, "Porch roof", Vector3(side * 1.4, 1.0, 0), Vector3(3.6, 0.25, 2.4), Color("b1a684"))
            slab.rotation.z = -side * atan2(2.0, 2.6)
        var pg := Kit.gable(porch_roof, "Porch gable", Vector3.ZERO, 5.0, 1.9, 1.95, trim)
        pg.material_override = rubble_2s
        var pf := Node3D.new()
        pf.position = Vector3(0, 0, 2.0)
        f.add_child(pf)
        _arch(pf, "Portal arch", 0, 0.0, 3.6, 5.0, 0.05, 0.1, Color("b1a684"))
        _arch(pf, "Portal tympanum", 0, 0.0, 2.6, 4.3, 0.14, 0.06, Color("d9cfb4"))
        Kit.box(pf, "Red door", Vector3(0, 1.7, 0.2), Vector3(2.3, 3.4, 0.06), red_door)
        Kit.box(pf, "Door split", Vector3(0, 1.7, 0.24), Vector3(0.06, 3.4, 0.03), Color("5e1712"))
        for x in [-1.75, -1.35, 1.35, 1.75]:
            Kit.cyl(pf, "Column", Vector3(x, 1.9, 0.25), 0.16, 0.16, 3.0, Color("d9cfb4"), 10)
            Kit.box(pf, "Capital", Vector3(x, 3.5, 0.25), Vector3(0.45, 0.25, 0.45), Color("d9cfb4"))
        Kit.box(pf, "Porch step", Vector3(0, 0.1, 0.8), Vector3(4.0, 0.2, 1.4), Color("b9b4a8"))
    # vieringtoren
    var ch := 27.0
    Kit.box(self, "Crossing tower", Vector3(0, (NAVE_EAVE + ch) * 0.5, CROSS_Z), Vector3(8.4, ch - NAVE_EAVE, 8.4), trim, true, ashlar)
    Kit.box(self, "Crossing cornice", Vector3(0, ch + 0.15, CROSS_Z), Vector3(8.9, 0.3, 8.9), trim)
    Kit.pyramid(self, "Crossing roof", Vector3(0, ch + 0.3, CROSS_Z), 4.7, 6.8, slate)
    Kit.box(self, "Crossing cross", Vector3(0, ch + 7.9, CROSS_Z), Vector3(0.14, 1.8, 0.14), Color("c9a64a"))
    Kit.box(self, "Crossing cross bar", Vector3(0, ch + 8.3, CROSS_Z), Vector3(0.8, 0.12, 0.12), Color("c9a64a"))
    for entry in [[Vector3(0, 0, 1), 0.0], [Vector3(1, 0, 0), 90.0], [Vector3(0, 0, -1), 180.0], [Vector3(-1, 0, 0), -90.0]]:
        var dir: Vector3 = entry[0]
        var f := _face(Vector3(0, 0, CROSS_Z) + dir * 4.2, entry[1])
        for x in [-1.0, 1.0]:
            _window(f, x, 22.0, 0.8, 2.4)
        Kit.cyl(f, "Oculus ring", Vector3(0, 25.6, 0.05), 0.55, 0.55, 0.1, trim, 16, "z")
        Kit.cyl(f, "Oculus", Vector3(0, 25.6, 0.12), 0.38, 0.38, 0.06, glass, 16, "z")
        for k in range(8):
            _arch(f, "Frieze arch", -3.5 + float(k), ch - 1.0, 0.55, 0.75, 0.05, 0.1, Color("b1a684"))
        # dakkapel op elk vlak van het piramidedak
        var d := _face(Vector3(0, 0, CROSS_Z) + dir * 2.9, entry[1])
        Kit.box(d, "Roof dormer", Vector3(0, ch + 2.6, 0), Vector3(1.0, 1.3, 1.3), slate)
        Kit.box(d, "Dormer window", Vector3(0, ch + 2.5, 0.67), Vector3(0.5, 0.7, 0.04), Color("eeeeea"))
        Kit.gable(d, "Dormer cap", Vector3(0, ch + 3.25, 0), 1.3, 1.5, 0.55, slate)

func _choir() -> void:
    var z0: float = CROSS_Z - 4.5
    var clen: float = z0 - CHOIR_Z1
    var zc: float = (z0 + CHOIR_Z1) * 0.5
    var eave := 13.0
    Kit.box(self, "Choir", Vector3(0, eave * 0.5, zc + 0.2), Vector3(9.0, eave, clen + 0.4), trim, true, rubble)
    _pitched_roof(Vector3(0, eave, zc + 0.2), 10.0, clen + 0.4, 5.5, false, rubble_2s)
    Kit.cyl(self, "Apse", Vector3(0, eave * 0.5, CHOIR_Z1), 4.5, 4.5, eave, trim, 16, "y", true, rubble)
    Kit.cyl(self, "Apse roof", Vector3(0, eave + 2.0, CHOIR_Z1), 5.0, 0.3, 4.0, slate, 16)
    for a in [-50.0, 0.0, 50.0]:
        var r: float = deg_to_rad(a)
        var f := _face(Vector3(sin(r) * 4.5, 0, CHOIR_Z1 - cos(r) * 4.5), 180.0 - a)
        _window(f, 0.0, 4.0, 1.2, 4.0)
    for s in [-1.0, 1.0]:
        var f := _face(Vector3(s * 4.5, 0, zc), 90.0 if s > 0.0 else -90.0)
        _window(f, 0.0, 4.0, 1.3, 4.2)

# ---------------------------------------------------------------- omgeving

func _statue(p: Vector3) -> void:
    var bronze := Color("5d6a5a")
    Kit.box(self, "Statue base", p + Vector3(0, 0.15, 0), Vector3(1.9, 0.3, 1.9), Color("8f8c86"))
    Kit.box(self, "Statue pedestal", p + Vector3(0, 1.0, 0), Vector3(1.5, 1.4, 1.5), Color("1f2022"), true)
    Kit.label(self, "P.J. SAVELBERG", p + Vector3(0, 1.1, 0.77), 0.006, Color("d8d4c8"), 48)
    var top: Vector3 = p + Vector3(0, 1.7, 0)
    Kit.cyl(self, "Priest robe", top + Vector3(0.15, 0.9, -0.1), 0.42, 0.24, 1.8, bronze, 10)
    Kit.cyl(self, "Priest head", top + Vector3(0.15, 2.0, -0.1), 0.15, 0.15, 0.3, bronze, 10)
    Kit.cyl(self, "Priest cap", top + Vector3(0.15, 2.2, -0.1), 0.16, 0.14, 0.12, bronze, 10)
    for x in [-0.45, -0.1]:
        Kit.cyl(self, "Child", top + Vector3(x, 0.45, 0.35), 0.17, 0.13, 0.9, bronze, 8)
        Kit.cyl(self, "Child head", top + Vector3(x, 1.0, 0.35), 0.11, 0.11, 0.2, bronze, 8)

func _hedge_fence() -> void:
    var zc: float = (NAVE_Z0 + NAVE_Z1) * 0.5 - 1.0
    var hlen: float = NAVE_Z0 - NAVE_Z1 - 1.0
    for s in [-1.0]:
        var x: float = s * (AISLE_HW + 1.0)
        Kit.box(self, "Hedge", Vector3(x, 0.6, zc), Vector3(0.9, 1.2, hlen), Color("2f5a33"))
        var fx: float = x + s * 0.6
        Kit.box(self, "Fence rail", Vector3(fx, 1.5, zc), Vector3(0.06, 0.06, hlen), Color("1c1d1e"))
        Kit.box(self, "Fence rail", Vector3(fx, 0.3, zc), Vector3(0.06, 0.06, hlen), Color("1c1d1e"))
        for k in range(int(hlen / 2.5) + 1):
            Kit.box(self, "Fence post", Vector3(fx, 0.85, NAVE_Z0 - 1.5 - float(k) * 2.5), Vector3(0.08, 1.7, 0.08), Color("1c1d1e"))
