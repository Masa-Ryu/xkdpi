import Foundation

/// ログレベル
public enum LogLevel: String, Sendable {
    case debug = "DEBUG"
    case info  = "INFO"
    case error = "ERROR"
}

/// 標準出力へのシンプルなロガー
public struct Logger: Sendable {

    private let label: String

    public init(label: String = "xkdpi") {
        self.label = label
    }

    public func log(_ level: LogLevel, _ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] [\(label)] \(message)")
    }

    public func info(_ message: String)  { log(.info,  message) }
    public func debug(_ message: String) { log(.debug, message) }
    public func error(_ message: String) { log(.error, message) }
}
