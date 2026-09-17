# 剪贴成文

把微信、飞书等应用中复制的口播稿、提示词，直接保存为桌面上的文本文件。启动后常驻菜单栏，无需打开主窗口，不显示 Dock 图标。

## 使用

1. 打开「剪贴成文」，顶部菜单栏出现透明底的剪贴板线条图标。
2. 复制一段文字。
3. 点击菜单栏图标 → **将剪贴板保存为文本**。

菜单还提供打开桌面、右键扩展状态、管理右键扩展、设置与使用说明、退出。设置窗口仅在主动选择时打开，关闭后工具继续运行。退出后菜单栏图标消失；Finder 扩展由系统管理，后续通过扩展保存时可重新启动宿主。本版不自动添加登录启动项。

桌面右键入口需要先从「管理右键扩展…」启用同名 Finder 扩展。目前已在 Finder 的桌面文件夹窗口验证；**真实壁纸桌面菜单仍在定位，尚未验收**，菜单栏入口可独立使用。

生成 UTF-8 `.txt`，按第一行非空文字自动命名，重名自动加序号。正文中的换行、空行和 Emoji 原样保留。只在保存时读取剪贴板，不联网、不保存剪贴板历史。

保存成功后在 Finder 中选中文件；macOS 可能打开桌面文件夹窗口。需要桌面访问时，按系统提示授权。

## 本机构建

需要 macOS 13+、Apple Silicon/Intel 对应架构的 Command Line Tools。当前只验收本机架构。

```sh
./scripts/test.sh
./scripts/build.sh
./scripts/install.sh
```

构建产物：`build/剪贴成文.app`。安装到 `~/Applications/剪贴成文.app`。

默认 ad-hoc 签名，用于本机开发；没有公证，不是可面向其他电脑直接分发的安装包。可通过 `CLIPTEXT_SIGN_IDENTITY` 指定已有签名身份。

## 技术

AppKit 菜单栏、SwiftUI 按需设置页、Finder Sync 原生右键扩展、Foundation 文件读写；不需要后端。
扩展只发送保存指令到宿主，正文不放入 URL。完成临时文件写入后，以原子不覆盖方式发布最终文件名。

CLT 不包含 XCTest，因此 `scripts/test.sh` 编译并执行独立 Swift 验收程序，覆盖正文、文件名、并发、失败清理与性能。

## 图标

应用使用复古棕底白线图标，菜单栏使用同一剪贴板/文档核心形状的透明底单色模板，适配系统深浅外观。原图见 [Resources/AppIcon.png](Resources/AppIcon.png)，生成说明见 [Resources/Icon.md](Resources/Icon.md)。

## 卸载

在系统设置中关闭 Finder 扩展，退出应用，将 `~/Applications/剪贴成文.app` 移到废纸篓即可。此前保存的文本不受影响。

## 需求与验证

- [需求](specs/001-clipboard-to-text/spec.md)
- [技术计划](specs/001-clipboard-to-text/plan.md)
- [任务](specs/001-clipboard-to-text/tasks.md)
- [验证记录](specs/001-clipboard-to-text/validation.md)
