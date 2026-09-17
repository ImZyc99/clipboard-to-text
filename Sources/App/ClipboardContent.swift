import AppKit
import UniformTypeIdentifiers

enum ClipboardContent {
    case text(String)
    case image(Data)
}

enum ClipboardReadError: LocalizedError {
    case empty, files, changed, invalidImage, imageTooLarge

    var errorDescription: String? {
        switch self {
        case .empty: return "请先复制文字或图片，再试一次。"
        case .files: return "你复制的是文件，请在桌面直接按 ⌘V 粘贴。"
        case .changed: return "剪贴板内容刚刚发生变化，请重新保存。"
        case .invalidImage: return "这张图片的数据不完整或格式暂不支持，请重新复制图片后再试。"
        case .imageTooLarge: return "图片过大，暂时无法保存。请使用不超过 256 MB、约 1 亿像素的图片。"
        }
    }

    var ignoredByShortcut: Bool {
        switch self {
        case .empty, .files, .changed: return true
        default: return false
        }
    }
}

enum ClipboardReader {
    static func read(from pasteboard: NSPasteboard = .general,
                     imageDecoder: (Data) throws -> Data = ImageFileWriter.pngData) throws -> ClipboardContent {
        let before = pasteboard.changeCount
        do {
            let content = try readContent(from: pasteboard, imageDecoder: imageDecoder)
            guard pasteboard.changeCount == before else { throw ClipboardReadError.changed }
            return content
        } catch {
            guard pasteboard.changeCount == before else { throw ClipboardReadError.changed }
            throw error
        }
    }

    private static func readContent(from pasteboard: NSPasteboard,
                                    imageDecoder: (Data) throws -> Data) throws -> ClipboardContent {
        let items = pasteboard.pasteboardItems ?? []
        var types = Set((pasteboard.types ?? []).map(\.rawValue))
        for item in items { types.formUnion(item.types.map(\.rawValue)) }
        guard !DesktopPastePolicy.hasFileRepresentation(types),
              types.isDisjoint(with: Set(NSFilePromiseReceiver.readableDraggedTypes)) else {
            throw ClipboardReadError.files
        }

        for item in items {
            let images = orderedImageTypes(item.types)
            if !images.isEmpty { return .image(try decode(types: images, getData: item.data, imageDecoder: imageDecoder)) }
        }
        // Legacy single-item pasteboards may expose data without NSPasteboardItem objects.
        if items.isEmpty {
            let images = orderedImageTypes(pasteboard.types ?? [])
            if !images.isEmpty { return .image(try decode(types: images, getData: pasteboard.data, imageDecoder: imageDecoder)) }
        }
        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ClipboardReadError.empty }
        return .text(text)
    }

    private static func orderedImageTypes(_ types: [NSPasteboard.PasteboardType]) -> [NSPasteboard.PasteboardType] {
        let preferred: [NSPasteboard.PasteboardType] = [.png, .tiff, .init(UTType.jpeg.identifier)]
        let images = types.filter { UTType($0.rawValue)?.conforms(to: .image) == true }
        return preferred.filter { images.contains($0) } + images.filter { !preferred.contains($0) }
    }

    private static func decode(types: [NSPasteboard.PasteboardType],
                               getData: (NSPasteboard.PasteboardType) -> Data?,
                               imageDecoder: (Data) throws -> Data) throws -> Data {
        var tooLarge = false
        for type in types {
            guard let data = getData(type) else { continue }
            do { return try imageDecoder(data) }
            catch ImageFileWriter.ImageError.tooLarge { tooLarge = true }
            catch { continue }
        }
        throw tooLarge ? ClipboardReadError.imageTooLarge : ClipboardReadError.invalidImage
    }
}
