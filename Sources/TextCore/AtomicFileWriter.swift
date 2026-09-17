import Foundation
import Darwin

// Callers supply a sanitized name and a fixed extension; never accepts a full path.
enum AtomicFileWriter {
    static func save(_ data: Data, baseName: String, fileExtension: String, to directory: URL) throws -> URL {
        // Publish a fully written inode with link(), which atomically refuses to replace any existing path.
        var template = Array(directory.appendingPathComponent(".clipboardtotext-XXXXXX").path.utf8CString)
        let descriptor = template.withUnsafeMutableBufferPointer { mkstemp($0.baseAddress!) }
        guard descriptor >= 0 else { throw posixError() }
        let temporary = URL(fileURLWithPath: String(cString: template))
        defer { try? FileManager.default.removeItem(at: temporary) }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        try handle.write(contentsOf: data)
        try handle.synchronize()
        try handle.close()

        for number in 1...100_000 {
            let suffix = number == 1 ? "" : " \(number)"
            let destination = directory.appendingPathComponent("\(baseName)\(suffix).\(fileExtension)")
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
