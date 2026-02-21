// Cauliflower / Bloom Watercolor Wash Background
// Backruns where wet paint creeps into drying areas.
// Fractal-edged shapes with dark pigment concentrated at the boundary.

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

    // --- Cauliflower blooms: backruns with fractal edges ---
    // WASH_HUE is replaced by randomize-shader.sh, default 0.6
    float hue = WASH_HUE;
    vec3 pigment = 0.3 + 0.2 * cos(6.28318 * (hue + vec3(0.0, 0.33, 0.67)));

    // Base wash that was drying when the backruns happened
    vec2 p = fragCoord * 0.001 + vec2(hue * 100.0, hue * 73.0);
    float baseWash = fbm(p * 1.5 + vec2(2.0, 4.0));
    vec3 washColor = mix(iBackgroundColor, pigment, smoothstep(0.25, 0.55, baseWash) * 0.5);

    // Bloom 1: heavily domain-warped noise creates fractal cauliflower edges
    vec2 q1 = vec2(fbm(p * 3.0 + vec2(1.7, 9.2)), fbm(p * 3.0 + vec2(8.3, 2.8)));
    vec2 r1 = vec2(fbm(p * 3.0 + 4.0 * q1 + vec2(1.0, 6.0)),
                   fbm(p * 3.0 + 4.0 * q1 + vec2(5.0, 3.0)));
    float bloom1 = fbm(p * 3.0 + 4.0 * r1);

    // Bloom 2: second backrun at a different position
    vec2 q2 = vec2(fbm(p * 2.5 + vec2(5.0, 3.0)), fbm(p * 2.5 + vec2(2.0, 8.0)));
    float bloom2 = fbm(p * 2.5 + 3.5 * q2 + vec2(10.0));

    // Sharp edges with pigment concentration — the cauliflower signature
    float inside1 = smoothstep(0.46, 0.52, bloom1);
    float edgeLine1 = smoothstep(0.44, 0.48, bloom1) * (1.0 - smoothstep(0.50, 0.56, bloom1));

    float inside2 = smoothstep(0.48, 0.54, bloom2);
    float edgeLine2 = smoothstep(0.46, 0.50, bloom2) * (1.0 - smoothstep(0.52, 0.58, bloom2));

    // Inside the bloom: lighter (water pushed pigment outward to the edges)
    washColor = mix(washColor, washColor * 1.3, inside1 * 0.3);
    washColor = mix(washColor, washColor * 1.25, inside2 * 0.25);

    // Edge lines: darker concentrated pigment where the backrun stopped
    vec3 darkPigment = pigment * 0.5;
    washColor = mix(washColor, darkPigment, edgeLine1 * 0.5);
    washColor = mix(washColor, darkPigment, edgeLine2 * 0.4);

    washColor = clamp(washColor, 0.0, 1.0);

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
