import Foundation

enum DesktopPastePolicy {
    struct Modifiers: OptionSet {
        let rawValue: Int
        static let command = Self(rawValue: 1 << 0)
        static let shift = Self(rawValue: 1 << 1)
        static let option = Self(rawValue: 1 << 2)
        static let control = Self(rawValue: 1 << 3)
        static let function = Self(rawValue: 1 << 4)
    }

    static func matches(keyCode: UInt16, modifiers: Modifiers, isRepeat: Bool) -> Bool {
        keyCode == 9 && modifiers == .command && !isRepeat
    }

    static func acceptsFocus(finderIsFrontmost: Bool, desktopIsConfirmed: Bool, hasWindow: Bool, isEditing: Bool) -> Bool {
        finderIsFrontmost && desktopIsConfirmed && !hasWindow && !isEditing
    }

    static func hasFileRepresentation(_ types: Set<String>) -> Bool {
        let files: Set<String> = ["public.file-url", "NSFilenamesPboardType", "NSFilesPromisePboardType",
                                 "com.apple.pasteboard.promised-file-url", "com.apple.pasteboard.promised-file-content-type",
                                 "com.apple.NSFilePromiseItemMetaData"]
        return !types.isDisjoint(with: files)
    }

    static func acceptsText(_ text: String?, types: Set<String>, before: Int, after: Int) -> Bool {
        guard before == after, !hasFileRepresentation(types), let text else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
