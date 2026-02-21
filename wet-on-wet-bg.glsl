// Wet-on-Wet Watercolor Wash Background
// Colors bleed and bloom into each other with soft, diffused edges.
// Like dropping pigment onto wet paper — no hard boundaries.

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

    // --- Wet-on-wet: soft blooming color regions ---
    // WASH_HUE is replaced by randomize-shader.sh, default 0.6
    float hue = WASH_HUE;

    // Three pigment drops on wet paper, each bleeding outward
    vec3 pigment1 = 0.35 + 0.2 * cos(6.28318 * (hue + vec3(0.0, 0.33, 0.67)));
    vec3 pigment2 = 0.35 + 0.2 * cos(6.28318 * (hue + 0.15 + vec3(0.0, 0.33, 0.67)));
    vec3 pigment3 = 0.35 + 0.2 * cos(6.28318 * (hue + 0.4 + vec3(0.0, 0.33, 0.67)));

    vec2 p = fragCoord * 0.001;

    // Domain-warped noise for soft, flowing bleed shapes
    vec2 q1 = vec2(fbm(p * 1.2), fbm(p * 1.2 + vec2(5.2, 1.3)));
    float bloom1 = fbm(p * 1.2 + 3.0 * q1);

    vec2 q2 = vec2(fbm(p * 1.0 + vec2(8.0, 3.0)), fbm(p * 1.0 + vec2(2.0, 7.0)));
    float bloom2 = fbm(p * 1.0 + 3.0 * q2);

    float bloom3 = fbm(p * 1.4 + vec2(12.0, 5.0));

    // Soft masks — no hard edges, everything blends
    float m1 = smoothstep(0.3, 0.7, bloom1);
    float m2 = smoothstep(0.35, 0.7, bloom2);
    float m3 = smoothstep(0.3, 0.65, bloom3);

    // Layer the pigments like wet paint bleeding together
    vec3 washColor = mix(pigment1, pigment2, m1);
    washColor = mix(washColor, pigment3, m2 * 0.6);

    // Water blooms — lighter spots where water pushed pigment away
    float waterBloom = fbm(p * 2.0 + vec2(20.0));
    washColor = mix(washColor, washColor * 1.4, smoothstep(0.55, 0.75, waterBloom) * 0.25);
    washColor = clamp(washColor, 0.0, 1.0);

    // Soft pigment concentration variation
    float concentration = fbm(p * 1.8 + vec2(15.0, 8.0));
    washColor = mix(washColor * 0.7, washColor, smoothstep(0.3, 0.7, concentration));

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
            result = mix(iBackgroundColor, washColor, 0.6);
            alpha = 0.9;
        } else {
            alpha = 0.0;
        }
    }

    fragColor = vec4(clamp(result, 0.0, 1.0), alpha);
}
