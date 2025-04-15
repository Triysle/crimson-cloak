shader_type canvas_item;

uniform vec4 original_color : source_color = vec4(0.294, 0.078, 0.157, 1.0);
uniform vec4 replacement_color : source_color = vec4(0.5, 0.0, 0.0, 1.0);
uniform float tolerance : hint_range(0.0, 0.1) = 0.03;
uniform float alpha_override : hint_range(0.0, 1.0) = 1.0;
uniform float hurt_effect : hint_range(0.0, 1.0) = 0.0; // Hurt effect intensity
uniform float pulse_time : hint_range(0.0, 6.28) = 0.0; // Time parameter for pulsing
uniform float outline_width : hint_range(0.0, 5.0) = 1.0; // Width of the outline in pixels

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);
    
    // Calculate color difference for cloak coloring
    float color_distance = length(current_pixel.rgb - original_color.rgb);
    
    // Calculate final color first (without hurt effect)
    vec3 final_color;
    if (color_distance < tolerance) {
        // Blend between original and replacement color based on distance
        float blend_factor = 1.0 - (color_distance / tolerance);
        final_color = mix(current_pixel.rgb, replacement_color.rgb, blend_factor);
    } else {
        final_color = current_pixel.rgb;
    }
    
    // Only apply outline effect if hurt_effect is active and pixel has some opacity
    if (hurt_effect > 0.0 && current_pixel.a > 0.1) {
        // Sample the texture at nearby points to detect edges
        float outline = 0.0;
        
        // Calculate pixel size
        vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
        
        // Check surrounding pixels
        for (float i = -outline_width; i <= outline_width; i += outline_width) {
            for (float j = -outline_width; j <= outline_width; j += outline_width) {
                // Skip the center pixel
                if (i == 0.0 && j == 0.0) continue;
                
                // Get the color of the offset pixel
                vec4 offset_pixel = texture(TEXTURE, UV + vec2(i, j) * pixel_size);
                
                // If the offset pixel is transparent and our pixel isn't, we're at an edge
                if (offset_pixel.a < 0.1 && current_pixel.a > 0.1) {
                    outline = 1.0;
                    break;
                }
            }
            if (outline > 0.0) break;
        }
        
        // If we're at an edge, apply the pulsing outline
        if (outline > 0.0) {
            // Create a pulse between red and white using sine function
            vec3 outline_color = mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), 
                                 (sin(pulse_time * 10.0) + 1.0) * 0.5);
            
            // Apply the outline
            final_color = mix(final_color, outline_color, hurt_effect);
        }
    }
    
    COLOR = vec4(final_color, current_pixel.a * alpha_override);
}