# Implementation Plan: 剪贴成文

**Branch**: 当前工作区 | **Date**: 2026-09-17 | **Spec**: [spec.md](spec.md)

## Summary
用 AppKit 菜单栏入口 + 按需 SwiftUI 设置窗口 + Finder Sync 扩展提供保存入口；扩展通过专用 URL 唤起宿主，宿主按需读取剪贴板并写入系统桌面。

## Technical Context
- Language/Version: Swift 6.4（Swift 5 语言兼容模式）。
- Dependencies: 系统 SwiftUI / AppKit / FinderSync / Foundation / Darwin，无第三方运行依赖。
- Storage: UTF-8 .txt；UserDefaults 仅保存设置引导状态，不存正文。
- Testing: 独立 Swift 验收程序测试核心逻辑（CLT 不含 XCTest）；实机验证应用启动、扩展注册、桌面右键。
- Target: macOS 13+，本机 arm64 macOS 26.6.2；仅声称实际测试过的平台。
- Type: desktop-app + embedded .appex。
- Performance: 10 万字保存 2 秒内。
- Constraints: 离线、按需读剪贴板、永不覆盖、不依赖完整 Xcode。
- Scope: 单用户、单功能、单设置窗口。

## Constitution Check
研究前及设计后均通过：正文保持不变；目录固定桌面；扩展只负责菜单，不抓聊天；无网络；原子不覆盖写入；系统启用与权限不绕过。
Finder Sync 桌面行为和 adhoc 签名兼容性属于实机验证任务，不能从编译通过推断成功。

## Project Structure
```text
Package.swift
Sources/TextCore/TextFileWriter.swift
Sources/App/ClipboardToTextApp.swift
Sources/FinderExtension/FinderSync.swift
Resources/App-Info.plist
Resources/Extension-Info.plist
Resources/Extension.entitlements
Tests/TextCoreTests/TextFileWriterTests.swift
scripts/build.sh
scripts/install.sh
specs/001-clipboard-to-text/
```
原生包由 swiftc 构建，扩展入口为 Foundation 的 NSExtensionMain；Swift Package 定义核心库；scripts/test.sh 无需 XCTest。

## Validation
测试正文逐字相等、Unicode 文件名上限、同名文件/目录、并发冲突和权限错误。
构建后 plutil / codesign 验证包，在用户 Applications 目录安装测试版，用标准 pluginkit 注册并在系统界面启用。
桌面实机菜单测试使用专门样本文字；不读取用户聊天。

## 桌面入口修复计划
先记录 Finder 回调类型、目标是否桌面以及选区分类（不记录路径/正文）；检查是否因仅接受 container 回调而过滤桌面。菜单判定提取为可测纯逻辑，兼容桌面作为 item 返回的情况，其他位置不展示。更新安装逻辑，避免旧扩展进程和备份副本造成加载旧版本。最终请用户在真实桌面触发并读取诊断，不能以文件夹窗口替代。

## 菜单栏形态与品牌
在 AppDelegate 强引用 NSStatusItem，通过 NSMenu 原生呈现操作；LSUIElement=true + accessory activation policy 全程保留，不切 regular。移除延时自动打开设置；重新打开应用只保留菜单栏入口。NSMenuDelegate 打开时刷新扩展状态，不预读剪贴板。设置窗口显式激活并允许关闭，进程继续常驻；退出只退出宿主，Finder 扩展仍由系统管理，之后右键调用可能重新启动宿主。
生成 Resources/AppIcon.png，保存生成说明 Resources/Icon.md。scripts/build.sh 调用 scripts/build-icon.sh，使用 sips 缩放与 iconutil 打包 ICNS；Resources/App-Info.plist 引用 AppIcon。菜单栏用 Sources/App/BrandIcon.swift 的 20pt 原生矢量 template 图形，仅剪贴板/折页文档轮廓和两条正文线，透明背景，系统在深色下渲染白色；提供可访问标签。设置页使用棕色应用图标。图像缩放属于打包处理，保留原 PNG。
验证冷启动无窗口、设置往返、菜单保存和退出；检查 activationPolicy、可见窗口及资源装包，复跑核心文件安全测试。已有桌面菜单未通过项不随菜单栏验收关闭。

## 应用图标透明度修正
imagegen 编辑后仍有内部半透明，用户已明确授权改用脚本修正。scripts/fix-icon-opacity.swift 在原图每行的近不透明边界之间将 alpha 设为 255，不改 RGB 字节，保留外缘抗锯齿。保留旧图至 build/backups，校验新 PNG 内部透明度及圆角外侧透明，重新打包 ICNS、构建签名并替换已安装版本。仅图标资源变化，不重复运行无关正文测试；菜单栏模板不变。

## 保存后不弹 Finder
用户截图确认文件已保存，但不希望弹出 Finder 桌面文件夹。删除 saveClipboard 成功分支的 activateFileViewerSelecting 调用，原子写入成功即返回。保留失败提示、显式「打开桌面」动作；不新增通知或桌面定位自动化。更新交互契约并构建、检查成功路径无窗口调用，安装 0.2.2。纯删除 UI 副作用，不新增镜像测试。
