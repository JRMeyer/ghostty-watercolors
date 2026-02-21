// Abstract Watercolor Painting Background
// Looks like brushstrokes on textured paper, not smooth blobs.
// Strokes have direction, dry brush edges, and pigment bleeds.

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

// Directional noise — stretched along an angle to simulate brush direction
float brushNoise(vec2 p, float angle, float stretch) {
    float c = cos(angle), s = sin(angle);
    mat2 rot = mat2(c, -s, s, c);
    vec2 rp = rot * p;
    rp.x *= stretch;
    return fbm(rp);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 orig = texture(iChannel0, uv);

    float distToBg = distance(orig.rgb, iBackgroundColor);
    float isBg = 1.0 - smoothstep(0.0, 0.15, distToBg);

    if (isBg < 0.3) {
        fragColor = orig;
        return;
    }

    vec2 p = fragCoord / iResolution.y;

    // =============================================
    // BRUSHSTROKES — each at a different angle/position
    // Like an artist layering washes across the canvas
    // =============================================

    // Stroke 1: broad diagonal wash, upper area
    float stroke1 = brushNoise(p * 2.0, 0.3, 3.5);
    // Hard-ish edge to make it feel like a stroke boundary, not a blob
    float mask1 = smoothstep(0.38, 0.52, stroke1);

    // Stroke 2: opposite diagonal
    float stroke2 = brushNoise(p * 2.2 + vec2(3.0, 1.0), -0.4, 4.0);
    float mask2 = smoothstep(0.40, 0.55, stroke2);

    // Stroke 3: nearly horizontal, wide
    float stroke3 = brushNoise(p * 1.8 + vec2(7.0, 5.0), 0.1, 5.0);
    float mask3 = smoothstep(0.35, 0.50, stroke3);

    // Stroke 4: steeper angle
    float stroke4 = brushNoise(p * 2.5 + vec2(2.0, 8.0), 0.7, 3.0);
    float mask4 = smoothstep(0.42, 0.56, stroke4);

    // Stroke 5: crossing stroke
    float stroke5 = brushNoise(p * 1.5 + vec2(11.0, 3.0), -0.2, 4.5);
    float mask5 = smoothstep(0.36, 0.48, stroke5);

    // --- Stroke colors: muted watercolor pigments ---
    vec3 col1 = vec3(0.40, 0.18, 0.50);  // violet
    vec3 col2 = vec3(0.15, 0.35, 0.55);  // cerulean
    vec3 col3 = vec3(0.50, 0.22, 0.25);  // alizarin
    vec3 col4 = vec3(0.18, 0.45, 0.38);  // viridian
    vec3 col5 = vec3(0.48, 0.38, 0.18);  // yellow ochre

    // --- Dry brush texture per stroke ---
    // Bristle marks: stretched noise perpendicular to stroke direction
    float dry1 = vnoise(vec2(p.x * 1.0, p.y * 12.0));
    float dry2 = vnoise(vec2(p.x * 12.0, p.y * 1.5));
    float dry3 = vnoise(vec2(p.x * 1.2, p.y * 10.0));
    float dry4 = vnoise(vec2(p.x * 8.0, p.y * 2.0));
    float dry5 = vnoise(vec2(p.x * 1.5, p.y * 11.0));

    // Apply dry brush — thin out the mask at bristle gaps
    mask1 *= smoothstep(0.2, 0.4, dry1);
    mask2 *= smoothstep(0.22, 0.42, dry2);
    mask3 *= smoothstep(0.18, 0.38, dry3);
    mask4 *= smoothstep(0.25, 0.45, dry4);
    mask5 *= smoothstep(0.2, 0.4, dry5);

    // --- Pigment variation within each stroke ---
    float pv1 = fbm(p * 4.0 + vec2(1.0));
    float pv2 = fbm(p * 4.0 + vec2(5.0));

    // --- Layer strokes like a painting: back to front ---
    // Start with paper (terminal background)
    vec3 color = iBackgroundColor;

    // Each stroke blends on top with watercolor transparency
    // Watercolor is semi-transparent — you see layers underneath
    float opacity = 0.5; // watercolor wash opacity

    // Stroke 1
    vec3 s1col = mix(col1, col1 * 0.6, pv1 * 0.4);
    color = mix(color, s1col, mask1 * opacity);

    // Stroke 2
    vec3 s2col = mix(col2, col2 * 1.3, pv2 * 0.3);
    s2col = clamp(s2col, 0.0, 1.0);
    color = mix(color, s2col, mask2 * opacity);

    // Stroke 3
    vec3 s3col = mix(col3, col3 * 0.7, pv1 * 0.3);
    color = mix(color, s3col, mask3 * opacity * 0.8);

    // Stroke 4
    vec3 s4col = mix(col4, col4 * 1.2, pv2 * 0.35);
    s4col = clamp(s4col, 0.0, 1.0);
    color = mix(color, s4col, mask4 * opacity * 0.7);

    // Stroke 5
    vec3 s5col = mix(col5, col5 * 0.8, pv1 * 0.3);
    color = mix(color, s5col, mask5 * opacity * 0.6);

    // --- Where strokes overlap, pigment mixes and darkens slightly ---
    float overlapCount = mask1 + mask2 + mask3 + mask4 + mask5;
    float overlap = smoothstep(1.2, 2.5, overlapCount);
    color = mix(color, color * 0.65, overlap * 0.3);

    // --- Wet edges: darken at stroke boundaries ---
    // Detect sharp transitions in stroke masks
    float edgeDark = 0.0;
    edgeDark += smoothstep(0.02, 0.0, abs(mask1 - 0.5)) * 0.3;
    edgeDark += smoothstep(0.02, 0.0, abs(mask2 - 0.5)) * 0.3;
    edgeDark += smoothstep(0.02, 0.0, abs(mask3 - 0.5)) * 0.25;
    color = mix(color, color * 0.35, edgeDark);

    // --- Paper texture ---
    // Coarse cold-pressed paper grain
    float paper = vnoise(fragCoord * 0.08);
    color *= 0.88 + 0.24 * paper;
    // Fine tooth
    float tooth = hash21(fragCoord * 0.6);
    color += vec3((tooth - 0.5) * 0.025);

    // Smooth blend based on how background-like this pixel is
    vec3 result = mix(orig.rgb, color, isBg);

    fragColor = vec4(clamp(result, 0.0, 1.0), orig.a);
}
