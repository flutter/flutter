// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Darwin
import Foundation
import os

/// The level of logging severity.
///
/// These levels are used by `Logger` to determine if a message should be output.
/// They are ordered by increasing severity.
@objc(FlutterLogLevel) enum LogLevel: Int, Sendable {
  /// Informational messages that are helpful for tracing application flow.
  case info

  /// Messages indicating a potential issue or an unexpected situation that isn't critical.
  case warning

  /// Messages indicating a runtime error from which the application can potentially recover.
  case error

  /// Messages that, while not an error, highlight significant progress or state changes in the
  /// application, and must be logged.
  case important

  /// Messages indicating a critical condition. Causes the application to immediately terminate.
  case fatal
}

/// A singleton logger for outputting runtime messages.
///
/// This logger allows for messages to be logged at different severity levels. Its output can be
/// filtered by setting the `logLevel` property to the minimum log level to be logged.
///
/// **Usage:**
/// ```swift
/// Logger.logInfo("Application has started.")
/// Logger.logLevel = .warning  // Only show warnings and above
/// Logger.logError("Failed to load asset: \(assetKey)")
/// ```
@objc(FlutterLogger) final class Logger: NSObject, @unchecked Sendable {
  private static let shared = Logger()
  private let lock = NSLock()
  private var _outputWriter: OutputWriter
  private var _logLevel: LogLevel

  var outputWriter: OutputWriter {
    get {
      return lock.withLock { _outputWriter }
    }
    set {
      lock.withLock {
        _outputWriter = newValue
      }
    }
  }

  var logLevel: LogLevel {
    get {
      return lock.withLock { _logLevel }
    }
    set {
      lock.withLock {
        _logLevel = newValue
      }
    }
  }

  init(outputWriter: OutputWriter, logLevel: LogLevel) {
    self._outputWriter = outputWriter
    self._logLevel = logLevel
    super.init()
  }

  override convenience init() {
    #if os(iOS)
      // On iOS, the user has no access to stdout.
      // Output can be read from the log by the user or the `flutter` tool.
      self.init(outputWriter: OSLogOutputWriter(), logLevel: .info)
    #elseif os(macOS)
      // On macOS, both the user and the tool read from stdout.
      self.init(outputWriter: StdoutOutputWriter(), logLevel: .info)
    #endif
  }

  func log(level: LogLevel, _ message: @autoclosure () -> String) {
    guard level.rawValue >= logLevel.rawValue else { return }

    // Evaluate outside the lock keep lock time minimal and to guard against the possibility of
    // someone accidentally calling the Logger from within the autoclosure.
    let line = message()
    lock.withLock {
      _outputWriter.writeLine(level: level, line)
    }
  }

  func logDirect(_ message: String) {
    lock.withLock {
      _outputWriter.writeLine(level: .important, message)
    }
  }
}

extension Logger {
  /// Sets the minimum log level.
  @objc static var outputWriter: OutputWriter {
    get { return shared.outputWriter }
    set(newValue) { shared.outputWriter = newValue }
  }

  /// Sets the minimum log level.
  @objc static var logLevel: LogLevel {
    get { return shared.logLevel }
    set(newValue) { shared.logLevel = newValue }
  }

  /// Logs a message at `LogLevel.info`.
  @available(swift, obsoleted: 1.0)
  @objc(logInfo:) static func objcLogInfo(_ message: String) {
    shared.log(level: .info, message)
  }

  /// Logs a message at `LogLevel.info`.
  static func logInfo(_ message: @autoclosure () -> String) {
    shared.log(level: .info, message())
  }

  /// Logs a message at `LogLevel.important`.
  @available(swift, obsoleted: 1.0)
  @objc(logImportant:) static func objcLogImportant(_ message: String) {
    shared.log(level: .important, message)
  }

  /// Logs a message at `LogLevel.important`.
  static func logImportant(_ message: @autoclosure () -> String) {
    shared.log(level: .important, message())
  }

  /// Logs a message at `LogLevel.warning`.
  @available(swift, obsoleted: 1.0)
  @objc(logWarning:) static func objcLogWarning(_ message: String) {
    shared.log(level: .warning, message)
  }

  /// Logs a message at `LogLevel.warning`.
  static func logWarning(_ message: @autoclosure () -> String) {
    shared.log(level: .warning, message())
  }

  /// Logs a message at `LogLevel.error`.
  @available(swift, obsoleted: 1.0)
  @objc(logError:) static func objcLogError(_ message: String) {
    shared.log(level: .error, message)
  }

  /// Logs a message at `LogLevel.error`.
  static func logError(_ message: @autoclosure () -> String) {
    shared.log(level: .error, message())
  }

  /// Logs a message at `LogLevel.fatal` and immediately terminates the application.
  @available(swift, obsoleted: 1.0)
  @objc(logFatal:) static func objcLogFatal(_ message: String) {
    shared.log(level: .fatal, message)
    abort()
  }

  /// Logs a message at `LogLevel.fatal` and immediately terminates the application.
  static func logFatal(_ message: @autoclosure () -> String) {
    shared.log(level: .fatal, message())
    abort()
  }

  /// Logs a message unconditionally.
  @objc static func logDirect(_ message: String) {
    shared.logDirect(message)
  }
}

@objc(FlutterOutputWriter)
protocol OutputWriter: Sendable {
  func writeLine(level: LogLevel, _ message: String)
}

private extension LogLevel {
  /// The `OSLogType` used to emit a message at this level via `os_log`.
  ///
  /// `OSLogType` is not a strict severity ladder like `LogLevel`. It's a small set of categories
  /// with differing persistence and display behavior. Each level therefore maps to the type with
  /// the closest semantics rather than a matching severity.
  ///
  /// - `.info` is buffered in memory and not written to persistent store by default.
  /// - `.warning` is written to persistent store.
  /// - `.error` is logged with error metadata and is written to persistent store.
  /// - `.important` is used by Dart `print` output, so is written to persistent store.
  /// - `.fatal` is logged with fault metadata and is written to persistent store.
  var osLogType: OSLogType {
    switch self {
    case .info: return .info
    case .warning: return .default
    case .error: return .error
    case .important: return .default
    case .fatal: return .fault
    }
  }
}

final class OSLogOutputWriter: OutputWriter, Sendable {
  private let osLog = OSLog(subsystem: "io.flutter.flutter", category: "flutter")

  func writeLine(level: LogLevel, _ message: String) {
    os_log("%{public}@", log: osLog, type: level.osLogType, message)
  }
}

final class StdoutOutputWriter: OutputWriter, Sendable {
  func writeLine(level: LogLevel, _ message: String) {
    fputs(message, stdout)
    fputs("\n", stdout)
    fflush(stdout)
  }
}
