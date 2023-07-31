// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void assertStatement(Object x) {
  assert((x is int ? /*int*/ x : throw 'foo') == 0);
  // x is not promoted because the assertion won't execute in release
  // mode.
  x;
}

void promotionInConditionCarriesToMessage(Object x) {
  // Code in the message part of an assertion can assume that the
  // condition evaluated to false.
  assert(x is! int, /*int*/ x.toString());
}

class C {
  C.assertInitializer(Object x)
      : assert((x is int ? /*int*/ x : throw 'foo') == 0) {
    // x is not promoted because the assertion won't execute in release
    // mode.
    x;
  }

  C.promotionInConditionCarriesToMessage(Object x)
      : assert(x is! int, /*int*/ x.toString());
}
