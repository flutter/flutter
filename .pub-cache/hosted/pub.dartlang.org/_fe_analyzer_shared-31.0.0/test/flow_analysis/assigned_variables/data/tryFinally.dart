// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: tryFinally:declared={a, b, d}, assigned={a, b}*/
tryFinally(int a, int b) {
  /*assigned={a}*/ try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } finally {
    b = 0;
    var d;
  }
}

/*member: tryCatchFinally:declared={a, b, c, f}, assigned={a, b, c}*/
tryCatchFinally(int a, int b, int c) {
  // Note: try/catch/finally is desugared into try/catch nested inside
  // try/finally.  The comment preceding the "try" refers to the outer
  // "try" block of the desugaring, and the comment after the "try"
  // refers to the inner "try" block of the desugaring.
  /*declared={e}, assigned={a, b}*/ try /*declared={d}, assigned={a}*/ {
    a = 0;
    var d;
  } on String {
    b = 0;
    var e;
  } finally {
    c = 0;
    var f;
  }
}
