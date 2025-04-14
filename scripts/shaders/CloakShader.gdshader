shader_type canvas_item;

uniform vec4 original_color : source_color = vec4(0.294, 0.078, 0.157, 1.0); // The exact dark purple color from your sample
uniform vec4 replacement_color : source_color = vec4(0.5, 0.0, 0.0, 1.0); // Deep crimson
uniform float tolerance : hint_range(0.0, 0.1) = 0.03; // Extremely tight tolerance
uniform float alpha_override : hint_range(0.0, 1.0) = 1.0; // New parameter for spawn fade

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);
    
    // Calculate color difference
    float color_distance = length(current_pixel.rgb - original_color.rgb);
    
    // If the pixel color is close to the original color, replace it
    if (color_distance < tolerance) {
        // Blend between original and replacement color based on distance
        float blend_factor = 1.0 - (color_distance / tolerance);
        vec3 new_color = mix(current_pixel.rgb, replacement_color.rgb, blend_factor);
        COLOR = vec4(new_color, current_pixel.a * alpha_override);
    } else {
        COLOR = vec4(current_pixel.rgb, current_pixel.a * alpha_override);
    }
}