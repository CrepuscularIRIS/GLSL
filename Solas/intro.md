# Solas 光影详细介绍

## 简介

Solas是一个功能丰富的光影包，提供高质量的视觉效果和广泛的定制选项。该光影包支持Iris和OptiFine。

---

## 配置文件

**配置文件位置**: `shaders.properties`

### 预设配置

```properties
# Profiles
profile.LOW=!LPV_FOG !REFRACTION !BLOOM !VOLUMETRIC_CLOUDS !VL !AURORA !GENERATED_NORMALS !GENERATED_SPECULAR !NETHER_SMOKE !END_DISK !SHADOW_COLOR WATER_NORMALS=0 shadowMapResolution=1024 shadowDistance=128.0 VOXEL_VOLUME_SIZE=128

profile.MEDIUM=profile.LOW REFRACTION BLOOM VL SHADOW_COLOR WATER_NORMALS=3 VL_SAMPLES=7

profile.HIGH=profile.MEDIUM LPV_FOG VOLUMETRIC_CLOUDS AURORA GENERATED_NORMALS GENERATED_SPECULAR NETHER_SMOKE END_DISK shadowMapResolution=2048 shadowDistance=192.0 VOXEL_VOLUME_SIZE=192 VL_SAMPLES=8

profile.ULTRA=profile.HIGH LPV_CLOUDY_FOG SHADOW_ENTITIES shadowMapResolution=4096 shadowDistance=512.0 VOXEL_VOLUME_SIZE=256 VL_SAMPLES=12
```

### 菜单结构

```properties
screen=SOLAS_BY_SEPTONIOUS <profile> <empty> [ATMOSPHERICS] [WATER] [PBR] [LIGHTING] [COLOR] [POST] [OTHER]
```

---

## 大气系统

### 云系统

**代码位置**: `lib/atmosphere/`

| 功能 | 配置文件 | 描述 |
|------|----------|------|
| 体积云 | `volumetricClouds.glsl` | 3D体积云渲染 |
| 平面云 | `planarClouds.glsl` | 2D平面云 |
| Vanilla云 | shaders.properties | 传统Minecraft云 |

#### 体积云配置

```properties
VOLUMETRIC_CLOUDS          # 体积云开关
VC_SHADOWS                 # 云阴影
VC_DYNAMIC_WEATHER         # 动态天气影响
VC_AMOUNT                  # 云量
VC_HEIGHT                  # 云高度
VC_THICKNESS               # 云厚度
VC_OPACITY                 # 云透明度
VC_DENSITY                 # 云密度
VC_SPEED                   # 云速度
VC_DETAIL                  # 云细节
VC_DISTANCE                # 云距离
VC_ATTENUATION             # 云衰减
VC_SCALE                   # 云缩放
```

### 极光 (Aurora)

**代码位置**: `lib/atmosphere/aurora.glsl`

```properties
AURORA                      # 极光开关
AURORA_BRIGHTNESS          # 极光亮度
AURORA_LIGHTING_INFLUENCE  # 极光光照影响
```

### 体积光 (Volumetric Light)

**代码位置**: `lib/atmosphere/volumetrics.glsl`

```properties
VL                          # 体积光开关
VL_STRENGTH                 # 体积光强度
VL_DAY                      # 白天体积光
VL_MORNING_EVENING          # 早晨/黄昏体积光
VL_NIGHT                    # 夜间体积光
VL_STRENGTH_RATIO           # 强度比率
VL_SAMPLES                  # 采样数
```

### LPV雾

**代码位置**: shaders.properties

```properties
LPV_FOG                     # 光子映射体积雾
LPV_FOG_STRENGTH            # 雾强度
LPV_CLOUDY_FOG              # 阴天雾效
```

---

## 维度特殊效果

### 主世界 (Overworld)

#### 水效果

**代码位置**: `programs/dh_water.glsl`, `programs/gbuffers_water.glsl`

```properties
VANILLA_WATER               # Vanilla水
WATER_REFLECTIONS           # 水面反射
WATER_FOG                   # 水下雾
WATER_FOG_EXPONENT          # 雾指数
WATER_CAUSTICS              # 水下焦散
WATER_CAUSTICS_STRENGTH     # 焦散强度
WATER_NORMALS               # 水面法线 (0=关闭, 1-3=质量)
WATER_NORMAL_DETAIL         # 法线细节
WATER_NORMAL_BUMP          # 法线凹凸
WATER_NORMAL_OFFSET         # 法线偏移
REFRACTION                 # 折射效果
REFRACTION_STRENGTH         # 折射强度
```

#### 大气效果

```properties
OVERWORLD_ATMOSPHERE_CONFIG # 主世界大气配置
ROUND_SUN_MOON              # 圆形日月
STARS                       # 星星
END_STARS                   # 末地星星
SHOOTING_STARS              # 流星
RAINBOW                     # 彩虹
RAINBOW_BRIGHTNESS          # 彩虹亮度
```

### 下界 (Nether)

**代码位置**: `lib/atmosphere/volumetrics.glsl`

```properties
NETHER_SMOKE                # 下界烟雾
NETHER_SMOKE_STRENGTH       # 烟雾强度
NETHER_SMOKE_FREQUENCY      # 烟雾频率
NETHER_SMOKE_SPEED          # 烟雾速度
```

**雾效**:

```glsl
// lib/atmosphere/fog.glsl
#ifdef NETHER
    // 下界雾效渲染
#endif
```

### 末地 (End)

**代码位置**: `lib/atmosphere/endNebula.glsl`

| 功能 | 配置 | 描述 |
|------|------|------|
| 末地星云 | `END_NEBULA` | 末地独特星云 |
| 末地星云亮度 | `END_NEBULA_BRIGHTNESS` | 星云亮度 |
| 末地黑洞 | `END_BLACK_HOLE` | 末地黑洞效果 |
| 黑洞大小 | `END_BLACK_HOLE_SIZE` | 黑洞尺寸 |
| 末地闪光 | `END_FLASHES` | 末地闪光效果 |
| 闪光亮度 | `END_FLASH_BRIGHTNESS` | 闪光强度 |
| 末地圆盘 | `END_DISK` | 末地圆盘 (末影龙平台) |
| 银河 | `MILKY_WAY` | 银河效果 |
| 银河亮度 | `MILKY_WAY_BRIGHTNESS` | 银河亮度 |

**末地颜色配置**:

```properties
LIGHT_END                   # 末地光源颜色
AMBIENT_END                 # 末地环境光
NEBULA_END_FIRST            # 第一种星云颜色
NEBULA_END_SECOND           # 第二种星云颜色
FLASH_END                   # 末地闪光颜色
```

**代码详解**:

```glsl
// endNebula.glsl
#ifdef END_BLACK_HOLE
    // 黑洞渲染 (代码行: 48, 63, 79, 90, 97, 116)
#endif

#ifdef END_67
    // 末地时间倾斜效果
#endif

#ifdef END_TIME_TILT
    // 末地时间倾斜动画
#endif
```

---

## 特殊功能

### 植物晃动

**代码位置**: `lib/pbr/waving.glsl`

```glsl
#ifdef WAVING_PLANTS
    // 植物晃动
#endif

#ifdef WAVING_LEAVES
    // 树叶晃动
#endif
```

### PBR材质

**代码位置**: `lib/pbr/`

```properties
GENERATED_NORMALS           # 程序生成法线
GENERATED_SPECULAR          # 程序生成高光
NORMAL_MAPPING              # 法线映射
SPECULAR_MAPPING            # 高光映射
POM                         # 视差遮蔽映射
```

### 阴影

```properties
SHADOW                      # 阴影开关
SHADOW_COLOR                # 彩色阴影
SHADOW_ENTITIES             # 实体阴影
shadowMapResolution         # 阴影贴图分辨率
shadowDistance              # 阴影距离
SHADOW_PIXEL                # 像素化阴影
```

---

## 后处理效果

### 泛光 (Bloom)

**代码位置**: shaders.properties

```properties
BLOOM                       # 泛光开关
BLOOM_STRENGTH_OVERWORLD    # 主世界泛光强度
BLOOM_CONTRAST              # 泛光对比度
BLOOM_STRENGTH_NETHER       # 下界泛光强度
BLOOM_STRENGTH_END          # 末地泛光强度
BLOOM_TILE_SIZE             # 泛光瓦片大小
```

### 其他后处理

| 功能 | 配置 | 描述 |
|------|------|------|
| 折射 | `REFRACTION` | 画面折射 |
| 色差 | `CHROMATIC` | 色差效果 |
| DOF | `DOF` | 景深效果 |
| 光晕 | `LENS_FLARE` | 镜头光晕 |

---

## 光照系统

**代码位置**: `lib/lighting/gbuffersLighting.glsl`

### 光照设置

```properties
SUN_I                       # 太阳光强度
MOON_I                     # 月亮光强度
SKYLIGHT_I                 # 天光强度
BLOCKLIGHT_I               # 方块光强度
```

### 光源颜色

```properties
LIGHT_COLOR                 # 主世界光源颜色
BLOCKLIGHT_COLOR           # 方块光颜色
LPV_COLOR                  # 光子映射颜色
```

---

## 远距离渲染

**代码位置**: `programs/dh_terrain.glsl`, `programs/dh_water.glsl`

```properties
# 远距离地形和水渲染支持
DISTANT_HORIZONS           # 远距离地平线
VOXY                       # Voxy支持
```

---

## 总结

Solas光影的主要特点:

1. **体积云** - 高质量的3D体积云
2. **平面云** - 可选的2D平面云层
3. **极光** - 绚丽的极光效果
4. **体积光** - 光束效果
5. **LPV雾** - 光子映射体积雾
6. **末地黑洞** - 独特的末地黑洞特效
7. **末地星云** - 末地独特的星云效果
8. **下界烟雾** - 下界特有的烟雾效果
9. **末地圆盘** - 末影龙平台的发光圆盘
10. **银河** - 星空银河效果
11. **PBR材质** - 物理基础渲染
12. **植物晃动** - 植物和树叶晃动
