/*
----------------------------------------------------------------
Photon-style Gerstner waves for still water (day only).
Transplanted from Photon include/surface/water_normal.glsl.
----------------------------------------------------------------
*/

float PhotonGerstnerWave(vec2 coord, vec2 waveDir, float t, float noise, float wavelength) {
	const float g = 9.8;
	float k = TAU / wavelength;
	float w = sqrt(g * k);
	float x = w * t - k * (dot(waveDir, coord) + noise);
	return Pow2(sin(x) * 0.5 + 0.5);
}

float GetPhotonWaterHeight(vec2 coord) {
	const float waveAngle = 0.523599; // 30 deg
	vec2 waveDir = vec2(cos(waveAngle), sin(waveAngle));
	float goldenAngle = PHI;
	mat2 waveRot = mat2(cos(goldenAngle), sin(goldenAngle), -sin(goldenAngle), cos(goldenAngle));
	float t = 0.5 * PHOTON_WAVE_SPEED_STILL * frameTimeCounter;

	const float waveFrequency = 0.7 * PHOTON_WAVE_FREQUENCY;
	const float persistence = PHOTON_WAVE_PERSISTENCE;
	const float lacunarity = PHOTON_WAVE_LACUNARITY;
	const float noiseFreq = 0.007;
	const float noiseStrength = 2.0;

	const int iters = 3;
	float ampNorm = (1.0 - persistence) / (1.0 - pow(persistence, float(iters)));

	vec2 noiseCoord = (coord + vec2(0.0, 0.25 * t)) * noiseFreq;
	float waveNoise0 = texture2D(noisetex, noiseCoord).r;
	noiseCoord *= 2.5;
	float waveNoise1 = texture2D(noisetex, noiseCoord).r;
	noiseCoord *= 2.5;
	float waveNoise2 = texture2D(noisetex, noiseCoord).r;

	float height = 0.0;
	float waveLength = 1.0;
	float amplitude = 1.0;
	float frequency = waveFrequency;

	height += PhotonGerstnerWave(coord * frequency, waveDir, t, waveNoise0 * noiseStrength, waveLength) * amplitude;
	amplitude *= persistence; frequency *= lacunarity; waveLength *= 1.5; waveDir *= waveRot;
	height += PhotonGerstnerWave(coord * frequency, waveDir, t, waveNoise1 * noiseStrength, waveLength) * amplitude;
	amplitude *= persistence; frequency *= lacunarity; waveLength *= 1.5; waveDir *= waveRot;
	height += PhotonGerstnerWave(coord * frequency, waveDir, t, waveNoise2 * noiseStrength, waveLength) * amplitude;

	return height * ampNorm;
}
