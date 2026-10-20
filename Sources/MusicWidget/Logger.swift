import Foundation

/// Logging basico a consola: [timestamp] action provider result
enum Log {
    private static let fmt: ISO8601DateFormatter = ISO8601DateFormatter()

    static func info(_ action: String, provider: String, result: String = "ok") {
        print("[\(fmt.string(from: Date()))] action=\(action) provider=\(provider) result=\(result)")
    }

    static func error(_ action: String, provider: String, error: String) {
        print("[\(fmt.string(from: Date()))] action=\(action) provider=\(provider) result=error error=\(error)")
    }
}
