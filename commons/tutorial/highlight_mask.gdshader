shader_type canvas_item;
render_mode unshaded;

// Maximo de agujeros soportados
const int MAX_HOLES = 32;

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 0.65);

// Array de holes en coordenadas de pantalla normalizadas (0..1): x, y, w, h
uniform vec4 holes[MAX_HOLES];
uniform int hole_count = 0;

void fragment() {
	vec2 uv = SCREEN_UV;
	bool in_hole = false;
	for (int i = 0; i < MAX_HOLES; i++) {
		if (i >= hole_count) {
			break;
		}
		vec4 h = holes[i];
		if (uv.x >= h.x && uv.x <= h.x + h.z &&
			uv.y >= h.y && uv.y <= h.y + h.w) {
			in_hole = true;
			break;
		}
	}
	vec4 col = color;
	if (in_hole) {
		col.a = 0.0;
	}
	COLOR = col;
}
