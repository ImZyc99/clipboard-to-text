import AppKit
import ApplicationServices
import Combine
import OSLog

final class DesktopPasteController: ObservableObject {
    @Published private(set) var enabled: Bool
    @Published private(set) var authorized = false
    @Published private(set) var monitorFailed = false
    private var monitor: Any?
    private var activationObserver: NSObjectProtocol?
    private var timer: Timer?
    private var activationTime = ProcessInfo.processInfo.systemUptime
    private var lastPointerTime: TimeInterval = 0
    private let save: (ClipboardContent) -> Void
    private let reportError: (String) -> Void
    private let logger = Logger(subsystem: "local.clipboardtotext.desktop-paste", category: "shortcut")
    private let settingKey = "desktopPasteEnabled"

    var statusText: String {
        if !enabled { return "已暂停" }
        if !authorized { return "未授权" }
        if monitorFailed { return "监听未启动" }
        return "已开启"
    }

    init(save: @escaping (ClipboardContent) -> Void, reportError: @escaping (String) -> Void) {
        self.save = save
        self.reportError = reportError
        UserDefaults.standard.register(defaults: [settingKey: true])
        enabled = UserDefaults.standard.bool(forKey: settingKey)
    }

    func start() {
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.activationTime = ProcessInfo.processInfo.systemUptime
            self?.refresh()
        }
        // Poll only permission state; never poll the clipboard or AX tree.
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
        refresh()
    }

    func stop() {
        removeMonitor()
        timer?.invalidate()
        timer = nil
        if let observer = activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        activationObserver = nil
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        if authorized != trusted {
            authorized = trusted
            logger.notice("accessibility authorized=\(trusted, privacy: .public)")
        }
        guard enabled, trusted, NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder" else {
            removeMonitor()
            return
        }
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return }
            if event.type != .keyDown {
                self.lastPointerTime = event.timestamp
                return
            }
            self.handle(event)
        }
        monitorFailed = monitor == nil
    }

    func setEnabled(_ newValue: Bool) {
        enabled = newValue
        UserDefaults.standard.set(newValue, forKey: settingKey)
        refresh()
    }

    func enableAndAuthorize() {
        setEnabled(true)
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        refresh()
    }

    private func removeMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if monitorFailed { monitorFailed = false }
    }

    private func handle(_ event: NSEvent) {
        var modifiers: DesktopPastePolicy.Modifiers = []
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.function) { modifiers.insert(.function) }
        guard DesktopPastePolicy.matches(keyCode: event.keyCode, modifiers: modifiers, isRepeat: event.isARepeat),
              enabled, AXIsProcessTrusted(),
              event.timestamp >= activationTime, event.timestamp >= lastPointerTime,
              ProcessInfo.processInfo.systemUptime - event.timestamp < 0.5,
              let finder = NSWorkspace.shared.frontmostApplication,
              finder.bundleIdentifier == "com.apple.finder" else { return }

        guard desktopHasFocus(finder) else {
            logger.notice("paste ignored: desktop focus not confirmed")
            return
        }
        do {
            let content = try ClipboardReader.read()
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == finder.processIdentifier,
                  desktopHasFocus(finder) else { return }
            logger.notice("desktop paste accepted")
            save(content)
        } catch {
            if let error = error as? ClipboardReadError, error.ignoredByShortcut { return }
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == finder.processIdentifier,
                  desktopHasFocus(finder) else { return }
            reportError(error.localizedDescription)
        }
    }

    private func desktopHasFocus(_ finder: NSRunningApplication) -> Bool {
        let app = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(app, 0.1)
        guard let focused = element(app, kAXFocusedUIElementAttribute),
              let children = attribute(app, kAXChildrenAttribute) as? [AXUIElement] else { return false }
        var pid: pid_t = 0
        guard AXUIElementGetPid(focused, &pid) == .success, pid == finder.processIdentifier else { return false }

        let editingRoles: Set<String> = [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole]
        let windowRoles: Set<String> = [kAXWindowRole, kAXSheetRole, kAXMenuRole, kAXMenuBarRole, kAXMenuItemRole]
        let containerRoles: Set<String> = [kAXScrollAreaRole, kAXGroupRole]
        let desktopNames: Set<String> = ["Desktop", "桌面"]
        var current = focused
        for _ in 0..<16 {
            AXUIElementSetMessagingTimeout(current, 0.1)
            guard let role = attribute(current, kAXRoleAttribute) as? String else { return false }
            let editing = editingRoles.contains(role) || (attribute(current, "AXIsEditable") as? Bool == true)
            if !DesktopPastePolicy.acceptsFocus(finderIsFrontmost: true, desktopIsConfirmed: true,
                                               hasWindow: windowRoles.contains(role), isEditing: editing) { return false }
            guard let parent = element(current, kAXParentAttribute) else { return false }
            if CFEqual(parent, app) {
                // A folder called Desktop inside a normal Finder window is not enough:
                // require the non-window desktop container directly under the Finder app.
                let label = attribute(current, kAXDescriptionAttribute) as? String
                let title = attribute(current, kAXTitleAttribute) as? String
                let confirmed = containerRoles.contains(role)
                    && children.contains { CFEqual($0, current) }
                    && (label.map { desktopNames.contains($0) } == true || title.map { desktopNames.contains($0) } == true)
                logger.notice("focus root role=\(role, privacy: .public) desktop=\(confirmed, privacy: .public)")
                return confirmed
            }
            if CFEqual(parent, current) { return false }
            current = parent
        }
        return false
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func element(_ owner: AXUIElement, _ name: String) -> AXUIElement? {
        guard let value = attribute(owner, name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
}
