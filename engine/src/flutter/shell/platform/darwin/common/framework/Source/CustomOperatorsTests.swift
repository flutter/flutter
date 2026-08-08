// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwiftCommon
import Testing

@Suite struct `??= Operator Test` {
  @Test func `The operator assigns and has a return value`() {
    var value: String?
    let evaluated = value ??= "hello"
    #expect(value == "hello")
    #expect(evaluated == "hello")
  }

  @Test func `rhs is only evaluated if lhs is nil`() {
    var evaluationCount = 0
    func evaluate() -> String {
      evaluationCount += 1
      return "rhs"
    }

    var lhs: String? = "lhs"
    #expect((lhs ??= evaluate()) == "lhs")
    #expect(evaluationCount == 0)

    lhs = nil
    #expect((lhs ??= evaluate()) == "rhs")
    #expect(evaluationCount == 1)
  }
}
