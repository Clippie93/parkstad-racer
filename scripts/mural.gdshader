shader_type spatial;
render_mode cull_disabled;
// Muurschilderingen op blinde zijgevels (Heerlen staat bekend om zijn street-art). Eigen
// ontwerpen, geen namaak van bestaande werken. Elke muur krijgt via INSTANCE_CUSTOM een
// eigen startgetal (r) en de verhouding breedte/hoogte (g); daaruit volgen stijl, kleuren
// en vormen. Alles wordt hier getekend: geen afbeeldingen nodig.
//   0 = geometrische vlakken en cirkels, 1 = kleurrijke golven, 2 = heuvellandschap met zon
//   en vogels, 3 = mijnwerker met helmlamp voor een stralenkrans, 4 = grote bloem

varying vec4 cd;

const vec3 PAL[20] = vec3[](
	vec3(0.96, 0.78, 0.18), vec3(0.90, 0.30, 0.22), vec3(0.16, 0.42, 0.72), vec3(0.12, 0.62, 0.55), vec3(0.98, 0.94, 0.86),
	vec3(0.98, 0.42, 0.55), vec3(0.42, 0.24, 0.62), vec3(0.18, 0.75, 0.85), vec3(0.99, 0.80, 0.35), vec3(0.12, 0.12, 0.20),
	vec3(0.95, 0.55, 0.15), vec3(0.20, 0.55, 0.30), vec3(0.85, 0.90, 0.30), vec3(0.10, 0.25, 0.45), vec3(0.96, 0.92, 0.80),
	vec3(0.30, 0.80, 0.70), vec3(0.95, 0.35, 0.40), vec3(0.98, 0.85, 0.55), vec3(0.25, 0.30, 0.70), vec3(0.15, 0.15, 0.18)
);

void vertex() {
	cd = INSTANCE_CUSTOM;
}

float rnd(float n) {
	return fract(sin(n * 12.9898 + 4.1414) * 43758.5453);
}

vec3 pc(int pal, int i) {
	return PAL[pal * 5 + (i % 5)];
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

vec3 geometric(vec2 p, float A, float s, int pal) {
	vec3 col = mix(pc(pal, 4), pc(pal, 2), p.y);
	for (int i = 0; i < 6; i++) {
		float fi = float(i) + s * 31.0;
		vec2 c = vec2(rnd(fi) * A, rnd(fi + 7.3));
		float r = 0.12 + rnd(fi + 3.1) * 0.3;
		if (length(p - c) < r) {
			col = pc(pal, i);
		}
	}
	vec2 dir = normalize(vec2(1.0, rnd(s * 9.0) * 2.0 - 1.0));
	float band = dot(p - vec2(A * 0.5, 0.5), dir);
	if (abs(band) < 0.06) {
		col = pc(pal, 3);
	}
	if (abs(band - 0.2) < 0.025) {
		col = pc(pal, 0);
	}
	return col;
}

vec3 waves(vec2 p, float A, float s, int pal) {
	float f = p.y + 0.07 * sin(p.x * (5.0 + rnd(s) * 6.0) + s * 20.0) + 0.04 * sin(p.x * 13.0 + s * 5.0);
	int k = int(floor(f * 7.0));
	return pc(pal, k + int(s * 10.0));
}

vec3 landscape(vec2 p, float A, float s, int pal) {
	vec3 col = mix(pc(pal, 0), pc(pal, 1), smoothstep(0.3, 1.0, p.y));
	vec2 sun = vec2(A * (0.25 + rnd(s) * 0.5), 0.68);
	float d = length(p - sun);
	if (d < 0.16) {
		col = pc(pal, 4);
	} else if (d < 0.2) {
		col = mix(col, pc(pal, 4), 0.5);
	}
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float hy = 0.45 - fi * 0.13 + 0.07 * sin(p.x * (3.0 + fi * 2.0) + s * 10.0 + fi);
		if (p.y < hy) {
			col = pc(pal, 2 + i);
		}
	}
	// vogels: kleine v'tjes in de lucht
	for (int i = 0; i < 4; i++) {
		float fi = float(i) + s * 17.0;
		vec2 b = vec2(rnd(fi) * A, 0.72 + rnd(fi + 1.0) * 0.22);
		float w = 0.035;
		float dd = min(seg(p, b - vec2(w, -w * 0.6), b), seg(p, b, b + vec2(w, w * 0.6)));
		if (dd < 0.006) {
			col = vec3(0.1);
		}
	}
	return col;
}

vec3 miner(vec2 p, float A, float s, int pal) {
	vec2 c = vec2(A * 0.5, 0.42);
	vec2 q = p - c;
	float ang = atan(q.y, q.x);
	vec3 col = mod(floor((ang + 3.1416) / 6.2832 * 18.0), 2.0) < 0.5 ? pc(pal, 0) : pc(pal, 1);
	vec3 ink = vec3(0.08, 0.08, 0.1);
	// schouders, hoofd, helm met rand, lamp met lichtbundel
	if (length(vec2(q.x / 1.9, q.y + 0.5)) < 0.3) {
		col = ink;
	}
	if (length(vec2(q.x, (q.y - 0.02) * 1.15)) < 0.16) {
		col = ink;
	}
	if (q.y > 0.1 && length(vec2(q.x, q.y - 0.1)) < 0.18) {
		col = pc(pal, 2);
	}
	if (abs(q.y - 0.1) < 0.02 && abs(q.x) < 0.24) {
		col = pc(pal, 2);
	}
	float lamp = length(q - vec2(0.0, 0.2));
	if (lamp < 0.045) {
		col = vec3(1.0, 0.97, 0.75);
	} else if (lamp < 0.07) {
		col = mix(col, vec3(1.0, 0.95, 0.7), 0.6);
	}
	return col;
}

vec3 flower(vec2 p, float A, float s, int pal) {
	vec3 col = mod(floor((p.x + p.y) * 9.0), 2.0) < 0.5 ? pc(pal, 4) : pc(pal, 3);
	vec2 c = vec2(A * (0.3 + rnd(s) * 0.4), 0.5);
	vec2 q = p - c;
	float r = length(q);
	float a = atan(q.y, q.x);
	float n = 5.0 + floor(rnd(s * 3.0) * 4.0);
	float petal = 0.24 + 0.12 * cos(a * n);
	if (r < petal) {
		col = pc(pal, 1);
	}
	if (r < petal * 0.7) {
		col = pc(pal, 0);
	}
	if (r < 0.07) {
		col = pc(pal, 2);
	}
	// steel
	if (abs(q.x + 0.02 * sin(q.y * 12.0)) < 0.02 && q.y < -0.1) {
		col = pc(pal, 3) * 0.6;
	}
	return col;
}

void fragment() {
	float s = cd.r;
	float A = max(cd.g * 4.0, 0.3);
	vec2 p = vec2(UV.x * A, 1.0 - UV.y);
	int style = int(floor(rnd(s * 101.0) * 5.0));
	int pal = int(floor(rnd(s * 57.0) * 4.0));
	vec3 col;
	if (style == 0) {
		col = geometric(p, A, s, pal);
	} else if (style == 1) {
		col = waves(p, A, s, pal);
	} else if (style == 2) {
		col = landscape(p, A, s, pal);
	} else if (style == 3) {
		col = miner(p, A, s, pal);
	} else {
		col = flower(p, A, s, pal);
	}
	ALBEDO = col;
	ROUGHNESS = 0.9;
}
