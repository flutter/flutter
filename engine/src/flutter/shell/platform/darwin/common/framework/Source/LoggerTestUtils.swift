// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
@testable import InternalFlutterSwiftCommon

/// An `OutputWriter` that stores the most recently logged output in a string.
@objc(FlutterStringOutputWriter)
final class StringOutputWriter: NSObject, OutputWriter, @unchecked Sendable {
  @objc var didLog = false
  var lastLevel: LogLevel!
  @objc var lastLine: String!
  @objc var expectedOutput: String?
  @objc var gotExpectedOutput = false

  func writeLine(level: LogLevel, _ message: String) {
    didLog = true
    lastLevel = level
    lastLine = message
    if let expectedOutput, message.contains(expectedOutput) {
      gotExpectedOutput = true
    }
  }

  @objc func reset() {
    didLog = false
    lastLevel = nil
    lastLine = nil
    expectedOutput = nil
    gotExpectedOutput = false
  }
}
