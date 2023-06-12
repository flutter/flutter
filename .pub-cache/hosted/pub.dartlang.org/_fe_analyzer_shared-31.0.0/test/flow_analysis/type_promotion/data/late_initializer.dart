// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that a variable assigned in the initializer of a late
// variable is considered captured, just as it would be if the assignment
// appeared inside a closure.

eagerVariableInitializerDoesNotCapture(Object x) {
  f() {
    if (x is String) {
      // Promotion is ok because we know exactly when x might change.
      /*String*/ x;
    }
  }

  int y = (x = 0);
  if (x is String) {
    /*String*/ x;
  }
  f();
}

lateVariableInitializerCaptures(Object x) {
  f() {
    if (x is String) {
      // x is not promoted because its value might change at any time.
      x;
    }
  }

  late int y = (x = 0);
  if (x is String) {
    // x is not promoted because its value might change at any time.
    x;
  }
  f();
}
