// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

case1_default(int e) {
  late int v;
  switch (e) {
    case 1:
      v = 0;
      break;
    case 2:
      // not assigned
      break;
    default:
      v = 0;
  }
  v;
}

case2_default(int e) {
  late int v1, v2, v3;
  switch (e) {
    case 1:
      v1 = 0;
      v2 = 0;
      v1;
      break;
    default:
      v1 = 0;
      v1;
  }
  v1;
  v2;
  /*unassigned*/ v3;
}

case_default_break(int e, bool c) {
  late int v1, v2, v3;
  switch (e) {
    case 1:
      v1 = 0;
      if (c) break;
      v2 = 0;
      break;
    default:
      v1 = 0;
      if (c) break;
      v2 = 0;
  }
  v1;
  v2;
  /*unassigned*/ v3;
}

case_default_continue(int e) {
  late int v1, v2;
  switch (e) {
    L:
    case 1:
      v1 = 0;
      break;
    case 2:
      continue L;
    default:
      v1 = 0;
  }
  v1;
  /*unassigned*/ v2;
}

case_noDefault(int e) {
  late int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      break;
  }
  v1;
  /*unassigned*/ v2;
}

condition() {
  late int v1, v2;
  switch (v1 = 0) {
  }
  v1;
  /*unassigned*/ v2;
}
