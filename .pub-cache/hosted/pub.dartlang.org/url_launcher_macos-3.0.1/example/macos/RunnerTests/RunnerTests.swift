// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import FlutterMacOS
import XCTest
import url_launcher_macos

/// A stub to simulate the system Url handler.
class StubWorkspace: SystemURLHandler {

  var isSuccessful = true

  func open(_ url: URL) -> Bool {
    return isSuccessful
  }

  func urlForApplication(toOpen: URL) -> URL? {
    return toOpen
  }
}

class RunnerTests: XCTestCase {

  func testCanLaunchSuccessReturnsTrue() throws {
    let expectation = XCTestExpectation(description: "Check if the URL can be launched")
    let plugin = UrlLauncherPlugin()

    let call = FlutterMethodCall(
      methodName: "canLaunch",
      arguments: ["url": "https://flutter.dev"])

    plugin.handle(
      call,
      result: { (result: Any?) -> Void in
        XCTAssertEqual(result as? Bool, true)
        expectation.fulfill()
      })

    wait(for: [expectation], timeout: 10.0)
  }

  func testCanLaunchNoAppIsAbleToOpenUrlReturnsFalse() throws {
    let expectation = XCTestExpectation(description: "Check if the URL can be launched")
    let plugin = UrlLauncherPlugin()

    let call = FlutterMethodCall(
      methodName: "canLaunch",
      arguments: ["url": "example://flutter.dev"])

    plugin.handle(
      call,
      result: { (result: Any?) -> Void in
        XCTAssertEqual(result as? Bool, false)
        expectation.fulfill()
      })

    wait(for: [expectation], timeout: 10.0)
  }

  func testCanLaunchInvalidUrlReturnsFalse() throws {
    let expectation = XCTestExpectation(description: "Check if the URL can be launched")
    let plugin = UrlLauncherPlugin()

    let call = FlutterMethodCall(
      methodName: "canLaunch",
      arguments: ["url": "brokenUrl"])

    plugin.handle(
      call,
      result: { (result: Any?) -> Void in
        XCTAssertEqual(result as? Bool, false)
        expectation.fulfill()
      })

    wait(for: [expectation], timeout: 10.0)
  }

  func testCanLaunchMissingArgumentReturnsFlutterError() throws {
    let expectation = XCTestExpectation(description: "Check if the URL can be launched")
    let plugin = UrlLauncherPlugin()

    let call = FlutterMethodCall(
      methodName: "canLaunch",
      arguments: [])

    plugin.handle(
      call,
      result: { (result: Any?) -> Void in
        XCTAssertTrue(result is FlutterError)
        expectation.fulfill()
      })

    wait(for: [expectation], timeout: 10.0)
  }

  func testLaunchSuccessReturnsTrue() throws {
    let expectation = XCTestExpectation(description: "Try to open the URL")
    let workspace = StubWorkspace()
    let pluginWithStubWorkspace = UrlLauncherPlugin(workspace)

    let call = FlutterMethodCall(
      methodName: "launch",
      arguments: ["url": "https://flutter.dev"])

    pluginWithStubWorkspace.handle(
      call,
      result: { (result: Any?) -> Void in
        XCTAssertEqual(result as? Bool, true)
        expectation.fulfill()
      })

    wait(for: [expectation], timeout: 10.0)
  }

  func testLaunchNoAppIsAbleToOpenUrlReturnsFalse() throws {
    let expectation = XCTestExpectation(description: "Try to open the URL")
    let workspace = StubWorkspace()
    workspace.isSuccessful = false
    let pluginWithStubWorkspace = UrlLauncherPlugin(workspace)

    let call = FlutterMethodCall(
      methodName: "launch",
      arguments: ["url": "schemethatdoesnotexist://flutter.dev"])

    pluginWithStubWorkspace.handle(
      call,
      result: { (result: Any?) -> Void in
        XCTAssertEqual(result as? Bool, false)
        expectation.fulfill()
      })

    wait(for: [expectation], timeout: 10.0)
  }

  func testLaunchMissingArgumentReturnsFlutterError() throws {
    let expectation = XCTestExpectation(description: "Try to open the URL")
    let workspace = StubWorkspace()
    let pluginWithStubWorkspace = UrlLauncherPlugin(workspace)

    let call = FlutterMethodCall(
      methodName: "launch",
      arguments: [])

    pluginWithStubWorkspace.handle(
      call,
      result: { (result: Any?) -> Void in
        XCTAssertTrue(result is FlutterError)
        expectation.fulfill()
      })

    wait(for: [expectation], timeout: 10.0)
  }
}
