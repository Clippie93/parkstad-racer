shader_type spatial;
// Bandenrook: een zacht rond wit wolkje dat naar de camera kijkt. Alleen de doorzichtigheid
// komt van het deeltjessysteem (vervagen over de levensduur); de kleur blijft wit. (Met de
// deeltjeskleur als albedo kregen de randen in de compatibiliteitsrenderer een zwarte gloed.)
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.92, 0.92, 0.92);

void vertex() {
	// naar de camera draaien, met de schaal van het deeltje (zoals BILLBOARD_PARTICLES)
	mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float soft = 1.0 - smoothstep(0.2, 1.0, r);
	ALBEDO = tint;
	ALPHA = soft * COLOR.a;
}
