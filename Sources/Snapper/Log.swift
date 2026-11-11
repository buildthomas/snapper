import Foundation
import os

/// File log at ~/Library/Logs/Snapper/snapper.log (also mirrored to the unified log, subsystem com.thoeksema.Snapper).
/// Records lifecycle and errors. Never logs key presses, window titles or window contents.
enum Log {
    private static let queue = DispatchQueue(label: "snapper.log")
    private static let osLog = Logger(subsystem: "com.thoeksema.Snapper", category: "app")
    private static let maxBytes = 1_000_000

    static var directory: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/Snapper") }
    static var file: URL { directory.appendingPathComponent("snapper.log") }

    static func info(_ message: String) { write("INFO ", message) }
    static func error(_ message: String) { write("ERROR", message) }
    /// Waits for pending writes (before an early exit).
    static func flush() { queue.sync {} }

    private static func write(_ level: String, _ message: String) {
        let line = "\(timestamp()) \(level) \(message)\n"
        osLog.log("\(level, privacy: .public) \(message, privacy: .public)")
        if ProcessInfo.processInfo.environment["SNAPPER_LOG_STDERR"] == "1" { FileHandle.standardError.write(Data(line.utf8)) }
        queue.async {
            let fm = FileManager.default
            try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
            if let size = (try? fm.attributesOfItem(atPath: file.path))?[.size] as? Int, size > maxBytes {
                let old = directory.appendingPathComponent("snapper.1.log")
                try? fm.removeItem(at: old)
                try? fm.moveItem(at: file, to: old)
            }
            if !fm.fileExists(atPath: file.path) { fm.createFile(atPath: file.path, contents: nil) }
            if let h = try? FileHandle(forWritingTo: file) {
                h.seekToEndOfFile()
                h.write(Data(line.utf8))
                try? h.close()
            }
        }
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}
