// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@testable import InternalFlutterSwiftCommon
import Foundation

class StringOutputWriter: OutputWriter {
  var content = ""

  func writeLine(_ message: String) {
    content += "\(message)\n"
  }

  func reset() {
    content = ""
  }
}

@objc public class LoggerTest: NSObject {
  @objc public func testLogsWithNewline() {
    let writer = StringOutputWriter()
    let logger = Logger(outputWriter: writer)
    Logger.logInfo("Hello world")
    if (writer.content != "Hello world") {
      fatalError("Wrong content")
    }
  }
}

