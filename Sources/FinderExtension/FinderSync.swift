import AppKit
import FinderSync
import Darwin

@objc(ClipboardFinderSync)
final class ClipboardFinderSync: FIFinderSync {
    private let desktop: URL

    override init() {
        // NSHomeDirectory points into the extension sandbox. Resolve the account home instead.
        let home = getpwuid(getuid()).map { String(cString: $0.pointee.pw_dir) } ?? NSHomeDirectory()
        desktop = URL(fileURLWithPath: home, isDirectory: true).appendingPathComponent("Desktop", isDirectory: true)
        super.init()
        FIFinderSyncController.default().directoryURLs = [desktop, desktop.resolvingSymlinksInPath()]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer,
              let target = FIFinderSyncController.default().targetedURL(),
              target.resolvingSymlinksInPath().standardizedFileURL == desktop.resolvingSymlinksInPath().standardizedFileURL else {
            return nil
        }
        let menu = NSMenu(title: "剪贴成文")
        let item = NSMenuItem(title: "将剪贴板保存为文本", action: #selector(saveClipboard), keyEquivalent: "")
        item.target = self
        item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
        menu.addItem(item)
        return menu
    }

    @objc private func saveClipboard() {
        let host = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.open(
            [URL(string: "clipboardtotext://save")!],
            withApplicationAt: host,
            configuration: configuration
        ) { _, error in
            if let error { NSLog("剪贴成文无法启动宿主：%@", error.localizedDescription) }
        }
    }
}
