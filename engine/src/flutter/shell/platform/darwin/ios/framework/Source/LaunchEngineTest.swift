// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import XCTest

class LaunchEngineTest: XCTestCase {

  /// Verifies that the engine is lazily created on first access, cached on subsequent accesses, and
  /// successfully transferred when taken, leaving the container empty.
  func testEngineAccessAndOwnershipTransfer() {
    let launchEngine = LaunchEngine()

    // The engine should be created on first access.
    let firstAccessEngine = launchEngine.acquireEngine()
    XCTAssertNotNil(firstAccessEngine)

    // Subsequent accesses should return the same cached instance.
    XCTAssertTrue(
      launchEngine.acquireEngine() === firstAccessEngine, "Should return the cached engine instance.")

    // The taken engine should be the same instance that was created.
    let takenEngine = launchEngine.takeEngine()
    XCTAssertTrue(takenEngine === firstAccessEngine, "Should return the original engine instance.")

    // The container should be empty after the engine is taken.
    XCTAssertNil(launchEngine.acquireEngine(), "Engine should be nil after being taken.")
    XCTAssertNil(launchEngine.takeEngine(), "Subsequent takes should return nil.")
  }

  /// Verifies that calling takeEngine before accessing the engine returns nil and prevents any
  /// future lazy allocation of the engine.
  func testTakeBeforeAccessReturnsNilAndPreventsAllocation() {
    let launchEngine = LaunchEngine()

    // Taking ownership before access should return nil.
    let takenEngine = launchEngine.takeEngine()
    XCTAssertNil(takenEngine, "Taking before access should return nil.")

    // Accessing the engine after it was taken should return nil without allocating a new one.
    XCTAssertNil(launchEngine.acquireEngine(), "Accessing engine after take should return nil.")
  }
}
