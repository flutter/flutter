// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

@testable import shared_preferences_foundation

class RunnerTests: XCTestCase {
  func testSetAndGet() throws {
    let plugin = SharedPreferencesPlugin()

    plugin.setBool(key: "flutter.aBool", value: true)
    plugin.setDouble(key: "flutter.aDouble", value: 3.14)
    plugin.setValue(key: "flutter.anInt", value: 42)
    plugin.setValue(key: "flutter.aString", value: "hello world")
    plugin.setValue(key: "flutter.aStringList", value: ["hello", "world"])

    let storedValues = plugin.getAll()
    XCTAssertEqual(storedValues["flutter.aBool"] as? Bool, true)
    XCTAssertEqual(storedValues["flutter.aDouble"] as! Double, 3.14, accuracy: 0.0001)
    XCTAssertEqual(storedValues["flutter.anInt"] as? Int, 42)
    XCTAssertEqual(storedValues["flutter.aString"] as? String, "hello world")
    XCTAssertEqual(storedValues["flutter.aStringList"] as? Array<String>, ["hello", "world"])
  }

  func testRemove() throws {
    let plugin = SharedPreferencesPlugin()
    let testKey = "flutter.foo"
    plugin.setValue(key: testKey, value: 42)

    // Make sure there is something to remove, so the test can't pass due to a set failure.
    let preRemovalValues = plugin.getAll()
    XCTAssertEqual(preRemovalValues[testKey] as? Int, 42)

    // Then verify that removing it works.
    plugin.remove(key: testKey)

    let finalValues = plugin.getAll()
    XCTAssertNil(finalValues[testKey] as Any?)
  }

  func testClear() throws {
    let plugin = SharedPreferencesPlugin()
    let testKey = "flutter.foo"
    plugin.setValue(key: testKey, value: 42)

    // Make sure there is something to clear, so the test can't pass due to a set failure.
    let preRemovalValues = plugin.getAll()
    XCTAssertEqual(preRemovalValues[testKey] as? Int, 42)

    // Then verify that clearing works.
    plugin.clear()

    let finalValues = plugin.getAll()
    XCTAssertNil(finalValues[testKey] as Any?)
  }
}
