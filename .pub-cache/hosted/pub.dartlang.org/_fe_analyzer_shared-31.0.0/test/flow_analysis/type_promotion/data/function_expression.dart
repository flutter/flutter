// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void isType() {
  void g(Object x) {
    if (x is String) {
      /*String*/ x;
    }
  }
}

void isType_mutatedInClosure() {
  void g(Object x) {
    if (x is String) {
      /*String*/ x;
    }
    x = 42;
  }
}

void isType_mutatedInclosure2() {
  void g(Object x) {
    if (x is String) {
      /*String*/ x;
    }

    void h() {
      x = 42;
    }

    if (x is String) {
      x;
    }
  }
}

void outerIsType_assignedOutside(Object x, void Function() g) {
  if (x is String) {
    /*String*/ x;

    g = () {
      x;
    };
  }

  x = 42;
  x;
  g();
}
