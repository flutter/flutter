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
  let prefixes: [String] = ["aPrefix", ""]

  func testSetAndGet() throws {
    for aPrefix in prefixes {
      let plugin = SharedPreferencesPlugin()

      plugin.setBool(key: "\(aPrefix)aBool", value: true)
      plugin.setDouble(key: "\(aPrefix)aDouble", value: 3.14)
      plugin.setValue(key: "\(aPrefix)anInt", value: 42)
      plugin.setValue(key: "\(aPrefix)aString", value: "hello world")
      plugin.setValue(key: "\(aPrefix)aStringList", value: ["hello", "world"])

      let storedValues = plugin.getAllWithPrefix(prefix: aPrefix)
      XCTAssertEqual(storedValues["\(aPrefix)aBool"] as? Bool, true)
      XCTAssertEqual(storedValues["\(aPrefix)aDouble"] as! Double, 3.14, accuracy: 0.0001)
      XCTAssertEqual(storedValues["\(aPrefix)anInt"] as? Int, 42)
      XCTAssertEqual(storedValues["\(aPrefix)aString"] as? String, "hello world")
      XCTAssertEqual(storedValues["\(aPrefix)aStringList"] as? Array<String>, ["hello", "world"])
    }
  }

  func testRemove() throws {
    for aPrefix in prefixes {
      let plugin = SharedPreferencesPlugin()
      let testKey = "\(aPrefix)foo"
      plugin.setValue(key: testKey, value: 42)

      // Make sure there is something to remove, so the test can't pass due to a set failure.
      let preRemovalValues = plugin.getAllWithPrefix(prefix: aPrefix)
      XCTAssertEqual(preRemovalValues[testKey] as? Int, 42)

      // Then verify that removing it works.
      plugin.remove(key: testKey)

      let finalValues = plugin.getAllWithPrefix(prefix: aPrefix)
      XCTAssertNil(finalValues[testKey] as Any?)
    }
  }

  func testClear() throws {
    for aPrefix in prefixes {
      let plugin = SharedPreferencesPlugin()
      let testKey = "\(aPrefix)foo"
      plugin.setValue(key: testKey, value: 42)

      // Make sure there is something to clear, so the test can't pass due to a set failure.
      let preRemovalValues = plugin.getAllWithPrefix(prefix: aPrefix)
      XCTAssertEqual(preRemovalValues[testKey] as? Int, 42)

      // Then verify that clearing works.
      plugin.clearWithPrefix(prefix: aPrefix)

      let finalValues = plugin.getAllWithPrefix(prefix: aPrefix)
      XCTAssertNil(finalValues[testKey] as Any?)
    }
  }
  
}
