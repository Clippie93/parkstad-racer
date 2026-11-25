extends Control
class_name SpeedGauge

# Retro analog dial. Drawn with Godot's 2D primitives; no external images/fonts.
# De schaal loopt tot minstens 180 km/u. Stel hem af op de bereikbare topsnelheid.
var max_speed: float = 180.0
const START_ANGLE: float = 0.75 * PI
const END_ANGLE: float = 2.25 * PI
var displayed_speed: float = 0.0
var target_speed: float = 0.0

func set_speed(kmh: int) -> void:
    target_speed = maxf(float(kmh), 0.0)

# Schaal afstemmen op de topsnelheid van de auto (afgerond naar boven op 20 km/u).
func set_top(top_kmh: float) -> void:
    max_speed = maxf(180.0, ceilf((top_kmh + 4.0) / 20.0) * 20.0)
    queue_redraw()

func _process(delta: float) -> void:
    displayed_speed = move_toward(displayed_speed, target_speed, 260.0 * delta)
    queue_redraw()

func _draw() -> void:
    var c: Vector2 = size * 0.5
    var r: float = minf(size.x, size.y) * 0.45
    draw_circle(c, r + 9.0, Color("090d15", 0.9))
    draw_arc(c, r + 4, 0, TAU, 90, Color("8b9296"), 4.0, true)
    draw_circle(c, r, Color("1b222b"))
    draw_arc(c, r - 12, START_ANGLE, END_ANGLE, 64, Color("66707a"), 2.0, true)
    # labels om de 20 km/u; bij een grote schaal om de 40, anders wordt het te druk
    var label_step: int = 20 if max_speed <= 200.0 else 40
    var warn: float = max_speed * 0.78   # laatste stuk van de schaal in geel
    # streepjes en getallen schalen mee met de meter (op de telefoon is hij kleiner), en
    # zijn korter dan vroeger, zodat er meer ruimte is (jouw wens, 24-11)
    var k: float = clampf(r / 124.0, 0.6, 1.2)
    for v in range(0, int(max_speed) + 1, 10):
        var t: float = float(v) / max_speed
        var a: float = lerpf(START_ANGLE, END_ANGLE, t)
        var direction: Vector2 = Vector2(cos(a), sin(a))
        var major: bool = v % label_step == 0
        var out_r: float = r - 13.0 * k
        var in_r: float = r - (24.0 if major else 19.0) * k
        var col: Color = Color("efbd53") if float(v) >= warn else Color("e8e5d9")
        draw_line(c + direction * in_r, c + direction * out_r, col, (2.6 if major else 1.3) * maxf(k, 0.8), true)
        if major:
            var font: Font = ThemeDB.fallback_font
            var text: String = str(v)
            var fs: int = maxi(11, roundi(15.0 * k))
            var pos: Vector2 = c + direction * (r - 38.0 * k)
            var dimensions: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
            draw_string(font, pos + Vector2(-dimensions.x * 0.5, dimensions.y * 0.33), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
    # The center readout and rotating needle form a real gauge rather than a number-only HUD.
    var fraction: float = clampf(displayed_speed / max_speed, 0.0, 1.0)
    var needle_angle: float = lerpf(START_ANGLE, END_ANGLE, fraction)
    var needle_end: Vector2 = c + Vector2(cos(needle_angle), sin(needle_angle)) * (r - 40.0)
    draw_line(c, needle_end, Color("f44e42"), 4.0, true)
    draw_circle(c, 7.0, Color("f0e4cb"))
    var font: Font = ThemeDB.fallback_font
    # onderin de meter, in het vrije stuk waar de naald nooit komt: PARKSTAD, snelheid, km/u
    _centered(font, "PARKSTAD", c + Vector2(0, 30), 13, Color("f2cc69"))
    _centered(font, "%03d" % roundi(displayed_speed), c + Vector2(0, 60), 28, Color("f3eee1"))
    _centered(font, "km/u", c + Vector2(0, 78), 14, Color("d6b65d"))

func _centered(font: Font, text: String, pos: Vector2, size: int, color: Color) -> void:
    var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
    draw_string(font, pos - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
