// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import XCTest

class ConnectionCollectionTest: XCTestCase {
  func testAcquireAndRelease() {
    let connections = ConnectionCollection()
    let connectionID = connections.acquireConnection(forChannel: "foo")
    XCTAssertGreaterThan(connectionID, 0)
    XCTAssertEqual("foo", connections.cleanupConnection(withID: connectionID))
    XCTAssertEqual("", connections.cleanupConnection(withID: connectionID))
  }

  func testUniqueIDs() {
    let connections = ConnectionCollection()
    let firstConnectionID = connections.acquireConnection(forChannel: "foo")
    let secondConnectionID = connections.acquireConnection(forChannel: "bar")
    XCTAssertNotEqual(firstConnectionID, secondConnectionID)
    XCTAssertEqual("foo", connections.cleanupConnection(withID: firstConnectionID))
    XCTAssertEqual("bar", connections.cleanupConnection(withID: secondConnectionID))
  }

  func testErrorConnectionWithNegativeCode() {
    XCTAssertEqual(55, ConnectionCollection.makeErrorConnection(errorCode: 55))
    XCTAssertEqual(55, ConnectionCollection.makeErrorConnection(errorCode: -55))
  }
}
