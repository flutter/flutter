// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import InternalFlutterSwiftCommon
import Testing

@Suite struct TracingTest {

  @Test func testTraceScopeExecutesWork() {
    var workExecuted = false

    Tracing.traceScope("TestScope") {
      workExecuted = true
    }

    #expect(workExecuted)
  }

  @Test func testTracePlatformVsyncDoesNotCrash() {
    Tracing.tracePlatformVsync(withStartTime: 1000, targetTime: 2000)
  }

  @Test func testTraceAsyncDoesNotCrash() {
    Tracing.traceAsyncBegin("TestAsyncEvent", eventId: 123)
    Tracing.traceAsyncEnd("TestAsyncEvent", eventId: 123)
  }
}
