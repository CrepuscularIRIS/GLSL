// LUX-compatible formula: waterColorSqrt^2 = linear color
vec4 waterColorSqrt = vec4(vec3(WATER_R, WATER_G, WATER_B) / 255.0, 1.0) * WATER_I;
vec4 waterColor = waterColorSqrt * waterColorSqrt;

const float waterAlpha = WATER_A;
// LUX: waterFog = WATER_F (block distance). BSL: waterFogRange for distance, WATER_F for fog color intensity.
const float waterFog = WATER_F;
const float waterFogRange = 64.0 / WATER_FOG_DENSITY;