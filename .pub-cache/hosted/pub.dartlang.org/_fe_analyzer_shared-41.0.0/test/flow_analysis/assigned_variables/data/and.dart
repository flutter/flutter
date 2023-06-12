// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that binary `&&` expressions are annotated with the
// variables written on their right hand sides.  This is needed for legacy type
// promotion, to ensure that an assignment on the RHS defeats promotion.

/*member: rhs:declared={a, b, c}, read={a, c}, assigned={b}*/
rhs(bool a, bool b, bool c) {
  a /*read={c}, assigned={b}*/ && (b = c);
}
