// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void condition_isNotType(Object x) {
  do {
    x;
  } while (x is! String);
  /*String*/ x;
}

void condition_isType(Object x) {
  do {
    x;
  } while (x is String);
  x;
}

void outerIsType(bool b, Object x) {
  if (x is String) {
    do {
      /*String*/ x;
    } while (b);
    /*String*/ x;
  }
}

void outerIsType_loopAssigned_body(bool b, Object x) {
  if (x is String) {
    do {
      x;
      x = (x as String).length;
    } while (b);
    x;
  }
}

void outerIsType_loopAssigned_condition(bool b, Object x) {
  if (x is String) {
    do {
      x;
      x = (x as String).length;
    } while (x != 0);
    x;
  }
}

void outerIsType_loopAssigned_condition2(bool b, Object x) {
  if (x is String) {
    do {
      x;
    } while ((x = 1) != 0);
    x;
  }
}
