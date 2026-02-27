vec3 DrawEnderBeams(float VdotU, vec3 playerPos, vec3 nViewPos) {
    int sampleCount = 8;
    float beamPow = 3.0;
    float beamPurpleReducer = 0.25;
    float beamOrangeIncreaser = 0.0;

    float VdotUM = 1.0 - VdotU * VdotU;
    float VdotUM2 = sqrt(VdotUM) + 0.15 * min(1.0, max(0.0, (1.0 - abs(VdotU)) * (1.0 - abs(VdotU)) * (1.0 - abs(VdotU)) * (1.0 - abs(VdotU))));

    vec4 endColSqrt = vec4(vec3(173.0, 130.0, 255.0) / 255.0, 1.0) * 0.9;
    vec3 endColorBeam = (endColSqrt.rgb * endColSqrt.rgb) * 1.1; // Tone down to prevent blindness
    vec3 endOrangeCol = vec3(1.0, 0.4, 0.0);

    vec3 beamPurple = normalize(endColorBeam * endColorBeam * endColorBeam) * (2.5 - beamPurpleReducer);
    beamPurple *= 0.7;
    vec3 beamOrange = endOrangeCol * (150.0 + 350.0 * beamOrangeIncreaser);

    vec4 beams = vec4(0.0);
    float gradientMix = 1.0;

    vec2 wind = vec2(frameTimeCounter * 0.00);

    for (int i = 0; i < sampleCount; i++) {
        // Restore BSL original scale and multiplier
        vec2 planeCoord = playerPos.xz + cameraPosition.xz;
        planeCoord *= (1.0 + float(i) * 6.0 / float(sampleCount)) * 0.0014;

        vec2 w1 = planeCoord * 0.175 - wind * 0.0625;
        vec2 w2 = planeCoord * 0.04375 + wind * 0.0375;

        // Complementary: use .b channel, planeCoord*0.0014, threshold 4.0+VdotUM*2.0
        float noise = texture2D(noisetex, w1, -10.0).b;
        noise += texture2D(noisetex, w2, -10.0).b * 5.0;

        noise = max(0.75 - 1.0 / abs(noise - (4.0 + VdotUM * 2.0)), 0.0) * 3.0;

        if (noise > 0.0) {
            noise *= 0.65;
            float fireNoise = texture2D(noisetex, abs(planeCoord * 0.2) - wind, -10.0).b;
            noise *= 0.5 * fireNoise + 0.75;
            noise = pow(noise, 1.75) * 2.9 / float(sampleCount);
            noise *= VdotUM2;

            vec3 beamColor = beamPurple;
            float fireNoiseSq = (fireNoise - 0.5) * (fireNoise - 0.5);
            beamColor += beamOrange * fireNoiseSq * fireNoiseSq * 0.15;
            beamColor *= gradientMix / float(sampleCount);

            noise *= exp2(-6.0 * float(i) / float(sampleCount));
            beams += vec4(noise * beamColor, noise);
        }
        gradientMix += 1.0;
    }

    float beamMult = pow(beams.a, beamPow) * 3.5;
    beams.rgb = sqrt(max(beams.rgb, vec3(0.0))) * beamMult;

    return beams.rgb;
}
