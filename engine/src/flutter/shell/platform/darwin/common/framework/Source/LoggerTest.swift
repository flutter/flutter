// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

@testable import InternalFlutterSwiftCommon

/// An `OutputWriter` that stores the most recently logged output in a string.
final class StringOutputWriter: OutputWriter {
  var didLog = false
  var lastLevel: LogLevel!
  var lastLine: String!

  func writeLine(level: LogLevel, _ message: String) {
    didLog = true
    lastLevel = level
    lastLine = message
  }

  func reset() {
    didLog = false
    lastLevel = nil
    lastLine = nil
  }
}

@objc public class LoggerTest: NSObject {

  @objc public func runAllTests() {
    testDefaultLogLevelIsInfo()
    testDoesNotLogMessageBelowLogLevel()
    testLogsMessageAtLogLevel()
    testLogsMessageAboveLevel()
    testLogsImportant()
  }

  func testDefaultLogLevelIsInfo() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer)
    assert(logger.logLevel == .info)
  }

  func testDoesNotLogMessageBelowLogLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer)

    logger.logLevel = .warning
    logger.log(level: .info, "Hello world")
    assert(!writer.didLog)
  }

  func testLogsMessageAtLogLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer)

    logger.logLevel = .info
    logger.log(level: .info, "Hello world")
    assert(writer.didLog)
    assert(writer.lastLevel == .info)
    assert(writer.lastLine == "Hello world")
  }

  func testLogsMessageAboveLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer)

    logger.logLevel = .info
    logger.log(level: .warning, "Hello world")
    assert(writer.didLog)
    assert(writer.lastLevel == .warning)
    assert(writer.lastLine == "Hello world")
  }

  // Verify that important messages are logged, even if log level is set to error.
  func testLogsImportant() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer)

    logger.logLevel = .error
    logger.log(level: .important, "Hello world")
    assert(writer.didLog)
    assert(writer.lastLevel == .important)
    assert(writer.lastLine == "Hello world")
  }

}
