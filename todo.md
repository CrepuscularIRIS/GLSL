# Shader Modding TODO

## 当前进度与剩余计划

**已完成：**
- 极光（BSL/LUX 移植）
- 末地光束增强（BSL lightShafts）
- 末地雾（BSL fog）
- 水面反射增强（LUX：skyRefMult 0.55×1.4，fresnel 0.2）

- **按维度区分 world0 / world7**
  - **world0（主世界）**：Photon 水面波浪、Snow Biome Only 极光、晴朗夜晚 Railgun 反射增强
  - **world7（常夜世界）**：LUX 水面、极光始终开启
- 主世界夜晚天空/水面反射联动（按资源包天空颜色）
- Nether 烟雾与风暴逻辑对齐（持续调校中）

**待办：**
1. **Complementary 体积光系列**：移植 volumetricLight 主链路（含相关依赖）
2. **END BEAM 系列**：对齐 Complementary/Solas 风格的末地光束与天空联动
3. **Solas 系列**：Ender Protoplanetary Disk、Ender Nebula、Black Hole 等
4. **水下白屏修复**（LUX：z0≥0.9999 时用 waterFogColor，吸收深度 clamp，mult 下限）
---

## 1. 极光实现说明

shaders/program/gbuffers_skybasic.glsl 里有：

#include "/lib/atmospherics/aurora.glsl"（在 OVERWORLD 下）

然后：vec4 aurora = DrawAurora(viewPos.xyz, dither, AURORA_SAMPLES_SKY);

albedo.rgb = mix(albedo.rgb, aurora.rgb, aurora.a);

也就是：天空底色算完以后，把极光按 alpha 混进去。

也会出现在水面/光滑材质的天空反射里
shaders/program/deferred.glsl 里（OVERWORLD 分支）：

vec4 aurora = DrawAurora(skyRefPos * 100.0, dither, AURORA_SAMPLES_REFLECTION);

skyReflection = mix(skyReflection, aurora.rgb, aurora.a);

所以你夜里看水面/反光材质，会看到“天空里有极光”的反射，这是同一套函数画的，只是采样次数不同。

极光为什么“夜晚才有”

核心条件在 DrawAurora(...) 一开始：

if (1.0 - max(sunVisibility, rainStrength) == 0.0) return vec4(0.0);

等价于：只要 sunVisibility 或 rainStrength 有一个是 1（太阳很可见 / 雨很强），就直接不画。

后面又有一段把透明度乘上夜晚因子：

auroraAlpha = auroraAlpha * auroraAlpha * 0.05 * Pow2((1 - rainStrength) * (1 - sunVisibility));

所以：

白天 sunVisibility≈1 → (1-sunVisibility)≈0 → 透明度几乎归零

夜晚 sunVisibility≈0 → 透明度才上得来

下雨会明显压制（rainStrength 越大越看不见）

另外它还有“按天决定出现概率”的机制（但你默认设置基本是每天都出）：

float probabilityHash = Hash11(worldDay * 239.9963...);

if (probabilityHash > AURORA_PROBABILITY) return vec4(0.0);

AURORA_PROBABILITY 在 shaders/lib/settings.glsl 默认是 1.0，意味着 probabilityHash 不可能大于 1 → 每天都会有极光。你如果把它调低，比如 0.3，就会变成“只有部分日子有极光”。

它怎么“生成”极光形状

它不是一层贴图，而是一个“沿视线向上取多个高度平面采样”的伪体积做法：

先算视线和上方向夹角：cosT = dot(normalize(viewPos), upVec);

cosT < 0（看向地平线以下）就不画

horizonIntensity = 1 - exp2(-cosT * 20)：让极光更偏向地平线附近更亮（你抬头看正上方会弱一些）

noiseSharpness 会随视角变化：越靠近地平线，“条带”越尖锐

然后循环采样（iterations 次，天空默认 8 次）：

对每一层高度，算出“视线与该高度平面相交”的坐标 planeCoord

用 simplex + noisetex 做 ridged 噪声，得到条带噪声 noise

用 auroraAlpha = mix(auroraAlpha, 1.0, noise / fIterations * 6.0) 逐步把透明度推高

最终透明度再乘“夜晚强度”和“雨衰减”

所以它看起来像“有厚度、有层次”，但成本比真正 raymarch 低很多：本质是采了几层平面。

极光颜色怎么做的（你夜里看到的那种颜色从哪来）

颜色由 GetAuroraColor() 决定，里面有明确的“预设类型”：

AURORA_COLORING_TYPE == 0（默认）：三色混合（蓝/绿/红）+ 噪声控制混色

颜色常量：

auroraBlue = (0.1, 0.2, 1.0)

auroraGreen = (0.1, 1.0, 0.2)

auroraRed = (1.0, 0.1, 0.6)

用多个 SimplexNoise 做 n1/n2/mixFactor，让颜色在空间里变化，不是整片同色

AURORA_COLORING_TYPE == 1：只在蓝↔绿之间变化

AURORA_COLORING_TYPE == 2：只在蓝↔红之间变化

AURORA_COLORING_TYPE == 3：用你在设置里填的两组 RGB（AURORA_COLOR_ONE_* 和 AURORA_COLOR_TWO_*）做自定义渐变

你这包的 settings.glsl 里默认就是 AURORA_COLORING_TYPE 0，所以夜晚看到“有时偏绿、有时偏紫/粉”的那种极光，就是它在蓝/绿/红三色之间按噪声乱混出来的。

还有一个“按群系限制”的选项，但默认没开：

// #define AURORA_PERBIOME（注释掉）

开了的话：if (isCold < 0.005) return vec4(0.0);

意味着只有寒冷群系（isCold）才出现极光

你现在的默认配置是：不按群系限制，只按“夜晚 + 不下大雨 + 概率（默认100%）”控制。）
---

## 2. Solas 末地特效核心移植
末地的宇宙尘埃云带和黑洞星系是一种极具科幻感的高级视效。

### A. 末地“周围云团”：Ender Protoplanetary Disk (末地云雾) - [中等]
- **算法原理**：典型的“体积云 raymarch（沿视线步进采样）”，但被限制为一个“盘状体积”。
  1. 用 `END_DISK_HEIGHT` 和 `END_DISK_THICKNESS` 定义上下两层平面，形成一个“厚盘”。
  2. 在盘内沿视线采样 `noisetex`（混合了 perlin/worley + 分层 detail），得到云密度。
  3. 密度里叠了一个螺旋结构：`getProtoplanetaryDisk(...)`（做出盘旋臂的形状）。

### B. 末地“黑洞”：Ender Nebula + Black Hole - [困难]
- **主要渲染步骤**：
  1. **坐标投影**：黑洞绑在 `sunVec` 上。
  2. **引力透镜/螺旋扭曲 (nebula warping)**。
  3. **本体绘制**：遮蔽强度（hole）、光子亮环（photonRing）、吸积盘（torus）。

### C. 末地氛围环境 (End Atmosphere: Beams + Center Glow) - [简单]
- **思路**：
  1. **冲天光束 (Ender Beams)**：垂直的发光长条。
  2. **中心岛屿发光 (End Center Lighting)**：从坐标 (0,0,0) 向外扩散的球形淡紫色辉光。
  3. **维度雾气染色**：将末地的基础雾色改为淡紫色并增加发光感。

---

## 3. 引入 SOLAS 相关的视效 
- **目标**：将 SOLAS Shaders 中的特色相关效果整合或参考至目前的光影中。具体细节待进一步规划。
（一、末地的“周围云团”是什么：Ender Protoplanetary Disk（END_DISK）
你看到那种“末地四周一圈圈像宇宙尘埃/云带”的东西，在这个包的命名里是：

开关：END_DISK

UI 里叫：Ender Protoplanetary Disk（末地云雾）

实现文件：shaders/lib/atmosphere/volumetricClouds.glsl 里 computeEndVolumetricClouds(...)

调用位置：shaders/programs/deferred.glsl 里 computeEndVolumetricClouds(...)

它的做法是典型的“体积云 raymarch（沿视线步进采样）”，不过是一个“盘状体积”：

用 END_DISK_HEIGHT 和 END_DISK_THICKNESS 定义上下两层平面，形成一个“厚盘”

在盘内沿视线采样 noisetex（混合了 perlin/worley + 分层 detail），得到云密度

密度里还叠了一个螺旋结构：getProtoplanetaryDisk(...)（做出盘旋臂的形状）

最终颜色基本是偏黄绿的能量尘埃色：vec3(0.95, 1.0, 0.5) * endLightCol，再乘采样得到的 lighting

你能调的关键参数（都在 shaders/lib/common.glsl 里有默认值，且在 shaders.properties 里做成滑条/选项）：

END_DISK_HEIGHT（盘在世界坐标里的高度）

END_DISK_THICKNESS（盘厚度/体积范围）

END_DISK_OPACITY（盘整体不透明度/强度）

END_DISK_AMOUNT（云覆盖量/“密不密”）

所以“末地周围云团”在这个包里不是一张贴图糊上去，而是一个盘状体积云系统（只是专门给 END 做了盘的几何限制）。

二、末地“黑洞”是什么：Ender Nebula + Black Hole（END_NEBULA / END_BLACK_HOLE）
黑洞这套在这里写得很明确：

星云开关：END_NEBULA

黑洞开关：END_BLACK_HOLE

黑洞大小：END_BLACK_HOLE_SIZE（UI 里叫 Black Hole Radius）

实现文件：shaders/lib/atmosphere/endNebula.glsl 里的 drawEndNebula(...)

调用位置：shaders/programs/deferred.glsl 里 drawEndNebula(skyColor, worldPos, VoU, VoS)

它干了几件很“科幻美术管线”的事：

先算出黑洞在天空里的“中心方向”
这里黑洞是绑在 sunVec 上的（末地里 sunVec 其实是一个“黑洞方向向量”，并不是真太阳）。然后把视线方向投到一个 2D 坐标（worldPos.xz / (...) - sunCoord），得到黑洞在屏幕天空中的局部坐标。

做“引力透镜/螺旋扭曲”（nebula warping）
getSpiralWarping(...) 会生成螺旋臂样式的扭曲量，然后把这个扭曲加到 nebulaCoord 上，于是星云会被“吸”出旋涡感。

画黑洞本体 + 光子环 + 周围环带（torus）

hole 是黑洞遮蔽强度（会把 skyColor 乘 1-hole，形成“吞光”）

photonRing 是黑洞边缘那圈亮环

torus 是类似吸积盘/环带的结构（再乘一点噪声，让它不是死板圆环）

另外你在设置里会看到一个：SUN_ANGLE_END（UI 文本写的是 Black Hole Angle (The End)）。这对应代码里对黑洞坐标做的倾斜项（blackHoleCoord.y -= blackHoleCoord.x * END_ANGLE;），用来让黑洞/盘面不是正对你，而是带角度的“倾斜天体”。）
