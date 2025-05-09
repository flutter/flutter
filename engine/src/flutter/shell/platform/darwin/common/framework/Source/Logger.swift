// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Darwin
import Foundation

/// The level of logging severity.
///
/// These levels are used by `Logger` to determine if a message should be output.
/// They are ordered by increasing severity.
@objc(FlutterLogLevel) public enum LogLevel: Int {
  /// Informational messages that are helpful for tracing application flow.
  case info = 0

  /// Messages that highlight significant progress or state changes in the application.
  case important

  /// Messages indicating a potential issue or an unexpected situation that isn't critical.
  case warning

  /// Messages indicating a runtime error from which the application can potentially recover.
  case error

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
/// Logger.setLogLevel = .warning // Only show warnings and above
/// Logger.logError("Failed to load asset: \(assetKey)")
/// ```
@objc(FlutterLogger) public final class Logger: NSObject {
  private static let shared = Logger()
  private let outputWriter: OutputWriter
  private var logLevel = LogLevel.info

  init(outputWriter: OutputWriter) {
    self.outputWriter = outputWriter
  }

  private override convenience init() {
#if os(iOS)
    // On iOS, the user has no access to stdout.
    // Output can be read from the log by the user or the `flutter` tool.
    self.init(outputWriter: SyslogOutputWriter())
#elseif os(macOS)
    // On macOS, both the user and the tool read from stdout.
    self.init(outputWriter: StdoutOutputWriter())
#endif
  }

  private func log(level: LogLevel, _ message: String) {
    if level.rawValue >= logLevel.rawValue {
      outputWriter.writeLine(message)
    }
  }
}

extension Logger {
  /// Sets the minimum log level.
  @objc public static func setLogLevel(_ level: LogLevel) {
    shared.logLevel = level
  }

  /// Logs a message at `LogLevel.info`.
  @objc public static func logInfo(_ message: String) {
    shared.log(level: .info, message)
  }

  /// Logs a message at `LogLevel.important`.
  @objc public static func logImportant(_ message: String) {
    shared.log(level: .important, message)
  }

  /// Logs a message at `LogLevel.warning`.
  @objc public static func logWarning(_ message: String) {
    shared.log(level: .warning, message)
  }

  /// Logs a message at `LogLevel.error`.
  @objc public static func logError(_ message: String) {
    shared.log(level: .error, message)
  }

  /// Logs a message at `LogLevel.fatal` and immediately terminates the application.
  @objc public static func logFatal(_ message: String) {
    shared.log(level: .fatal, message)
    abort()
  }

  /// Logs a message unconditionally.
  @objc public static func logDirect(_ message: String) {
    shared.outputWriter.writeLine(message)
  }
}

protocol OutputWriter {
  func writeLine(_ message: String)
}

final class SyslogOutputWriter: OutputWriter {
  func writeLine(_ message: String) {
    // TODO(cbracken): replace this with os_log-based approach.
    // https://github.com/flutter/flutter/issues/44030
    message.withCString { vsyslog(LOG_ALERT, "%s", getVaList([$0])) }
  }
}

final class StdoutOutputWriter: OutputWriter {
  func writeLine(_ message: String) {
    fputs(message, stdout)
    fputs("\n", stdout)
    fflush(stdout)
  }
}
