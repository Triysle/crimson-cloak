shader_type canvas_item;

uniform vec4 pulse_color : source_color = vec4(0.8, 0.0, 0.0, 1.0);
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.0;
uniform float darkness_threshold : hint_range(0.0, 0.5) = 0.2; // Threshold for dark pixels

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);

    // Calculate darkness (closer to 0 means darker)
    float darkness = (texture_color.r + texture_color.g + texture_color.b) / 3.0;

    // Apply pulse to darker areas, but not transparent pixels
    if (darkness < darkness_threshold && texture_color.a > 0.9) {
        // Mix the original color with the pulse color based on pulse amount
        COLOR = mix(texture_color, pulse_color, pulse_amount);
    } else {
        COLOR = texture_color;
    }
}