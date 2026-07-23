// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import XCTest

@testable import InternalFlutterSwift

/// A mock `Bundle` subclass.
///
/// By default, lacks the `UILaunchStoryboardName` key in its Info.plist.
final class MockBundle: Bundle, @unchecked Sendable {
  var mockInfoDictionary: [String: Any]?
  var mockPaths: [String: String] = [:]

  override init(path: String) {
    // Use the path of the test bundle to ensure valid Bundle.
    // See: https://stackoverflow.com/questions/34898283/mocking-nsbundle-in-swift-tdd
    let testBundle = Bundle(for: MockBundle.self)
    super.init(path: testBundle.bundlePath)!
  }

  override var infoDictionary: [String: Any]? {
    return mockInfoDictionary
  }

  override func path(forResource name: String?, ofType ext: String?) -> String? {
    guard let name = name, let ext = ext else { return nil }
    return mockPaths["\(name).\(ext)"]
  }
}

class SplashScreenManagerTests: XCTestCase {

  /// Verifies `loadDefaultSplashScreenView` fails when the `UILaunchStoryboardName` key is missing.
  func testLoadDefaultSplashScreenViewFailsWhenNoPlistKey() {
    let mockBundle = MockBundle(path: "")
    let manager = SplashScreenManager(bundle: mockBundle)

    XCTAssertFalse(manager.loadDefaultSplashScreenView())
  }

  /// Verifies `loadDefaultSplashScreenView` fails when the storyboard file is not in the bundle.
  func testLoadDefaultSplashScreenViewFailsWhenStoryboardNotFound() {
    let mockBundle = MockBundle(path: "")
    mockBundle.mockInfoDictionary = ["UILaunchStoryboardName": "LaunchScreen"]
    let manager = SplashScreenManager(bundle: mockBundle)

    XCTAssertFalse(manager.loadDefaultSplashScreenView())
  }

  /// Verifies `setSplashScreenView` sets the view and applies autoresizing masks.
  func testSetSplashScreenView() {
    let manager = SplashScreenManager()
    let view = UIView()

    manager.splashScreenView = view

    XCTAssertEqual(manager.splashScreenView, view)
    XCTAssertEqual(view.autoresizingMask, [.flexibleWidth, .flexibleHeight])
  }

  /// Verifies setting `splashScreenView` to nil triggers its removal.
  func testSetSplashScreenViewToNilRemovesIt() {
    let manager = SplashScreenManager()
    let view = UIView()

    manager.splashScreenView = view
    XCTAssertEqual(manager.splashScreenView, view)

    manager.splashScreenView = nil
    XCTAssertNil(manager.splashScreenView)
  }

  /// Verifies `removeSplashScreen` calls the completion block after fading out.
  func testRemoveSplashScreenCallsCompletion() {
    let manager = SplashScreenManager()
    let view = UIView()
    manager.splashScreenView = view

    let expectation = self.expectation(description: "Completion called")

    manager.removeSplashScreen {
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1.0, handler: nil)
    XCTAssertNil(manager.splashScreenView)
  }

  /// Verifies `installSplashScreenView` adds the view to the parent view parent bounds as frame.
  func testInstallSplashScreenView() {
    let manager = SplashScreenManager()
    let view = UIView()
    manager.splashScreenView = view

    let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

    manager.installSplashScreenView(asSubviewOf: parentView)

    XCTAssertEqual(view.superview, parentView)
    XCTAssertEqual(view.frame, parentView.bounds)
  }
}
