// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void condition_false(Object x) {
  while (x is! String) {
    x;
  }
  /*String*/ x;
}

void condition_true(Object x) {
  while (x is String) {
    /*String*/ x;
  }
  x;
}

void outerIsType(bool b, Object x) {
  if (x is String) {
    while (b) {
      /*String*/ x;
    }
    /*String*/ x;
  }
}

void outerIsType_loopAssigned_body(bool b, Object x) {
  if (x is String) {
    while (b) {
      x;
      x = (x as String).length;
    }
    x;
  }
}

void outerIsType_loopAssigned_condition(bool b, Object x) {
  if (x is String) {
    while (x != 0) {
      x;
      x = (x as String).length;
    }
    x;
  }
}
