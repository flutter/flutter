// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import InternalFlutterSwiftCommon
import Testing

@Suite struct CustomOperatorsTests {

  @Test func testAssignsWhenNilAndReturnsNewValue() {
    var value: String? = nil
    let evaluated = value ??= "hello"
    #expect(value == "hello")
    #expect(evaluated == "hello")
  }

  @Test func testDoesNotAssignWhenNonNilAndEvaluatesLazily() {
    var value: String? = "existing"
    var sideEffectRun = false

    func computeValue() -> String {
      sideEffectRun = true
      return "new"
    }

    let result = value ??= computeValue()
    #expect(value == "existing")
    #expect(result == "existing")
    #expect(!sideEffectRun)
  }
}
