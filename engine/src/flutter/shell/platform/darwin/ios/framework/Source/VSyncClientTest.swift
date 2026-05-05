// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

class VSyncClientTest: XCTestCase {
  var threadTaskRunner: TaskRunner!

  override func setUp() {
    super.setUp()
    threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "VSyncClientTest")
  }

  override func tearDown() {
    threadTaskRunner = nil
    super.tearDown()
  }

  func testSetAllowPauseAfterVsyncCorrect() {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }!
    let link = vsyncClient.displayLink

    vsyncClient.allowPauseAfterVsync = false
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    XCTAssertFalse(link.isPaused)

    vsyncClient.allowPauseAfterVsync = true
    vsyncClient.await()
    vsyncClient.onDisplayLink(link)
    XCTAssertTrue(link.isPaused)
  }

  func testSetCorrectVariableRefreshRates() {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: true,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }!
    let link = vsyncClient.displayLink

    if #available(iOS 15.0, *) {
      XCTAssertEqual(Double(link.preferredFrameRateRange.maximum), maxFrameRate, accuracy: 0.1)
      XCTAssertEqual(
        Double(link.preferredFrameRateRange.preferred ?? 0), maxFrameRate, accuracy: 0.1)
      XCTAssertEqual(Double(link.preferredFrameRateRange.minimum), maxFrameRate / 2, accuracy: 0.1)
    } else {
      XCTAssertEqual(Double(link.preferredFramesPerSecond), maxFrameRate, accuracy: 0.1)
    }
  }

  func testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn() {
    let maxFrameRate: Double = 120.0
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: maxFrameRate
    ) { _, _ in }!
    let link = vsyncClient.displayLink

    if #available(iOS 15.0, *) {
      XCTAssertEqual(Double(link.preferredFrameRateRange.maximum), 0, accuracy: 0.1)
      XCTAssertEqual(Double(link.preferredFrameRateRange.preferred ?? 0), 0, accuracy: 0.1)
      XCTAssertEqual(Double(link.preferredFrameRateRange.minimum), 0, accuracy: 0.1)
    } else {
      XCTAssertEqual(Double(link.preferredFramesPerSecond), 0, accuracy: 0.1)
    }
  }

  func testAwaitAndPauseWillWorkCorrectly() {
    let vsyncClient = VSyncClient(
      taskRunner: threadTaskRunner,
      isVariableRefreshRateEnabled: false,
      maxRefreshRate: 60.0
    ) { _, _ in }!
    let link = vsyncClient.displayLink

    XCTAssertTrue(link.isPaused)
    vsyncClient.await()
    XCTAssertFalse(link.isPaused)
    vsyncClient.pause()
    XCTAssertTrue(link.isPaused)
  }

  func testReleasesLinkOnInvalidation() {
    let threadTaskRunner = TaskRunnerTestHelper.makeTaskRunner(withLabel: "FlutterVSyncClientTest")
    weak var weakClient: VSyncClient?

    autoreleasepool {
      let vsyncExpectation = expectation(description: "vsync")
      let client = VSyncClient(
        taskRunner: threadTaskRunner,
        isVariableRefreshRateEnabled: false,
        maxRefreshRate: 60.0
      ) { _, _ in
        vsyncExpectation.fulfill()
      }!
      weakClient = client

      threadTaskRunner.postTask {
        client.await()
      }

      waitForExpectations(timeout: 1.0, handler: nil)

      client.invalidate()
    }

    let backgroundThreadFlushed = expectation(description: "Background thread flushed")
    threadTaskRunner.postTask {
      backgroundThreadFlushed.fulfill()
    }

    waitForExpectations(timeout: 1.0, handler: nil)
    XCTAssertNil(weakClient)
  }
}
