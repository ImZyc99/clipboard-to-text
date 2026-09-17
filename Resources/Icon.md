# 图标

- `AppIcon.png`：imagegen 内置工具生成的最终应用图标，复古烟草棕底、暖白线条剪贴板和折角文档，无文字。保留原始 PNG；构建时 sips / iconutil 仅缩放并打包 ICNS。
- `Sources/App/BrandIcon.swift`：同核心图形的小尺寸原生矢量版本；透明背景、单色 template，系统按菜单栏明暗适配。无需从棕色底图抠图。

生成提示词：
> Use case: logo-brand. Create one finished production macOS app icon for a small clipboard-to-text utility. Square 1024x1024 composition. A centered rounded square tile of rich vintage tobacco brown (#79563F), genuinely transparent outside the rounded tile. On the tile, an elegant bold warm-white continuous monoline icon combining a clipboard clip at the top and one folded paper document with two short horizontal text strokes. Simple balanced geometry, rounded line caps, large readable mark occupying about 60% of tile, generous even margins. Warm 1970s stationery feel, restrained flat vector-like finish. No text, no letters, no mockup, no surrounding scene, no drop shadow, no grain, no gradients. White line logo on brown base is essential. This is the actual icon asset, not a presentation sheet.

生成结果实际为 1254×1254；构建按系统 ICNS 各尺寸重采样。菜单栏版本按用户后续要求仅保留线条核心元素。
