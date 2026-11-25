extends RefCounted
# Route van een level: een hoekpuntenlijn waarvan elke hoek wordt afgerond met een
# eigen straal. Alles in een level (weg, checkpoints, verkeer, bebouwing) leest
# posities af via de afstand s (meters vanaf het begin van de route).

var points := PackedVector3Array()   # dichte middenlijn
var dist := PackedFloat32Array()      # cumulatieve afstand per punt
var length := 0.0

var closed := false

# closed = true: de laatste hoek sluit weer aan op de eerste (een rondje). Leg de eerste hoek
# dan midden op een recht stuk (zonder bocht), daar ligt de start/finish.
func _init(corners: Array, radii: Array, is_closed := false) -> void:
    closed = is_closed
    var n: int = corners.size()
    var raw := PackedVector3Array()
    raw.append(corners[0])
    var last: int = n if closed else n - 1
    for i in range(1, last):
        var prev: Vector3 = corners[i - 1]
        var v: Vector3 = corners[i % n]
        var nxt: Vector3 = corners[(i + 1) % n]
        var d1: Vector3 = (v - prev).normalized()
        var d2: Vector3 = (nxt - v).normalized()
        var turn: float = acos(clampf(d1.dot(d2), -1.0, 1.0))
        var r: float = float(radii[i - 1]) if i - 1 < radii.size() else 40.0
        var t: float = r * tan(turn * 0.5)
        t = minf(t, minf(v.distance_to(prev), v.distance_to(nxt)) * 0.45)
        var a: Vector3 = v - d1 * t
        var b: Vector3 = v + d2 * t
        var steps: int = maxi(2, int(t / 3.0))
        for k in range(steps + 1):
            var u: float = float(k) / float(steps)
            # kwadratische bezier a-v-b: raakt de rechte stukken netjes
            raw.append(a.lerp(v, u).lerp(v.lerp(b, u), u))
    raw.append(corners[0] if closed else corners[n - 1])
    points = raw
    dist.resize(points.size())
    dist[0] = 0.0
    for i in range(1, points.size()):
        dist[i] = dist[i - 1] + points[i].distance_to(points[i - 1])
    length = dist[dist.size() - 1]

func _index(s: float) -> int:
    var lo := 0
    var hi: int = dist.size() - 1
    while hi - lo > 1:
        var mid: int = (lo + hi) / 2
        if dist[mid] <= s:
            lo = mid
        else:
            hi = mid
    return lo

func pos_at(s: float) -> Vector3:
    s = fposmod(s, length) if closed else clampf(s, 0.0, length)
    var i: int = _index(s)
    var seg: float = dist[i + 1] - dist[i]
    var u: float = 0.0 if seg <= 0.0 else (s - dist[i]) / seg
    return points[i].lerp(points[i + 1], u)

func dir_at(s: float) -> Vector3:
    var a: Vector3 = pos_at(s - 1.5 if closed else maxf(0.0, s - 1.5))
    var b: Vector3 = pos_at(s + 1.5 if closed else minf(length, s + 1.5))
    var d: Vector3 = b - a
    d.y = 0.0
    return d.normalized() if d.length() > 0.001 else Vector3.FORWARD

func right_at(s: float) -> Vector3:
    return dir_at(s).cross(Vector3.UP).normalized()

func basis_at(s: float) -> Basis:
    # -Z van de basis wijst in rijrichting (zoals de auto)
    return Basis.looking_at(dir_at(s), Vector3.UP)

func closest_s(p: Vector3) -> float:
    var best := INF
    var best_s := 0.0
    for i in range(points.size() - 1):
        var c: Vector3 = Geometry3D.get_closest_point_to_segment(p, points[i], points[i + 1])
        var d: float = c.distance_to(p)
        if d < best:
            best = d
            best_s = dist[i] + c.distance_to(points[i])
    return best_s

func distance_to(p: Vector3) -> float:
    var best := INF
    for i in range(points.size() - 1):
        var c: Vector3 = Geometry3D.get_closest_point_to_segment(p, points[i], points[i + 1])
        best = minf(best, c.distance_to(p))
    return best

# Snel dichtstbijzijnde punt rond een vorige index (elke frame aanroepbaar).
# Geeft [afstand, index, s] terug; zoekt alles door als het lokale venster niets oplevert.
func nearest(p: Vector3, hint: int, window := 40) -> Array:
    var n: int = points.size() - 1
    var best := INF
    var best_i := hint
    for k in range(-window, window + 1):
        var i: int = hint + k
        if closed:
            i = posmod(i, n)
        elif i < 0 or i >= n:
            continue
        var c: Vector3 = Geometry3D.get_closest_point_to_segment(p, points[i], points[i + 1])
        var d: float = Vector2(c.x - p.x, c.z - p.z).length()
        if d < best:
            best = d
            best_i = i
    if best > 40.0:
        for i in range(n):
            var c: Vector3 = Geometry3D.get_closest_point_to_segment(p, points[i], points[i + 1])
            var d: float = Vector2(c.x - p.x, c.z - p.z).length()
            if d < best:
                best = d
                best_i = i
    var q: Vector3 = Geometry3D.get_closest_point_to_segment(p, points[best_i], points[best_i + 1])
    return [best, best_i, dist[best_i] + q.distance_to(points[best_i])]

# Kromming (1/m) rond afstand s: richtingsverandering over een stukje van 2*h meter.
func curvature(s: float, h := 6.0) -> float:
    var a: Vector3 = dir_at(s - h)
    var b: Vector3 = dir_at(s + h)
    return acos(clampf(a.dot(b), -1.0, 1.0)) / (2.0 * h)
