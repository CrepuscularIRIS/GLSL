# BSL enhanced for 1.7.10 - 维度区分交接文档

## 概述

本文档记录在 **BSL Shaders v10** 基础上实现的 **World0 / World7 / World9 维度区分**功能，包括极光、水面波浪、天空反射、亮度等特性。

---

## 维度定义

| 维度 | 宏定义 | 用途 |
|------|--------|------|
| World0 | `#define WORLD0` | 主世界（白天/夜晚循环） |
| World7 | `#define WORLD7` | 常夜世界（永久夜晚） |
| World9 | - | （未使用维度标记，预留） |

维度宏在对应维度的入口文件（`world0/*.fsh`、`world7/*.fsh`）中定义。

---

## 功能实现

### 1. 极光 (Aurora)

**文件**：`BSL/lib/atmospherics/clouds.glsl`

| 维度 | 逻辑 |
|------|------|
| **World7** | 始终显示，跳过 `sunVisibility` 和 `probabilityHash` 检查；强度与 LUX 一致（0.05）；不在 Snow Biome 限制 |
| **World0** | 仅 Snow Biome 显示（`isCold < 0.005` 时不显示）；受 `sunVisibility` 影响 |

```glsl
// World7: 极光始终可见
#ifdef WORLD7
    auroraAlpha = auroraAlpha * auroraAlpha * 0.05 * pow((1.0 - 0.15 * rainStrength), 2.0);
#else
    auroraAlpha = auroraAlpha * auroraAlpha * 0.05 * pow((1.0 - 0.15 * rainStrength) * (1.0 - sunVisibility), 2.0);
#endif
```

**叠加方式**：World7 极光在 `deferred1.glsl` 中用 `mix()` 叠加在云层之上，避免穿墙问题。

---

### 2. 水面波浪 (Water Waves)

**文件**：`BSL/lib/surface/photonWaterWaves.glsl`（新增）、`BSL/program/gbuffers_water.glsl`

| 维度 | 波浪实现 |
|------|----------|
| **World0** | Photon Gerstner 波浪 (`GetPhotonWaterHeight`) |
| **World7** | LUX/BSL 默认 `ComputeWaterWaves` |

```glsl
#ifdef WORLD0
    noise += GetPhotonWaterHeight(worldPos.xz) * mult * 0.4;
#else
    noise += ComputeWaterWaves(...);
#endif
```

---

### 3. 天空反射 (World0 晴朗夜晚)

**文件**：`BSL/program/gbuffers_water.glsl`

在 World0 + 晴朗夜晚（`clearNight > 0.01`）时，注入 Railgun 冷蓝色，使水面反射更接近 Railgun 风格：

```glsl
#ifdef WORLD0
    float clearNight = (1.0 - sunVisibility) * (1.0 - rainStrength);
    waterSkyOcclusion = max(waterSkyOcclusion, 0.9 * clearNight);
    if (clearNight > 0.01) {
        vec3 railgunNight = pow(vec3(40.0, 116.0, 255.0) / 255.0, vec3(2.2)) * 1.0;
        skyReflection = mix(railgunNight, skyReflection, max(waterSkyOcclusion, 0.45));
        skyReflection *= max(waterSkyOcclusion, 0.65);
    }
#endif
```

---

### 4. 亮度增强 (World7)

**文件**：`BSL/lib/color/lightColor.glsl`、`BSL/lib/color/skyColor.glsl`

World7 下所有光照、天空颜色乘以 `WORLD7_BRIGHTNESS`：

```glsl
vec3 lightCol = lightColSqrt * lightColSqrt
#ifdef WORLD7
    * WORLD7_BRIGHTNESS
#endif
    ;
```

---

### 5. World7 强制夜晚时间

**文件**：18 个 `program/*.glsl` 文件

无论 World7 实际时间如何，强制使用主世界夜晚时间值：

| 变量 | World7 强制值 |
|------|---------------|
| `sunVisibility` | 0.0 |
| `sunSkyVisibility` | 0.0 |
| `moonVisibility` | 1.0 |

涉及文件：
- `gbuffers_skybasic.glsl`
- `gbuffers_water.glsl`
- `deferred1.glsl`
- `composite.glsl`
- `dh_water.glsl`
- `voxy_translucent.glsl`
- `composite5.glsl`
- `gbuffers_block.glsl`
- `gbuffers_terrain.glsl`
- `composite1.glsl`
- `dh_terrain.glsl`
- `voxy_opaque.glsl`
- `gbuffers_textured.glsl`
- `gbuffers_hand.glsl`
- `gbuffers_entities.glsl`
- `gbuffers_entities_glowing.glsl`
- `gbuffers_basic.glsl`
- `gbuffers_skytextured.glsl`
- `gbuffers_clouds.glsl`
- `gbuffers_weather.glsl`

---

### 6. World0 夜空提亮

**文件**：`BSL/lib/atmospherics/sky.glsl`

提升 World0 夜晚天空亮度，接近 Railgun 效果：

```glsl
#ifdef WORLD0
    nightSky *= 1.6;
#endif
```

---

## 配置项

**文件**：`BSL/lib/settings.glsl`

```glsl
#define AURORA 0
#define AURORA_BRIGHTNESS 5.5
#define AURORA_WORLD7_BRIGHTNESS 2.50
#define WORLD7_BRIGHTNESS 1.50
```

---

## 语法兼容性

所有修改遵循旧版 GLSL / Shaders Mod 语法：

1. **避免复合赋值**：不使用 `*=`, `+=`, `/=`，改用显式乘法
2. **声明时直接计算**：不在声明后二次赋值全局变量
3. **使用 `texture2D`**：不使用 `texture()`（GLSL 3.00+ 语法）

---

## 待测试 / 已知问题

1. **World7 极光穿墙**：已在 `deferred1.glsl` 中改用 `mix()` 叠加，需验证是否解决
2. **World0 水面反射**：如需更强反射，可进一步增大 `railgunNight` 权重或降低 `waterSkyOcclusion` 下限

---

## 变更文件列表

| 文件 | 变更类型 |
|------|----------|
| `BSL/lib/atmospherics/clouds.glsl` | 极光逻辑修改 |
| `BSL/lib/surface/photonWaterWaves.glsl` | 新增（Photon 波浪） |
| `BSL/program/gbuffers_water.glsl` | 水面反射、波浪调用 |
| `BSL/program/deferred1.glsl` | 极光叠加 |
| `BSL/lib/atmospherics/sky.glsl` | 夜空提亮 |
| `BSL/lib/color/lightColor.glsl` | World7 亮度 |
| `BSL/lib/color/skyColor.glsl` | World7 亮度 |
| `BSL/lib/color/lightSkyColor.glsl` | World7 强制夜晚 |
| `BSL/lib/settings.glsl` | 新增配置项 |
| 18 个 `program/*.glsl` | 强制夜晚时间变量 |

---

## 交接时间

2026-02-27
