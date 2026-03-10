shader_type canvas_item;

uniform vec4 slow_color = vec4(0.0, 0.5, 1.0, 0.5);  // Blueish tint
uniform float distortion_strength = 0.1;   // Amount of distortion effect
uniform float time_slow_factor = 0.5;      // Time slow effect intensity

void fragment() {
    // Get the UV coordinates of the current pixel
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;

    // Distort the UV coordinates to simulate a time slow effect (glitchy look)
    uv.x += sin(uv.y * 10.0 + TIME * distortion_strength) * distortion_strength;
    uv.y += cos(uv.x * 10.0 + TIME * distortion_strength) * distortion_strength;

    // Sample the screen at the distorted coordinates
    vec4 color = texture(TEXTURE, uv);

    // Apply the blue-ish tint to the color
    color.rgb *= slow_color.rgb;
    color.a *= slow_color.a;

    // Modify the intensity of the effect based on the time slow factor
    color.rgb *= time_slow_factor;

    // Output the final color
    COLOR = color;
}