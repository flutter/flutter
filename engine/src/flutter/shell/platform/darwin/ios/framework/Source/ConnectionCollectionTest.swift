// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import XCTest

class ConnectionCollectionTest: XCTestCase {
  func testAcquireAndRelease() {
    let connections = ConnectionCollection()
    let connection = connections.acquireConnection(channel: "foo")
    XCTAssertEqual("foo", connections.cleanup(connection: connection))
    XCTAssertEqual("", connections.cleanup(connection: connection))
  }

  func testErrorConnectionWithNegativeCode() {
    XCTAssertEqual(55, ConnectionCollection.makeErrorConnection(errorCode: 55))
    XCTAssertEqual(55, ConnectionCollection.makeErrorConnection(errorCode: -55))
  }
}
