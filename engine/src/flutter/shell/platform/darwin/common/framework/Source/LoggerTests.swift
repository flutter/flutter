// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import InternalFlutterSwiftCommon
import Testing
import test_utils_swift

// Several tests mutate shared `Logger` singleton properties (`outputWriter`, `logLevel`).
// Even though those mutations are all lock-guarded and thread-safe, we serialize the tests to keep
// them from racing each other.
@Suite(.serialized) struct LoggerTests {

  @Test func testInitialization() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer, logLevel: .info)
    #expect(logger.logLevel == .info)
  }

  @Test func testDoesNotLogMessageBelowLogLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer, logLevel: .warning)

    logger.log(level: .info, "Hello world")
    #expect(!writer.didLog)
  }

  @Test func testLogsMessageAtLogLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer, logLevel: .info)

    logger.log(level: .info, "Hello world")
    #expect(writer.didLog)
    #expect(writer.lastLevel == .info)
    #expect(writer.lastLine == "Hello world")
  }

  @Test func testLogsMessageAboveLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer, logLevel: .info)

    logger.log(level: .warning, "Hello world")
    #expect(writer.didLog)
    #expect(writer.lastLevel == .warning)
    #expect(writer.lastLine == "Hello world")
  }

  // Verify that important messages are logged, even if log level is set to error.
  @Test func testLogsImportant() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer, logLevel: .error)

    logger.log(level: .important, "Hello world")
    #expect(writer.didLog)
    #expect(writer.lastLevel == .important)
    #expect(writer.lastLine == "Hello world")
  }

  @Test func testAutoclosureDoesNotEvaluateMessageBelowLogLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer, logLevel: .warning)
    var wasEvaluated = false

    logger.log(
      level: .info,
      {
        wasEvaluated = true
        return "Hello world"
      }())
    #expect(!writer.didLog)
    #expect(!wasEvaluated)
  }

  @Test func testAutoclosureEvaluatesMessageAtOrAboveLogLevel() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer, logLevel: .info)
    var wasEvaluated = false

    logger.log(
      level: .info,
      {
        wasEvaluated = true
        return "Hello world"
      }())
    #expect(writer.didLog)
    #expect(wasEvaluated)
  }

  @Test func testStaticLogInfoDoesNotEvaluateMessageBelowLogLevel() {
    let writer = StringOutputWriter()
    let oldWriter = Logger.outputWriter
    let oldLevel = Logger.logLevel
    defer {
      Logger.outputWriter = oldWriter
      Logger.logLevel = oldLevel
    }
    Logger.outputWriter = writer
    Logger.logLevel = .warning
    var wasEvaluated = false

    Logger.logInfo(
      {
        wasEvaluated = true
        return "Hello world"
      }())
    #expect(!writer.didLog)
    #expect(!wasEvaluated)
  }

  // Hammers the shared `Logger` from concurrent tasks so that unsynchronised access to mutable
  // state is caught under TSan.
  @Test func testConcurrentLoggingAndLevelMutation() async {
    let writer = StringOutputWriter()
    let oldWriter = Logger.outputWriter
    let oldLevel = Logger.logLevel
    defer {
      Logger.outputWriter = oldWriter
      Logger.logLevel = oldLevel
    }
    Logger.outputWriter = writer
    Logger.logLevel = .info

    await withTaskGroup(of: Void.self) { group in
      for i in 0..<100 {
        group.addTask {
          if i % 2 == 0 {
            Logger.logLevel = .warning
          } else {
            Logger.logLevel = .info
          }
          Logger.logInfo("Message \(i)")
        }
      }
    }

    // After concurrent mutations and logging, Logger should remain in a valid state without data
    // races or crashes.
    #expect(Logger.logLevel == .info || Logger.logLevel == .warning)
  }

  @Test func testDefaultInitialization() {
    let logger = Logger()
    #expect(logger.logLevel == .info)
    logger.log(level: .info, "Test default logger")
  }
}
