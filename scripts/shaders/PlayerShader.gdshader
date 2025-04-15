shader_type canvas_item;

uniform vec4 original_color : source_color = vec4(0.294, 0.078, 0.157, 1.0);
uniform vec4 replacement_color : source_color = vec4(0.5, 0.0, 0.0, 1.0);
uniform float tolerance : hint_range(0.0, 0.1) = 0.03;
uniform float alpha_override : hint_range(0.0, 1.0) = 1.0;
uniform float hurt_effect : hint_range(0.0, 1.0) = 0.0; // Hurt effect intensity
uniform float pulse_time : hint_range(0.0, 6.28) = 0.0; // Time parameter for pulsing

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);
    
    // Calculate color difference
    float color_distance = length(current_pixel.rgb - original_color.rgb);
    
    // Apply hurt effect
    vec3 final_color;
    if (hurt_effect > 0.0) {
        // Create a pulse between red and white using sine function
        vec4 pulse_color = mix(vec4(1.0, 0.0, 0.0, 0.5), vec4(1.0, 1.0, 1.0, 0.5), 
                              (sin(pulse_time * 10.0) + 1.0) * 0.5);
        
        // Apply the pulse effect
        final_color = mix(current_pixel.rgb, pulse_color.rgb, hurt_effect);
    } else {
        // Normal cloak color behavior
        if (color_distance < tolerance) {
            // Blend between original and replacement color based on distance
            float blend_factor = 1.0 - (color_distance / tolerance);
            final_color = mix(current_pixel.rgb, replacement_color.rgb, blend_factor);
        } else {
            final_color = current_pixel.rgb;
        }
    }
    
    COLOR = vec4(final_color, current_pixel.a * alpha_override);
}