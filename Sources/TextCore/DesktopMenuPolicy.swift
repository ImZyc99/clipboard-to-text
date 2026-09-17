import Foundation

enum DesktopMenuPolicy {
    enum Kind { case items, container, other }

    static func shouldShow(kind: Kind, target: URL?, desktop: URL) -> Bool {
        guard kind == .items || kind == .container, let target else { return false }
        return target.resolvingSymlinksInPath().standardizedFileURL == desktop.resolvingSymlinksInPath().standardizedFileURL
    }
}
