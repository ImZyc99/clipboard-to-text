import Foundation
import Darwin

public enum TextFileWriter {
    public enum SaveError: LocalizedError {
        case emptyText
        public var errorDescription: String? { "请先复制一段文字。" }
    }

    public static func baseName(for text: String) -> String {
        let line = text.split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? ""
        let sanitized = String(String.UnicodeScalarView(line.unicodeScalars.compactMap { scalar in
            if scalar.properties.generalCategory == .control { return nil }
            if "/:\\".unicodeScalars.contains(scalar) { return Unicode.Scalar("-") }
            return scalar
        }))
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".-")))
        var result = ""
        for character in trimmed.prefix(60) {
            let next = String(character)
            guard result.utf8.count + next.utf8.count <= 180 else { break }
            result.append(character)
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "未命名" : result
    }

    public static func save(_ text: String, to directory: URL) throws -> URL {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw SaveError.emptyText }
        let name = baseName(for: text)
        // Publish a fully written inode with link(), which atomically refuses to replace any existing path.
        var template = Array(directory.appendingPathComponent(".clipboardtotext-XXXXXX").path.utf8CString)
        let descriptor = template.withUnsafeMutableBufferPointer { mkstemp($0.baseAddress!) }
        guard descriptor >= 0 else { throw posixError() }
        let temporary = URL(fileURLWithPath: String(cString: template))
        defer { try? FileManager.default.removeItem(at: temporary) }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        try handle.write(contentsOf: Data(text.utf8))
        try handle.synchronize()
        try handle.close()

        for number in 1...100_000 {
            let suffix = number == 1 ? "" : " \(number)"
            let destination = directory.appendingPathComponent("\(name)\(suffix).txt")
            let status = temporary.withUnsafeFileSystemRepresentation { source in
                destination.withUnsafeFileSystemRepresentation { target in link(source!, target!) }
            }
            if status == 0 { return destination }
            let code = errno
            if code != EEXIST { throw posixError(code) }
        }
        throw CocoaError(.fileWriteFileExists)
    }

    private static func posixError(_ code: Int32 = errno) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }
}
