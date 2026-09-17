# Implementation Plan: 剪贴成文

**Branch**: 当前工作区 | **Date**: 2026-09-17 | **Spec**: [spec.md](spec.md)

## Summary
用 SwiftUI 设置窗口 + Finder Sync 扩展提供桌面右键入口；扩展通过专用 URL 唤起宿主，宿主按需读取剪贴板并写入系统桌面。

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
