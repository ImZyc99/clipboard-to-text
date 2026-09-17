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
        return try AtomicFileWriter.save(Data(text.utf8), baseName: name, fileExtension: "txt", to: directory)
    }
}
