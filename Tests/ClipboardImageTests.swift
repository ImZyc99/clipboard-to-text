import AppKit
import ImageIO
import UniformTypeIdentifiers

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

private func expectFailure(_ action: () throws -> Void) {
    do { try action() } catch { return }
    fatalError("Expected failure")
}

private func fixture(_ type: UTType, orientation: Int = 1) -> Data {
    // Six distinct pixels, including fully and partly transparent samples.
    let pixels: [UInt8] = [255,0,0,255, 0,255,0,128, 0,0,255,0,
                           255,255,0,255, 0,255,255,255, 255,0,255,255]
    let provider = CGDataProvider(data: Data(pixels) as CFData)!
    let image = CGImage(width: 3, height: 2, bitsPerComponent: 8, bitsPerPixel: 32,
                        bytesPerRow: 12, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                        provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation,
                                                   kCGImagePropertyDPIWidth: 144,
                                                   kCGImagePropertyDPIHeight: 144] as CFDictionary)
    require(CGImageDestinationFinalize(destination), "Fixture encode")
    return data as Data
}

private func decode(_ data: Data) -> CGImage {
    let source = CGImageSourceCreateWithData(data as CFData, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}

private func rgba(_ image: CGImage) -> Data {
    var bytes = Data(count: image.width * image.height * 4)
    bytes.withUnsafeMutableBytes { buffer in
        let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    return bytes
}

private func withPasteboard(_ body: (NSPasteboard) throws -> Void) rethrows {
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    try body(pasteboard)
}

@main
struct ClipboardImageTests {
    static func main() throws {
        let png = fixture(.png)
        let tiff = fixture(.tiff)
        let jpeg = fixture(.jpeg)
        let normalized = try ImageFileWriter.pngData(from: png)
        require(normalized == png, "PNG original bytes must be preserved")
        print("PASS: PNG original bytes")

        let convertedTIFF = decode(try ImageFileWriter.pngData(from: tiff))
        require(convertedTIFF.width == 3 && convertedTIFF.height == 2, "144 DPI TIFF must retain pixel dimensions")
        require(rgba(convertedTIFF) == rgba(decode(tiff)), "TIFF transparent pixels must be preserved")
        print("PASS: TIFF full pixel dimensions and transparency")

        let convertedJPEG = decode(try ImageFileWriter.pngData(from: jpeg))
        require(convertedJPEG.width == 3 && convertedJPEG.height == 2, "JPEG dimensions")
        require(rgba(convertedJPEG) == rgba(decode(jpeg)), "JPEG decoded pixels must not undergo lossy recompression")
        let rotated = decode(try ImageFileWriter.pngData(from: fixture(.jpeg, orientation: 6)))
        require(rotated.width == 2 && rotated.height == 3, "EXIF rotation must swap pixel dimensions")
        print("PASS: JPEG lossless PNG output and EXIF direction")

        for bad in [Data(), Data("not an image".utf8), Data(png.prefix(png.count / 2))] {
            expectFailure { _ = try ImageFileWriter.pngData(from: bad) }
        }
        print("PASS: invalid and truncated images rejected")

        try withPasteboard { board in
            let first = NSPasteboardItem()
            first.setData(tiff, forType: .tiff)
            first.setString("https://example.com/picture", forType: .string)
            let second = NSPasteboardItem()
            second.setData(fixture(.png, orientation: 6), forType: .png)
            board.writeObjects([first, second])
            guard case let .image(data) = try ClipboardReader.read(from: board) else { fatalError("Image must beat attached URL") }
            require(rgba(decode(data)) == rgba(decode(tiff)), "Representations must stay within first image item")
            board.clearContents()
            let fallback = NSPasteboardItem()
            fallback.setData(Data("bad".utf8), forType: .png)
            fallback.setData(tiff, forType: .tiff)
            board.writeObjects([fallback])
            guard case .image = try ClipboardReader.read(from: board) else { fatalError("Valid TIFF alternative") }
            board.clearContents()
            board.setString("https://example.com/picture", forType: .string)
            guard case let .text(value) = try ClipboardReader.read(from: board) else { fatalError("URL only stays text") }
            require(value == "https://example.com/picture", "URL content preserved")
        }
        print("PASS: image before text, first item, alternate representation, URL remains text")

        try withPasteboard { board in
            for fileType in [NSPasteboard.PasteboardType.fileURL,
                             NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url")] {
                board.clearContents()
                let imageItem = NSPasteboardItem()
                imageItem.setData(png, forType: .png)
                let fileItem = NSPasteboardItem()
                fileItem.setString("file:///fixture.png", forType: fileType)
                board.writeObjects([imageItem, fileItem])
                do { _ = try ClipboardReader.read(from: board); fatalError("File must take precedence") }
                catch ClipboardReadError.files { }
            }
            board.clearContents()
            let corrupt = NSPasteboardItem()
            corrupt.setData(Data("bad".utf8), forType: .png)
            corrupt.setString("attached text", forType: .string)
            board.writeObjects([corrupt])
            do { _ = try ClipboardReader.read(from: board); fatalError("Corrupt image must not fall back to text") }
            catch ClipboardReadError.invalidImage { }
            board.clearContents()
            board.setData(png, forType: .png)
            do {
                _ = try ClipboardReader.read(from: board, imageDecoder: { data in
                    board.clearContents()
                    board.setString("new clipboard", forType: .string)
                    return try ImageFileWriter.pngData(from: data)
                })
                fatalError("Changing clipboard must invalidate snapshot")
            } catch ClipboardReadError.changed { }
        }
        print("PASS: files/promises, corruption and stale clipboard guards")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        let first = try ImageFileWriter.save(png, to: directory, date: date)
        let original = try Data(contentsOf: first)
        let secondName = first.deletingPathExtension().lastPathComponent + " 2.png"
        try FileManager.default.createDirectory(at: directory.appendingPathComponent(secondName), withIntermediateDirectories: false)
        let third = try ImageFileWriter.save(png, to: directory, date: date)
        require(third.lastPathComponent.hasSuffix(" 3.png"), "Image file/directory collisions must advance suffix")
        require(tryData(first) == original, "Original image must remain unchanged")
        require(tryData(third) == png, "Saved PNG bytes")
        let lock = NSLock()
        var failures = 0
        DispatchQueue.concurrentPerform(iterations: 12) { _ in
            do { _ = try ImageFileWriter.save(png, to: directory, date: date) }
            catch { lock.lock(); failures += 1; lock.unlock() }
        }
        let entries = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        require(failures == 0 && entries.count == 15, "Concurrent PNG saves must remain separate")
        require(!entries.contains { $0.hasPrefix(".") }, "No temporary files left")
        expectFailure { _ = try ImageFileWriter.save(png, to: directory.appendingPathComponent("missing"), date: date) }
        print("PASS: PNG save, file/directory collisions, concurrency and failure cleanup")
        print("All 7 image acceptance groups passed; general clipboard untouched.")
    }

    private static func tryData(_ url: URL) -> Data { try! Data(contentsOf: url) }
}
