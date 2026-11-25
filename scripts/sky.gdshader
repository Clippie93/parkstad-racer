shader_type sky;
// Zomerse lucht: blauw van de horizon naar boven, een zon met een zachte gloed en hier en
// daar een stapelwolkje. Goedkoop genoeg voor telefoons (een paar ruisopzoekingen per pixel,
// geen bewegende delen).

uniform vec3 zenith : source_color = vec3(0.22, 0.46, 0.82);
uniform vec3 horizon : source_color = vec3(0.70, 0.82, 0.94);
uniform vec3 sun_dir = vec3(0.0, 0.42, -0.9);
uniform float brightness = 1.0;
uniform float cloud_cover = 0.63;   // hoger = minder wolken

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void sky() {
	vec3 d = EYEDIR;
	float h = max(d.y, 0.0);
	vec3 col = mix(horizon, zenith, pow(h, 0.6));

	// zon: scherpe schijf met een warme gloed eromheen
	vec3 sd = normalize(sun_dir);
	float s = max(dot(d, sd), 0.0);
	col += vec3(1.0, 0.86, 0.62) * pow(s, 12.0) * 0.22;
	col += vec3(1.0, 0.93, 0.78) * pow(s, 180.0) * 0.5;
	float disc = smoothstep(0.99955, 0.9997, s);

	// wolkjes op een plat vlak boven de wereld, naar de horizon toe vervagend
	if (d.y > 0.01) {
		vec2 uv = d.xz / d.y * 0.9 + vec2(13.0, 7.0);
		float n = noise(uv) * 0.55 + noise(uv * 2.17) * 0.3 + noise(uv * 4.9) * 0.15;
		float c = smoothstep(cloud_cover, cloud_cover + 0.12, n);
		c *= smoothstep(0.02, 0.2, d.y);
		// onderkant iets grijzer, bovenkant wit; aan de zonkant lichter
		float top = smoothstep(cloud_cover, cloud_cover + 0.3, n);
		vec3 cc = mix(vec3(0.80, 0.84, 0.90), vec3(1.0, 1.0, 0.98), top) + vec3(0.08) * pow(s, 6.0);
		col = mix(col, cc, c * 0.92);
		disc *= 1.0 - c;
	}
	col = mix(col, vec3(1.0, 0.97, 0.88) * 1.6, disc);
	COLOR = col * brightness;
}
