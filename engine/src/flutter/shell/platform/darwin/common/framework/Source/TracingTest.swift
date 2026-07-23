// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import InternalFlutterSwiftCommon
import Testing

@Suite struct TracingTest {

  @Test func testTracePlatformVsyncDoesNotCrash() {
    Tracing.tracePlatformVsync(
      withStartTime: .microseconds(1000),
      targetTime: .microseconds(2000)
    )
  }

  @Test func testTraceAsyncDoesNotCrash() {
    Tracing.traceAsyncBegin("TestAsyncEvent", eventID: 123)
    Tracing.traceAsyncEnd("TestAsyncEvent", eventID: 123)
  }

  @Test func testWithTraceExecutesWorkAndReturns() {
    var workExecuted = false
    let result = Tracing.withTrace("TestScope") { () -> Int in
      workExecuted = true
      return 42
    }
    #expect(workExecuted)
    #expect(result == 42)
  }

  @Test func testWithTracePropagatesThrows() {
    struct DummyError: Error {}
    #expect(throws: DummyError.self) {
      try Tracing.withTrace("TestScope") {
        throw DummyError()
      }
    }
  }

  @Test func testTraceScopeTokenDoesNotCrash() {
    let scope = Tracing.beginScope("TestScope")
    defer { scope.end() }
  }
}

extension TimeInterval {
  fileprivate static func microseconds(_ value: Int) -> TimeInterval {
    return Double(value) / 1_000_000.0
  }
}
