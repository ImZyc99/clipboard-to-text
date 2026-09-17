# 技术研究

## 构建
Decision: 使用现有 CLT 的 swiftc 编译原生应用和扩展，生成标准 .app/.appex 并 adhoc 签名。
Rationale: 本机有 Swift 6.4 与 macOS SDK，无 Xcode。SDK Foundation 导出 _NSExtensionMain，CLT app-extension 产品规格同样使用此入口。
Alternatives: 安装大型 Xcode 不作为原型前置；Electron/Tauri 仍需原生扩展。

## 菜单与权限
Decision: 仅监控用户桌面，响应 contextualMenuForContainer；通过 NSWorkspace 定向打开宿主并传入专用 URL，宿主负责桌面写入。
Rationale: 将受沙盒限制的菜单进程与需要桌面权限的保存行为分开，不传输正文到 URL。
Alternatives: Automator 服务不能保证桌面空白右键入口；扩展直接写桌面增加沙盒授权复杂度。
Evidence: 本机 FinderSync.h；https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html
Apple 将此扩展定位为同步用途，本应用属于本地实验工具；桌面支持需验证。

## 不覆盖
Decision: 在目标目录创建临时文件，写入并关闭后以原子硬链接发布最终名称；EEXIST 重试序号；defer 移除临时文件。
Rationale: 先完成写入再发布且永不替换目标，既防并发覆盖又避免公开空文件。
Alternatives: exists + write 有竞态；普通 atomic write 会覆盖目标。

## 文件定位
Decision: NSWorkspace.activateFileViewerSelecting 选中文件。
Rationale: 官方公开 API，无辅助功能或 Apple Events 授权。
Limitation: 系统可能打开桌面文件夹窗口选中，不能保证桌面图标原位选中。
Evidence: https://developer.apple.com/documentation/appkit/nsworkspace/activatefileviewerselecting(_:)

## CLT 配套差异
本机 SDK 27 的 State 新宏缺少 SwiftUIMacros 编译插件，使用类型别名明确选择兼容的 State 属性包装器。CLT 缺少 XCTest，验收程序采用 Foundation 独立编译运行，保持同样测试范围。
# 菜单栏形态补充

## 桌面 ⌘V 决策
- Decision: 使用 NSEvent 全局被动监听，辅助功能授权后仅 Finder 前台时安装，不吞键、不合成键盘事件。
- Rationale: [Apple Monitoring Events](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html) 明确 global monitor 只能观察，键盘监听要求辅助功能信任。被动方式保持系统文件粘贴，避免同步 event tap 中读取 AX 或剪贴板导致输入阻塞。
- Alternatives: CGEventTap 可以吞键，但增加事件超时/恢复与权限复杂度；本版接受 Finder 可能仍发出原生提示音。
- Desktop focus: SDK 没有公开桌面专用 AX role，不能只根据 Finder 前台或 focusedWindow=nil 判断。采用 Finder 进程身份 + AXChildren 直接非窗口 ScrollArea/Group 容器 + Desktop/桌面名称辅证；父链出现窗口/菜单/编辑控件即拒绝，读取失败或过期事件不处理。当前本机中文/英文结构仍需获授权后实测。
- 本机 `security find-identity -v -p codesigning` 显示 0 个有效身份；保持 adhoc，不绕过权限存储。代码更新可能需要用户重新授权，稳定运行时不会每次触发权限请求。
- Decision: NSStatusItem 强引用保存在 AppDelegate；菜单使用 NSMenuDelegate.menuNeedsUpdate 刷新扩展状态，autoenablesItems=false。
- Rationale: status bar 不持有 status item，菜单 delegate 为 weak；本机 NSMenu.h 要求菜单项更新放在 menuNeedsUpdate，避免 menuWillOpen 时修改。
- Decision: LSUIElement + accessory 全程保留，设置窗口仍可显式激活，不切 regular。reopen 不自动弹设置。
- Alternatives: SwiftUI MenuBarExtra 会引入额外生命周期，与现有 AppDelegate/CLT 宿主不如 NSStatusItem 直接；无需新增框架。
- 品牌：imagegen 生成棕底白线应用图标；菜单栏使用同核心元素的原生矢量单色模板，由系统适配深浅菜单栏。
