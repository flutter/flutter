// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The tests in this file exercise various kinds of constructs that initialize a
// variable at its declaration site.  We verify that the variable is not
// considered "written to" for purposes of defeating type promotions inside
// closures.

parameter(Object a) {
  if (a is int) {
    () {
      /*int*/ a;
    };
  }
}

localParameter() {
  localFunction(Object a) {
    if (a is int) {
      () {
        /*int*/ a;
      };
    }
  }

  (Object b) {
    if (b is int) {
      () {
        /*int*/ b;
      };
    }
  };
}

localVariable() {
  Object a = 1;
  if (a is int) {
    () {
      /*int*/ a;
    };
  }
}

class MyStackTrace implements StackTrace {
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

catchParameters() {
  try {} on Object catch (e, st) {
    if (e is int) {
      () {
        /*int*/ e;
      };
    }
    if (st is MyStackTrace) {
      () {
        /*MyStackTrace*/ st;
      };
    }
  }
}
