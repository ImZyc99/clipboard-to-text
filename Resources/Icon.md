# 图标

- `AppIcon.png`：imagegen 内置工具生成设计，经用户授权用脚本修正内部 alpha 的最终应用图标，复古烟草棕底、暖白线条剪贴板和折角文档，无文字。构建时 sips / iconutil 仅缩放并打包 ICNS。
- `Sources/App/BrandIcon.swift`：同核心图形的小尺寸原生矢量版本；透明背景、单色 template，系统按菜单栏明暗适配。无需从棕色底图抠图。

生成提示词：
> Use case: logo-brand. Create one finished production macOS app icon for a small clipboard-to-text utility. Square 1024x1024 composition. A centered rounded square tile of rich vintage tobacco brown (#79563F), genuinely transparent outside the rounded tile. On the tile, an elegant bold warm-white continuous monoline icon combining a clipboard clip at the top and one folded paper document with two short horizontal text strokes. Simple balanced geometry, rounded line caps, large readable mark occupying about 60% of tile, generous even margins. Warm 1970s stationery feel, restrained flat vector-like finish. No text, no letters, no mockup, no surrounding scene, no drop shadow, no grain, no gradients. White line logo on brown base is essential. This is the actual icon asset, not a presentation sheet.

生成结果实际为 1254×1254；构建按系统 ICNS 各尺寸重采样。菜单栏版本按用户后续要求仅保留线条核心元素。

## 0.2.1 透明度修复
imagegen 编辑提示要求「保持设计、图标内部 alpha=255、只有圆角外侧透明」，但输出仍为 alpha 253–254。该候选未采用。用户明确回复「用脚本修正」后，使用 `scripts/fix-icon-opacity.swift` 修正原始图，而非重绘候选。仅改 1,084,245 个 alpha 字节；全部 RGB 字节保持一致，外侧透明度保持一致，方形内部完全不透明。
