// Development-only repair for this solid rounded tile, not arbitrary transparent artwork.
// Usage: swift scripts/fix-icon-opacity.swift input.png output.png
import AppKit

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: fix-icon-opacity.swift input.png output.png")
}
let source = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = URL(fileURLWithPath: CommandLine.arguments[2])
let data = try Data(contentsOf: source)
guard let bitmap = NSBitmapImageRep(data: data),
      bitmap.bitsPerSample == 8, bitmap.samplesPerPixel == 4,
      !bitmap.isPlanar, bitmap.hasAlpha,
      bitmap.bitmapFormat.contains(.alphaNonpremultiplied),
      !bitmap.bitmapFormat.contains(.alphaFirst),
      let pixels = bitmap.bitmapData else {
    fatalError("Expected an 8-bit, unpremultiplied RGBA PNG")
}

var repaired = 0
for y in 0..<bitmap.pixelsHigh {
    let row = y * bitmap.bytesPerRow
    // Near-opaque pixels identify both ends of the solid tile on this scanline.
    // Fill all interior alpha, including any internal holes, while preserving
    // the outer antialiased edge. RGB bytes are never changed.
    let solid = (0..<bitmap.pixelsWide).filter { pixels[row + $0 * 4 + 3] >= 250 }
    guard let left = solid.first, let right = solid.last else { continue }
    for x in left...right {
        let offset = row + x * 4 + 3
        if pixels[offset] != 255 { repaired += 1 }
        pixels[offset] = 255
    }
}
guard let output = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}
try output.write(to: destination, options: .atomic)
print("Repaired \(repaired) alpha values; RGB and exterior transparency preserved.")
