// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardToText",
    platforms: [.macOS(.v13)],
    products: [.library(name: "TextCore", targets: ["TextCore"])],
    targets: [
        .target(name: "TextCore")
    ]
)
