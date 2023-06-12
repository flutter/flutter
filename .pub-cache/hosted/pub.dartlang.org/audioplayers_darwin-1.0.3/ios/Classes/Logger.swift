enum LogLevel: Int {
    case info = 0
    case error = 1
    case none = 2
}

extension LogLevel {
    static func parse(_ value: String) -> LogLevel? {
        switch (value) {
        case "LogLevel.info": return LogLevel.info
        case "LogLevel.error": return LogLevel.error
        case "LogLevel.none": return LogLevel.none
        default: return nil
        }
    }
}

class Logger {
    static var logLevel = LogLevel.error

    static func info(_ items: Any...) {
        _log(.info, items: items)
    }

    static func error(_ items: Any...) {
        _log(.error, items: items)
    }

    static func log(_ level: LogLevel, _ items: Any...) {
        _log(level, items: items)
    }

    static func _log(_ level: LogLevel, items: [Any]) {
        if level.rawValue > logLevel.rawValue {
            return
        }

        let string: String
        if items.count == 1, let s = items.first as? String {
            string = s
        } else if items.count > 1, let format = items.first as? String, let arguments = Array(items[1..<items.count]) as? [CVarArg] {
            string = String(format: format, arguments: arguments)
        } else {
            string = ""
        }
        
        debugPrint(string)
    }
}
