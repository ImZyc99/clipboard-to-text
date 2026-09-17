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
