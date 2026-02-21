// Glazing Watercolor Wash Background
// Multiple transparent color layers stacked on each other.
// Each layer is visible through the ones above, creating depth.

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

    float distToBg = distance(orig.rgb, iBackgroundColor);
    float isBg = 1.0 - smoothstep(0.0, 0.15, distToBg);

    if (isBg < 0.3) {
        fragColor = orig;
        return;
    }

    // --- Organic edge shape (pixel-based so it works at any window size) ---
    float dTop    = iResolution.y - fragCoord.y;
    float dBottom = fragCoord.y;
    float dLeft   = fragCoord.x;
    float dRight  = iResolution.x - fragCoord.x;

    float nTop    = fbm(vec2(fragCoord.x * 0.008, 0.0));
    float nBottom = fbm(vec2(fragCoord.x * 0.008, 100.0));
    float nLeft   = fbm(vec2(0.0, fragCoord.y * 0.008));
    float nRight  = fbm(vec2(100.0, fragCoord.y * 0.008));

    float edgePx = 32.0;
    float roughPx = 20.0;

    float paintTop    = step(edgePx + nTop * roughPx, dTop);
    float paintBottom = step(edgePx + nBottom * roughPx, dBottom);
    float paintLeft   = step(edgePx + nLeft * roughPx, dLeft);
    float paintRight  = step(edgePx + nRight * roughPx, dRight);

    float inPaint = paintTop * paintBottom * paintLeft * paintRight;

    // --- Glazing: transparent layers stacked with visible overlap ---
    // WASH_HUE is replaced by randomize-shader.sh, default 0.6
    float hue = WASH_HUE;

    // Three glaze colors — related hues at different saturations
    vec3 glaze1 = 0.3 + 0.2 * cos(6.28318 * (hue + vec3(0.0, 0.33, 0.67)));
    vec3 glaze2 = 0.3 + 0.2 * cos(6.28318 * (hue + 0.12 + vec3(0.0, 0.33, 0.67)));
    vec3 glaze3 = 0.3 + 0.2 * cos(6.28318 * (hue + 0.28 + vec3(0.0, 0.33, 0.67)));

    vec2 p = fragCoord * 0.001;

    // Each glaze layer has a distinct shape with crisp-ish edges
    // (dried before the next layer was applied)
    float layer1 = fbm(p * 1.5 + vec2(3.0, 1.0));
    float layer2 = fbm(p * 1.3 + vec2(8.0, 5.0));
    float layer3 = fbm(p * 1.1 + vec2(15.0, 9.0));

    // Sharper masks than wet-on-wet — each layer dried before the next
    float m1 = smoothstep(0.38, 0.48, layer1);
    float m2 = smoothstep(0.40, 0.50, layer2);
    float m3 = smoothstep(0.42, 0.52, layer3);

    // Stack glazes: each layer is semi-transparent over what's below
    // Start with paper
    vec3 washColor = iBackgroundColor;

    // Layer 1 (bottom, most visible)
    washColor = mix(washColor, glaze1, m1 * 0.4);

    // Layer 2 (middle)
    washColor = mix(washColor, glaze2, m2 * 0.35);

    // Layer 3 (top, most transparent)
    washColor = mix(washColor, glaze3, m3 * 0.3);

    // Where layers overlap, colors mix and deepen
    float overlap = m1 * m2 + m2 * m3 + m1 * m3;
    washColor = mix(washColor, washColor * 0.7, overlap * 0.2);

    // Very subtle pigment settling
    float settle = fbm(fragCoord * 0.008);
    washColor *= 0.95 + 0.1 * settle;

    // Minimal paper grain
    washColor *= 0.97 + 0.06 * vnoise(fragCoord * 0.04);

    // --- Composite ---
    vec3 result = orig.rgb;
    float alpha = orig.a;

    if (isBg > 0.5) {
        if (inPaint > 0.5) {
            result = washColor;
            alpha = 0.9;
        } else {
            alpha = 0.0;
        }
    }

    fragColor = vec4(clamp(result, 0.0, 1.0), alpha);
}
