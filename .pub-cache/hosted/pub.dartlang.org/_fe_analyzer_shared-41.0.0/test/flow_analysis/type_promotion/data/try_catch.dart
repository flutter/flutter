// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void g() {}

void tryCatch_assigned_body(Object x) {
  if (x is! String) return;
  /*String*/ x;
  try {
    x = 42;
    g(); // might throw
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {}
  x;
}

void tryCatch_isNotType_exit_body(Object x) {
  try {
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {}
  x;
}

void isNotType_exit_body_catch(Object x) {
  try {
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {
    if (x is! String) return;
    /*String*/ x;
  }
  /*String*/ x;
}

void isNotType_exit_body_catchRethrow(Object x) {
  try {
    if (x is! String) return;
    /*String*/ x;
  } catch (_) {
    x;
    rethrow;
  }
  /*String*/ x;
}

void isNotType_exit_catch(Object x) {
  try {} catch (_) {
    if (x is! String) return;
    /*String*/ x;
  }
  x;
}
