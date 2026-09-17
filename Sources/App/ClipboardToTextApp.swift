import AppKit
import SwiftUI
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var receivedCommand = false

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于剪贴成文", action: #selector(showSettings), keyEquivalent: ",").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出剪贴成文", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = menu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, !self.receivedCommand else { return }
            self.showSettings()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard urls.contains(where: {
            $0.scheme == "clipboardtotext" && $0.host == "save" &&
            ($0.path.isEmpty || $0.path == "/") && $0.query == nil && $0.fragment == nil &&
            $0.user == nil && $0.password == nil && $0.port == nil
        }) else { return }
        receivedCommand = true
        saveClipboard()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @objc private func showSettings() {
        NSApp.setActivationPolicy(.regular)
        if window == nil {
            let content = SetupView(save: { [weak self] in self?.saveClipboard() })
            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 440),
                styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false
            )
            newWindow.title = "剪贴成文"
            newWindow.contentView = NSHostingView(rootView: content)
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            window = newWindow
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func saveClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("请先复制一段文字", detail: "在微信、飞书或其他应用中复制口播稿、提示词，再试一次。图片和文件暂不支持。")
            return
        }
        do {
            let desktop = try FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let saved = try TextFileWriter.save(text, to: desktop)
            NSWorkspace.shared.activateFileViewerSelecting([saved])
        } catch {
            showError("文本未能保存", detail: "\(error.localizedDescription)\n\n请检查桌面是否可写、磁盘空间是否充足，以及系统设置中的桌面访问权限。")
        }
    }

    private func showError(_ title: String, detail: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }
}

// Disambiguate the property wrapper from the SDK 27 State macro when building with CLT.
private typealias ViewState<Value> = SwiftUI.State<Value>

private struct SetupView: View {
    let save: () -> Void
    @ViewState private var extensionEnabled = FIFinderSyncController.isExtensionEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("剪贴成文").font(.title2.bold())
                    Text("复制好文字，右键存下来。")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 13) {
                step("1", "复制口播稿或提示词")
                step("2", "在桌面空白处右键")
                step("3", "选择「将剪贴板保存为文本」")
            }

            Divider()

            HStack {
                Label(extensionEnabled ? "桌面右键扩展已启用" : "首次使用，请启用右键扩展",
                      systemImage: extensionEnabled ? "checkmark.circle.fill" : "info.circle")
                    .foregroundStyle(extensionEnabled ? Color.green : Color.secondary)
                    .font(.callout)
                Spacer()
                Button("去启用") { FIFinderSyncController.showExtensionManagementInterface() }
            }

            Text("自动取第一行作文件名，保存为 TXT。原文与换行完整保留，重名自动加序号。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("立即保存剪贴板", action: save)
                    .buttonStyle(.borderedProminent)
                Button("打开桌面") {
                    if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
                        NSWorkspace.shared.open(desktop)
                    }
                }
                Spacer()
            }

            Text("只在点击保存时读取剪贴板 · 所有内容留在本机")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 480)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            extensionEnabled = FIFinderSyncController.isExtensionEnabled
        }
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.06), in: Circle())
            Text(text).font(.body)
        }
    }
}
