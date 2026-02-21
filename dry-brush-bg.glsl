// Dry Brush Watercolor Wash Background
// Paint dragged across textured paper, catching on raised fibers.
// Scratchy, energetic streaks with bare paper showing through gaps.

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

    // --- Dry brush: paint catches on raised paper fibers ---
    // WASH_HUE is replaced by randomize-shader.sh, default 0.6
    float hue = WASH_HUE;
    vec3 pigment = 0.3 + 0.2 * cos(6.28318 * (hue + vec3(0.0, 0.33, 0.67)));

    // Paper texture stretched horizontally — brush dragged sideways
    float coarseFiber = vnoise(vec2(fragCoord.x * 0.015, fragCoord.y * 0.06));
    float medFiber = vnoise(vec2(fragCoord.x * 0.03, fragCoord.y * 0.12));
    float fineFiber = hash21(floor(fragCoord * vec2(0.2, 0.5)));

    // Combined paper surface: high = raised fiber (catches paint)
    float paperHeight = coarseFiber * 0.5 + medFiber * 0.3 + fineFiber * 0.2;

    // Paint only sticks to raised areas — aggressive threshold for lots of gaps
    float paintStick = smoothstep(0.28, 0.45, paperHeight);

    // Brush load varies across surface — some areas got more paint
    vec2 p = fragCoord * 0.001 + vec2(hue * 100.0, hue * 73.0);
    float brushLoad = fbm(p * 1.5 + vec2(3.0, 7.0));
    paintStick *= smoothstep(0.2, 0.5, brushLoad);

    // Horizontal streak emphasis — the directional signature of dry brush
    float streak = vnoise(vec2(fragCoord.x * 0.004, fragCoord.y * 0.04));
    paintStick *= smoothstep(0.15, 0.45, streak);

    // Where paint sticks: pigment. Where it skips: bare paper.
    vec3 washColor = mix(iBackgroundColor, pigment, paintStick * 0.75);

    // Slight color variation along brush direction
    float colorVar = vnoise(vec2(fragCoord.x * 0.003, 0.0));
    washColor = mix(washColor, washColor * (0.9 + 0.2 * colorVar), paintStick);

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
