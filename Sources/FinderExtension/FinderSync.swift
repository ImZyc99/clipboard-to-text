import AppKit
import FinderSync
import Darwin
import OSLog

@objc(ClipboardFinderSync)
final class ClipboardFinderSync: FIFinderSync {
    private let desktop: URL
    private let logger = Logger(subsystem: "local.clipboardtotext.finder", category: "menu")

    override init() {
        // NSHomeDirectory points into the extension sandbox. Resolve the account home instead.
        let home = getpwuid(getuid()).map { String(cString: $0.pointee.pw_dir) } ?? NSHomeDirectory()
        desktop = URL(fileURLWithPath: home, isDirectory: true).appendingPathComponent("Desktop", isDirectory: true)
        super.init()
        FIFinderSyncController.default().directoryURLs = [desktop, desktop.resolvingSymlinksInPath()]
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        logger.notice("Finder extension build \(version, privacy: .public) started")
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let targetURL = FIFinderSyncController.default().targetedURL()
        let selected = FIFinderSyncController.default().selectedItemURLs() ?? []
        let targetIsDesktop = targetURL?.resolvingSymlinksInPath().standardizedFileURL == desktop.resolvingSymlinksInPath().standardizedFileURL
        let desktopSelected = selected.contains { $0.resolvingSymlinksInPath().standardizedFileURL == desktop.resolvingSymlinksInPath().standardizedFileURL }
        logger.notice("menu kind=\(menuKind.rawValue, privacy: .public) targetPresent=\(targetURL != nil, privacy: .public) targetDesktop=\(targetIsDesktop, privacy: .public) selectionCount=\(selected.count, privacy: .public) desktopSelected=\(desktopSelected, privacy: .public)")
        let kind: DesktopMenuPolicy.Kind
        switch menuKind {
        case .contextualMenuForItems: kind = .items
        case .contextualMenuForContainer: kind = .container
        default: kind = .other
        }
        let showMenu = DesktopMenuPolicy.shouldShow(kind: kind, target: targetURL, desktop: desktop)
        logger.notice("menu visible=\(showMenu, privacy: .public)")
        guard showMenu else { return nil }
        let menu = NSMenu(title: "剪贴成文")
        let item = NSMenuItem(title: "将剪贴板保存到桌面", action: #selector(saveClipboard), keyEquivalent: "")
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
