import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageFileWriter {
    enum ImageError: Error { case invalid, tooLarge }

    static func pngData(from data: Data) throws -> Data {
        guard data.count <= 256 * 1024 * 1024 else { throw ImageError.tooLarge }
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0,
              CGImageSourceGetStatus(source) == .statusComplete,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw ImageError.invalid }
        guard width <= 100 * 1024 * 1024 / height else { throw ImageError.tooLarge }

        let isPNG = CGImageSourceGetType(source) as String? == UTType.png.identifier
        if isPNG && CGImageSourceGetCount(source) == 1 {
            // Preserve PNG bytes, including metadata and alpha; still require a real decode.
            guard CGImageSourceCreateImageAtIndex(source, 0,
                    [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) != nil,
                  CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else { throw ImageError.invalid }
            return data
        }

        // Full pixel-size transform handles EXIF orientation without Retina point-size scaling.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(width, height),
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else { throw ImageError.invalid }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        let rotated = (5...8).contains(orientation)
        guard image.width == (rotated ? height : width), image.height == (rotated ? width : height) else {
            throw ImageError.invalid
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else {
            throw ImageError.invalid
        }
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: 1] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ImageError.invalid }
        return output as Data
    }

    // png is the validated snapshot from ClipboardReader.
    static func save(_ png: Data, to directory: URL, date: Date = Date()) throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return try AtomicFileWriter.save(png, baseName: "图片 " + formatter.string(from: date),
                                         fileExtension: "png", to: directory)
    }
}
