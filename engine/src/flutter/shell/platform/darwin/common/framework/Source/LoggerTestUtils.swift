// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import InternalFlutterSwiftCommon

/// An `OutputWriter` that stores the most recently logged output in a string.
@objc(FlutterStringOutputWriter)
public final class StringOutputWriter: NSObject, OutputWriter {
  @objc public var didLog = false
  public var lastLevel: LogLevel!
  @objc public var lastLine: String!
  @objc public var expectedOutput: String?
  @objc public var gotExpectedOutput = false

  public func writeLine(level: LogLevel, _ message: String) {
    didLog = true
    lastLevel = level
    lastLine = message
    if let expectedOutput, message.contains(expectedOutput) {
      gotExpectedOutput = true
    }
  }

  @objc public func reset() {
    didLog = false
    lastLevel = nil
    lastLine = nil
    expectedOutput = nil
    gotExpectedOutput = false
  }
}
