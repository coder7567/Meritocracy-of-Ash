shader_type canvas_item;

uniform float rain_speed : hint_range(0.1, 5.0) = 1.6;
uniform float rain_length : hint_range(0.005, 0.08) = 0.03;
uniform float rain_width : hint_range(0.0005, 0.05) = 0.008;
uniform float slant : hint_range(-1.0, 1.0) = -0.22;
uniform float opacity : hint_range(0.0, 1.0) = 0.35;
uniform float wobble_amount : hint_range(0.0, 0.5) = 0.05;
uniform float wobble_speed : hint_range(0.0, 20.0) = 8.0;
uniform float wobble_variation : hint_range(0.0, 10.0) = 2.0;
uniform float splash_height : hint_range(0.0, 0.3) = 0.08;
uniform float splash_width : hint_range(0.001, 0.1) = 0.025;
uniform float splash_strength : hint_range(0.0, 2.0) = 0.5;

float rand(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec2 tilted_uv = UV;
	tilted_uv.x += (tilted_uv.y - 0.5) * slant; 
    float final_rain = 0.0;

    for (float i = 1.0; i <= 3.0; i++) {
        float scale = i * 15.0;
        float speed_mod = i * 0.5;

		vec2 st = tilted_uv * vec2(scale, scale * 0.1);
		

		float col = floor(st.x);
		float seed = rand(vec2(col, i * 123.45));

		float wobble = sin(TIME * wobble_speed + col * wobble_variation + seed * 6.2831) * (wobble_amount * i);
		float draw_x = st.x + wobble;

        // Rain Streak Logic
        float t = TIME * (rain_speed + seed) * speed_mod;
        float y_pos = fract(st.y - t - seed * 10.0);
        float line = smoothstep(rain_width * i, 0.0, abs(fract(draw_x) - 0.5));
        float streak = smoothstep(0.0, rain_length * i, y_pos) * smoothstep(rain_length * 2.0 * i, rain_length * i, y_pos);

        // Splash Logic
		float splash_t = fract(TIME * (rain_speed + seed) * 1.5 + seed); // Added seed so they don't all pop at once
		float splash_mask = smoothstep(1.0 - splash_height, 1.0, UV.y);
		float current_width = splash_width * i * splash_t;
		float splash_shape_x = smoothstep(current_width, 0.0, abs(fract(draw_x) - 0.5));

        // Improved vertical pop: fast up, slow fade
        float splash_shape_y = smoothstep(0.0, 0.1, splash_t) * (1.0 - splash_t);
		float splash = splash_shape_x * splash_shape_y * splash_mask * splash_strength * i;

        final_rain += (line * streak) * (0.5 * i) + splash;
    }

    COLOR = vec4(1.0, 1.0, 1.0, final_rain * opacity);
}
