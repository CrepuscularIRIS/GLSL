/* 
BSL Shaders v10 Series by Capt Tatsu 
https://capttatsu.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying float mat;
varying float dist;

varying vec2 texCoord, lmCoord;

varying vec3 normal, binormal, tangent;
varying vec3 sunVec, upVec, eastVec;
varying vec3 viewVector;

varying vec4 color;
varying vec4 vTexCoord, vTexCoordAM;

//Uniforms//
uniform int bedrockLevel;
uniform int frameCounter;
uniform int isEyeInWater;
uniform int moonPhase;
uniform int worldTime;

uniform float blindFactor, darknessFactor, nightVision;
uniform float cloudHeight;
uniform float endFlashIntensity;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition, previousCameraPosition;
uniform vec3 relativeEyePosition;

uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;
uniform sampler2D gaux2;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

#ifdef ADVANCED_MATERIALS
uniform ivec2 atlasSize;

uniform sampler2D specular;
uniform sampler2D normals;

#ifdef REFLECTION_RAIN
uniform float wetness;
#endif
#endif

#if DYNAMIC_HANDLIGHT > 0
uniform int heldBlockLightValue, heldBlockLightValue2;
#endif

#if defined MULTICOLORED_BLOCKLIGHT || defined MCBL_SS
uniform int heldItemId, heldItemId2;
#endif

#ifdef MULTICOLORED_BLOCKLIGHT
uniform sampler3D lighttex0;
uniform sampler3D lighttex1;
#endif

#ifdef MCBL_SS
uniform sampler2D colortex8;
uniform sampler2D colortex9;
#endif

#if CLOUDS == 2
uniform sampler2D gaux1;
#endif

#ifdef VOXY
uniform int vxRenderDistance;

uniform mat4 vxProjInv;

uniform sampler2D vxDepthTexOpaque;
#endif

#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;
uniform float dhFarPlane;

uniform mat4 dhProjectionInverse;

uniform sampler2D dhDepthTex1;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
#ifdef WORLD7
float sunVisibility = 0.0;
#else
float sunVisibility  = clamp(dot( sunVec, upVec) * 10.0 + 0.5, 0.0, 1.0);
#endif
#ifdef WORLD7
float moonVisibility = 1.0;
#else
float moonVisibility = clamp(dot(-sunVec, upVec) * 10.0 + 0.5, 0.0, 1.0);
#endif

#ifdef WORLD_TIME_ANIMATION
float time = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float time = frameTimeCounter * ANIMATION_SPEED;
#endif

vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float Hash11(float x) {
	x = fract(x * 0.3183099);
	x += dot(x, x + 19.19);
	return fract(x * 0.3183099);
}

float GetWaveLayer(vec2 coord, float wavelength, vec2 direction, float speed) {
    float k = 6.2831853 / wavelength;
	float x = k * dot(normalize(direction), coord.xy) - frameTimeCounter * 3.0 * speed;
    return sin(x + cos(x) * 0.8) / k;
}

float ComputeWaterWaves(
	in vec2 planeCoord,
	in float mult,
	in float waveSpeed,
	in float gWaveLength,
	in float gWaveLacunarity,
	in float gWavePersistance,
	in float gWaveAmplitude,
	in float gWaveDirSpread,
	in int gWaveIterations,
	in float noiseScale,
	in float noiseLacunarity,
	in float noiseAmplitude,
	in float noisePersistance,
	in int noiseIterations
) {
	float noise = 0.0;

	for (int i = 0; i < gWaveIterations; i++) {
		vec2 direction = vec2(Hash11(float(i)), Hash11(-float(i))) * 2.0 - 1.0;
		direction = mix(vec2(1.0), direction, gWaveDirSpread);
		noise += GetWaveLayer(planeCoord * 8.4, gWaveLength, direction, waveSpeed) * gWaveAmplitude;
		gWaveLength *= gWaveLacunarity;
		gWaveAmplitude *= gWavePersistance;
	}
	noise *= gWaveAmplitude;

	for (int i = 0; i < noiseIterations; i++) {
		float wind = frameTimeCounter * waveSpeed * 0.7 * (float(fract(float(i) / 2.0) == 0.0) * 2.0 - 1.0);
		noise += texture2D(noisetex, (planeCoord + wind) * noiseScale).r * noiseAmplitude;
		noiseScale *= noiseLacunarity;
		noiseAmplitude *= noisePersistance;
	}

	return noise * mult * mult;
}

float clamp_positive(float x) { return max(x, 0.0); }
float saturate(float x) { return clamp(x, 0.0, 1.0); }

#ifdef WORLD0
#include "/lib/surface/photonWaterWaves.glsl"
#endif

float GetWaterHeightMap(vec3 worldPos, vec3 viewPos) {
    float noise = 0.0;
    float mult = saturate(-dot(normalize(normal), normalize(viewPos)) * 8.0) / pow(max(dist, 4.0), 0.25);

    if (mult > 0.01) {
        #if WATER_NORMALS > 0
		#ifdef WORLD0
		// world0: Photon Gerstner waves (day and night)
		noise += GetPhotonWaterHeight(worldPos.xz) * mult * 0.4;
		#else
		// world7: LUX/BSL ComputeWaterWaves
		noise += ComputeWaterWaves(
			worldPos.xz,
			mult,
			WATER_SPEED,
			GERSTNER_WAVE_LENGTH,
			GERSTNER_WAVE_LACUNARITY,
			GERSTNER_WAVE_PERSISTANCE,
			GERSTNER_WAVE_AMPLITUDE,
			GERSTNER_WAVE_DIR_SPREAD,
			GERSTNER_WAVE_ITERATIONS,
			NOISE_WAVE_SCALE,
			NOISE_WAVE_LACUNARITY,
			NOISE_WAVE_AMPLITUDE,
			NOISE_WAVE_PERSISTANCE,
			NOISE_WAVE_ITERATIONS
		);
		#endif
		#endif
    }

    return noise * WATER_BUMP;
}

vec3 GetParallaxWaves(vec3 worldPos, vec3 viewPos, vec3 viewVector) {
	vec3 parallaxPos = worldPos;

	for (int i = 0; i < 4; i++) {
		float height = (GetWaterHeightMap(parallaxPos, viewPos) - 0.5) * 0.24;
		parallaxPos.xz += height * viewVector.xy / dist;
	}
	return parallaxPos;
}

vec3 GetWaterNormal(vec3 worldPos, vec3 viewPos, vec3 viewVector) {
	vec3 waterPos = worldPos + cameraPosition;

	#if WATER_PIXEL > 0
	waterPos = floor(waterPos * WATER_PIXEL) / WATER_PIXEL;
	#endif

	#ifdef WATER_PARALLAX
	waterPos = GetParallaxWaves(waterPos, viewPos, viewVector);
	#endif

	float h1 = GetWaterHeightMap(waterPos + vec3( 0.1, 0.0, 0.0), viewPos);
	float h2 = GetWaterHeightMap(waterPos + vec3(-0.1, 0.0, 0.0), viewPos);
	
	float h3 = GetWaterHeightMap(waterPos + vec3(0.0, 0.0,  0.1), viewPos);
	float h4 = GetWaterHeightMap(waterPos + vec3(0.0, 0.0, -0.1), viewPos);

	float xDelta = (h1 - h2) / 0.1;
	float yDelta = (h3 - h4) / 0.1;

	vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));
	return normalMap * 0.03 + vec3(0.0, 0.0, 0.97);
}

void NetherPortalParallax(inout vec4 albedo, float dither) {
	int sampleCount = 4;
	float parallaxDepth = 0.125;

	#ifdef TAA
	dither = fract(dither + frameCounter * 0.618);
	#endif
	
	for (int i = 0; i < sampleCount; i++) {
		float currentDepth = float(i + dither) / sampleCount * parallaxDepth;
		float weight = 1.0 - currentDepth * 2.0;

		vec2 offset = viewVector.xy / -viewVector.z * currentDepth;
		vec2 newCoord = fract(vTexCoord.st + offset) * vTexCoordAM.pq + vTexCoordAM.st;

		vec4 parallaxSample = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
		albedo = max(albedo, parallaxSample * weight);
	}
}

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/lightSkyColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/specularColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/atmospherics/weatherDensity.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/atmospherics/waterFog.glsl"
#include "/lib/lighting/dynamicHandlight.glsl"
#include "/lib/lighting/forwardLighting.glsl"
#include "/lib/reflections/raytrace.glsl"
#include "/lib/reflections/simpleReflections.glsl"
#include "/lib/surface/ggx.glsl"
#include "/lib/surface/hardcodedEmission.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#ifdef ADVANCED_MATERIALS
#include "/lib/reflections/complexFresnel.glsl"
#include "/lib/surface/directionalLightmap.glsl"
#include "/lib/surface/materialGbuffers.glsl"
#include "/lib/surface/parallax.glsl"

#ifdef REFLECTION_RAIN
#include "/lib/reflections/rainPuddles.glsl"
#endif
#endif

#ifdef MULTICOLORED_BLOCKLIGHT
#include "/lib/util/voxelMapHelper.glsl"
#endif

#if defined MULTICOLORED_BLOCKLIGHT || defined MCBL_SS
#include "/lib/lighting/coloredBlocklight.glsl"
#endif

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * vec4(color.rgb, 1.0);
	vec3 newNormal = normal;
	float smoothness = 0.0;
	vec3 lightAlbedo = vec3(0.0);
	
	#ifdef ADVANCED_MATERIALS
	vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;
	float surfaceDepth = 1.0;
	float parallaxFade = clamp((dist - PARALLAX_DISTANCE) / 32.0, 0.0, 1.0);
	float skipParallax = float(mat > 0.98 && mat < 1.02);
		  skipParallax+= float(mat > 4.98 && mat < 5.02);

	#ifdef PARALLAX_PORTAL
		  skipParallax+= float(mat > 3.98 && mat < 4.02);
	#endif
	
	#ifdef PARALLAX
	if(skipParallax < 0.5) {
		newCoord = GetParallaxCoord(texCoord, parallaxFade, surfaceDepth);
		albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
	}
	#endif
	#endif

	vec3 vlAlbedo = vec3(1.0);
	vec3 refraction = vec3(0.0);

	float cloudBlendOpacity = 1.0;

	{
		vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
		
		float water       = float(mat > 0.98 && mat < 1.02);
		float glass 	  = float(mat > 1.98 && mat < 2.02);
		float translucent = float(mat > 2.98 && mat < 3.02);
		float portal      = float(mat > 3.98 && mat < 4.02);
		
		float metalness       = 0.0;
		float emission        = portal;
		float subsurface      = 0.0;
		float basicSubsurface = water;
		vec3 baseReflectance  = vec3(0.04);

		vec3 hsv = RGB2HSV(albedo.rgb);
		emission *= GetHardcodedEmission(albedo.rgb, hsv);
		
		#ifndef REFLECTION_TRANSLUCENT
		glass = 0.0;
		translucent = 0.0;
		#endif

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		#ifdef TAA
		vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
		#else
		vec3 viewPos = ToNDC(screenPos);
		#endif
		vec3 worldPos = ToWorld(viewPos);

		float dither = Bayer8(gl_FragCoord.xy);
		float viewLength = length(viewPos);

		#if CLOUDS == 2
		float cloudMaxDistance = 2.0 * far;
		#ifdef VOXY
		cloudMaxDistance = max(cloudMaxDistance, vxRenderDistance * 16.0);
		#endif
		#ifdef DISTANT_HORIZONS
		cloudMaxDistance = max(cloudMaxDistance, dhFarPlane);
		#endif

		float cloudViewLength = texture2D(gaux1, screenPos.xy).r * cloudMaxDistance;

		cloudBlendOpacity = step(viewLength, cloudViewLength);

		if (cloudBlendOpacity == 0) {
			discard;
		}
		// albedo.rgb *= fract(viewLength);
		#endif
		
		#if defined DISTANT_HORIZONS && !defined VOXY
		float minDist = (dither - 0.75) * 16.0 + far;
		if (viewLength > minDist) {
			discard;
		}
		#endif

		vec3 normalMap = vec3(0.0, 0.0, 1.0);
		
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);

		#if WATER_NORMALS > 0
		if (water > 0.5) {
			#if WATER_NORMALS == 1 || WATER_NORMALS == 2
			normalMap = GetWaterNormal(worldPos, viewPos, viewVector);
			newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
			#elif WATER_NORMALS == 3 && defined ADVANCED_MATERIALS
			float tempF0 = 0.0, tempPorosity = 0.5, tempAo = 1.0;
			GetMaterials(smoothness, metalness, tempF0, emission, subsurface, tempPorosity, tempAo, normalMap,
						 newCoord, dcdx, dcdy);
			metalness = 0.0;
			emission = 0.0;

			newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
			#endif
		}
		#endif

		#ifdef ADVANCED_MATERIALS
		float f0 = 0.0, porosity = 0.5, ao = 1.0, skyOcclusion = 0.0;
		if (water < 0.5) {
			GetMaterials(smoothness, metalness, f0, emission, subsurface, porosity, ao, normalMap,
						 newCoord, dcdx, dcdy);

			if ((normalMap.x > -0.999 || normalMap.y > -0.999) && viewVector == viewVector)
				newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		}
		#endif

		#if REFRACTION == 1
		refraction = vec3((newNormal.xy - normal.xy) * 0.5 + 0.5, float(albedo.a < 0.95) * water);
		#elif REFRACTION == 2
		refraction = vec3((newNormal.xy - normal.xy) * 0.5 + 0.5, float(albedo.a < 0.95));
		#endif
		
		#if DYNAMIC_HANDLIGHT == 2
		lightmap = ApplyDynamicHandlight(lightmap, worldPos);
		#endif

		#ifdef TOON_LIGHTMAP
		lightmap = floor(lightmap * 14.999 * (0.75 + 0.25 * color.a)) / 14.0;
		lightmap = clamp(lightmap, vec2(0.0), vec2(1.0));
		#endif

		#ifdef PARALLAX_PORTAL
		if (portal > 0.5) {
			NetherPortalParallax(albedo, dither);
		}
		#endif

    	albedo.rgb = pow(albedo.rgb, vec3(2.2));
		
		vlAlbedo = albedo.rgb;

		#ifdef MCBL_SS
		vec3 opaquelightAlbedo = texture2D(colortex8, screenPos.xy).rgb;
		if (water < 0.5) {
			opaquelightAlbedo *= vlAlbedo;
		}
		lightAlbedo = albedo.rgb + 0.00001;

		if (portal > 0.5) {
			lightAlbedo = lightAlbedo * 0.95 + 0.05;
		}

		lightAlbedo = normalize(lightAlbedo + 0.00001) * emission;
		lightAlbedo = mix(opaquelightAlbedo, sqrt(lightAlbedo), albedo.a);

		#ifdef MULTICOLORED_BLOCKLIGHT
		lightAlbedo *= GetMCBLLegacyMask(worldPos);
		#endif
		#endif

		#ifdef WHITE_WORLD
		albedo.rgb = vec3(0.35);
		#endif
		
		if (water > 0.5) {
			#if WATER_MODE == 0
			albedo.rgb = waterColor.rgb * waterColor.a;
			#elif WATER_MODE == 1
			albedo.rgb *= WATER_VI * WATER_VI;
			#elif WATER_MODE == 2
			float waterLuma = length(albedo.rgb / pow(color.rgb, vec3(2.2))) * 2.0;
			albedo.rgb = waterLuma * waterColor.rgb * waterColor.a;
			#elif WATER_MODE == 3
			albedo.rgb = color.rgb * color.rgb * WATER_VI * WATER_VI;
			#endif
			#if WATER_ALPHA_MODE == 0
			albedo.a = waterAlpha;
			#else
			albedo.a = pow(albedo.a, WATER_VA);
			#endif
			vlAlbedo = sqrt(albedo.rgb);
			baseReflectance = vec3(0.02);
		}
		
		#if WATER_FOG == 1
		vec3 fogAlbedo = albedo.rgb;
		#endif
		
		vlAlbedo = mix(vec3(1.0), vlAlbedo, sqrt(albedo.a)) * (1.0 - pow(albedo.a, 64.0));
		
		#ifndef HALF_LAMBERT
		float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
		#else
		float NoL = clamp(dot(newNormal, lightVec) * 0.5 + 0.5, 0.0, 1.0);
		NoL *= NoL;
		#endif

		float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
		float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);
		float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			  vanillaDiffuse*= vanillaDiffuse;

		float parallaxShadow = 1.0;
		#ifdef ADVANCED_MATERIALS
		vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
		albedo.rgb *= ao;

		#ifdef REFLECTION_SPECULAR
		albedo.rgb *= 1.0 - metalness * smoothness;
		#endif
		
		#ifdef SELF_SHADOW
		if (lightmap.y > 0.0 && NoL > 0.0 && water < 0.5) {
			parallaxShadow = GetParallaxShadow(surfaceDepth, parallaxFade, newCoord, lightVec,
											   tbnMatrix);
		}
		#endif

		#ifdef DIRECTIONAL_LIGHTMAP
		mat3 lightmapTBN = GetLightmapTBN(viewPos);
		lightmap.x = DirectionalLightmap(lightmap.x, lmCoord.x, newNormal, lightmapTBN);
		lightmap.y = DirectionalLightmap(lightmap.y, lmCoord.y, newNormal, lightmapTBN);
		#endif
		#endif

		#if defined MULTICOLORED_BLOCKLIGHT || defined MCBL_SS
		blocklightCol = ApplyMultiColoredBlocklight(blocklightCol, screenPos, worldPos, newNormal, 0.0);
		#endif
		
		vec3 shadow = vec3(0.0);
		GetLighting(albedo.rgb, shadow, viewPos, worldPos, normal, lightmap, 1.0, NoL, 
					vanillaDiffuse, parallaxShadow, emission, subsurface, basicSubsurface);

		#ifdef ADVANCED_MATERIALS
		float puddles = 0.0;
		#ifdef REFLECTION_RAIN	
		if (water < 0.5) {
			puddles = GetPuddles(worldPos, newCoord, lightmap.y, NoU, wetness);
		}

		ApplyPuddleToMaterial(puddles, albedo, smoothness, f0, porosity);

		if (puddles > 0.001 && rainStrength > 0.001) {
			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);

			vec3 puddleNormal = GetPuddleNormal(worldPos, viewPos, tbnMatrix);
			newNormal = normalize(
				mix(newNormal, puddleNormal, puddles * sqrt(1.0 - porosity) * rainStrength)
			);
		}
		#endif
		#endif
		
		float fresnel = pow(clamp(1.0 + dot(newNormal, normalize(viewPos)), 0.0, 1.0), 5.0);

		if (water > 0.5 || ((translucent + glass) > 0.5 && albedo.a > 0.01 && albedo.a < 0.95)) {
			#if REFLECTION > 0
			vec4 reflection = vec4(0.0);
			vec3 skyReflection = vec3(0.0);
			float reflectionMask = 0.0;
	
			fresnel = fresnel * 0.98 + 0.02;
			fresnel*= max(1.0 - isEyeInWater * 0.5 * water, 0.5);
			// fresnel = 1.0;
			
			#if REFLECTION == 2
			reflection = SimpleReflection(viewPos, newNormal, dither, reflectionMask);
			reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
			#endif
			
			if (reflection.a < 1.0) {
				#ifdef OVERWORLD
				vec3 skyRefPos = reflect(normalize(viewPos), newNormal);
				skyReflection = GetSkyColor(skyRefPos, true);
				
				#if AURORA > 0 || defined(WORLD7)
				vec4 aurora = DrawAurora(skyRefPos * 100.0, dither, 12);
				skyReflection = mix(skyReflection, aurora.rgb, aurora.a);
				#endif

				#ifndef WORLD7
				float clearNightCloud = (1.0 - sunVisibility) * (1.0 - rainStrength);
				if (clearNightCloud < 0.01) {
				#if CLOUDS == 1
				vec4 cloud = DrawCloudSkybox(skyRefPos * 100.0, 1.0, dither, lightCol, ambientCol, true);
				skyReflection = mix(skyReflection, cloud.rgb, cloud.a);
				#endif
				#if CLOUDS == 2
				vec3 cameraPos = GetReflectedCameraPos(worldPos, newNormal);
				float cloudViewLength = 0.0;

				vec4 cloud = DrawCloudVolumetric(skyRefPos * 8192.0, cameraPos, 1.0, dither, lightCol, ambientCol, cloudViewLength, true);
				skyReflection = mix(skyReflection, cloud.rgb, cloud.a);
				#endif
				}
				#endif

				#ifdef CLASSIC_EXPOSURE
				skyReflection *= 4.0 - 3.0 * eBS;
				#endif
				#ifdef WORLD7
				skyReflection *= WORLD7_WATER_REFLECTION_BOOST;
				#endif
				
				float waterSkyOcclusion = lightmap.y;
				#if REFLECTION_SKY_FALLOFF > 1
				waterSkyOcclusion = clamp(1.0 - (1.0 - waterSkyOcclusion) * REFLECTION_SKY_FALLOFF, 0.0, 1.0);
				#endif
				waterSkyOcclusion *= waterSkyOcclusion;
				#ifdef WORLD0
				// world0 clear night: keep sky detail, then push toward Railgun bright-cyan style.
				float clearNight = (1.0 - sunVisibility) * (1.0 - rainStrength);
				if (clearNight > 0.01) {
					skyReflection *= mix(1.0, WORLD0_WATER_NIGHT_REFLECTION_BOOST, clearNight);
					vec3 railgunNight = skyReflection * WORLD0_WATER_NIGHT_BLUE_BOOST;
					railgunNight = mix(railgunNight, railgunNight * vec3(0.96, 1.03, 1.12), 0.45 * clearNight);
					float moonMask = smoothstep(0.9985, 0.9998, dot(normalize(skyRefPos), -sunVec));
					railgunNight = mix(railgunNight, railgunNight * 0.55, moonMask * clearNight);
					waterSkyOcclusion = mix(waterSkyOcclusion, 1.0, 0.55 * clearNight);
					waterSkyOcclusion = max(waterSkyOcclusion, 0.94 * clearNight);
					skyReflection = mix(skyReflection, railgunNight, WORLD0_WATER_NIGHT_BLEND * clearNight);
					skyReflection *= max(waterSkyOcclusion, WATER_NIGHT_OCCLUSION_FLOOR);
				} else {
					skyReflection *= waterSkyOcclusion;
				}
				#endif
				#ifndef WORLD0
				skyReflection *= waterSkyOcclusion;
				#endif
				#endif

				#ifdef NETHER
				skyReflection = netherCol.rgb * 0.04;
				#endif

				#ifdef END
				skyReflection = endCol.rgb * 0.01;
				#endif

				skyReflection *= clamp(1.0 - isEyeInWater, 0.0, 1.0);
			}
			
			reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));

			#if (defined OVERWORLD || defined END) && SPECULAR_HIGHLIGHT == 2
			vec3 specularColor = GetSpecularColor(lightmap.y, 0.0, vec3(1.0));

			vec3 specular = GetSpecularHighlight(newNormal, viewPos,  0.9, vec3(0.02),
													specularColor, shadow, color.a);
			#if ALPHA_BLEND == 0
			float specularAlpha = pow(mix(albedo.a, 1.0, fresnel), 2.2) * fresnel;
			#else
			float specularAlpha = mix(albedo.a , 1.0, fresnel) * fresnel;
			#endif

			reflection.rgb += specular * (1.0 - reflectionMask) / specularAlpha;
			#endif
			
			albedo.rgb = mix(albedo.rgb, reflection.rgb, fresnel);
			albedo.a = mix(albedo.a, 1.0, fresnel);
			#endif
		} else if (albedo.a > 0.01) {
			#ifdef ADVANCED_MATERIALS
			skyOcclusion = lightmap.y;
			#if REFLECTION_SKY_FALLOFF > 1
			skyOcclusion = clamp(1.0 - (1.0 - skyOcclusion) * REFLECTION_SKY_FALLOFF, 0.0, 1.0);
			#endif
			skyOcclusion *= skyOcclusion;

			baseReflectance = mix(vec3(f0), rawAlbedo, metalness);

			#ifdef REFLECTION_SPECULAR
			vec3 fresnel3 = mix(baseReflectance, vec3(1.0), fresnel);
			#if MATERIAL_FORMAT == 0
			if (f0 >= 0.9 && f0 < 1.0) {
				baseReflectance = GetMetalCol(f0);
				fresnel3 = ComplexFresnel(pow(fresnel, 0.2), f0);
				#ifdef ALBEDO_METAL
				fresnel3 *= rawAlbedo;
				#endif
			}
			#endif
			
			float aoSquared = ao * ao;
			shadow *= aoSquared; fresnel3 *= aoSquared * smoothness * smoothness;

			if (smoothness > 0.0) {
				vec4 reflection = vec4(0.0);
				vec3 skyReflection = vec3(0.0);
				float reflectionMask = 0.0;
				
				float ssrMask = clamp(length(fresnel3) * 400.0 - 1.0, 0.0, 1.0);
				if(ssrMask > 0.0) reflection = SimpleReflection(viewPos, newNormal, dither, reflectionMask);
				reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
				reflection.a *= ssrMask;

				if (reflection.a < 1.0) {
					#ifdef OVERWORLD
					vec3 skyRefPos = reflect(normalize(viewPos.xyz), newNormal);
					skyReflection = GetSkyColor(skyRefPos, true);
					
					#if AURORA > 0 || defined(WORLD7)
					vec4 aurora = DrawAurora(skyRefPos * 100.0, dither, 12);
					skyReflection = mix(skyReflection, aurora.rgb, aurora.a);
					#endif
					
					#ifndef WORLD7
					float clearNightCloud2 = (1.0 - sunVisibility) * (1.0 - rainStrength);
					if (clearNightCloud2 < 0.01) {
					#if CLOUDS == 1
					vec4 cloud = DrawCloudSkybox(skyRefPos * 100.0, 1.0, dither, lightCol, ambientCol, false);
					skyReflection = mix(skyReflection, cloud.rgb, cloud.a);
					#endif
					#if CLOUDS == 2
					vec3 cameraPos = GetReflectedCameraPos(worldPos, newNormal);
					float cloudViewLength = 0.0;

					vec4 cloud = DrawCloudVolumetric(skyRefPos * 8192.0, cameraPos, 1.0, dither, lightCol, ambientCol, cloudViewLength, true);
					skyReflection = mix(skyReflection, cloud.rgb, cloud.a);
					#endif
					}
					#endif

					#ifdef CLASSIC_EXPOSURE
					skyReflection *= 4.0 - 3.0 * eBS;
					#endif
					#ifdef WORLD7
					skyReflection *= WORLD7_WATER_REFLECTION_BOOST;
					#endif

					#ifdef WORLD0
					// world0 clear night: keep sky detail, then push toward Railgun bright-cyan style.
					float clearNight2 = (1.0 - sunVisibility) * (1.0 - rainStrength);
					if (clearNight2 > 0.01) {
						skyReflection *= mix(1.0, WORLD0_WATER_NIGHT_REFLECTION_BOOST, clearNight2);
						vec3 railgunNight2 = skyReflection * WORLD0_WATER_NIGHT_BLUE_BOOST;
						railgunNight2 = mix(railgunNight2, railgunNight2 * vec3(0.96, 1.03, 1.12), 0.45 * clearNight2);
						float moonMask2 = smoothstep(0.9985, 0.9998, dot(normalize(skyRefPos), -sunVec));
						railgunNight2 = mix(railgunNight2, railgunNight2 * 0.55, moonMask2 * clearNight2);
						float nightSkyOcc = mix(skyOcclusion, 1.0, 0.55 * clearNight2);
						nightSkyOcc = max(nightSkyOcc, 0.94 * clearNight2);
						skyReflection = mix(skyReflection, railgunNight2, WORLD0_WATER_NIGHT_BLEND * clearNight2);
						skyReflection *= max(nightSkyOcc, WATER_NIGHT_OCCLUSION_FLOOR);
					} else {
						skyReflection = mix(vanillaDiffuse * minLightCol, skyReflection, skyOcclusion);
					}
					#else
					skyReflection = mix(vanillaDiffuse * minLightCol, skyReflection, skyOcclusion);
					#endif
					#endif

					#ifdef NETHER
					skyReflection = netherCol.rgb * 0.04;
					#endif

					#ifdef END
					skyReflection = endCol.rgb * 0.01;
					#endif
				}

				reflection.rgb = max(mix(skyReflection, reflection.rgb, reflectionMask), vec3(0.0));

				albedo.rgb = albedo.rgb * (1.0 - fresnel3 * (1.0 - metalness)) +
							 reflection.rgb * fresnel3;
				albedo.a = mix(albedo.a, 1.0, GetLuminance(fresnel3));
			}
			#endif
			#endif

			#if (defined OVERWORLD || defined END) && SPECULAR_HIGHLIGHT == 2
			vec3 specularColor = GetSpecularColor(lightmap.y, metalness, baseReflectance);

			albedo.rgb += GetSpecularHighlight(newNormal, viewPos, smoothness, baseReflectance,
										   	   specularColor, shadow * vanillaDiffuse, color.a);
			#endif
		}

		#if WATER_FOG == 1
		if((isEyeInWater == 0 && water > 0.5) || (isEyeInWater == 1 && water < 0.5)) {
			float opaqueDepth = texture2D(depthtex1, screenPos.xy).r;
			vec3 opaqueScreenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), opaqueDepth);
			#ifdef TAA
			vec3 opaqueViewPos = ToNDC(vec3(TAAJitter(opaqueScreenPos.xy, -0.5), opaqueScreenPos.z));
			#else
			vec3 opaqueViewPos = ToNDC(opaqueScreenPos);
			#endif

			vec4 waterFog = GetWaterFog(opaqueViewPos - viewPos.xyz, fogAlbedo);
			waterFog.rgb *= waterFog.a;
			albedo = mix(waterFog, albedo / max(albedo.a, 0.0001), albedo.a);
		}
		#endif

		Fog(albedo.rgb, viewPos);

		#ifdef OVERWORLD
		#ifdef FAR_VANILLA_FOG_OVERWORLD
		float cloudMask = GetCloudMask(viewPos, 0.0);
		albedo.a *= 1.0 - pow(cloudMask, 4.0);
		#endif
		#endif

		#if ALPHA_BLEND == 0
		albedo.rgb = sqrt(max(albedo.rgb, vec3(0.0)));
		#endif
	}
	albedo.a *= cloudBlendOpacity;

    /* DRAWBUFFERS:01 */
    gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(vlAlbedo, 1.0);

	#ifdef MCBL_SS
		/* DRAWBUFFERS:018 */
		gl_FragData[2] = vec4(lightAlbedo, 1.0);
		#if REFRACTION > 0
		/* DRAWBUFFERS:0186 */
		gl_FragData[3] = vec4(refraction, 1.0);
		#endif
	#else
		#if REFRACTION > 0
		/* DRAWBUFFERS:016 */
		gl_FragData[2] = vec4(refraction, 1.0);
		#endif
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying float mat;
varying float dist;

varying vec2 texCoord, lmCoord;

varying vec3 normal, binormal, tangent;
varying vec3 sunVec, upVec, eastVec;
varying vec3 viewVector;

varying vec4 color;
varying vec4 vTexCoord, vTexCoordAM;

//Uniforms//
uniform int worldTime;

uniform float far;
uniform float frameTimeCounter;
uniform float timeAngle;

uniform vec3 cameraPosition;
uniform vec3 relativeEyePosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

#ifdef TAA
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

//Attributes//
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;

//Common Variables//
#ifdef WORLD_TIME_ANIMATION
float time = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float time = frameTimeCounter * ANIMATION_SPEED;
#endif

//Common Functions//
float WavingWater(vec3 worldPos) {
	float viewLength = length(worldPos);

	worldPos += cameraPosition;
	float fractY = fract(worldPos.y + 0.005);
		
	float wave = sin(8.28 * (-time * 0.4 + worldPos.x * 0.14 + worldPos.z * 0.07)) +
				 sin(8.28 * (-time * 0.3 + worldPos.x * 0.10 + worldPos.z * 0.20));

    #if defined DISTANT_HORIZONS || defined VOXY
    wave *= smoothstep(far + 4.0, far - 12.0, length(viewLength));
    #endif

	if (fractY > 0.01) return wave * 0.025 * ANIMATION_STRENGTH;
	return 0.0;
}

//Includes//
#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
	
	int blockID = int(mc_Entity.x / 100);

	normal   = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);
								  
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	
	dist = length(gl_ModelViewMatrix * gl_Vertex);

	vec2 midCoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texMinMidCoord = texCoord - midCoord;

	vTexCoordAM.pq  = abs(texMinMidCoord) * 2;
	vTexCoordAM.st  = min(texCoord, midCoord - texMinMidCoord);
	
	vTexCoord.xy    = sign(texMinMidCoord) * 0.5 + 0.5;
    
	color = gl_Color;

	if(color.a < 0.1) color.a = 1.0;
	
	mat = 0.0;
	
	if (blockID == 200 || blockID == 204) mat = 1.0;
	if (blockID == 201)                   mat = 2.0;
	if (blockID == 202)                   mat = 3.0;
	if (blockID == 203)                   mat = 4.0;
	if (blockID == 251)                   mat = 5.0;

	const vec2 sunRotationData = vec2(
		 cos(sunPathRotation * 0.01745329251994),
		-sin(sunPathRotation * 0.01745329251994)
	);
	#ifndef END
	float ang = fract(timeAngle - 0.25);
	#else
	float ang = 0.0;
	#endif
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	
	#ifdef WAVING_WATER
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	if (blockID == 200 || blockID == 202 || blockID == 204) position.y += WavingWater(position.xyz);
	#endif

    #ifdef WORLD_CURVATURE
	position.y -= WorldCurvature(position.xz);
    #endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	if (mat == 0.0) gl_Position.z -= 0.00001;
	
	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif
