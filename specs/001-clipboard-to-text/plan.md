# Implementation Plan: 剪贴成文

**Branch**: 当前工作区 | **Date**: 2026-09-17 | **Spec**: [spec.md](spec.md)

## Summary
用 AppKit 菜单栏入口 + 按需 SwiftUI 设置窗口 + Finder Sync 扩展提供保存入口；扩展通过专用 URL 唤起宿主，宿主按需读取剪贴板并写入系统桌面。

## Technical Context
- Language/Version: Swift 6.4（Swift 5 语言兼容模式）。
- Dependencies: 系统 SwiftUI / AppKit / ApplicationServices / FinderSync / Foundation / Darwin，无第三方运行依赖。
- Storage: UTF-8 .txt；UserDefaults 仅保存功能开关等设置，不存正文。
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
诊断已记录多次 kind=0、targetDesktop=true、selectionCount=1，当前只接受 container 导致这些回调被过滤。菜单判定提取为 DesktopMenuPolicy：同时接受 items 与 container 的上下文菜单，要求目标为桌面（标准化并解析符号链接）；桌面上的文件右键也显示该动作，始终保存到桌面。工具栏、侧栏、其他目录和缺失目标不显示。保留仅注册 Desktop 的范围，不扩大到根目录。更新安装逻辑避免旧扩展进程和备份副本造成加载旧版本。最终请用户在真实桌面触发并读取诊断，不能以文件夹窗口替代。

用户实测 0.2.3 空白桌面仍无菜单，且没有任何 menu 回调。下一次单变量实验改为注册 `/`（参考已有 Finder 新建文件工具的公开实现），菜单策略仍限定明确的桌面目标，不请求文件读取权限、不遍历目录。若仍无回调则还原 Desktop 注册，避免把扩大范围当作已证实的修复。实际效果须用户测试后决定保留。

## 菜单栏形态与品牌
在 AppDelegate 强引用 NSStatusItem，通过 NSMenu 原生呈现操作；LSUIElement=true + accessory activation policy 全程保留，不切 regular。移除延时自动打开设置；重新打开应用只保留菜单栏入口。NSMenuDelegate 打开时刷新扩展状态，不预读剪贴板。设置窗口显式激活并允许关闭，进程继续常驻；退出只退出宿主，Finder 扩展仍由系统管理，之后右键调用可能重新启动宿主。
生成 Resources/AppIcon.png，保存生成说明 Resources/Icon.md。scripts/build.sh 调用 scripts/build-icon.sh，使用 sips 缩放与 iconutil 打包 ICNS；Resources/App-Info.plist 引用 AppIcon。菜单栏用 Sources/App/BrandIcon.swift 的 20pt 原生矢量 template 图形，仅剪贴板/折页文档轮廓和两条正文线，透明背景，系统在深色下渲染白色；提供可访问标签。设置页使用棕色应用图标。图像缩放属于打包处理，保留原 PNG。
验证冷启动无窗口、设置往返、菜单保存和退出；检查 activationPolicy、可见窗口及资源装包，复跑核心文件安全测试。已有桌面菜单未通过项不随菜单栏验收关闭。

## 应用图标透明度修正
imagegen 编辑后仍有内部半透明，用户已明确授权改用脚本修正。scripts/fix-icon-opacity.swift 在原图每行的近不透明边界之间将 alpha 设为 255，不改 RGB 字节，保留外缘抗锯齿。保留旧图至 build/backups，校验新 PNG 内部透明度及圆角外侧透明，重新打包 ICNS、构建签名并替换已安装版本。仅图标资源变化，不重复运行无关正文测试；菜单栏模板不变。

## 保存后不弹 Finder
用户截图确认文件已保存，但不希望弹出 Finder 桌面文件夹。删除 saveClipboard 成功分支的 activateFileViewerSelecting 调用，原子写入成功即返回。保留失败提示、显式「打开桌面」动作；不新增通知或桌面定位自动化。更新交互契约并构建、检查成功路径无窗口调用，安装 0.2.2。纯删除 UI 副作用，不新增镜像测试。

## 桌面 ⌘V
选择 AppKit NSEvent 全局被动监听，仅 Finder 为前台且授权/开关均有效时安装；切换其他应用立即移除。不吞掉或改写键盘事件，无辅助功能时不安装。只处理精确 Command+V 的非重复 keyDown，随后通过 AX 验证焦点位于 Finder 顶层桌面区域，拒绝窗口、编辑控件或未知焦点；不读取其他应用的控件。
Sources/App/DesktopPasteController.swift 管理监听、生命周期、权限与状态；Sources/TextCore/DesktopPastePolicy.swift 提供可测事件/场景判断。在确认桌面后检查 NSPasteboard.types，拒绝文件 URL/文件承诺；读取一次 string 前后校验 changeCount，成功调用宿主共享 saveText，不再读取剪贴板。不采用需吞键的 CGEventTap，避免阻断已有系统粘贴；系统可能保留其原有不可粘贴提示音。
UserDefaults 仅存开关；菜单「启用桌面 ⌘V…」显式请求辅助功能并引导系统设置，未授权时不自动弹窗。低频检查仅授权状态，不轮询剪贴板。应用退出移除监听；重启按开关和权限恢复。
没有可用代码签名身份，仍为本机 adhoc 构建：正常运行不反复请求，未来替换二进制可能需重新授权；不绕过 TCC 或修改其数据库。安装前还原未经确认的根目录实验，保留窄范围右键扩展；右键旧需求仍独立待验收。
测试正/负向判定、剪贴板文件类型、修改键与 repeat；构建安装后由用户完成首次系统授权，再验证桌面实际保存与不弹 Finder。
