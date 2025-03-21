shader_type canvas_item;

uniform vec2 resolution = vec2(1024, 1024);
uniform float star_count : hint_range(100, 5000) = 1000;
uniform float star_size : hint_range(0.1, 5.0) = 1.5;
uniform float star_brightness : hint_range(0.1, 2.0) = 1.0;

// Hash function for randomization
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = UV;
    vec3 color = vec3(0.0);
    
    // Generate stars
    for (float i = 0.0; i < star_count; i++) {
        vec2 seed = vec2(i * 0.01, i * 0.0073);
        vec2 star_pos = vec2(hash(seed), hash(seed + 0.5));
        
        // Vary star size and brightness
        float size = star_size * 0.005 * (0.5 + hash(seed + 0.2));
        float brightness = star_brightness * (0.5 + hash(seed + 0.3));
        
        // Calculate distance to star
        float dist = length(uv - star_pos);
        
        // Star shape with soft edges
        float star = smoothstep(size, 0.0, dist);
        
        // Star color variation (from blue-white to yellow-white)
        vec3 star_color = mix(
            vec3(0.7, 0.8, 1.0),  // Blue-white
            vec3(1.0, 0.9, 0.7),  // Yellow-white
            hash(seed + 0.1)
        );
        
        // Add star to the texture
        color += star * brightness * star_color;
    }
    
    // Output the final color
    COLOR = vec4(color, 1.0);
}
