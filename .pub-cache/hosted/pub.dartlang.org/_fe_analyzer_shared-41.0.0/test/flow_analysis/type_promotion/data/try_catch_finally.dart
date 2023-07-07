// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void g() {}

void outerIsType(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
    } catch (_) {
      /*String*/ x;
    } finally {
      /*String*/ x;
    }
    /*String*/ x;
  }
}

void outerIsType_assigned_body(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
      x = 42;
      g();
    } catch (_) {
      x;
    } finally {
      x;
    }
    x;
  }
}

void outerIsType_assigned_catch(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
    } catch (_) {
      /*String*/ x;
      x = 42;
    } finally {
      x;
    }
    x;
  }
}
