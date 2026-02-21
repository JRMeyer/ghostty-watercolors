// Watercolor Background — abstract color washes behind terminal text.

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) { s += vnoise(p) * a; p *= 2.0; a *= 0.5; }
    return s;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 orig = texture(iChannel0, uv);

    // Check if this pixel is close to the background color
    float distToBg = distance(orig.rgb, iBackgroundColor);
    float isBg = 1.0 - smoothstep(0.0, 0.15, distToBg);

    // Not background — leave text and other elements alone
    if (isBg < 0.3) {
        fragColor = orig;
        return;
    }

    // --- Watercolor coordinate space ---
    vec2 p = fragCoord / iResolution.y;
    float t = iTime * 0.04;

    // --- Domain warping for organic shapes ---
    // First warp layer
    vec2 q = vec2(fbm(p * 1.5 + vec2(t, 0.0)),
                  fbm(p * 1.5 + vec2(0.0, t * 0.8)));
    // Second warp layer feeds from first
    vec2 r = vec2(fbm(p * 1.5 + 3.0 * q + vec2(1.7, 9.2)),
                  fbm(p * 1.5 + 3.0 * q + vec2(8.3, 2.8)));
    float warped = fbm(p * 1.5 + 3.0 * r);

    // Additional warped layers for color variation
    float w2 = fbm(p * 1.2 + 2.0 * vec2(fbm(p * 1.0 + vec2(t * 0.5, 3.0)),
                                          fbm(p * 1.0 + vec2(7.0, t * 0.3))));

    // --- Color palette ---
    vec3 c1 = vec3(0.45, 0.20, 0.55);  // purple
    vec3 c2 = vec3(0.15, 0.40, 0.60);  // blue
    vec3 c3 = vec3(0.55, 0.25, 0.30);  // rose
    vec3 c4 = vec3(0.20, 0.50, 0.45);  // teal
    vec3 c5 = vec3(0.50, 0.35, 0.20);  // amber

    // Blend colors based on warped noise
    vec3 color = mix(c1, c2, smoothstep(0.3, 0.7, warped));
    color = mix(color, c3, smoothstep(0.35, 0.65, w2) * 0.7);

    // Third noise for more color
    float w3 = fbm(p * 0.8 + vec2(t * 0.3, t * 0.2) + vec2(15.0));
    color = mix(color, c4, smoothstep(0.4, 0.7, w3) * 0.5);
    color = mix(color, c5, smoothstep(0.55, 0.75, warped * w3) * 0.4);

    // --- Wet edges: darken where washes meet ---
    float edge = abs(warped - 0.5);
    color = mix(color * 0.3, color, smoothstep(0.0, 0.1, edge));

    // --- Pigment pooling ---
    float pool = fbm(p * 2.5 + vec2(t * 0.1));
    color = mix(color, color * 0.5, smoothstep(0.55, 0.7, pool) * 0.3);

    // --- Light blooms ---
    color = mix(color, color * 1.6, smoothstep(0.65, 0.85, w2) * 0.2);
    color = clamp(color, 0.0, 1.0);

    // --- Paper grain ---
    float grain = vnoise(fragCoord * 0.1);
    color *= 0.9 + 0.2 * grain;
    color += vec3((hash21(fragCoord) - 0.5) * 0.02);

    // Blend: watercolor replaces background
    // Keep it dark enough to read text by mixing with background
    vec3 result = mix(iBackgroundColor, color, 0.55);

    // Smooth blend based on how "background-like" this pixel is
    result = mix(orig.rgb, result, isBg);

    fragColor = vec4(clamp(result, 0.0, 1.0), orig.a);
}
