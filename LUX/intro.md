# Complementary 光影详细介绍

## 简介

Complementary是一个功能极为丰富的Minecraft光影包，提供高质量的视觉效果和广泛的自定义选项。该光影基于BSL Shaders开发，添加了大量额外功能。

---

## 配置文件

**配置文件位置**: `shaders.properties`

### 预设配置

| 预设 | 描述 |
|------|------|
| POTATO | 最低画质，禁用大多数效果 |
| LOW | 低画质 |
| MEDIUM | 中等画质 |
| HIGH | 高画质 |
| ULTRA | 终极画质 |

### 主要设置项

```properties
# 核心设置
SHADOW_QUALITY          # 阴影质量 (-1=关闭, 0-3)
shadowMapResolution     # 阴影贴图分辨率
shadowDistance          # 阴影距离

# 云设置
CLOUD_QUALITY           # 云质量
CLOUD_STYLE_DEFINE      # 云样式 (-1=默认, 0=无, 1=reimagined, 2=unbound)
CLOUD_UNBOUND_SIZE_MULT # unbound云大小倍率

# 水设置
WATER_STYLE_DEFINE      # 水样式
WATER_CAUSTIC_STYLE_DEFINE # 水下焦散样式

# 大气效果
VOLUMETRIC_FOG          # 体积雾
AURORA_COLOR_PRESET     # 极光颜色预设
NIGHT_NEBULAE           # 夜间星云
```

---

## 云系统

### 云类型

**代码位置**: `lib/atmospherics/clouds/`

| 功能 | 文件 | 描述 |
|------|------|------|
| 主云系统 | `mainClouds.glsl` | 主云渲染逻辑 |
| Reimagined云 | `reimaginedClouds.glsl` | 改进的高质量云 |
| Unbound云 | `unboundClouds.glsl` | 无边界云层 |
| 云坐标 | `cloudCoord.glsl` | 云层坐标计算 |

### 云相关配置

```glsl
// mainClouds.glsl
#ifdef CLOUDS_REIMAGINED       // 改进版云
#ifdef CLOUDS_UNBOUND          // 无边界云
#ifdef DOUBLE_UNBOUND_CLOUDS   // 双层unbound云
#ifdef DOUBLE_REIM_CLOUDS      // 双层reimagined云
#ifdef RAINBOW_CLOUD           // 彩虹云
```

### 云配置参数

| 参数 | 位置 | 描述 |
|------|------|------|
| `CLOUD_SPEED_MULT` | cloudCoord.glsl:23 | 云速度倍率 |
| `CLOUD_DIRECTION` | cloudCoord.glsl:34 | 云方向 |
| `CLOUD_TRANSPARENCY` | shaders.properties | 云透明度 |
| `CLOUD_STRETCH` | shaders.properties | 云拉伸 |
| `CLOUD_UNBOUND_SIZE_MULT` | shaders.properties | unbound云大小 |

---

## 大气系统

### 极光 (Aurora Borealis)

**代码位置**: `lib/atmospherics/auroraBorealis.glsl`

**配置选项**:
- `AURORA_COLOR_PRESET` - 极光颜色预设 (0-5)
- `AURORA_INFLUENCE` - 极光影响范围
- `AURORA_STYLE` - 极光样式

### 夜间星云 (Night Nebulae)

**代码位置**: `lib/atmospherics/nightNebula.glsl`

**配置选项**:
- `NIGHT_NEBULAE` - 夜间星云开关 (-1/0/1)
- `NIGHT_NEBULA_I` - 夜间星云强度

### 光束效果 (Light Shafts)

**代码位置**: `lib/atmospherics/overworldBeams.glsl`, `lib/atmospherics/volumetricLight.glsl`

**配置选项**:
- `LIGHTSHAFT_QUALI_DEFINE` - 光束质量
- `LIGHTSHAFT_SMOKE` - 光束中的烟雾效果

---

## 维度特殊效果

### 主世界 (Overworld)

**水下效果**:

- **代码位置**: `program/final.glsl`, `lib/materials/specificMaterials/translucents/water.glsl`
- **配置**: `WATER_CAUSTIC_STYLE_DEFINE` - 水下焦散效果
- **水下模糊**: `underwaterOverlay` 设置

**天气效果**:

- **代码位置**: `program/gbuffers_weather.glsl`
- **配置**:
  - `RAIN_PUDDLES` - 雨天水坑
  - `RAIN_ATMOSPHERE` - 雨天大气效果
  - `SLANTED_RAIN` - 倾斜的雨
  - `GLITTER_RAIN` - 闪烁的雨滴

### 下界 (Nether)

**代码位置**: `world-1/`, `lib/atmospherics/netherStorm.glsl`

**特殊效果**:
- `NETHER_NOISE` - 下界噪声纹理
- `LAVA_VARIATION` - 熔岩变化
- `NETHER_SMOKE` - 下界烟雾 (需启用)
- `BIOME_COLORED_NETHER_PORTALS` - 生物群系着色的下界传送门
- `EMISSIVE_SOUL_SAND` - 发光灵魂沙
- `SOUL_SAND_VALLEY_OVERHAUL` - 灵魂沙谷改造

**下界雾效果**:

- **代码位置**: `lib/atmospherics/fog/coloredLightFog.glsl`
- `NETHER_FOG_INTENSITY` - 下界雾强度

### 末地 (End)

**代码位置**: `lib/atmospherics/` 下的多个文件

| 效果 | 文件 | 配置 |
|------|------|------|
| 末地星星 | `enderStars.glsl` | `END_STAR_AMOUNT`, `END_STAR_BRIGHTNESS`, `END_STAR_SIZE` |
| 闪烁星星 | `enderStars.glsl:43` | `END_TWINKLING_STARS` |
| 末影水晶旋涡 | `endCrystalVortex.glsl` | `END_CRYSTAL_VORTEX` |
| 末地光束 | `enderBeams.glsl`, `endPortalBeam.glsl` | `END_BEAMS`, `END_PORTAL_BEAM` |
| 末地闪光 | `endFlash.glsl` | `END_FLASH` |
| 末地中心雾 | `fog/endCenterFog.glsl` | `END_CENTER_FOG` |
| 末地黑洞 | `endCrystalVortex.glsl` | `END_CRYSTAL_VORTEX` |

**配置详解**:

```glsl
// enderStars.glsl
END_STAR_AMOUNT         // 星星数量 (0-4)
END_STAR_BRIGHTNESS     // 星星亮度
END_STAR_SIZE           // 星星大小
END_TWINKLING_STARS     // 闪烁星星 (0-3)
END_STAR_COLOR_*_END   // 星星颜色 RGB

// endCrystalVortex.glsl
END_CRYSTAL_VORTEX      // 末影水晶旋涡效果
                        // 0=关闭
                        // 1=旋转
                        // 2=黑洞
                        // 3=旋转+黑洞
DRAGON_DEATH_EFFECT     // 龙死亡特效
```

---

## 特殊功能

### 植物晃动

**代码位置**: `lib/shaderSettings/wavingBlocks.glsl`, `lib/materials/materialMethods/wavingBlocks.glsl`

**晃动类型**:

| 功能 | 定义 | 描述 |
|------|------|------|
| 树叶晃动 | `WAVING_LEAVES` | 树叶摇摆效果 |
| 植物晃动 | `WAVING_FOLIAGE` | 植物摇摆效果 |
| 熔岩晃动 | `WAVING_LAVA` | 熔岩表面波动 |
| 睡莲叶晃动 | `WAVING_LILY_PAD` | 睡莲叶摇摆 |
| 水面波动 | `WAVING_WATER_VERTEX` | 水面顶点波动 |

**配置参数**:

```glsl
// lib/shaderSettings/wavingBlocks.glsl
WAVING_SPEED            // 晃动速度 (0.00-5.00)
WAVING_I                // 晃动强度 (0.25-50.0)
WAVING_I_RAIN_MULT     // 雨天晃动强度倍率
NO_WAVING_INDOORS       // 室内不晃动
```

### 彩色云 (Rainbow Cloud)

**代码位置**: `lib/atmospherics/clouds/mainClouds.glsl:117`

```glsl
#if RAINBOW_CLOUD != 0
    // 彩虹云渲染代码
#endif
```

### 天气相关

**配置位置**: `shaders.properties`

| 功能 | 配置 | 描述 |
|------|------|------|
| 雨天水坑 | `RAIN_PUDDLES` | 下雨时的水坑效果 |
| 雨天大气 | `RAIN_ATMOSPHERE` | 雨天的特殊大气 |
| 倾斜的雨 | `SLANTED_RAIN` | 风吹雨斜 |
| 闪烁雨滴 | `GLITTER_RAIN` | 雨滴在阳光下闪烁 |
| 雨滴样式 | `RAIN_STYLE` | 雨滴样式变化 |

### 光照相关

**配置**: `lib位置/lighting/`

| 功能 | 配置 | 描述 |
|------|------|------|
| 阴影颜色 | `SHADOW_COLOR` | 彩色阴影 |
| 阴影过滤 | `SHADOW_FILTER` | 软阴影 |
| 环境光遮蔽 | `AO` / `SSAO` | AO效果 |
| 体积光 | `VOLUMETRIC_FOG` | 体积雾效果 |
| 光束 | `LIGHTSHAFT_QUALI_DEFINE` | 体积光束 |

### 水效果

**代码位置**: `lib/materials/specificMaterials/translucents/water.glsl`

| 功能 | 配置 | 代码位置 |
|------|------|----------|
| 水下焦散 | `WATER_CAUSTIC_STYLE_DEFINE` | water.glsl |
| 水边高光 | `WATER_EDGE_HIGHLIGHT` | water.glsl |
| 水面波动 | `WATER_STYLE_DEFINE` | water.glsl |
| 彩虹水 | `RAINBOW_WATER` | water.glsl |

### 材质效果

**PBR材质**:

- **代码位置**: `lib/materials/materialHandling/irisIPBR.glsl`, `lib/materials/materialHandling/terrainIPBR.glsl`
- **配置**: `NORMAL_MAPPING`, `SPECULAR_MAPPING`, `POM` (视差遮蔽映射)

**配置**:

```properties
NORMAL_MAPPING          # 法线映射
SPECULAR_MAPPING        # 高光映射
POM                     # 视差遮蔽映射
HARDCODED_SPECULAR      # 硬编码高光
HARDCODED_EMISSION      # 硬编码发光
HARDCODED_SSS           # 硬编码次表面散射
RAIN_PUDDLES            # 雨天水坑
```

---

## 后处理效果

**代码位置**: `program/composite*.glsl`, `program/final.glsl`

### 景深 (DOF)

**代码位置**: `lib/shaderSettings/final.glsl`

```properties
DOF                     # 景深开关
DOF_SNEAKING            # 蹲下时景深
DOF_VIEW_FOCUS_NEW2     # 新的对焦方式
WB_CHROMATIC            # 白平衡色差
```

### 泛光 (Bloom)

**配置**:

```properties
BLOOM                   # 泛光开关
BLOOM_INTENSITY         # 泛光强度
BLOOMY_FOG              # 雾气泛光
```

### 其他后处理

| 效果 | 配置 | 描述 |
|------|------|------|
| 色差 | `CHROMATIC_ABBERATION` | 边缘色差效果 |
| 动态模糊 | `MOTION_BLUR` | 运动模糊 |
| 抗锯齿 | `FXAA`, `TAA` | 抗锯齿 |
| 色调映射 | `TONEMAP` | 色调映射选择 |
| 暗角 | `VIGNETTE` | 画面暗角 |

---

## 世界渲染

### gbuffers 阶段

**代码位置**: `program/gbuffers_*.glsl`

| 文件 | 描述 |
|------|------|
| `gbuffers_terrain.glsl` | 地形渲染 |
| `gbuffers_water.glsl` | 水渲染 |
| `gbuffers_clouds.glsl` | 云渲染 |
| `gbuffers_entities.glsl` | 实体渲染 |
| `gbuffers_skybasic.glsl` | 天空基础 |
| `gbuffers_skytextured.glsl` | 天空纹理 |
| `gbuffers_weather.glsl` | 天气粒子 |

### composite 后处理阶段

**代码位置**: `program/composite*.glsl`

| 文件 | 描述 |
|------|------|
| `composite1.glsl` | 主后处理 |
| `composite2.glsl` | 阴影处理 |
| `composite3.glsl` | 光照处理 |
| `composite4.glsl` | 大气处理 |
| `final.glsl` | 最终输出 |

---

## 总结

Complementary是一个非常全面的光影包，具有以下亮点:

1. **多种云系统** - 支持Reimagined、Unbound、双层云等
2. **极光和星云** - 绚丽的极光和夜间星云效果
3. **完整的维度效果** - 末地黑洞、龙死亡特效、下界烟雾等
4. **丰富的植物晃动** - 树叶、植物、熔岩、水面波动
5. **全面的PBR材质** - 法线映射、高光、视差遮蔽
6. **多样的后处理** - DOF、Bloom、色差等
7. **天气系统** - 雨天水坑、倾斜雨、闪烁雨滴
