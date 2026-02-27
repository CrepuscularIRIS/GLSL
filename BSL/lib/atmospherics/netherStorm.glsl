float Noise3D(vec3 p) {
    p.z = fract(p.z) * 128.0;
    float iz = floor(p.z);
    float fz = fract(p.z);
    vec2 a_off = vec2(23.0, 29.0) * iz / 128.0;
    vec2 b_off = vec2(23.0, 29.0) * (iz + 1.0) / 128.0;
    float a = texture2D(noisetex, p.xy + a_off).b;
    float b = texture2D(noisetex, p.xy + b_off).b;
    return mix(a, b, fz);
}

vec4 GetNetherStorm(vec3 color, vec3 viewPos, float dither) {
    if (isEyeInWater != 0) return vec4(0.0);
    vec4 netherStorm = vec4(1.0, 1.0, 1.0, 0.0);

    float maxDist = min(far, 128.0);
    vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos.xyz, 1.0)).xyz;
    vec3 nPlayerPos = normalize(playerPos);
    float lViewPos = length(playerPos);
    
    int sampleCount = int(maxDist / 8.0 + 0.001);

    vec3 traceAdd = nPlayerPos * maxDist / float(sampleCount);
    vec3 tracePos = cameraPosition;
    tracePos += traceAdd * dither;

    for (int i = 0; i < sampleCount; i++) {
        tracePos += traceAdd;

        vec3 tracedPlayerPos = tracePos - cameraPosition;
        float lTracePos = length(tracedPlayerPos);
        if (lTracePos > lViewPos) break;

        vec3 wind = vec3(frameTimeCounter * 0.002);

        vec3 tracePosM = tracePos * 0.001;
        tracePosM.y += tracePosM.x;
        tracePosM += Noise3D(tracePosM - wind) * 0.01;
        tracePosM = tracePosM * vec3(2.0, 0.5, 2.0);

        float traceAltitudeM = abs(tracePos.y - float(NETHER_STORM_LOWER_ALT));
        if (tracePos.y < float(NETHER_STORM_LOWER_ALT)) traceAltitudeM *= 10.0;
        traceAltitudeM = 1.0 - min(abs(traceAltitudeM) / float(NETHER_STORM_HEIGHT), 1.0);

        for (int h = 0; h < 4; h++) {
            float stormSample = Noise3D(tracePosM + wind);
            stormSample *= stormSample;
            stormSample *= traceAltitudeM;
            stormSample = stormSample * stormSample;
            stormSample = stormSample * stormSample;
            stormSample *= sqrt(max(1.0 - lTracePos / maxDist, 0.0));

            netherStorm.a += stormSample;
            tracePosM *= 2.0;
            wind *= -2.0;
        }
    }

    netherStorm.a = min(netherStorm.a * NETHER_STORM_I, 1.0);
    netherStorm.rgb *= netherCol.rgb * 3.0 * (1.0 - max(blindFactor, darknessFactor));

    return netherStorm;
}
