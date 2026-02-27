#if (WATER_MODE == 1 || WATER_MODE == 3) && !defined SKY_VANILLA && !defined NETHER && !defined VOXY_PATCH
uniform vec3 fogColor;
#endif

vec4 GetWaterFog(vec3 viewPos, vec3 waterAlbedo) {
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-2.0 * fog);
    fog = clamp(fog, 0.0, 0.92);
    
    #if WATER_MODE == 0 || WATER_MODE == 2
    vec3 waterFogColor = waterColor.rgb * waterColor.a;
    #elif  WATER_MODE == 1 || WATER_MODE == 3
    vec3 waterFogColor = fogColor * fogColor * 0.125;
    if (isEyeInWater == 0) waterFogColor = waterAlbedo;
    #endif
    waterFogColor *= WATER_F * WATER_F * (1.0 - max(blindFactor, darknessFactor));

    #ifdef OVERWORLD
    vec3 waterFogTint = lightCol * eBS * shadowFade * 0.9 + 0.1;
    #endif
    #ifdef NETHER
    vec3 waterFogTint = netherCol.rgb;
    #endif
    #ifdef END
    vec3 waterFogTint = endCol.rgb;
    #endif
    waterFogTint = sqrt(max(waterFogTint, vec3(0.0)) * max(length(waterFogTint), 0.001));
    waterFogTint = min(waterFogTint, vec3(1.4));

    waterFogColor *= waterFogTint;
    waterFogColor = min(waterFogColor, vec3(1.2));

    return vec4(waterFogColor, fog);
}
