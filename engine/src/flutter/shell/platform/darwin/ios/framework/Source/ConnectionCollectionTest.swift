// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import Testing

struct ConnectionCollectionTest {
  @Test func acquireAndRelease() {
    let connections = ConnectionCollection()
    let connectionID = connections.acquireConnection(forChannel: "foo")
    #expect(connectionID > 0)
    #expect("foo" == connections.cleanupConnection(withID: connectionID))
    #expect("" == connections.cleanupConnection(withID: connectionID))
  }

  @Test func uniqueIDs() {
    let connections = ConnectionCollection()
    let firstConnectionID = connections.acquireConnection(forChannel: "foo")
    let secondConnectionID = connections.acquireConnection(forChannel: "bar")
    #expect(firstConnectionID != secondConnectionID)
    #expect("foo" == connections.cleanupConnection(withID: firstConnectionID))
    #expect("bar" == connections.cleanupConnection(withID: secondConnectionID))
  }

  @Test func errorConnectionWithNegativeCode() {
    #expect(55 == ConnectionCollection.makeErrorConnection(errorCode: 55))
    #expect(55 == ConnectionCollection.makeErrorConnection(errorCode: -55))
  }
}

