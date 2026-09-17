import Foundation
import Darwin

final class TextFileWriterTests {
    private var directory: URL!

    func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testPreservesOriginalBytesAndFirstNonemptyLine() throws {
        let text = "\r\n  \n口播稿 👨‍👩‍👧‍👦\r\n\r\n第一段：你好！\r第二段\u{2028}结束  \n"
        let result = try TextFileWriter.save(text, to: directory)
        checkEqual(result.lastPathComponent, "口播稿 👨‍👩‍👧‍👦.txt")
        checkEqual(try Data(contentsOf: result), Data(text.utf8))
    }

    func testFilenameSafetyAndFallback() {
        checkEqual(TextFileWriter.baseName(for: " ../提示:词/示例\t\n正文"), "提示-词-示例")
        checkEqual(TextFileWriter.baseName(for: "...\n正文"), "未命名")
        checkEqual(TextFileWriter.baseName(for: "  标题  \n正文"), "标题")
        let name = TextFileWriter.baseName(for: String(repeating: "👨‍👩‍👧‍👦", count: 200))
        checkLessOrEqual(name.count, 60)
        checkLessOrEqual(name.utf8.count, 180)
        checkFalse(name.isEmpty)
        checkTrue(String(repeating: "👨‍👩‍👧‍👦", count: 200).hasPrefix(name))
    }

    func testBlankTextCreatesNothing() throws {
        for text in ["", " \n\r\t", "\u{3000}\u{2028}"] {
            checkThrows(try TextFileWriter.save(text, to: directory))
        }
        checkEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testExistingFileDirectoryAndSymlinkAreNotOverwritten() throws {
        let original = directory.appendingPathComponent("标题.txt")
        try Data("旧内容".utf8).write(to: original)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("标题 2.txt"), withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: directory.appendingPathComponent("标题 3.txt"), withDestinationURL: original)
        let saved = try TextFileWriter.save("标题\n新内容", to: directory)
        checkEqual(saved.lastPathComponent, "标题 4.txt")
        checkEqual(try String(contentsOf: original, encoding: .utf8), "旧内容")
        checkEqual(try String(contentsOf: saved, encoding: .utf8), "标题\n新内容")
    }

    func testConcurrentSavesNeverOverwriteAndLeaveNoTemporaryFiles() throws {
        let lock = NSLock()
        var errors: [Error] = []
        DispatchQueue.concurrentPerform(iterations: 20) { index in
            do { _ = try TextFileWriter.save("并发标题\n内容 \(index)", to: directory) }
            catch { lock.lock(); errors.append(error); lock.unlock() }
        }
        checkTrue(errors.isEmpty, "\(errors)")
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        checkEqual(files.count, 20)
        let contents = try Set(files.map { try String(contentsOf: $0, encoding: .utf8) })
        checkEqual(contents.count, 20)
        checkTrue(files.allSatisfy { $0.pathExtension == "txt" })
    }

    func testInvalidDirectoryAndReadOnlyDirectoryFailCleanly() throws {
        checkThrows(try TextFileWriter.save("稿件", to: directory.appendingPathComponent("missing")))
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: directory.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path) }
        checkThrows(try TextFileWriter.save("稿件", to: directory))
        checkEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testLargeTextSavesWithinTwoSeconds() throws {
        let text = "长口播稿\n" + String(repeating: "中文🙂\n", count: 25_000)
        let started = Date()
        let file = try TextFileWriter.save(text, to: directory)
        checkLess(Date().timeIntervalSince(started), 2)
        checkEqual(try Data(contentsOf: file), Data(text.utf8))
    }

    func testDesktopContextMenuKindsAndScope() throws {
        let desktop = directory.appendingPathComponent("Desktop", isDirectory: true)
        try FileManager.default.createDirectory(at: desktop, withIntermediateDirectories: false)
        let alias = directory.appendingPathComponent("DesktopAlias", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: desktop)
        // Finder returned item callbacks for the desktop target; the old container-only guard rejected them.
        for kind in [DesktopMenuPolicy.Kind.items, .container] {
            checkTrue(DesktopMenuPolicy.shouldShow(kind: kind, target: desktop, desktop: desktop))
            checkTrue(DesktopMenuPolicy.shouldShow(kind: kind, target: alias, desktop: desktop))
            checkFalse(DesktopMenuPolicy.shouldShow(kind: kind, target: nil, desktop: desktop))
            checkFalse(DesktopMenuPolicy.shouldShow(kind: kind, target: directory, desktop: desktop))
            checkFalse(DesktopMenuPolicy.shouldShow(kind: kind, target: desktop.appendingPathComponent("Subfolder"), desktop: desktop))
        }
        checkFalse(DesktopMenuPolicy.shouldShow(kind: .other, target: desktop, desktop: desktop))
    }

    func testDesktopPasteShortcutAndFocusBoundaries() {
        checkTrue(DesktopPastePolicy.matches(keyCode: 9, modifiers: .command, isRepeat: false))
        for modifiers: DesktopPastePolicy.Modifiers in [[], .shift, [.command, .shift], [.command, .option], [.command, .control], [.command, .function]] {
            checkFalse(DesktopPastePolicy.matches(keyCode: 9, modifiers: modifiers, isRepeat: false))
        }
        checkFalse(DesktopPastePolicy.matches(keyCode: 9, modifiers: .command, isRepeat: true))
        checkFalse(DesktopPastePolicy.matches(keyCode: 8, modifiers: .command, isRepeat: false))
        checkTrue(DesktopPastePolicy.acceptsFocus(finderIsFrontmost: true, desktopIsConfirmed: true, hasWindow: false, isEditing: false))
        checkFalse(DesktopPastePolicy.acceptsFocus(finderIsFrontmost: false, desktopIsConfirmed: true, hasWindow: false, isEditing: false))
        checkFalse(DesktopPastePolicy.acceptsFocus(finderIsFrontmost: true, desktopIsConfirmed: false, hasWindow: false, isEditing: false))
        checkFalse(DesktopPastePolicy.acceptsFocus(finderIsFrontmost: true, desktopIsConfirmed: true, hasWindow: true, isEditing: false))
        checkFalse(DesktopPastePolicy.acceptsFocus(finderIsFrontmost: true, desktopIsConfirmed: true, hasWindow: false, isEditing: true))
    }

    func testDesktopPastePreservesFilesAndIgnoresUnstableClipboard() {
        for type in ["public.file-url", "NSFilenamesPboardType", "NSFilesPromisePboardType", "com.apple.pasteboard.promised-file-url", "com.apple.pasteboard.promised-file-content-type", "com.apple.NSFilePromiseItemMetaData"] {
            checkTrue(DesktopPastePolicy.hasFileRepresentation([type, "public.utf8-plain-text"]))
            checkFalse(DesktopPastePolicy.acceptsText("/a/file.txt", types: [type], before: 4, after: 4))
        }
        checkTrue(DesktopPastePolicy.acceptsText("提示词\n正文🙂", types: ["public.utf8-plain-text"], before: 4, after: 4))
        checkTrue(DesktopPastePolicy.acceptsText("https://example.com", types: ["public.url", "public.utf8-plain-text"], before: 4, after: 4))
        checkFalse(DesktopPastePolicy.acceptsText("文字", types: [], before: 4, after: 5))
        checkFalse(DesktopPastePolicy.acceptsText(nil, types: ["public.png"], before: 4, after: 4))
        checkFalse(DesktopPastePolicy.acceptsText(" \n", types: [], before: 4, after: 4))
    }
}

private func checkEqual<T: Equatable>(_ a: T, _ b: T, file: StaticString = #filePath, line: UInt = #line) {
    guard a == b else { fatalError("Expected equal values at \(file):\(line)") }
}
private func checkTrue(_ value: Bool, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    guard value else { fatalError("Expected true \(message) at \(file):\(line)") }
}
private func checkFalse(_ value: Bool) { checkTrue(!value) }
private func checkLess<T: Comparable>(_ a: T, _ b: T) { checkTrue(a < b) }
private func checkLessOrEqual<T: Comparable>(_ a: T, _ b: T) { checkTrue(a <= b) }
private func checkThrows<T>(_ value: @autoclosure () throws -> T) {
    do { _ = try value() } catch { return }
    fatalError("Expected an error")
}

@main
struct TestRunner {
    static func main() {
        let suite = TextFileWriterTests()
        let tests: [(String, () throws -> Void)] = [
            ("preserves original bytes", suite.testPreservesOriginalBytesAndFirstNonemptyLine),
            ("safe Unicode filenames", suite.testFilenameSafetyAndFallback),
            ("blank input", suite.testBlankTextCreatesNothing),
            ("existing file, directory, symlink", suite.testExistingFileDirectoryAndSymlinkAreNotOverwritten),
            ("20 concurrent saves", suite.testConcurrentSavesNeverOverwriteAndLeaveNoTemporaryFiles),
            ("invalid and read-only directory", suite.testInvalidDirectoryAndReadOnlyDirectoryFailCleanly),
            ("100,000 characters under 2 seconds", suite.testLargeTextSavesWithinTwoSeconds),
            ("desktop item and background menu scope", suite.testDesktopContextMenuKindsAndScope),
            ("desktop paste shortcut and focus boundaries", suite.testDesktopPasteShortcutAndFocusBoundaries),
            ("desktop paste file and clipboard guards", suite.testDesktopPastePreservesFilesAndIgnoresUnstableClipboard)
        ]
        for (name, test) in tests {
            do {
                try suite.setUpWithError()
                defer { try? suite.tearDownWithError() }
                try test()
                print("PASS: \(name)")
            } catch {
                print("FAIL: \(name): \(error)")
                exit(1)
            }
        }
        print("All \(tests.count) acceptance tests passed.")
    }
}
