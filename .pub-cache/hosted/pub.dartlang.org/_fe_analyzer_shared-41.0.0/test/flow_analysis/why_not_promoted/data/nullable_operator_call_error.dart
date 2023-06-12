// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableOperatorCallError` error, for which we wish to report "why not
// promoted" context information.

class C1 {
  int? bad;
}

userDefinableBinaryOpLhs(C1 c) {
  if (c.bad == null) return;
  c.bad
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C1.bad, type: int?))*/
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C1.bad, type: int?))*/
      +
      1;
}

class C2 {
  int? bad;
}

userDefinableUnaryOp(C2 c) {
  if (c.bad == null) return;
  /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C2.bad, type: int?))*/
  -c.
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C2.bad, type: int?))*/
      bad;
}
