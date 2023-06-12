// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void conditional_both(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : ((x is int) || (throw 2));
  x;
}

void conditional_else(bool b, Object x) {
  b ? 0 : ((x is int) || (throw 2));
  x;
}

void conditional_then(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : 0;
  x;
}

int conditional_in_expression_function_body(Object o) =>
    o is int ? /*int*/ o : 0;

void conditional_factor_Null(int? x) {
  x is Null ? /*Null*/ x : /*int*/ x;
  x;
}

void conditional_factor_nullable(num? x) {
  x is int? ? /*int?*/ x : /*num*/ x;
  x;
}

void conditional_join_then(bool b, Object x) {
  if (b ? x is int : x is int) {
    /*int*/ x;
  } else {
    x;
  }
}

void conditional_join_else(bool b, Object x) {
  if (b ? x is! int : x is! int) {
    x;
  } else {
    /*int*/ x;
  }
}
