#ifdef END

float EndSpacePow2(float x) { return x * x; }
float EndSpacePow3(float x) { return x * x * x; }
float EndSpacePow4(float x) { float x2 = x * x; return x2 * x2; }
float EndSpacePow8(float x) { float x4 = EndSpacePow4(x); return x4 * x4; }
float EndSpacePow16(float x) { float x8 = EndSpacePow8(x); return x8 * x8; }
float EndSpacePow20(float x) { return EndSpacePow16(x) * EndSpacePow4(x); }
float EndSpacePow24(float x) { float x8 = EndSpacePow8(x); return x8 * x8 * x8; }
float EndSpacePow32(float x) { float x16 = EndSpacePow16(x); return x16 * x16; }

vec2 EndSpaceRotate2D(vec2 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

vec3 EndSpaceToWorld(vec3 viewPos) {
    return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
}

vec3 endLightColSqrtSolas = vec3(205.0, 188.0, 142.0) / 255.0 * 1.02;
vec3 endLightColSolas = endLightColSqrtSolas * endLightColSqrtSolas;
vec3 endNebulaColFirstSqrtSolas = vec3(NEBULA_END_FIRST_R, NEBULA_END_FIRST_G, NEBULA_END_FIRST_B) / 255.0 * NEBULA_END_FIRST_I;
vec3 endNebulaColFirstSolas = endNebulaColFirstSqrtSolas * endNebulaColFirstSqrtSolas;
vec3 endNebulaColSecondSqrtSolas = vec3(NEBULA_END_SECOND_R, NEBULA_END_SECOND_G, NEBULA_END_SECOND_B) / 255.0 * NEBULA_END_SECOND_I;
vec3 endNebulaColSecondSolas = endNebulaColSecondSqrtSolas * endNebulaColSecondSqrtSolas;

void EndSpaceSampleNebulaNoise(vec2 coord, inout float colorMixer, inout float noise) {
    colorMixer = texture2D(noisetex, coord * 0.25).r;
    noise = texture2D(noisetex, coord * 0.50).r;
    noise = noise * colorMixer;
    noise = noise * texture2D(noisetex, coord * 0.125).r;
    noise = noise * (2.0 + noise * 20.0);
}

float EndSpaceSpiralWarp(vec2 coord) {
    float whirl = -15.0;
    float arms = 15.0;

    vec2 p = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.1, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = EndSpacePow8(1.0 - p.y) * 24.0;
    float spiral = sin((p.x + sqrt(max(p.y, 0.0)) * whirl) * arms) + center - p.y;

    return clamp(spiral * 0.025, 0.0, 1.0);
}

float EndSpaceDiskShape(vec2 coord) {
    float whirl = -5.0;
    float arms = 5.0;

    vec2 p = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.01, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = EndSpacePow4(1.0 - p.y);
    float spiral = sin((p.x + sqrt(max(p.y, 0.0)) * whirl) * arms) + center - p.y;

    return min(spiral * 1.75, 1.5);
}

void EndSpaceDiskNoise(vec2 rayXZ, float attenuation, inout float noise) {
    vec2 uv = rayXZ * 0.00025;

    float worleyNoise = (1.0 - texture2D(noisetex, uv).g) * 0.5 + 0.25;
    float perlinNoise = texture2D(noisetex, uv).r;
    float noiseBase = mix(perlinNoise, worleyNoise, 0.5);

    float detailZ = floor(attenuation * END_DISK_THICKNESS) * 0.05;
    float noiseDetailA = texture2D(noisetex, uv + vec2(detailZ)).b;
    float noiseDetailB = texture2D(noisetex, uv + vec2(detailZ + 0.05)).b;
    float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * END_DISK_THICKNESS));

    float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 5.0);
    noiseCoverage = noiseCoverage * noiseCoverage * 5.0;

    noise = mix(noiseBase, noiseDetail, 0.025 * float(noiseBase > 0.0)) * 22.0;
    noise = max(noise - END_DISK_AMOUNT - 1.0 + EndSpaceDiskShape(uv), 0.0);
    noise = noise / sqrt(noise * noise + 0.25);
}

vec4 DrawEndDiskSolas(vec3 viewPos, float dither) {
    vec3 nWorldPos = normalize(EndSpaceToWorld(viewPos) - cameraPosition);
    nWorldPos.y = nWorldPos.y + nWorldPos.x * END_ANGLE;
    #ifdef END_TIME_TILT
    nWorldPos.y = nWorldPos.y + nWorldPos.x * min(0.025 * frameTimeCounter, 1.0);
    #endif
    #ifdef END_67
    if (frameCounter < 500) nWorldPos.y = nWorldPos.y + nWorldPos.x * 0.5 * sin(frameTimeCounter * 8.0);
    #endif

    float cloudBottom = END_DISK_HEIGHT;
    float cloudTop = END_DISK_HEIGHT + END_DISK_THICKNESS * 10.0;

    float ny = nWorldPos.y;
    if (abs(ny) < 0.0005) ny = ny < 0.0 ? -0.0005 : 0.0005;

    float lowerPlane = (cloudBottom - cameraPosition.y) / ny;
    float upperPlane = (cloudTop - cameraPosition.y) / ny;
    float minDist = max(min(lowerPlane, upperPlane), 0.0);
    float maxDist = max(lowerPlane, upperPlane);

    if (maxDist <= 0.0) return vec4(0.0);

    float planeDifference = maxDist - minDist;
    float rayLength = END_DISK_THICKNESS * 6.0;
    rayLength = rayLength / (nWorldPos.y * nWorldPos.y * 6.0 + 1.0);

    int sampleCount = int(min(planeDifference / max(rayLength, 0.001), 64.0) + dither);
    if (sampleCount > 32) sampleCount = 32;
    if (sampleCount <= 0) return vec4(0.0);

    vec3 samplePos = cameraPosition + nWorldPos * (minDist + rayLength * dither);
    vec3 sampleStep = nWorldPos * rayLength;

    vec3 worldLightVec = normalize(EndSpaceToWorld(normalize(sunVec * 10000.0)) - cameraPosition);
    worldLightVec.xz = worldLightVec.xz * 32.0;

    float cloud = 0.0;
    float cloudAlpha = 0.0;
    float cloudLighting = 0.0;

    float voS = clamp(dot(normalize(viewPos), sunVec), 0.0, 1.0);
    float halfVoLSqrt = voS * 0.5 + 0.5;
    float scattering = EndSpacePow8(halfVoLSqrt);

    for (int i = 0; i < 32; i++) {
        if (i >= sampleCount) break;
        if (cloudAlpha > 0.99) break;

        float attenuation = smoothstep(cloudBottom, cloudTop, samplePos.y);

        float noise = 0.0;
        float lightingNoise = 0.0;

        EndSpaceDiskNoise(samplePos.xz, attenuation, noise);
        EndSpaceDiskNoise(samplePos.xz + worldLightVec.xz, attenuation + worldLightVec.y * 0.15, lightingNoise);

        float sampleLighting = 0.05 + clamp(noise - lightingNoise * (0.9 - scattering * 0.15), 0.0, 0.95) * (1.5 + scattering);
        sampleLighting = sampleLighting * (1.0 - noise * 0.75);
        sampleLighting = clamp(sampleLighting, 0.0, 1.0);

        cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
        cloud = mix(cloud, 1.0, noise);
        cloudAlpha = mix(cloudAlpha, 1.0, noise * EndSpacePow8(smoothstep(4000.0, 8.0, length((samplePos - cameraPosition).xz) * 0.1)));

        samplePos = samplePos + sampleStep;
    }

    vec3 cloudColor = vec3(1.00, 0.96, 0.82) * endLightColSolas;
    cloudColor = cloudColor * cloudLighting * 0.35 * END_DISK_BRIGHTNESS;

    return vec4(cloudColor, cloudAlpha * END_DISK_OPACITY);
}

void DrawEndNebulaBlackHole(inout vec3 color, vec3 worldPos, float VoU, float VoS) {
    vec3 blackHoleColor = vec3(5.6, 3.2, 0.7) * endLightColSolas;

    vec3 wSunVec = normalize(mat3(gbufferModelViewInverse) * sunVec);
    vec2 sunCoord = wSunVec.xz / (wSunVec.y + length(wSunVec));

    vec2 blackHoleCoord = worldPos.xz / (length(worldPos) + worldPos.y) - sunCoord;
    blackHoleCoord.y = blackHoleCoord.y - blackHoleCoord.x * END_ANGLE;
    #ifdef END_67
    if (frameCounter < 500) blackHoleCoord.y = blackHoleCoord.y - blackHoleCoord.x * 0.5 * sin(frameTimeCounter * 8.0);
    #endif
    #ifdef END_TIME_TILT
    blackHoleCoord.y = blackHoleCoord.y - blackHoleCoord.x * min(0.025 * frameTimeCounter, 1.0);
    #endif

    float warping = 0.0;
    #ifdef END_SOLAS_BLACK_HOLE
    warping = EndSpaceSpiralWarp(blackHoleCoord);
    #endif

    // Use a sign-safe denominator to avoid a hard seam near the world Y horizon.
    float nebulaDenom = max(length(worldPos) + worldPos.y * 0.35, 0.05);
    vec2 nebulaCoord = worldPos.xz / nebulaDenom;
    nebulaCoord = nebulaCoord + warping * END_NEBULA_WARP_STRENGTH;
    nebulaCoord = nebulaCoord + cameraPosition.xz * 0.0001;

    float nebulaNoise = 0.0;
    float nebulaMixer = 0.0;
    EndSpaceSampleNebulaNoise(nebulaCoord, nebulaMixer, nebulaNoise);
    nebulaMixer = EndSpacePow3(nebulaMixer) * 4.5;

    float nebulaVisibility = 1.0;
    #ifdef END_SOLAS_BLACK_HOLE
    nebulaVisibility = (0.175 - EndSpacePow3(VoS) * 0.175) + EndSpacePow20(VoS) * 0.425;
    #endif

    vec3 nebula = mix(endNebulaColFirstSolas, endNebulaColSecondSolas, clamp(nebulaMixer, 0.0, 1.0));
    nebula = nebula * nebulaNoise * nebulaNoise * nebulaVisibility;

    #ifdef END_SOLAS_BLACK_HOLE
    nebula = nebula * (1.0 + blackHoleColor * EndSpacePow24(VoS) * 0.25);
    nebula = nebula * max(1.0 - EndSpacePow32(VoS), 0.0);
    #endif

    nebula = nebula * length(nebula) * END_NEBULA_BRIGHTNESS;
    color = color + nebula;

    #ifdef END_SOLAS_BLACK_HOLE
    float bhDist = length(blackHoleCoord);
    float holeCore = 1.0 - smoothstep(0.015, 0.085, bhDist);
    float hole = pow(max(holeCore, 0.0), 1.6 / max(END_BLACK_HOLE_SIZE, 0.15));
    float gravityLens = hole;

    float photonRingShape = 1.0 - abs(bhDist - 0.105) / 0.03;
    float photonRing = EndSpacePow3(clamp(photonRingShape, 0.0, 1.0));
    photonRing = photonRing * (1.0 - hole) * 8.0;
    photonRing = max(photonRing, 0.0);

    hole = clamp(hole * 1.35, 0.0, 1.0);

    float torus = 1.0 - clamp(length(blackHoleCoord), 0.0, 1.0);
    torus = pow(pow(torus * torus, 1.0 + (180.0 - abs(sunPathRotation)) / 8.0 * (0.5 + 0.5 * sqrt(abs(VoU)))), sqrt(END_BLACK_HOLE_SIZE) * 1.5);

    vec2 noiseCoord = blackHoleCoord - hole * hole;
    noiseCoord = EndSpaceRotate2D(noiseCoord, 3.14159265358979);
    noiseCoord = noiseCoord - vec2(frameTimeCounter * 0.025, 0.0);
    noiseCoord.y = noiseCoord.y * 0.33;
    noiseCoord = noiseCoord * 2.0;

    float blackHoleNoise = texture2D(noisetex, noiseCoord).r;

    color = color + mix(blackHoleColor * 0.85, blackHoleColor * 1.15, hole * 0.5) * hole * hole * 2.0 * blackHoleNoise;
    color = color * (1.0 - hole);
    vec3 photonRingColor = vec3(1.0, 0.62, 0.22);
    color = color + photonRingColor * photonRing * END_BLACK_HOLE_BRIGHTNESS;
    color = color + mix(blackHoleColor, vec3(2.0 + torus * 6.0), pow(torus, 0.33)) * torus * EndSpacePow2(1.0 - torus * 0.65) * blackHoleNoise * 3.0 * END_BLACK_HOLE_BRIGHTNESS;
    float centerDist = length(blackHoleCoord);
    float coreMask = 1.0 - smoothstep(0.05, 0.16, centerDist);
    color *= 1.0 - coreMask * 0.985;
    #endif
}

#endif
