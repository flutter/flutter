// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The tests in this file exercise various kinds of constructs that initialize a
// variable at its declaration site.  We verify that the variable is not
// considered definitely unassigned by the initialization.

parameter(int a) {
  a;
}

localParameter() {
  localFunction(int a) {
    a;
  }

  (int b) {
    b;
  };
}

localVariable() {
  Object a = 1;
  a;
}

catchParameters() {
  try {} on Object catch (e, st) {
    e;
    st;
  }
}
