#ifdef SKY_VANILLA
#ifndef VOXY_PATCH
uniform vec3 skyColor;

#ifndef NETHER
uniform vec3 fogColor;
#endif
#endif

// SKY_VANILLA path: follow Minecraft/resource-pack sky & fog colors directly.
vec3 skyCol = pow(skyColor, vec3(2.2)) * SKY_I * SKY_I
#ifdef WORLD7
	* WORLD7_BRIGHTNESS
#endif
	;
vec3 fogCol = pow(fogColor, vec3(2.2)) * SKY_I * SKY_I
#ifdef WORLD7
	* WORLD7_BRIGHTNESS
#endif
	;
#else
// LUX sky colors for day/morning/evening (night uses Railgun)
vec3 skyColSqrt = vec3(SKY_R, SKY_G, SKY_B) * SKY_I / 255.0;
vec3 fogColSqrt = vec3(FOG_R, FOG_G, FOG_B) * FOG_I / 255.0;
vec3 baseSkyCol = skyColSqrt * skyColSqrt;
vec3 baseFogCol = fogColSqrt * fogColSqrt;

// Railgun night (BSL modified) - keep for night
vec3 railgunNightSkySqrt = vec3(40.0, 116.0, 255.0) * 0.8 / 255.0;
vec3 railgunNightSky = railgunNightSkySqrt * railgunNightSkySqrt;

// Sunset: blend LUX day colors with Railgun night for smooth twilight transition
float sunsetBlend = pow(sunVisibility, 0.85);
vec3 skyCol = mix(railgunNightSky, baseSkyCol, sunsetBlend)
#ifdef WORLD7
	* WORLD7_BRIGHTNESS
#endif
	;
vec3 fogCol = mix(railgunNightSky, baseFogCol, sunsetBlend)
#ifdef WORLD7
	* WORLD7_BRIGHTNESS
#endif
	;
#endif
