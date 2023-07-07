// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: singleNesting:declared={a, b, c, fn}, assigned={a, b, c, d}, captured={b}*/
singleNesting(int a, int b, int c) {
  a = 0;
  // Note: for a closure, "assigned" and "captured" are restricted to
  // variables declared in enclosing contexts, so d is not included.
  var fn = /*declared={d, e}, assigned={b}*/ (int d, int e) {
    b = 0;
    d = 0;
  };
  c = 0;
}

/*member: doubleNesting:declared={a, b, c, fn1}, assigned={a, b, c, d, e, f}, captured={b, c, e}*/
doubleNesting(int a, int b, int c) {
  a = 0;
  // Note: for a closure, "assigned" and "captured" are restricted to
  // variables declared in enclosing contexts, so d, e, and f are not
  // included.
  var fn1 = /*declared={d, e, fn2}, assigned={b, c}, captured={c}*/ (int d,
      int e) {
    b = 0;
    d = 0;
    // Similarly, f is not included in "assigned" here.
    var fn2 = /*declared={f}, assigned={c, e}*/ (int f) {
      c = 0;
      e = 0;
      f = 0;
    };
  };
}
